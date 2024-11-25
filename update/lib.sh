#!/usr/bin/env bash

set -euo pipefail

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

function fetch_release() {
    curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/esp-rs/rust-build/releases/$1"
}

# NOTE: GH API 404s if we have a trailing slash
function list_releases() {
    curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/esp-rs/rust-build/releases"
}

function get_triple() {
    v_name="$1"
    sed "s|rust-$v_name"'-\([^.]*\)\..*|\1|'
}

function prefetch() {
    nix store prefetch-file --hash-type sha256 --json "$1" | jq -r .hash
}

function process_asset() {
    tag="$1"
    version_name="$2"
    ASSET="$3"

    name="$(echo "$ASSET" | jq -r .name)"
    if echo "$name" | grep -q windows
    then
        echo "skipping $name" >&2
        return
    fi

    if echo "$name" | grep -q rust-src
    then
        echo "skipping $name" >&2
        return
    fi

    triple="$(echo "$name" | get_triple $version_name)"
    url="$(echo "$ASSET" | jq -r .browser_download_url)"
    sha256="$(prefetch "$url")"

    # {
    #   "unknown-linux-gnu": {
    #     "latest": {
    #       "date": "v1.82.0.3",
    #       "components": {
    #         "rust": {
    #           "date": "v1.82.0.3",
    #           "url": "https://github.com/esp-rs/rust-build/releases/download/v1.82.0.3/rust-1.82.0.3-x86_64-unknown-linux-gnu.tar.xz",
    #           "sha256": "..."
    #         },
    #         "rust-src": {
    #           "date": "v1.82.0.3",
    #           "url": "https://github.com/esp-rs/rust-build/releases/download/v1.82.0.3/rust-src-1.82.0.3.tar.xz",
    #           "sha256": "..."
    #         }
    #       }
    #       ...
    #     }
    #   }
    # }
    echo "
    {
      \"$triple\": {
        \"esp\": {
          \"date\": \"$tag\",
          \"components\": {
            \"rust\": {
              \"date\": \"$tag\",
              \"url\": \"$url\",
              \"sha256\": \"$sha256\"
            },
            \"rust-src\": {
              \"date\": \"$tag\",
              \"url\": \"$src_url\",
              \"sha256\": \"$src_sha256\"
            }
          }
        }
      }
    }" | jq -c .
}

function process_release() {
    release_data="$1"

    tag="$(echo "$release_data" | jq -r .tag_name)"
    version_name="$(echo "$tag" | sed 's|^v||')"

    out_file="$STORAGE_DIR/$tag.json"
    if [[ -e "$out_file" ]]
    then
        return
    fi

    src_url="$(echo "$release_data" | jq -r '.assets[] | select(.name | startswith("rust-src-")) | .browser_download_url')"
    src_sha256="$(prefetch "$src_url")"

    echo "$release_data" | jq -c '.assets[]' | while read ASSET
    do
        process_asset "$tag" "$version_name" "$ASSET"
    done | jq --slurp '. | add' > "$out_file"
}

