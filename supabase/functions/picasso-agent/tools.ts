// Picasso's tools. Each returns a dict with a `status` key so the model can tell
// success from failure, and every call is written to agent_actions for auditing.

import { ClaudeTool } from "../_shared/anthropic.ts";
import { embed } from "../_shared/embed.ts";

// deno-lint-ignore no-explicit-any
type Db = any;

export interface ToolContext {
  userId: string;
  /** Client bound to the user's token: row-level security applies to every read. */
  db: Db;
  /** Service-role client, used only for memory writes and the audit log. */
  admin: Db;
  shownArtworkIds: string[];
  actions: { type: "checkout"; listing_id: string; title: string; price: number }[];
}

type ToolResult = { status: "success" | "error"; [key: string]: unknown };

const CATEGORIES = ["Painting", "Photography", "Sculpture", "Digital", "Drawing", "Printmaking", "Mixed Media"];

export const TOOLS: ClaudeTool[] = [
  {
    name: "search_artworks",
    description:
      "Search active Picartdo listings by meaning, e.g. 'moody blue abstract for a small bedroom' or 'bold portrait with thick brushwork'. Returns up to 8 matches with id, title, artist, price, medium, size and a short description. Use this before recommending or describing any listing.",
    input_schema: {
      type: "object",
      properties: {
        query: { type: "string", description: "What the user is looking for, in natural language." },
        max_price: { type: "number", description: "Upper budget in USD, if the user gave one." },
        min_price: { type: "number", description: "Lower price bound in USD, if relevant." },
        category: { type: "string", enum: CATEGORIES, description: "Only if the user asked for a specific category." },
      },
      required: ["query"],
    },
  },
  {
    name: "get_artwork",
    description: "Get full details of one listing by id, including whether it is still available.",
    input_schema: {
      type: "object",
      properties: { listing_id: { type: "string", description: "Listing id from a previous tool result." } },
      required: ["listing_id"],
    },
  },
  {
    name: "get_my_saved_artworks",
    description: "List the artworks the user has saved or liked. Useful for learning their taste or answering questions about their saves.",
    input_schema: { type: "object", properties: {} },
  },
  {
    name: "get_my_orders",
    description: "List the user's recent purchases with status (pending, paid, shipped, completed, refunded).",
    input_schema: { type: "object", properties: {} },
  },
  {
    name: "show_artworks",
    description: "Display listings to the user as tappable cards under your reply. Pass the ids of the 2 to 4 pieces you are recommending.",
    input_schema: {
      type: "object",
      properties: { listing_ids: { type: "array", items: { type: "string" }, maxItems: 6 } },
      required: ["listing_ids"],
    },
  },
  {
    name: "propose_checkout",
    description:
      "Show a Buy button for one listing when the user clearly wants to purchase it. This does NOT buy anything; the user must confirm in the app.",
    input_schema: {
      type: "object",
      properties: { listing_id: { type: "string" } },
      required: ["listing_id"],
    },
  },
  {
    name: "remember_preference",
    description:
      "Save one lasting fact about the user's taste for future conversations, e.g. 'Loves Cubism and bold reds' or 'Budget usually under $1,000'. One short sentence. Never save sensitive personal data.",
    input_schema: {
      type: "object",
      properties: { fact: { type: "string", maxLength: 200 } },
      required: ["fact"],
    },
  },
];

export async function runTool(name: string, input: Record<string, unknown>, ctx: ToolContext): Promise<ToolResult> {
  const started = Date.now();
  let result: ToolResult;
  try {
    result = await dispatch(name, input, ctx);
  } catch (err) {
    result = { status: "error", error: err instanceof Error ? err.message : String(err) };
  }
  await ctx.admin.from("agent_actions").insert({
    user_id: ctx.userId,
    agent: "picasso",
    tool: name,
    input,
    status: result.status,
    error: result.status === "error" ? String(result.error ?? "") : null,
    duration_ms: Date.now() - started,
  });
  return result;
}

async function dispatch(name: string, input: Record<string, unknown>, ctx: ToolContext): Promise<ToolResult> {
  switch (name) {
    case "search_artworks":
      return await searchArtworks(input, ctx);
    case "get_artwork":
      return await getArtwork(String(input.listing_id ?? ""), ctx);
    case "get_my_saved_artworks":
      return await getSaved(ctx);
    case "get_my_orders":
      return await getOrders(ctx);
    case "show_artworks":
      return await showArtworks(input.listing_ids, ctx);
    case "propose_checkout":
      return await proposeCheckout(String(input.listing_id ?? ""), ctx);
    case "remember_preference":
      return await rememberPreference(String(input.fact ?? ""), ctx);
    default:
      return { status: "error", error: `Unknown tool ${name}` };
  }
}

const SUMMARY_COLUMNS = "id,title,description,price,category,medium,dimensions,status,users(full_name)";

// deno-lint-ignore no-explicit-any
function summarize(row: any) {
  return {
    id: row.id,
    title: row.title,
    artist: row.users?.full_name ?? "Unknown artist",
    price_usd: Number(row.price),
    category: row.category,
    medium: row.medium,
    size: row.dimensions,
    available: row.status === "active",
    description: (row.description ?? "").slice(0, 400),
  };
}

async function searchArtworks(input: Record<string, unknown>, ctx: ToolContext): Promise<ToolResult> {
  const query = String(input.query ?? "").trim();
  if (!query) return { status: "error", error: "query is required" };
  const maxPrice = typeof input.max_price === "number" ? input.max_price : null;
  const minPrice = typeof input.min_price === "number" ? input.min_price : null;
  const category = typeof input.category === "string" ? input.category : null;

  const { data: matches, error } = await ctx.db.rpc("match_listings", {
    query_embedding: await embed(query),
    match_count: 8,
    min_price: minPrice,
    max_price: maxPrice,
    filter_category: category,
  });
  if (error) return { status: "error", error: error.message };

  let ids: string[] = (matches ?? []).map((m: { id: string }) => m.id);

  // Keyword fallback while listings are still being embedded.
  if (!ids.length) {
    let q = ctx.db.from("listings").select("id").eq("status", "active").limit(8);
    const term = query.replace(/[%,()]/g, " ").split(/\s+/).filter((w) => w.length > 2)[0];
    if (term) q = q.or(`title.ilike.%${term}%,description.ilike.%${term}%,medium.ilike.%${term}%`);
    if (maxPrice !== null) q = q.lte("price", maxPrice);
    if (minPrice !== null) q = q.gte("price", minPrice);
    if (category) q = q.ilike("category", category);
    const { data } = await q;
    ids = (data ?? []).map((r: { id: string }) => r.id);
  }
  if (!ids.length) return { status: "success", results: [], note: "No matching listings." };

  const { data: rows, error: rowsError } = await ctx.db.from("listings").select(SUMMARY_COLUMNS).in("id", ids);
  if (rowsError) return { status: "error", error: rowsError.message };
  const byId = new Map((rows ?? []).map((r: { id: string }) => [r.id, r]));
  return { status: "success", results: ids.map((id) => byId.get(id)).filter(Boolean).map(summarize) };
}

async function getArtwork(id: string, ctx: ToolContext): Promise<ToolResult> {
  if (!isUuid(id)) return { status: "error", error: "listing_id must be a listing id from a tool result" };
  const { data, error } = await ctx.db.from("listings").select(SUMMARY_COLUMNS + ",tags").eq("id", id).maybeSingle();
  if (error) return { status: "error", error: error.message };
  if (!data) return { status: "error", error: "Listing not found or no longer available" };
  return { status: "success", artwork: { ...summarize(data), tags: data.tags ?? [] } };
}

async function getSaved(ctx: ToolContext): Promise<ToolResult> {
  const { data, error } = await ctx.db
    .from("saves")
    .select(`created_at, listings(${SUMMARY_COLUMNS})`)
    .eq("user_id", ctx.userId)
    .order("created_at", { ascending: false })
    .limit(15);
  if (error) return { status: "error", error: error.message };
  // deno-lint-ignore no-explicit-any
  return { status: "success", saved: (data ?? []).filter((r: any) => r.listings).map((r: any) => summarize(r.listings)) };
}

async function getOrders(ctx: ToolContext): Promise<ToolResult> {
  const { data, error } = await ctx.db
    .from("orders")
    .select("id,status,amount,created_at,listings(title)")
    .eq("buyer_id", ctx.userId)
    .order("created_at", { ascending: false })
    .limit(10);
  if (error) return { status: "error", error: error.message };
  return {
    status: "success",
    // deno-lint-ignore no-explicit-any
    orders: (data ?? []).map((o: any) => ({
      order_id: o.id,
      artwork: o.listings?.title ?? "Artwork",
      status: o.status,
      amount_usd: Number(o.amount),
      ordered_at: o.created_at,
    })),
  };
}

async function showArtworks(raw: unknown, ctx: ToolContext): Promise<ToolResult> {
  const ids = Array.isArray(raw) ? raw.map(String).filter(isUuid).slice(0, 6) : [];
  if (!ids.length) return { status: "error", error: "listing_ids must contain listing ids from a tool result" };
  const { data } = await ctx.db.from("listings").select("id").in("id", ids).eq("status", "active");
  const found = (data ?? []).map((r: { id: string }) => r.id);
  ctx.shownArtworkIds.push(...found);
  return { status: "success", shown: found.length, missing: ids.filter((id) => !found.includes(id)) };
}

async function proposeCheckout(id: string, ctx: ToolContext): Promise<ToolResult> {
  if (!isUuid(id)) return { status: "error", error: "listing_id must be a listing id from a tool result" };
  const { data } = await ctx.db.from("listings").select("id,title,price,status,artist_id").eq("id", id).maybeSingle();
  if (!data) return { status: "error", error: "Listing not found" };
  if (data.status !== "active") return { status: "error", error: "This piece is no longer available" };
  if (data.artist_id === ctx.userId) return { status: "error", error: "This is the user's own listing" };
  if (!ctx.actions.some((a) => a.listing_id === id)) {
    ctx.actions.push({ type: "checkout", listing_id: id, title: data.title, price: Number(data.price) });
  }
  if (!ctx.shownArtworkIds.includes(id)) ctx.shownArtworkIds.push(id);
  return { status: "success", note: "A Buy button is shown. The user must confirm the purchase themselves." };
}

async function rememberPreference(fact: string, ctx: ToolContext): Promise<ToolResult> {
  const clean = fact.replace(/\s+/g, " ").trim().slice(0, 200);
  if (clean.length < 3) return { status: "error", error: "fact is too short" };
  const { error } = await ctx.admin.from("picasso_memories").insert({ user_id: ctx.userId, fact: clean });
  if (error) return { status: "error", error: error.message };
  return { status: "success" };
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}
