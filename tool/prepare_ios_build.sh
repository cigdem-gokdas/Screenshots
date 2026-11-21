#!/bin/sh
# Run only if an iCloud-managed project causes codesign's "resource fork,
# Finder information, or similar detritus not allowed" error, or generated
# SwiftPM files time out through File Provider. Only generated files are staged.
set -eu
cd "$(dirname "$0")/.."
# Flutter generates plugin metadata for both Darwin platforms, even on iOS.
for platform in ios macos; do
  generated="$platform/Flutter/ephemeral"
  if [ -L "$generated" ]; then
    if [ -e "$generated" ]; then continue; fi
    rm "$generated"
  fi
  if [ -d "$generated" ]; then
    # Rename inside the cloud-managed parent; a cross-directory move can demand
    # downloading unreadable placeholders. The preserved folder is ignored.
    mv "$generated" "$platform/Flutter/.ephemeral-preserved-$(date +%s)"
  fi
  generated_staging=$(mktemp -d "/private/tmp/screenshot-$platform-generated.XXXXXX")
  ln -s "$generated_staging" "$generated"
done
if [ -L build ]; then
  if [ -e build ]; then
    printf '%s\n' 'Build staging is already configured.'
    exit 0
  fi
  # Remove only a dangling build symlink, never its destination.
  rm build
fi
staging_dir=$(mktemp -d /private/tmp/screenshot-cehennemi-build.XXXXXX)
if [ -d build ]; then
  # Keep all existing generated artifacts; source files are never moved.
  mv build "$staging_dir/artifacts"
else
  mkdir "$staging_dir/artifacts"
fi
ln -s "$staging_dir/artifacts" build
# Only strip signing-incompatible metadata from generated app frameworks.
if [ -d build/ios/Debug-iphonesimulator/Flutter.framework ]; then
  xattr -dr com.apple.FinderInfo build/ios/Debug-iphonesimulator/Flutter.framework 2>/dev/null || true
fi
printf '%s\n' "Build staging: $staging_dir/artifacts"
