#!/usr/bin/env bash
# Rewrites src.json to the newest stayfree-app/desktop-releases tag.
# Exits 0 with no change when already current; the workflow decides what to do
# with the result by diffing src.json.
set -euo pipefail

repo=stayfree-app/desktop-releases
current=$(jq -r .version src.json)

tag=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | jq -r .tag_name)
version=${tag#v}

if [[ $version == "$current" ]]; then
  echo "already at $current"
  exit 0
fi

url="https://github.com/$repo/releases/download/$tag/stayfree-linux-x86_64.AppImage"
hash=$(nix store prefetch-file --json --name "stayfree-$version.AppImage" "$url" | jq -r .hash)

jq -n --arg version "$version" --arg url "$url" --arg hash "$hash" \
  '{$version, $url, $hash}' > src.json

echo "$current -> $version"
[[ -n ${GITHUB_OUTPUT:-} ]] && echo "version=$version" >> "$GITHUB_OUTPUT"
