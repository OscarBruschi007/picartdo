# Picartdo — Full CTO Audit & Action Plan
### Built to scale to billions. No shortcuts.

---

## FIRST: YOUR BRUTAL HONEST BASELINE

Before any section — here's where you stand right now:

✅ Great market (global art market = $65B/year, online art growing 19% YoY)
✅ Unique angle: products + services + EXPERIENCES in one place (nobody does all three well)
✅ Building in Xcode = iOS-first = right platform for art (visual, premium, buyers have money)
⚠️ No tech stack defined yet = you need to fix this in the next 7 days
⚠️ No users = you need a waitlist running before your pitch, not users
⚠️ Business model uncertain = this needs to be locked before you pitch
⚠️ One month is tight but doable if you focus on demo + deck, not a fully built app

**The pitch is NOT about having a finished app. It's about showing a compelling vision, a working demo, and a clear roadmap. You can win this.**

---

## 1. DESIGN AUDIT

### What a billion-dollar art marketplace looks like in 2025

Think: Etsy's trust + Instagram's discovery + Airbnb's experience booking — with an editorial, gallery-quality aesthetic. The art must be the hero of every screen. Every pixel that isn't art is wasted space.

**References to study right now:**
- **Are.na** — editorial discovery, minimal chrome
- **Artsy** — how they display gallery-quality art with price and provenance
- **Etsy** — trust signals, reviews, seller profiles
- **Airbnb** — experience booking flow (copy this exactly for your Experiences section)

### The 5 Critical UI/UX Improvements to Make Immediately

**1. Art-First Layout — Full bleed, zero clutter**
Every listing image should take up 90%+ of the screen. No borders, no heavy UI chrome. The artwork IS the UI. Use a floating navigation bar (glass morphism style) over images, not below them.

**2. Dual Persona Onboarding (Artist vs Collector)**
On screen 2 of onboarding, ask: "Are you here to sell your art or discover it?" Then customize everything — the feed, the home screen, the suggestions — based on that answer. Artists see studio tools, pricing help, and portfolio features. Buyers see curated collections and experiences.

**3. Trust Signals on Every Listing**
- Verified Artist badge (blue checkmark, but make it art-themed — a palette icon)
- "X collectors own this artist's work"
- Secure checkout badge
- Return policy clearly stated
- Response time ("Usually replies in 2 hours")

No trust = no purchase. This is the #1 reason art marketplaces fail.

**4. One-Tap Save / Wishlist**
A heartbeat animation when someone saves a piece. Show "47 people saved this." Saved items live in a beautiful gallery-style collection. This drives return visits and eventual purchases.

**5. Friction-Free Checkout — 2 taps maximum**
Tap "Buy" → review order → tap "Pay with Apple Pay." Done. No forms, no accounts required for first purchase (guest checkout). Every additional tap kills 20% of conversions.

### Design System

**Colors:**
- Primary background: `#0A0A0A` (near-black) — makes art pop like a gallery wall
- Surface: `#1A1A1A`
- Accent: `#E8C547` (warm gold) — premium, artistic, memorable
- Text primary: `#FFFFFF`
- Text secondary: `#A0A0A0`
- Success: `#4CAF82`
- Error: `#E85547`

**Typography:**
- Display / Headlines: Canela or Freight Display (editorial, gallery feel)
- Body: SF Pro (native iOS — fast, accessible, Apple-approved)
- Prices / Numbers: SF Mono (clean, precise)

**Spacing:** Use an 8pt grid system. All margins and paddings divisible by 8 (8, 16, 24, 32, 48, 64).

**Component Library:** Build in SwiftUI using Apple's native components + your custom design tokens. Do NOT try to rebuild everything from scratch — use SF Symbols for all icons.

### Animations & Micro-interactions That Feel Premium

- Listing tap → image expands with spring animation (stiffness: 300, damping: 30)
- Save → pulse + fill animation on heart icon, satisfying haptic feedback
- Checkout success → confetti burst + "You're a collector now" celebration screen
- Pull to refresh → custom art-themed loading animation (paintbrush stroke drawing)
- Scroll → parallax effect on hero images in the feed
- Artist profile → portfolio images stagger-animate in on appear

Use `withAnimation(.spring(response: 0.4, dampingFraction: 0.7))` in SwiftUI for most interactions.

### Onboarding Flow for Maximum Day-1 Retention

- **Screen 1:** Full-screen art image (carousel of 3 stunning pieces), tagline: "Buy. Sell. Experience Art." → "Get Started" button
- **Screen 2:** "I'm here to..." → [Sell My Art] [Discover & Buy] [Find Experiences] (can select multiple)
- **Screen 3:** Sign up with Apple (required on iOS if you offer other social login) or Email. No passwords — magic link or Apple Sign In only.
- **Screen 4 (Artist path):** "Upload your first piece in 60 seconds" → camera roll opens immediately
- **Screen 4 (Buyer path):** "What moves you?" → 8 art style tiles (Abstract, Photography, Sculpture, Digital, etc.) → personalized feed instantly
- **Screen 5:** Enable notifications with context: "Get notified when [artist name] drops new work" — NOT a generic permission dialog. Context-specific = 3x higher acceptance.

**Target: Onboarding completion in under 90 seconds.**

---

## 2. BACKEND ARCHITECTURE

### Your Tech Stack (Decided. No debate needed.)

You're building in Xcode with Swift/SwiftUI. Here is your complete stack:

**Frontend:** Swift + SwiftUI (iOS first — ship Android 12 months later)

**Backend:** Supabase — this is your entire backend
- PostgreSQL database (fully hosted, infinitely scalable)
- Authentication (Apple Sign In, Email, Google)
- File/image storage (built-in S3-compatible)
- Real-time subscriptions (for notifications, live updates)
- Edge Functions (serverless — for payment webhooks, AI calls)
- Row Level Security (RLS) — critical for marketplace data protection

> Why Supabase and not Firebase? Supabase uses PostgreSQL (relational = perfect for marketplace relationships like orders, listings, commissions). Firebase uses NoSQL which gets messy for this type of app. Supabase is also open-source and you can self-host if you ever need to.

**Image Storage & CDN:** Supabase Storage + Cloudflare CDN
- Store originals in Supabase Storage
- Serve through Cloudflare for global speed (images load in <100ms worldwide)
- Use Cloudflare Image Resizing to auto-compress and resize (thumbnail, medium, full)

**Payments:** Stripe Connect (marketplace payments) + RevenueCat (subscriptions)
**Analytics:** PostHog (self-hosted or cloud — open source, no vendor lock-in)
**Error Tracking:** Sentry (free tier, install on day 1)
**Email:** Resend (the best transactional email API — dead simple)
**Push Notifications:** Apple Push Notification Service (APNs) via Supabase

### Database Schema

```sql
-- USERS
users (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE,
  full_name TEXT,
  username TEXT UNIQUE,
  avatar_url TEXT,
  user_type TEXT CHECK (user_type IN ('artist', 'collector', 'both')),
  bio TEXT,
  location TEXT,
  website TEXT,
  verified BOOLEAN DEFAULT false,
  stripe_account_id TEXT,  -- for artists receiving payments
  stripe_customer_id TEXT, -- for buyers making payments
  created_at TIMESTAMPTZ DEFAULT now()
)

-- LISTINGS (products, services, experiences)
listings (
  id UUID PRIMARY KEY,
  artist_id UUID REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  listing_type TEXT CHECK (listing_type IN ('product', 'service', 'experience')),
  price DECIMAL(10,2),
  currency TEXT DEFAULT 'USD',
  images TEXT[],  -- array of image URLs
  category TEXT,
  tags TEXT[],
  status TEXT DEFAULT 'active',  -- active, sold, draft
  inventory_count INT,  -- null = unlimited (services/experiences)
  location TEXT,  -- for in-person experiences
  duration_minutes INT,  -- for experiences/services
  embedding VECTOR(1536),  -- for AI semantic search (pgvector)
  created_at TIMESTAMPTZ DEFAULT now()
)

-- ORDERS
orders (
  id UUID PRIMARY KEY,
  listing_id UUID REFERENCES listings(id),
  buyer_id UUID REFERENCES users(id),
  seller_id UUID REFERENCES users(id),
  amount DECIMAL(10,2),
  platform_fee DECIMAL(10,2),  -- your commission
  seller_amount DECIMAL(10,2), -- what artist receives
  stripe_payment_intent_id TEXT,
  status TEXT DEFAULT 'pending',  -- pending, paid, shipped, completed, refunded, disputed
  shipping_address JSONB,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
)

-- REVIEWS
reviews (
  id UUID PRIMARY KEY,
  order_id UUID REFERENCES orders(id),
  reviewer_id UUID REFERENCES users(id),
  reviewee_id UUID REFERENCES users(id),
  listing_id UUID REFERENCES listings(id),
  rating INT CHECK (rating BETWEEN 1 AND 5),
  text TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
)

-- SAVES / WISHLIST
saves (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  listing_id UUID REFERENCES listings(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, listing_id)
)

-- FOLLOWS
follows (
  follower_id UUID REFERENCES users(id),
  following_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (follower_id, following_id)
)

-- MESSAGES (for buyer-artist communication)
messages (
  id UUID PRIMARY KEY,
  sender_id UUID REFERENCES users(id),
  recipient_id UUID REFERENCES users(id),
  listing_id UUID REFERENCES listings(id),
  content TEXT,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
)
```

### Image Handling at Scale

1. Artist uploads → iOS app compresses to max 4MB before upload
2. Upload to Supabase Storage (which uses S3 under the hood)
3. Cloudflare CDN sits in front — serves images from edge globally
4. Use Cloudflare Image Resizing URLs: `?width=400&quality=85&format=webp`
5. Store 3 versions automatically: thumbnail (200px), medium (800px), full (2000px)

Cost at 10M users: approximately $200–400/month for storage + CDN. Negligible.

### Discovery Algorithm (The Feed)

For your first version: **Interest Graph + Recency**

```
Score = (0.4 × style_match) + (0.3 × artist_following) + (0.2 × location_proximity) + (0.1 × recency)
```

- `style_match`: cosine similarity between listing embedding and user interest embedding
- `artist_following`: boost listings from artists the user follows
- `location_proximity`: boost local artists/experiences (especially for experiences)
- `recency`: decay function (new listings get a 48-hour boost)

Build this as a Supabase Edge Function that runs on feed load.

---

## 3. PAYMENTS & MONETIZATION

### Your Business Model (Recommended: Hybrid Marketplace)

Three revenue streams that compound on each other:

**Stream 1: Transaction Commission — 12% on every sale**
- Industry standard for art marketplaces is 10–20%
- Etsy charges 6.5% + listing fees. Artsy charges 20–40%. You live in the middle.
- Applies to all three categories: products, services, experiences
- Example: $500 painting sold → you earn $60

**Stream 2: Artist Pro Subscription — $19.99/month**
- Free artists: up to 10 listings, basic analytics, 10% commission
- Pro artists: unlimited listings, advanced analytics, 8% commission, featured placement, AI tools
- Creates recurring revenue BEFORE artists sell anything

**Stream 3: Promoted Listings — $9.99 to $49.99**
- Artists pay to feature work in discovery feeds, search results, or "Editor's Pick"
- Pure margin — no fulfillment

**What NOT to do:**
- Don't charge listing fees upfront (kills artist supply early)
- Don't try to compete on commission alone (win on features + trust instead)
- Don't do in-app purchases for physical goods via Apple (Apple takes 30% — catastrophic for margins)

**Revenue projection:**
- 1,000 artists × $19.99 Pro = $20K/month recurring
- 500 transactions/month × $200 avg × 12% = $12K/month
- 100 promoted listings × $25 avg = $2.5K/month
- **Month 6 target: ~$35K MRR**

### Stripe vs RevenueCat — Both. Different jobs.

**Stripe Connect** → for marketplace transactions
- Set up "Standard" Stripe Connect account for each artist
- When buyer pays, Stripe automatically splits: 88% to artist, 12% to you
- Handles all payouts, 1099s, international transfers
- Stripe Radar handles fraud detection automatically

**RevenueCat** → for the Pro Artist subscription ($19.99/month)
- Handles Apple's in-app purchase system (required for recurring subscriptions in iOS)
- Handles receipt validation, renewal, cancellation, grace periods
- Apple takes 15% (you're new) of $19.99 = you keep ~$17

Setup order: Stripe first (primary money). RevenueCat second (subscriptions).

### Freemium Conversion

Free tier creates ONE friction point that makes Pro obvious:
- Artists hit 10 listings → "You've hit the limit. Serious artists go Pro."
- Analytics locked → after first sale → "See who's viewing your work."
- Show Pro artists' earnings vs free artists (real anonymized data after 60 days)

**Target: 15% of active artists convert to Pro within 90 days.**

### Refunds & Disputes (Automated)

- Physical products: 14-day return, buyer pays return shipping
- Digital products: No refunds (stated clearly at checkout)
- Services: Refund if artist cancels, no refund if buyer cancels within 24 hours
- Experiences: Full refund if cancelled 72+ hours before, 50% within 72 hours

Automate with a Supabase Edge Function handling Stripe webhook events:
- `charge.dispute.created` → immediately email both parties, freeze funds
- `payment_intent.payment_failed` → email buyer, release inventory
- `charge.refunded` → update order status, email both parties

### Subscription Page for Maximum Conversion

One screen. Three elements only:
1. Side-by-side Free vs Pro comparison table (Pro column highlighted in gold)
2. Testimonial: "Made $3,200 in my first month as a Pro artist — Maria G."
3. Big button: **"Start 14-Day Free Trial"** (not "Subscribe" — trial reduces friction 40%)

---

## 4. SECURITY & TRUST

### Authentication

Use: **Apple Sign In + Supabase Auth**

Apple Sign In is mandatory on iOS if you offer any third-party login. It also gives you the highest trust signals (Face ID, Touch ID) and Apple's fraud detection.

For artist verification (critical for trust): Use **Stripe Identity** ($1.50/verification) — artists upload ID, Stripe verifies it, you display "Verified Artist" badge. Do this for sellers, not buyers.

### Protecting Art & User Data

- **Supabase Row Level Security (RLS):** Users can ONLY see/modify their own data. Write policies for every table. Non-negotiable.
- **Images:** Never expose direct S3/Supabase URLs. Always serve through Cloudflare with signed URLs that expire in 24 hours for private content.
- **Watermarking:** Add subtle watermark to full-resolution images. Buyers only get unwatermarked files after purchase confirmation.
- **EXIF data:** Strip all EXIF metadata from uploaded images before storage (privacy).

### Content Moderation

**Layer 1 (automatic):** AWS Rekognition or Hive Moderation API
- Scan every uploaded image for: nudity, violence, hate symbols
- Auto-reject with explanation if flagged
- Cost: ~$1 per 1,000 images

**Layer 2 (human):** Build a simple admin dashboard in Supabase Studio
- All flagged content goes to a review queue
- Approve/reject within 24 hours

**Layer 3 (community):** Users can report listings. 3 reports = auto-suspend pending review.

### Privacy Law Compliance

**GDPR (Europe):** Add "Delete My Account" button that wipes all personal data within 30 days. Add cookie consent banner (use Cookiebot — free tier works).

**CCPA (California):** Add "Do Not Sell My Personal Information" link in settings.

**Both:** Add Privacy Policy and Terms of Service (use Termly.io — $10/month, legally solid) before launch.

### Protecting Against Abuse

- Rate limiting: Cloudflare rules — max 100 API calls/minute per IP
- Account takeover: Supabase Auth has built-in brute force protection. Enable it.
- Fake listings: New artists start with a "probationary" period — listings manually reviewed until first successful sale
- Spam messages: Limit messages to 10/day between users until first transaction
- Chargeback fraud: Require ID verification for purchases over $500

---

## 5. AI FEATURES

These features are what separate Picartdo from every other art marketplace and what makes the pitch compelling.

**Feature 1: AI Semantic Search — "Find me a moody blue abstract under $300"**
Buyers type natural language. Your system uses embeddings to find semantically matching listings — not keyword matching.
- Call OpenAI `text-embedding-3-small` on title + description + tags when listing is uploaded
- Store in `listings.embedding` (pgvector in Supabase)
- On search: `SELECT * FROM listings ORDER BY embedding <-> $query_embedding LIMIT 20`
- Cost: fractions of a cent per search

**Feature 2: AI Price Recommendation for Artists**
"Based on similar works, artists price this between $180–$340." Uses similar listing embeddings + their prices. Show as a range, not a number (artists don't like being told what to charge).

**Feature 3: AI Style DNA for Buyers**
After a buyer saves 5+ pieces, Claude analyzes their collection: "You're drawn to geometric abstraction with warm palettes — here are 3 artists who match your taste."

**Feature 4: AI Art Description Generator for Artists**
Artists describe their piece in one sentence → AI writes the full listing description.
- Input: "This is my painting of the ocean at sunset, oil on canvas"
- Output: A compelling, emotional 150-word description that sells
- Built with a carefully crafted Claude API system prompt

**Feature 5: Visual Similarity Search**
"Show me more like this" button on every listing. Uses CLIP model via Replicate API for image embeddings stored in pgvector.

**Feature 6: AI Content Moderation** (covered in Security — but mention it in your pitch as an AI feature)

---

## 6. CO-FOUNDER PITCH READINESS

### Brutal Truth About Your Pitch

You have 30 days. You cannot build everything. You need to walk in with:
1. A polished demo (not a finished app — a demo)
2. A story about the market
3. A clear business model
4. Evidence of demand (waitlist, even 50 artist sign-ups is proof)
5. A credible 90-day plan

Co-founders invest in people and ideas first, traction second, product third.

### Metrics to Show (Even Pre-Launch)

- Waitlist size: "347 artists and collectors have signed up to be first." Even 50 is meaningful.
- Market size: $65B global art market, $13.3B online (growing 19% YoY)
- Comparable exits: Etsy IPO at $3.5B. Artsy raised $100M+. Proven appetite.
- Your differentiation: "The only marketplace combining products + services + experiences in one place."
- Your edge: "We're embedding AI-powered discovery that Etsy built only after 10 years."

If you have zero users, run 5 user interviews with artists this week and quote them.

### Your Demo Flow (10 Minutes — Practice Until Flawless)

1. **Pain (2 min):** "Today, an artist has to use Etsy for products, Fiverr for commissions, Eventbrite for workshops. Three apps, three audiences, three fees. Fragmented and broken."
2. **Solution demo (5 min):**
   - Open Picartdo → show the gallery feed (beautiful, art-first)
   - Tap a listing → show trust signals, one-tap checkout
   - Switch to Artist view → show dashboard with "You earned $340 this week"
   - Show the Experiences tab → "Book a private painting class with this artist"
   - Search: "watercolor sunset under $200" → AI returns perfect results
3. **Business model (2 min):** Show the three revenue streams + 12-month model
4. **Ask (1 min):** Be specific — skills? money? connections? All three?

### Pitch Deck (10 slides, no more)

1. **Cover:** "Picartdo — Where Art Lives." Your best photo as background.
2. **Problem:** 3 bullet points. Make it visceral.
3. **Solution:** One screenshot of your app.
4. **Market Size:** TAM $65B → SAM $13.3B online → SOM $50M realistic Y3 target
5. **Product:** 3 key screens. No walls of text.
6. **Business Model:** Three revenue streams + revenue projection to Year 3.
7. **Traction:** Waitlist + any user interviews. Be honest.
8. **Competition:** Etsy, Artsy, Instagram. Your differentiation clearly stated.
9. **Team:** You + what roles you need (gaps show self-awareness).
10. **The Ask:** What you need and what you'll do with it.

Build in Canva (free, fast) or Pitch.com (purpose-built for investor decks).

### The 3 Biggest Risks Right Now

**Risk 1: Cold Start Problem (chicken and egg)**
You need artists to attract buyers. You need buyers to attract artists.
Mitigation: Launch artist-first. Spend the first 90 days exclusively recruiting artists. Don't open to buyers until you have 100 verified artist listings. Find 10 local artists this week. Offer them lifetime free Pro accounts.

**Risk 2: Trust and Fraud**
Art is high-value and subjective. A single viral "I got scammed on Picartdo" tweet could kill you early.
Mitigation: Verify every artist with Stripe Identity before they can sell. Hold buyer funds for 48 hours after delivery. Handle every early dispute personally.

**Risk 3: Apple's 30% Cut on Subscriptions**
Apple takes 30% of your Pro subscription ($6/month of your $19.99). Manageable in year 1, painful at scale.
Mitigation: Don't try to work around it in year 1 (App Store violations = ban). At scale, offer web subscriptions at a better price and drive users there.

---

## 7. IMMEDIATE ACTION PLAN

### THE NEXT 7 DAYS (Non-Negotiable)

**Day 1 — Foundation**
- Create Supabase account (free) at supabase.com → new project "picartdo-production"
- Enable pgvector: `CREATE EXTENSION vector;`
- Run the database schema from Section 2

**Day 2 — Design**
- Create Figma account → new file "Picartdo Design System"
- Define color palette (exact hex codes from Section 1)
- Wireframe 5 core screens: Home Feed, Listing Detail, Artist Profile, Checkout, Onboarding
- Use v0.dev to generate SwiftUI code from your Figma screens

**Day 3 — Payments**
- Create Stripe account → enable Stripe Connect (Platform → Connect settings)
- Create test product: "Pro Artist Subscription" ($19.99)
- Create RevenueCat account, connect Stripe and your Apple app

**Day 4 — Auth**
- Add Supabase to Xcode via Swift Package Manager
- Implement Apple Sign In with Supabase Auth (follow Supabase iOS quickstart)
- Create users table with Row Level Security policies

**Day 5 — Waitlist**
- Create Typeform: "Be the first artist on Picartdo"
- Ask: Name, email, art type, Instagram handle, monthly art earnings
- Share with 20 artists personally this weekend
- **Goal: 50 sign-ups before your pitch**

**Days 6 & 7 — Core MVP Screens**
- Build Listing creation flow in SwiftUI (this is what artists use first)
- Connect to Supabase Storage for image upload
- Build Home Feed screen pulling from the `listings` table

### THE NEXT 30 DAYS (Before Your Pitch)

**Week 2 — Core Buyer Flow**
- Listing detail screen (the most important buyer screen — make it perfect)
- Stripe payment integration (test mode — one-tap checkout)
- Order confirmation screen + email via Resend

**Week 3 — Artist Tools**
- Artist dashboard (earnings, listing management, views)
- Onboarding flow (both personas)
- Push notifications via APNs + Supabase

**Week 4 — Polish + Pitch Prep**
- Add animations and micro-interactions (what makes it feel premium)
- Set up Sentry for error tracking
- Install PostHog for analytics
- Record a 90-second demo video (Loom, then export)
- Build pitch deck in Canva or Pitch.com
- **Practice demo 10 times until it flows without thinking**

**By pitch day you have:**
- A working demo with real listings (your 10 artist friends added content)
- A waitlist with 50+ names
- Clear business model + revenue projections
- A polished deck

### THE NEXT 90 DAYS (Post-Pitch)

**Month 2 — Soft Launch with 50 Artists**
- Invite waitlist artists (hand-selected, personally onboarded)
- Verify every one with Stripe Identity
- Monitor EVERY transaction personally
- Do support via text/WhatsApp — high touch
- Target: 50 listings, 10 real sales, $2,000 GMV

**Month 3 — AI Features + First Marketing**
- Implement semantic search (pgvector + embeddings)
- Launch AI description generator for artists
- Start Instagram + TikTok content featuring your artists
- Partner with 2–3 local art schools for Experiences
- Target: 150 artists, 100 transactions, $10,000 GMV, $1,200 commission revenue

**Month 4 (30-day stretch goal)**
- Enable Pro Artist subscriptions (RevenueCat live in production)
- Launch Android (if you have a developer co-founder)
- First PR push: local art magazine or blog feature
- Target: First $5,000 MRR

---

## THE SINGLE MOST IMPORTANT THING

Everything above is worthless without this: **talk to 10 artists this week.**

Not survey them. Talk to them. Ask:
- Where do you sell your art today?
- What's broken about it?
- What would you pay to fix it?
- Would you list on Picartdo tomorrow if I gave you a free Pro account?

Their answers will tell you what to build first. Their words will become your pitch. Their faces will remind you why this matters when building gets hard.

**You are not building an app. You are building a home for artists.**

Now go build it.

---

*Built for Oscar Bruschi & Picartdo — think big, build right, ship fast.*
