# Picartdo 🎨
### The art marketplace for products, services & experiences.
**Pitch date: July 29, 2026**

---

## Folder Structure

```
Picartdo/
│
├── Picartdo/                        ← iOS app source code
│   │
│   ├── App/                         ← Entry points
│   │   ├── PicartdoApp.swift         ← App launch (@main)
│   │   └── ContentView.swift        ← Root navigation
│   │
│   ├── Models/                      ← Data structures
│   │   ├── Artwork.swift            ← Artwork model
│   │   ├── Service.swift            ← Service/Experience model
│   │   └── PicartdoModels.swift      ← Shared models
│   │
│   ├── Views/
│   │   ├── Home/                    ← Discovery & browsing
│   │   │   ├── HomeView.swift       ← Main feed screen
│   │   │   ├── FeedView.swift       ← Artwork grid feed
│   │   │   ├── DiscoverView.swift   ← Explore / categories
│   │   │   └── SearchView.swift     ← Search + AI search
│   │   │
│   │   ├── Listings/                ← Art & service screens
│   │   │   ├── ArtworkDetailView.swift     ← Single artwork page
│   │   │   ├── CategoryServicesView.swift  ← Services browse
│   │   │   ├── CommissionRequestView.swift ← Commission form
│   │   │   └── SellArtView.swift           ← Artist upload flow
│   │   │
│   │   ├── Profile/                 ← User screens
│   │   │   ├── ArtistProfileView.swift  ← Public artist page
│   │   │   └── ProfileView.swift        ← My profile / settings
│   │   │
│   │   ├── Commerce/                ← Buying & selling
│   │   │   └── MessagesView.swift   ← Buyer ↔ Artist chat
│   │   │
│   │   └── Shared/                  ← Reusable UI components
│   │       ├── SplashScreenView.swift   ← Splash / onboarding
│   │       ├── OffWhiteUI.swift         ← UI components library
│   │       └── PicartdoBackground.swift ← Background styles
│   │
│   ├── Resources/                   ← Design tokens
│   │   └── Colors.swift             ← Color palette & typography
│   │
│   └── Assets.xcassets/             ← Images, icons, art photos
│
├── Picartdo.xcodeproj/              ← Open this to build in Xcode
│
├── Planning/                        ← Strategy & docs
│   └── Picartdo_CTO_Audit.md        ← Full audit + 30/90-day plan
│
├── README.md                        ← This file
│
└── _Archive/                        ← Old files (safe to ignore)
    ├── Old Swift Files/             ← Early app drafts
    └── Web Prototype/               ← Original HTML prototype
```

---

## Quick Reference

| What | Where |
|---|---|
| Open the app | Double-click `Picartdo.xcodeproj` |
| App entry point | `App/PicartdoApp.swift` |
| Color palette | `Resources/Colors.swift` |
| Data models | `Models/` |
| Main feed | `Views/Home/HomeView.swift` |
| Buy artwork | `Views/Listings/ArtworkDetailView.swift` |
| Sell artwork | `Views/Listings/SellArtView.swift` |
| Artist page | `Views/Profile/ArtistProfileView.swift` |
| CTO audit & roadmap | `Planning/Picartdo_CTO_Audit.md` |

---

## Tech Stack

| Layer | Tool |
|---|---|
| Frontend | Swift + SwiftUI (iOS) |
| Backend | Supabase (DB + Auth + Storage + Edge Functions) |
| Payments | Stripe Connect + Stripe Checkout |
| ID Verification | Stripe Identity |
| Subscriptions | RevenueCat (planned) |
| CDN | Cloudflare |
| AI Search | OpenAI embeddings + pgvector (planned) |
| AI Copy | Claude API |
| Analytics | PostHog (planned) |
| Errors | Sentry (planned) |

See **`docs/BACKEND_SETUP.md`** for full backend setup instructions.

---

## Business Model

| Stream | Rate | Example |
|---|---|---|
| Transaction commission | 12% of every sale | $500 painting → $60 to Picartdo |
| Pro Artist subscription | $19.99/month | Unlimited listings + AI tools |
| Promoted listings | $9.99–$49.99 | Featured placement in feed |

**Month 6 target: ~$35K MRR**

---

## 30-Day Build Plan

| Week | Dates | Focus |
|---|---|---|
| 1 | Jun 29 – Jul 5 | Supabase + Figma + Stripe + Auth + Waitlist |
| 2 | Jul 6 – Jul 12 | Feed + Detail screen + Checkout + Artist Profile |
| 3 | Jul 13 – Jul 19 | Dashboard + Animations + Security + CDN |
| 4 | Jul 20 – Jul 26 | AI search + AI descriptions + Pitch deck |
| 5 | Jul 27 – Jul 29 | Rehearsal → **Pitch Day 🚀** |

---

*Built by Oscar Bruschi — think big, build right, ship fast.*
