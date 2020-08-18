#!/usr/bin/env bash
set -Eeuo pipefail
[[ "${BASH_VERSINFO[0]}" -lt 4 ]] && echo "Bash >= 4 required" && exit 1

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\tShare / modify clipboard contents between sandboxes"
    exit 0
fi

readonly SCRIPT_DIR=$(dirname "$(readlink -f "${0}")")
readonly REPO_DIR=$(dirname "${SCRIPT_DIR}")
# # shellcheck source=/dev/null
# . "${SCRIPT_DIR}/_util.sh"

declare -A LXQ_SUBCOMMANDS
lxq_populate_subcommands "/lxq-clipboard-([a-z]+)\\.sh$"

function show_usage() {
    printf "Usage: lxq clipboard [command]\n" >&2
    printf "\n" >&2
    printf "Available commands:\n" >&2

    lxq_print_subcommand_summaries

    printf "\n" >&2
    printf "Flags:\n">&2
    printf "  -h, --help\t\tShow help message then exit\n" >&2
}

function show_usage_and_exit() {
    show_usage
    exit 1
}

function parse_commandline() {

    if [ "${#}" -gt "0" ]; then
        if lxq_is_set "${LXQ_SUBCOMMANDS[${1}]+x}"; then
            LXQ_COMMAND="${LXQ_SUBCOMMANDS[${1}]}"
            return # Let subcommands parse the rest of the parameters
        fi
    fi

    while [ "${#}" -gt "0" ]; do
        local consume=1

        case "$1" in
            -h|-\?|--help)
                ARG_HELP="true"
            ;;
            *)
                echo "Unrecognized argument: ${1}"
                show_usage_and_exit
            ;;
        esac

        shift ${consume}
    done
}

parse_commandline "$@"

if lxq_is_set "${LXQ_COMMAND+x}"; then

    default_config="${REPO_DIR}/default-config.sh"
    user_config="${REPO_DIR}/user-config.sh"

    # shellcheck source=/dev/null
    . "${default_config}"

    if [ -f "${user_config}" ]; then
        # shellcheck source=/dev/null
        . "${user_config}"
    fi

    shift 1
    "${LXQ_COMMAND}" "$@"
    exit "${?}"
fi

if lxq_is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi

echo "No arguments specified."
show_usage_and_exit
