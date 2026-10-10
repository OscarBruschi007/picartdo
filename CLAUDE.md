# Picartdo

## Profiles: one shared page

Every profile (the user's own Profile tab and every other artist's page) is built from
`ProfilePageBody` in `Picartdo/Views/Profile/ProfilePage.swift`.

- Any new profile feature (section, tab, sheet, button behavior) goes in `ProfilePage.swift`,
  so all profiles get it. Never add a feature to only `ProfileView` (own profile) or
  `ArtistStoreView` (other artists).
- Customization (avatar shape, name color, edit brush) is only on your own profile.
  Other artists never get Muse or the mail icon. They get a Contact button that opens chat.
- The wrappers only supply identity and the header actions: Edit/Messages on your own
  profile, Contact on other artists.
