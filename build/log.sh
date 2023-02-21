#!/bin/bash

function die
{
    echo "board: $@" 1>&2
    exit 1
}

function try
{
    "$@" || die "$@ failed. Aborting."
}

function main
{
    local target="$1"; shift
    local state="$1"; shift
    local message="$@"

    if [[ -z "$BUILDTAB" ]]; then
        die "\$BUILDTAB is not defined. 'source build/setup.sh' first!"
    fi

    mkdir -p $PRODUCT_OUT
    echo -e "$(TZ=UTC date)\t${target}\t${state}\t${message}" >> $BUILDTAB
}

if [[ "$#" -lt 2 ]]; then
    die "Usage: log.sh <target-name> <state> [<message...>]"
fi

main "$@"
