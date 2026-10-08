// Text embeddings with Supabase's built-in gte-small model (384 dims).
// Runs inside the Edge Runtime, so no third-party key is needed.

// deno-lint-ignore no-explicit-any
declare const Supabase: any;

let session: { run: (input: string, opts: Record<string, unknown>) => Promise<number[]> } | null = null;

export async function embed(text: string): Promise<number[]> {
  session ??= new Supabase.ai.Session("gte-small");
  const clean = text.replace(/\s+/g, " ").trim().slice(0, 2000);
  return await session!.run(clean, { mean_pool: true, normalize: true });
}

/** The text a listing is indexed by. Keep in sync with the reset trigger's columns. */
export function listingDocument(row: {
  title: string;
  description?: string | null;
  category?: string | null;
  medium?: string | null;
  tags?: string[] | null;
  dimensions?: string | null;
}): string {
  return [
    row.title,
    row.category,
    row.medium,
    row.dimensions,
    (row.tags ?? []).join(", "),
    row.description,
  ]
    .filter(Boolean)
    .join(". ");
}
