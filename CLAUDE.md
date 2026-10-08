# Picartdo

## Profiles: one shared page

Every profile (the user's own Profile tab and every other artist's page) is built from
`ProfilePageBody` in `Picartdo/Views/Profile/ProfilePage.swift`.

- Any new profile feature (section, tab, sheet, button behavior) goes in `ProfilePage.swift`,
  so all profiles get it. Never add a feature to only `ProfileView` (own profile) or
  `ArtistStoreView` (other artists).
- The wrappers only supply identity and the header buttons: Edit Profile/Message on your own
  profile, Muse/Message on other artists (Muse → Release Muse asks "Release this muse?").
