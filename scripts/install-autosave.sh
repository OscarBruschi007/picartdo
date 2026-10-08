#!/bin/bash
# One-time setup for the Picartdo nightly auto save (11 PM).
set -e
DIR="$HOME/Documents/Picartdo/scripts"
AGENTS="$HOME/Library/LaunchAgents"
mkdir -p "$AGENTS"
cp "$DIR/com.picartdo.autosave.plist" "$AGENTS/"
launchctl bootout "gui/$(id -u)/com.picartdo.autosave" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENTS/com.picartdo.autosave.plist"
git -C "$HOME/Documents/Picartdo" config credential.helper osxkeychain
echo ""
echo "Running the first save now. If asked:"
echo "  Username: OscarBruschi007"
echo "  Password: paste your ghp_ token (it will not show while you paste, that's normal)"
echo ""
cd "$HOME/Documents/Picartdo"
git add -A
git -c user.name="Oscar Bruschi" -c user.email="oscarbruschi@yahoo.com" commit -q -m "Add nightly auto save" || true
git push origin main
echo ""
echo "Testing the background save..."
launchctl kickstart "gui/$(id -u)/com.picartdo.autosave"
sleep 5
tail -3 "$HOME/Documents/Picartdo/.autosave.log" 2>/dev/null || echo "No log yet."
echo ""
echo "Done. Picartdo will auto save to GitHub every night at 11 PM."
