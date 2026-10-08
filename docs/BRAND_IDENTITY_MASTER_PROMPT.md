# Picartdo — Master Brand Identity Prompt
### Complete design brief for icon, logo, color system & splash transition
**Version 1.0 · For AI image generation + iOS implementation**

Use this document as a single source of truth. Feed sections **1–7** to a graphic designer or image model. Feed sections **8–10** to the iOS engineer implementing assets and splash.

---

## 1. EXECUTIVE BRIEF

**Product:** Picartdo — iOS art marketplace  
**Tagline:** *Buy · Sell · Experience Art*  
**One-liner:** The art marketplace for **products, services & experiences** — not just paintings on a wall.

**Design mission:** Create a brand identity as instantly recognizable as Instagram, WhatsApp, or Spotify — but with **museum-grade restraint**. Maximum impact, **minimum colors** (strict 3-color system). When someone sees the icon on a home screen, they should think *"art app"* and *"Picartdo"* without reading the name.

**What we are NOT making:**
- Generic serif letter "P" on cream (boring, no identity)
- Instagram-style rainbow gradient (overused, looks like a clone)
- Clip-art paint palette / easel (every failed art app ever)
- Off-White copy (zip ties, diagonal stripes as logo — tribute stays in UI components only)
- More than 3 brand colors in the mark

**What we ARE making:**
- One **ownable symbol** tied to the product thesis
- One **signature accent color** used sparingly
- A **wordmark system** that matches in-app typography
- A splash that **seamlessly dissolves** into the white app canvas

---

## 2. PRODUCT CONTEXT (follow the app structure)

Picartdo is a **dual-sided marketplace** with five entry points:

| Surface | User action | Brand should feel |
|---------|-------------|-------------------|
| **Home** | Scroll feed, stories, featured drops, BUY | Editorial, social, drop culture |
| **Services** | Book tattoos, murals, workshops, restoration | Professional, category-rich |
| **Sell (+)** | List original art | Creator empowerment |
| **Explore** | Pinterest-style discovery, wishlist | Visual, aspirational |
| **Profile** | Artist store, posts, commissions, DMs | Identity, trust, seller brand |

**Three revenue pillars (must inform the symbol):**
1. **Products** — buy/sell original art, Polaroid-style drops
2. **Services** — book living artists (12+ categories)
3. **Experiences** — events, live painting, galleries

**Founder DNA (unique to Picartdo — USE THIS):**  
Oscar Bruschi · **Biopointism** · *"Art made by dots."*  
The app demo is built around dot-based pointillism. A mark built from **precisely arranged dots forming a frame, a "P", or a collector's viewfinder** is ownable and cannot be copied by Artsy, Saatchi, or Etsy.

**In-app design language already established:**
- **Typography:** Black serif display (`PicardoType`) + monospaced uppercase meta labels (`ARTWORK`, `FEATURED DROP`)
- **UI patterns:** Polaroid cream mats `#F5F2ED`, industrial quotation marks, coral BUY pills, violet segment accents (to be replaced by new single accent)
- **Motion:** Spring-based, 350–550ms reveals, no bounce, no flash (`PicardoMotion`)
- **Canvas:** White app interior — brand lives in the **icon + accent**, not full-screen gradients inside the app

---

## 3. BRAND PERSONALITY

| Attribute | Expression |
|-----------|------------|
| **Confident** | Bold silhouette readable at 29×29 pt |
| **Editorial** | Gallery placard metadata, not startup playful |
| **Contemporary** | Living artists, tattoos, murals — not dusty auction house |
| **Trustworthy** | Certificate, shipping, Stripe identity — mark feels permanent |
| **Restrained** | 3 colors only; whitespace is luxury |

**Tone reference (principles, not copies):**  
Spotify's single-green discipline · Apple's icon simplicity · Aesop's warm neutrals · Tate Modern's bold type — combined into one art-commerce mark.

---

## 4. COLOR SYSTEM — STRICT 3-COLOR RULE

Only three colors exist in the brand mark and identity system. Everything else is derived (opacity, borders).

### Primary palette

| Token | Hex | Role | Usage |
|-------|-----|------|-------|
| **Ink** | `#0C0C0E` | Primary | Icon background, wordmark, primary buttons, tab bar labels |
| **Canvas** | `#F7F4ED` | Secondary | App background, splash handoff target, Polaroid mats, launch screen |
| **Dot** | `#E8542A` | Accent | Single point of heat — active tab, Sell FAB, BUY pill, one dot in the logo mark |

**Why Dot (#E8542A)?** Warm burnt-orange — reads as *creative energy* and *commerce* without violet/coral cliché. Distinct on home screens next to Instagram pink and WhatsApp green. Used **only** for interaction, never as icon background fill.

### Derived (not logo colors)
- Text secondary: Ink at 50% opacity
- Borders: Ink at 8% on Canvas
- Accent light: Dot at 12% for tinted backgrounds

### Forbidden
- Gradients in the app icon
- Second accent (no gold + coral + violet)
- Pure #FFFFFF or #000000 (use Ink and Canvas — warmer, premium)

---

## 5. THE MARK — ICON DESIGN PROMPT

Copy everything below this line into an image generator:

---

**PROMPT — Picartdo App Icon (1024×1024)**

Design an iOS app icon for **Picartdo**, an art marketplace app.

**Canvas:** Square 1024×1024, iOS rounded-rectangle safe zone respected. Background fill: solid warm near-black **#0C0C0E** (matte, no gradient).

**Central symbol (the entire identity):**  
A **viewfinder / picture frame** constructed from **Biopointism dots** — small perfect circles arranged in a grid, with some dots missing to form negative-space shape. The negative space reads as:
- A bold letter **"P"**, AND
- A rectangular **gallery frame** at the same time (dual read — like FedEx arrow)

**Dot specifications:**
- Dots: perfect circles, color **#F7F4ED** (warm off-white)
- One single dot in the composition: **#E8542A** (burnt orange) — placed at the brushstroke focal point (bottom-right of the P bowl, or the viewfinder corner) — **exactly ONE orange dot, no more**
- Dot grid: 8×8 or 10×10, evenly spaced, pointillism / Biopointism aesthetic
- Outer edge: implied square frame made of dot clusters at four corners (registration / viewfinder feel)

**Style constraints:**
- Flat vector, no shadows, no gloss, no 3D, no gradients
- No paintbrush clipart, no easel, no palette
- No text, no wordmark inside the icon
- Must be recognizable when scaled to 60×60 pixels on iPhone home screen
- High contrast: off-white dots on near-black field
- Premium, modern, editorial — NOT playful cartoon

**Reference quality bar:** As instantly readable as WhatsApp's phone-bubble or Reddit's Snoo — one glance, one app.

---

## 6. WORDMARK & LOGO LOCKUP PROMPT

**Primary wordmark:** `PICARTDO`  
- Typeface: High-contrast **serif**, bold/black weight (similar to Playfair Display Black or Didot Bold — classic editorial)  
- Case: ALL CAPS  
- Tracking: +80 to +120 (wide, gallery label)  
- Color on light: Ink `#0C0C0E`  
- Color on dark: Canvas `#F7F4ED`

**Secondary lockup line (below wordmark):**  
`BUY · SELL · EXPERIENCE ART`  
- Typeface: Monospaced semibold, 10–11pt equivalent  
- Tracking: +140  
- Color: Ink at 55% or Canvas at 60% on dark backgrounds

**Logo lockup composition (splash / marketing):**  
```
        [DOT-FRAME MARK — 120pt]
        
           PICARTDO
    BUY · SELL · EXPERIENCE ART
```
Centered, generous vertical spacing. No gradient backgrounds in lockup — either Ink field or Canvas field only.

**Optional micro-label (Off-White tribute, UI only — NOT in app icon):**  
`"ARTWORK"` in quotes — stays in `OffWhiteUI.swift`, not in the logo.

---

## 7. SPLASH & LAUNCH SCREEN PROMPT

**Goal:** Frame-zero continuity. Launch screen = first splash frame = zero flash, zero color jump.

### Launch screen (iOS `UILaunchScreen`)
- Background: **Canvas `#F7F4ED`** (solid, no gradient)
- Center image: **Mark only** (dot-frame symbol, no wordmark) — asset `SplashMark.png` at 512px
- No text on launch screen (text renders in SwiftUI for sharpness)

### Splash animation sequence (SwiftUI — ~3.8s total)

| Time | Element | Animation |
|------|---------|-----------|
| 0.0s | Canvas background + Mark visible | Instant (matches launch) |
| 0.35s | Wordmark `PICARTDO` | Fade up 8pt, easeOut 0.55s |
| 0.60s | Meta line `BUY · SELL · EXPERIENCE ART` | Fade up 6pt, easeOut 0.55s |
| 0.75s | Thin rule under wordmark (Dot color, 32pt wide) | Width 0→32, easeOut 0.45s |
| 2.40s | Load `ContentView` underneath (white/canvas) | Hidden, no layout flash |
| 2.55s | Splash overlay opacity 1→0 | easeInOut 0.85s |
| 3.40s | Remove splash layer entirely | Clean tree, only ContentView |

**Rules for engineer:**
- Never set `UIWindow.appearance().backgroundColor = .black`
- Never apply `.preferredColorScheme(.dark)` on root — splash only if needed
- Pre-decode mark in `App.init()` via `SplashAssets.mark`
- Splash overlay and app background must both use **Canvas `#F7F4ED`** during fade — invisible handoff
- No scale/zoom on exit (opacity only — prevents jank)

---

## 8. iOS ASSET DELIVERABLES

| Asset | Size | Path | Notes |
|-------|------|------|-------|
| App Icon | 1024×1024 | `Assets.xcassets/AppIcon.appiconset/AppIcon.png` | Single PNG, sRGB |
| Splash Mark | 512×512 | `Assets.xcassets/SplashMark.imageset/SplashMark.png` | Mark only, transparent or Canvas bg |
| Launch BG color | — | `LaunchScreenBackground.colorset` | `#F7F4ED` |
| Accent color | — | `AccentColor.colorset` | `#E8542A` (Dot) |

**After asset drop, update code:**
- `Resources/Colors.swift` — map `picardoAccent` → Dot, `picardoBackground` → Canvas, `picardoText` → Ink
- `Views/Shared/SplashScreenView.swift` — Canvas splash, mark + typography sequence above
- `App/ContentView.swift` — selected tab uses `picardoAccent` (Dot)
- Sell FAB — `picardoAccent` (Dot) — single accent throughout

---

## 9. INTEGRATION WITH EXISTING UI (do not break layout)

The brand refresh touches **colors and assets only**. Do NOT redesign screens.

| Component | Current | After rebrand |
|-----------|---------|---------------|
| Tab bar selected | Violet | Dot `#E8542A` |
| Sell FAB | Coral | Dot `#E8542A` |
| BUY pills | Coral | Dot `#E8542A` |
| Primary buttons | Black text fill | Ink `#0C0C0E` |
| App background | White | Canvas `#F7F4ED` |
| Polaroid mats | `#F5F2ED` | Keep (compatible) |
| Splash | Gradient | Canvas + mark (calm) |
| `OffWhiteUI` components | Unchanged | Unchanged |
| `PicardoType` serif/meta | Unchanged | Unchanged |

---

## 10. SUCCESS CRITERIA — HOW WE KNOW IT WORKED

**The 5-second test:** Show the icon alone to someone for 5 seconds. Ask: *"What app is this?"*  
Pass: They say *art*, *marketplace*, or *Picartdo*. Fail: They say *"some letter P"* or *"don't know"*.

**The home screen test:** Place Picartdo icon next to Instagram, WhatsApp, Spotify. It must hold its own — not disappear, not scream.

**The transition test:** Cold launch the app. No white flash, no black flash, no stutter. Canvas → canvas dissolve.

**The 3-color audit:** Count colors in the icon PNG. Exactly 3: Ink, Canvas, Dot. No fourth.

**The scale test:** Icon readable at 29×29 pt (@1x notification size). Dots merge into clear "P/frame" silhouette.

---

## 11. ANTI-PATTERNS — REJECT IMMEDIATELY

- Rainbow / violet-to-coral gradient backgrounds
- Serif "P" alone on cream (no symbol)
- Paintbrush crossing a frame (generic, already failed)
- More than one orange/colored dot
- Drop shadows, inner glow, glass effects on icon
- Wordmark inside the 1024 app icon
- Splash that morphs black → white (causes flash)
- Full-screen gradient splash that clashes with white app interior

---

## 12. ONE-PARAGRAPH MEGA-PROMPT (paste-ready)

> Design the Picartdo iOS app icon and brand mark for an art marketplace where users buy original art, book artist services (tattoos, murals, workshops), and discover experiences. The symbol must be instantly recognizable at small size using exactly three colors: near-black Ink #0C0C0E background, warm off-white Canvas #F7F4ED dots, and one burnt-orange Dot #E8542A accent dot. The mark is a Biopointism pointillism grid — dots arranged so negative space forms both a letter P and a gallery viewfinder frame, referencing founder Oscar Bruschi's dot-art style. Flat vector, no gradients, no clip-art brushes, no text in the icon. Pair with an editorial serif PICARTDO wordmark and monospaced tagline BUY · SELL · EXPERIENCE ART. Splash screen: Canvas background, centered mark, typography fades in, then opacity dissolve into the same Canvas app UI — no color flash. Quality bar: WhatsApp-level instant recognition with MoMA-level restraint.

---

*Picartdo · Brand Identity Master Prompt · Ready for design + iOS implementation*
