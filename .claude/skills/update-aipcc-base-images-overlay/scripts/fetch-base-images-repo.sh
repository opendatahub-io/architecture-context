#!/bin/bash
# Fetches the AIPCC base images repository to ./tmp/app.
# Safe to run multiple times — pulls updates if already cloned.

REPO_URL="https://gitlab.com/redhat/rhel-ai/core/base-images/app.git"
DEST_DIR="tmp/app"

if [ -d "$DEST_DIR/.git" ]; then
  echo "Repository already exists at $DEST_DIR, pulling latest changes..."
  if ! git -C "$DEST_DIR" pull; then
    echo "ERROR: git pull failed in $DEST_DIR" >&2
    exit 1
  fi
else
  echo "Cloning base images repository to $DEST_DIR..."
  mkdir -p tmp
  git clone --depth 1 "$REPO_URL" "$DEST_DIR"
fi

echo "Base images repository ready: $DEST_DIR"
