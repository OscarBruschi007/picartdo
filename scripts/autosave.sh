#!/bin/bash
# Picartdo nightly auto save: commits any changes and pushes them to GitHub.
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin"
PROJECT="$HOME/Documents/Picartdo"
LOG="$PROJECT/.autosave.log"
cd "$PROJECT" || { echo "$(date) cannot open $PROJECT" >> "$LOG"; exit 1; }
{
  echo "=== $(date)"
  if [ -z "$(git status --porcelain)" ]; then
    echo "No changes. Nothing to save."
    exit 0
  fi
  git add -A
  git -c user.name="Oscar Bruschi" -c user.email="oscarbruschi@yahoo.com" \
    commit -q -m "Auto save $(date '+%b %-d, %Y %-I:%M %p')"
  if git push -q origin main; then
    echo "Saved and uploaded to GitHub."
  else
    echo "Saved on Mac, but upload to GitHub FAILED."
  fi
} >> "$LOG" 2>&1
