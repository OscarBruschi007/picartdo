-- Picasso agent: semantic search, long-term memory, action audit log, usage limits.

-- 1. Semantic search over listings
-- Embeddings come from Supabase's built-in gte-small model (384 dims, no extra API key).
-- The original 1536-dim column was never populated, so it is replaced.
ALTER TABLE public.listings DROP COLUMN IF EXISTS embedding;
ALTER TABLE public.listings ADD COLUMN embedding VECTOR(384);
ALTER TABLE public.listings ADD COLUMN embedded_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_listings_embedding
  ON public.listings USING hnsw (embedding vector_cosine_ops);

-- Clear the embedding when the text it was built from changes, so embed-listings re-indexes it.
CREATE OR REPLACE FUNCTION public.reset_listing_embedding()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.title IS DISTINCT FROM OLD.title
     OR NEW.description IS DISTINCT FROM OLD.description
     OR NEW.category IS DISTINCT FROM OLD.category
     OR NEW.medium IS DISTINCT FROM OLD.medium
     OR NEW.tags IS DISTINCT FROM OLD.tags THEN
    NEW.embedding := NULL;
    NEW.embedded_at := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER listings_reset_embedding
  BEFORE UPDATE ON public.listings
  FOR EACH ROW EXECUTE FUNCTION public.reset_listing_embedding();

-- Meaning-based search with hard filters. Only active listings are ever returned.
CREATE OR REPLACE FUNCTION public.match_listings(
  query_embedding VECTOR(384),
  match_count INT DEFAULT 8,
  min_price NUMERIC DEFAULT NULL,
  max_price NUMERIC DEFAULT NULL,
  filter_category TEXT DEFAULT NULL
)
RETURNS TABLE (id UUID, similarity FLOAT)
LANGUAGE sql STABLE
AS $$
  SELECT l.id, 1 - (l.embedding <=> query_embedding) AS similarity
  FROM public.listings l
  WHERE l.status = 'active'
    AND l.embedding IS NOT NULL
    AND (min_price IS NULL OR l.price >= min_price)
    AND (max_price IS NULL OR l.price <= max_price)
    AND (filter_category IS NULL OR l.category ILIKE filter_category)
  ORDER BY l.embedding <=> query_embedding
  LIMIT LEAST(match_count, 20);
$$;

-- 2. Long-term memory: short distilled facts about each user's taste
CREATE TABLE public.picasso_memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  fact TEXT NOT NULL CHECK (char_length(fact) BETWEEN 3 AND 280),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_picasso_memories_user ON public.picasso_memories(user_id, created_at DESC);

ALTER TABLE public.picasso_memories ENABLE ROW LEVEL SECURITY;
CREATE POLICY picasso_memories_select_own ON public.picasso_memories
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY picasso_memories_delete_own ON public.picasso_memories
  FOR DELETE USING (user_id = auth.uid());
-- Inserts happen only from the picasso-agent function (service role).

-- 3. Audit log of every tool the agent ran
CREATE TABLE public.agent_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  agent TEXT NOT NULL,
  tool TEXT NOT NULL,
  input JSONB,
  status TEXT NOT NULL CHECK (status IN ('success', 'error')),
  error TEXT,
  duration_ms INT,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_agent_actions_user ON public.agent_actions(user_id, created_at DESC);
CREATE INDEX idx_agent_actions_tool ON public.agent_actions(tool, status);
ALTER TABLE public.agent_actions ENABLE ROW LEVEL SECURITY;
-- No client policies: service role only.

-- 4. Usage log for per-user rate limits and cost tracking
CREATE TABLE public.ai_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  feature TEXT NOT NULL,
  model TEXT NOT NULL,
  input_tokens INT DEFAULT 0,
  output_tokens INT DEFAULT 0,
  latency_ms INT,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_ai_usage_user_time ON public.ai_usage(user_id, feature, created_at DESC);
ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;

-- 5. Thumbs up/down on Picasso replies
CREATE TABLE public.picasso_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  request_id UUID NOT NULL,
  rating SMALLINT NOT NULL CHECK (rating IN (-1, 1)),
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (user_id, request_id)
);
ALTER TABLE public.picasso_feedback ENABLE ROW LEVEL SECURITY;
CREATE POLICY picasso_feedback_insert_own ON public.picasso_feedback
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY picasso_feedback_select_own ON public.picasso_feedback
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY picasso_feedback_update_own ON public.picasso_feedback
  FOR UPDATE USING (user_id = auth.uid());
