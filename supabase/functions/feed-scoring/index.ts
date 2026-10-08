import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { adminClient, userClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const authHeader = req.headers.get("Authorization");
    const admin = adminClient();
    const body = await req.json();
    const { page = 0, page_size = 12, search, category, price_min, price_max, sort, include_sold = true } = body;

    let query = admin
      .from("listings")
      .select("*, users!listings_artist_id_fkey(full_name, verified, stripe_identity_verified)", { count: "exact" })
      .eq("status", "active");

    if (!include_sold) {
      query = query.neq("status", "sold");
    }

    if (category) query = query.eq("category", category);
    if (search) {
      query = query.or(`title.ilike.%${search}%,description.ilike.%${search}%`);
    }
    if (price_min != null) query = query.gte("price", price_min);
    if (price_max != null) query = query.lte("price", price_max);

    switch (sort) {
      case "newest":
        query = query.order("created_at", { ascending: false });
        break;
      case "popular":
        query = query.order("save_count", { ascending: false });
        break;
      case "price_low":
        query = query.order("price", { ascending: true });
        break;
      case "price_high":
        query = query.order("price", { ascending: false });
        break;
      default:
        query = query.order("created_at", { ascending: false });
    }

    const from = page * page_size;
    const to = from + page_size - 1;
    const { data, count, error } = await query.range(from, to);

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({
        items: data ?? [],
        total: count ?? 0,
        has_more: (count ?? 0) > from + page_size,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
