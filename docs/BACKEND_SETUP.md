# Picartdo Backend Setup

This guide gets the Supabase + Stripe backend running for the Picartdo iOS app.

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli)
- [Stripe account](https://stripe.com) with **Connect** enabled
- Apple Developer account (Sign in with Apple + optional Push)

## 1. Supabase Project

```bash
cd /Users/bruschi/Documents/Picartdo
supabase login
supabase init   # skip if already initialized
supabase start  # local dev
supabase db push
```

For production:

```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
supabase functions deploy
```

### Storage buckets (Dashboard → Storage)

Create public buckets:

- `listing-images`
- `avatars`

Create private bucket:

- `commission-references`

## 2. Edge Function Secrets

```bash
supabase secrets set \
  STRIPE_SECRET_KEY=sk_test_... \
  STRIPE_WEBHOOK_SECRET=whsec_... \
  STRIPE_CONNECT_WEBHOOK_SECRET=whsec_... \
  STRIPE_IDENTITY_WEBHOOK_SECRET=whsec_... \
  SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  SUPABASE_ANON_KEY=eyJ... \
  SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

Deploy functions:

```bash
supabase functions deploy create-payment-intent
supabase functions deploy payment-webhook
supabase functions deploy create-connect-account
supabase functions deploy connect-webhook
supabase functions deploy create-identity-session
supabase functions deploy identity-webhook
supabase functions deploy payment-methods
supabase functions deploy feed-scoring
supabase functions deploy create-commission
```

### Stripe webhooks

Point these URLs to your Supabase functions:

| Event source | Function |
|---|---|
| Payments | `/functions/v1/payment-webhook` |
| Connect | `/functions/v1/connect-webhook` |
| Identity | `/functions/v1/identity-webhook` |

Local testing:

```bash
stripe listen --forward-to localhost:54321/functions/v1/payment-webhook
```

## 3. iOS Environment Variables

In Xcode → **Picartdo** scheme → **Run** → **Arguments** → **Environment Variables**:

| Variable | Example |
|---|---|
| `SUPABASE_URL` | `https://xxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | `eyJhbG...` |
| `STRIPE_PUBLISHABLE_KEY` | `pk_test_...` |

Without these, the app runs in **demo mode** (mock data, local-only checkout).

## 4. Apple Sign In

1. Enable **Sign in with Apple** capability in Xcode
2. Configure Apple provider in Supabase Dashboard → Authentication → Providers
3. Add redirect URL: `picartdo://auth-callback`

## 5. Artist Verification Flow

1. Artist signs in with Apple
2. Profile → complete **Stripe Identity** (opens Safari)
3. Complete **Stripe Connect** onboarding (opens Safari)
4. Upload listing via Sell tab

## 6. Buyer Checkout Flow

1. Tap **Buy** on artwork detail
2. Continue to Payment → Apple Pay or Card
3. Stripe Checkout opens in Safari
4. Webhook marks order paid + listing sold

Purchases over **$500** require buyer ID verification first.

## 7. Commission Requests

Submitted from `CommissionRequestView` → `create-commission` edge function → `commission_requests` table.

## Architecture

```
iOS App (SwiftUI)
  ├── SupabaseClient (REST + Auth + Storage)
  ├── Edge Functions (Stripe, payments, identity)
  └── Falls back to MockArtworkService when unconfigured
```

## Files

| Path | Purpose |
|---|---|
| `supabase/migrations/` | Database schema + RLS |
| `supabase/functions/` | Serverless backend |
| `Picartdo/Services/` | iOS service layer |
| `Picartdo/Config/AppConfig.swift` | Env var resolution |
