// Builds search embeddings for listings that don't have one yet.
// Call it after a listing is created or edited ({ "listing_id": "..." }), or with an
// empty body to backfill up to 50 listings at a time (safe to run on a schedule).

import { handleCors } from "../_shared/cors.ts";
import { adminClient } from "../_shared/supabase.ts";
import { embed, listingDocument } from "../_shared/embed.ts";
import { json, requireUser } from "../_shared/http.ts";

const BATCH = 50;

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  const body = await req.json().catch(() => ({}));
  const listingId = typeof body?.listing_id === "string" ? body.listing_id : null;
  const isServiceCall =
    req.headers.get("Authorization") === `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`;

  const admin = adminClient();
  let query = admin
    .from("listings")
    .select("id,artist_id,title,description,category,medium,tags,dimensions")
    .is("embedding", null)
    .limit(listingId ? 1 : BATCH);

  if (listingId) {
    // Artists can re-index their own listing; a backfill needs the service role.
    const user = await requireUser(req);
    if (!user && !isServiceCall) return json({ error: "Unauthorized" }, 401);
    query = query.eq("id", listingId);
    if (!isServiceCall) query = query.eq("artist_id", user!.id);
  } else if (!isServiceCall) {
    return json({ error: "Backfill requires the service role key" }, 403);
  }

  const { data: rows, error } = await query;
  if (error) return json({ error: error.message }, 500);

  let embedded = 0;
  for (const row of rows ?? []) {
    const vector = await embed(listingDocument(row));
    const { error: updateError } = await admin
      .from("listings")
      .update({ embedding: vector, embedded_at: new Date().toISOString() })
      .eq("id", row.id);
    if (!updateError) embedded++;
  }

  return json({ embedded, remaining: (rows?.length ?? 0) === BATCH ? "more" : 0 });
});
