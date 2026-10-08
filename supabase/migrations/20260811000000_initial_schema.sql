-- Picartdo production schema
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

-- USERS (extends Supabase auth.users via trigger)
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE,
  full_name TEXT,
  username TEXT UNIQUE,
  avatar_url TEXT,
  banner_url TEXT,
  user_type TEXT CHECK (user_type IN ('artist', 'collector', 'both')),
  persona TEXT[] DEFAULT '{}',
  bio TEXT,
  tagline TEXT,
  location TEXT,
  website TEXT,
  verified BOOLEAN DEFAULT false,
  stripe_account_id TEXT,
  stripe_customer_id TEXT,
  stripe_identity_verified BOOLEAN DEFAULT false,
  stripe_identity_session_id TEXT,
  identity_verified_at TIMESTAMPTZ,
  onboarding_completed BOOLEAN DEFAULT false,
  pro_subscription_status TEXT DEFAULT 'free',
  revenuecat_app_user_id TEXT,
  notification_token TEXT,
  is_suspended BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.stripe_connect_accounts (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  stripe_account_id TEXT UNIQUE,
  charges_enabled BOOLEAN DEFAULT false,
  payouts_enabled BOOLEAN DEFAULT false,
  details_submitted BOOLEAN DEFAULT false,
  onboarding_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  stripe_payment_method_id TEXT NOT NULL,
  brand TEXT,
  last4 TEXT,
  exp_month INT,
  exp_year INT,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  artist_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  listing_type TEXT NOT NULL DEFAULT 'product' CHECK (listing_type IN ('product', 'service', 'experience')),
  price DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  images TEXT[] DEFAULT '{}',
  category TEXT,
  medium TEXT,
  dimensions TEXT,
  tags TEXT[] DEFAULT '{}',
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'sold', 'pending_review', 'suspended')),
  inventory_count INT DEFAULT 1,
  location TEXT,
  duration_minutes INT,
  like_count INT DEFAULT 0,
  save_count INT DEFAULT 0,
  embedding VECTOR(1536),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES public.listings(id),
  buyer_id UUID REFERENCES public.users(id),
  seller_id UUID NOT NULL REFERENCES public.users(id),
  guest_email TEXT,
  amount DECIMAL(10,2) NOT NULL,
  platform_fee DECIMAL(10,2) NOT NULL,
  seller_amount DECIMAL(10,2) NOT NULL,
  stripe_payment_intent_id TEXT,
  stripe_checkout_session_id TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'shipped', 'completed', 'refunded', 'disputed', 'failed')),
  shipping_address JSONB,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL REFERENCES public.users(id),
  reviewee_id UUID NOT NULL REFERENCES public.users(id),
  listing_id UUID NOT NULL REFERENCES public.listings(id),
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  text TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(order_id, reviewer_id)
);

CREATE TABLE public.saves (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, listing_id)
);

CREATE TABLE public.follows (
  follower_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (follower_id, following_id)
);

CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  listing_id UUID REFERENCES public.listings(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.commission_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID REFERENCES public.users(id),
  artist_id UUID NOT NULL REFERENCES public.users(id),
  guest_name TEXT,
  guest_email TEXT,
  style TEXT,
  size TEXT,
  timeline TEXT,
  budget_min DECIMAL(10,2),
  budget_max DECIMAL(10,2),
  description TEXT,
  reference_note TEXT,
  reference_image_urls TEXT[] DEFAULT '{}',
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'completed')),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.moderation_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  reason TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_listings_artist ON public.listings(artist_id);
CREATE INDEX idx_listings_status ON public.listings(status);
CREATE INDEX idx_listings_category ON public.listings(category);
CREATE INDEX idx_listings_created ON public.listings(created_at DESC);
CREATE INDEX idx_orders_buyer ON public.orders(buyer_id);
CREATE INDEX idx_orders_seller ON public.orders(seller_id);
CREATE INDEX idx_messages_participants ON public.messages(sender_id, recipient_id);
CREATE INDEX idx_messages_created ON public.messages(created_at DESC);
CREATE INDEX idx_saves_user ON public.saves(user_id);
CREATE INDEX idx_saves_listing ON public.saves(listing_id);

-- Auto-create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Update save_count on listings
CREATE OR REPLACE FUNCTION public.update_listing_save_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.listings SET save_count = save_count + 1 WHERE id = NEW.listing_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.listings SET save_count = GREATEST(save_count - 1, 0) WHERE id = OLD.listing_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_save_change
  AFTER INSERT OR DELETE ON public.saves
  FOR EACH ROW EXECUTE FUNCTION public.update_listing_save_count();

-- RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stripe_connect_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saves ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moderation_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY users_select ON public.users FOR SELECT USING (true);
CREATE POLICY users_update_own ON public.users FOR UPDATE USING (auth.uid() = id);

-- Listings policies
CREATE POLICY listings_select_active ON public.listings FOR SELECT USING (
  status IN ('active', 'sold') OR artist_id = auth.uid()
);
CREATE POLICY listings_insert_own ON public.listings FOR INSERT WITH CHECK (artist_id = auth.uid());
CREATE POLICY listings_update_own ON public.listings FOR UPDATE USING (artist_id = auth.uid());
CREATE POLICY listings_delete_own ON public.listings FOR DELETE USING (artist_id = auth.uid());

-- Orders policies
CREATE POLICY orders_select_participant ON public.orders FOR SELECT USING (
  buyer_id = auth.uid() OR seller_id = auth.uid()
);
CREATE POLICY orders_insert_buyer ON public.orders FOR INSERT WITH CHECK (
  buyer_id = auth.uid() OR buyer_id IS NULL
);

-- Saves policies
CREATE POLICY saves_select_own ON public.saves FOR SELECT USING (user_id = auth.uid());
CREATE POLICY saves_insert_own ON public.saves FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY saves_delete_own ON public.saves FOR DELETE USING (user_id = auth.uid());

-- Follows policies
CREATE POLICY follows_select ON public.follows FOR SELECT USING (true);
CREATE POLICY follows_insert ON public.follows FOR INSERT WITH CHECK (follower_id = auth.uid());
CREATE POLICY follows_delete ON public.follows FOR DELETE USING (follower_id = auth.uid());

-- Messages policies
CREATE POLICY messages_select_participant ON public.messages FOR SELECT USING (
  sender_id = auth.uid() OR recipient_id = auth.uid()
);
CREATE POLICY messages_insert_sender ON public.messages FOR INSERT WITH CHECK (sender_id = auth.uid());
CREATE POLICY messages_update_recipient ON public.messages FOR UPDATE USING (recipient_id = auth.uid());

-- Reviews policies
CREATE POLICY reviews_select ON public.reviews FOR SELECT USING (true);
CREATE POLICY reviews_insert ON public.reviews FOR INSERT WITH CHECK (reviewer_id = auth.uid());

-- Payment methods policies
CREATE POLICY payment_methods_own ON public.payment_methods FOR ALL USING (user_id = auth.uid());

-- Connect accounts policies
CREATE POLICY connect_own ON public.stripe_connect_accounts FOR ALL USING (user_id = auth.uid());

-- Commission requests policies
CREATE POLICY commissions_select ON public.commission_requests FOR SELECT USING (
  buyer_id = auth.uid() OR artist_id = auth.uid()
);
CREATE POLICY commissions_insert ON public.commission_requests FOR INSERT WITH CHECK (
  buyer_id = auth.uid() OR buyer_id IS NULL
);

-- Reports policies
CREATE POLICY reports_insert ON public.reports FOR INSERT WITH CHECK (reporter_id = auth.uid());

-- Storage buckets (run via Supabase dashboard or API)
-- listing-images (public), avatars (public), commission-references (private)
