# Prompt: Replicate the X (Twitter) Profile Tab — exactly

Build a SwiftUI profile screen whose header and tab bar match the X (Twitter)
mobile profile layout precisely. Follow this spec top-to-bottom. Use the app's
adaptive colors so it renders dark in dark mode (identical to X's dark theme)
and light in light mode.

## 1. Navigation (over the banner)
- A back chevron on the left and a search glyph on the right, each inside a
  ~34pt translucent dark circle (`.ultraThinMaterial`, 40% black tint).
- On scroll, a compact title fades in: **display name** (bold, 17pt) with a
  smaller gray line beneath it ("N posts").

## 2. Cover banner
- Full-bleed image, edge to edge, aspect ratio 3:1 (height ≈ 132pt on iPhone).
- No corner rounding, no horizontal padding.

## 3. Avatar
- Circle, 80–84pt, offset up by ~40pt so it overlaps the banner by half.
- 4pt border in the **background color** (so it "punches" through the banner).
- Left-aligned, 16pt from the screen edge.

## 4. Identity block (16pt horizontal padding)
Vertical stack, left-aligned, in this exact order:
1. **Display name** — bold, 20–22pt. Optional inline lock (protected) and a
   verified badge to its right.
2. **@handle** — gray, 14–15pt, directly under the name (1pt gap).
3. **Bio** — primary text, 14–15pt, full (no truncation), preserves line breaks.
4. **Meta row** — one line, gray, 14pt, 16pt item spacing:
   - 📍 location  (`mappin`)
   - 📅 "Joined <Month Year>"  (`calendar`) followed by a small chevron ›
5. **Counts row** — "**N** Following   **N** Followers"
   (bold number in primary, label in gray, 14pt), 18pt spacing.

## 5. Action buttons (own profile)
- A single row, full width, two equal outline pills side by side, 12pt gap:
  - **Share Profile** (opens the system share sheet)
  - **Edit Profile** (opens the edit sheet)
- Pills: capsule, 1pt border in a subtle border color, bold 15pt label,
  40pt tall, no fill.
- (For another user's profile the row becomes a single filled **Follow** pill.)

## 6. Tab bar (sticky)
- Horizontal, evenly spaced tabs. Selected tab: bold label + a short underline
  bar in the accent color, animated between tabs.
- App tabs: **Selling · Sold · Reviews** (X uses Posts · Replies · Media · Likes).

## 7. Content
- The selected tab's content scrolls beneath the sticky tab bar.
- Grid of cards for Selling/Sold; a list for Reviews.

## Rules
- No stats cards, no trust badges, no CTA banner inside the header — X profiles
  are clean: header → buttons → tabs → content.
- Every spacing and font size above is the target; match within ±2pt.
- Use system SF Symbols only; do not embed the X logo or any X-owned asset.
