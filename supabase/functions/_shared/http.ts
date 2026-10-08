import { corsHeaders } from "./cors.ts";
import { adminClient, userClient } from "./supabase.ts";

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Returns the signed-in user, or null when the request has no valid user token. */
export async function requireUser(req: Request) {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return null;
  const { data: { user } } = await userClient(authHeader).auth.getUser();
  return user;
}

/** True when the user has made fewer than `limit` calls to `feature` in the last `windowMinutes`. */
export async function withinRateLimit(
  userId: string,
  feature: string,
  limit: number,
  windowMinutes: number,
): Promise<boolean> {
  const since = new Date(Date.now() - windowMinutes * 60_000).toISOString();
  const { count } = await adminClient()
    .from("ai_usage")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .eq("feature", feature)
    .gte("created_at", since);
  return (count ?? 0) < limit;
}

export async function logUsage(row: {
  user_id: string;
  feature: string;
  model: string;
  input_tokens: number;
  output_tokens: number;
  latency_ms: number;
}) {
  await adminClient().from("ai_usage").insert(row);
}
