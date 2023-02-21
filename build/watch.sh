#!/bin/bash

# Reload the LINES and COLUMNS vars from the terminal -- have to do this in the
# toplevel due to the weird use of IFS.
echo -en '\e7\e[r\e[999;999H\e[6n\e8'
OLDIFS=\$IFS
IFS='[;'
read -d R -s esc LINES COLUMNS
IFS=\$OLDIFS

function die
{
    echo "board: $@" >/dev/stderr
    exit 1
}

function try
{
    "$@" || die "$@ failed. Aborting."
}

function watch
{
    local columns=
    local timestamp
    local target
    local state
    local message
    declare -A tasks

    local red=$(tput setaf 1)
    local green=$(tput setaf 2)
    local yellow=$(tput setaf 3)
    local white=$(tput setaf 7)

    IFS=$'\t\n'
    while read timestamp target state message; do
        [[ -z $target ]] && continue

        if [[ "${target}" == "build" ]]; then
            unset tasks
            declare -A tasks
        fi

        tasks[$target]="$message ($state - $timestamp)"

        clear
        for target in "${!tasks[@]}"; do
            printf "%*s\r" "${COLUMNS}" "${tasks[$target]}"

            case "${tasks[$target]}" in
                *finished*) printf "$green"  ;;
                *failed*)   printf "$red"    ;;
                *)          printf "$yellow" ;;
            esac

            printf "%s%s\n" "$target" "$white"
        done

        if [[ "${state}" =~ finished ]]; then
            unset tasks[$target]
        fi

        sleep 0.25
    done
}

function main
{
    if [[ -z "$BUILDTAB" ]]; then
        die "\$BUILDTAB is not defined. 'source build/setup.sh' first!"
    fi

    echo -n "Waiting for $BUILDTAB to be available..."
    while true; do
          if [[ -f $BUILDTAB ]]; then
              break
          fi

          echo -n "."
          sleep 1
    done
    clear

    tail -f $BUILDTAB |watch
}

main
