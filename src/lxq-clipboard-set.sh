#!/usr/bin/env bash
set -Eeuo pipefail

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\t\tSet clipboard contents for a sandbox or template"
    exit 0
fi

function show_usage() {
    printf "Usage: lxq clipboard set [--sandbox name | --template name]\n" >&2
    printf "\n" >&2
    printf "Flags:\n" >&2
    printf "  -s, --sandbox\t\tSet sandbox clipboard contents\n" >&2
    printf "  -t, --template\tSet template clipboard contents\n" >&2
    printf "  -H, --host\t\tSet the host's clipboard contents\n" >&2
    printf "  -h, --help\t\tShow help message then exit\n" >&2
}

function show_usage_and_exit() {
    show_usage
    exit 1
}

function parse_commandline() {

    while [ "${#}" -gt "0" ]; do
        local consume=1

        case "$1" in
            -h|-\?|--help)
                ARG_HELP="true"
            ;;
            -s|--sandbox)
                if lxq_is_set "${ARG_HOST+x}" || lxq_is_set "${ARG_TEMPLATE_NAME+x}"; then
                    lxq_panic "Cannot use --sandbox with --template or --host."
                fi
                shift 1
                if [ "${#}" -gt "0" ]; then
                    ARG_SANDBOX_NAME="${1}"
                else
                    echo "No sandbox name specified."
                    show_usage_and_exit
                fi
            ;;
            -t|--template)
                if lxq_is_set "${ARG_HOST+x}" || lxq_is_set "${ARG_SANDBOX_NAME+x}"; then
                    lxq_panic "Cannot use --template with --sandbox or --host."
                fi
                shift 1
                if [ "${#}" -gt "0" ]; then
                    ARG_TEMPLATE_NAME="${1}"
                else
                    echo "No template name specified."
                    show_usage_and_exit
                fi
            ;;
            -H|--host)
                if lxq_is_set "${ARG_TEMPLATE_NAME+x}" || lxq_is_set "${ARG_SANDBOX_NAME+x}"; then
                    lxq_panic "Cannot use --host with --sandbox or --template."
                fi
                ARG_HOST="true"
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

if lxq_is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi

if lxq_is_set "${ARG_TEMPLATE_NAME+x}"; then
    [ "$(lxq template status "${ARG_TEMPLATE_NAME}")" == "RUNNING" ] || lxq_panic "Template ${ARG_TEMPLATE_NAME} is not running."
    lxq template exec "${ARG_TEMPLATE_NAME}" -- xsel --nodetach --clipboard < /dev/stdin &
elif lxq_is_set "${ARG_SANDBOX_NAME+x}"; then
    [ "$(lxq sandbox status "${ARG_SANDBOX_NAME}")" == "RUNNING" ] || lxq_panic "Sandbox ${ARG_SANDBOX_NAME} is not running."
    lxq sandbox exec "${ARG_SANDBOX_NAME}" -- xsel --nodetach --clipboard < /dev/stdin &
elif lxq_is_set "${ARG_HOST+x}"; then
    xsel --nodetach --clipboard < /dev/stdin &
else
    lxq_panic "Must specify --sandbox, --template, or --host."
fi
