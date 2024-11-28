#!/usr/bin/env bash

set -euo pipefail

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source "$SCRIPTPATH/lib.sh"

function run_get_release() {
    if [[ "$#" -gt 1 ]]
    then
        echo "USAGE: $0 get_release [RELEASE_TAG]" >&2
        exit 1
    fi

    if [[ "$#" -eq 0 ]]
    then
        RELEASE="latest"
    else
        RELEASE="tags/$1"
    fi

    release_data="$(fetch_release "$RELEASE")"
    process_release "$release_data"
}

function run_list_releases() {
    list_releases
}

function run_update_releases() {
    release_data="$(list_releases)"
    echo "$release_data" | jq -c '.[:5] | .[]' | while read RELEASE_DATA
    do
        process_release "$RELEASE_DATA"
    done

    # New release info for PR/commit message
    if [[ "${GITHUB_OUTPUT:-}" != "" ]]
    then
        echo "latest_release=$(echo "$release_data" | jq .[0].tag_name)" >> "$GITHUB_OUTPUT"
    fi
}

cmd="${1:-}"

case "$cmd" in
"get")
    shift
    run_get_release "$@"
    ;;
"list")
    shift
    run_list_releases "$@"
    ;;
"update")
    shift
    run_update_releases "$@"
    ;;
*)
    echo "USAGE: $0 get|list ..." >&2
    exit 1
    ;;
esac
