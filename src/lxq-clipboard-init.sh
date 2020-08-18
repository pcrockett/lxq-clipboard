#!/usr/bin/env bash
set -Eeuo pipefail

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\t\tInstall necessary components in a template"
    exit 0
fi

function show_usage() {
    printf "Usage: lxq clipboard init [template-name]\n" >&2
    printf "\n" >&2
    printf "Flags:\n">&2
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
            *)
                if lxq_is_set "${ARG_TEMPLATE_NAME+x}"; then
                    echo "Unrecognized argument: ${1}"
                    show_usage_and_exit
                else
                    ARG_TEMPLATE_NAME="${1}"
                fi
            ;;
        esac

        shift ${consume}
    done
}

parse_commandline "$@"

if lxq_is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi

lxq_is_set "${ARG_TEMPLATE_NAME+x}" || lxq_panic "No template name specified."

config_dir="${LXQ_REPO_DIR}/templates/${ARG_TEMPLATE_NAME}/config.d"
test -d "${config_dir}" || lxq_panic "Template \"${ARG_TEMPLATE_NAME}\" does not exist."

config_file="${config_dir}/${LXQ_CLIPBOARD_CONFIG_FILE}"
test ! -f "${config_file}" || lxq_panic "Template \"${ARG_TEMPLATE_NAME}\" has already been initialized for clipboard access."

original_template_status=$(lxq template status "${ARG_TEMPLATE_NAME}")
test "${original_template_status}" == "RUNNING" || lxq template start "${ARG_TEMPLATE_NAME}"

lxq template exec "${ARG_TEMPLATE_NAME}" -- "apt update && apt install xsel --yes"

if [ "${original_template_status}" == "STOPPED" ]; then
    lxq template stop "${ARG_TEMPLATE_NAME}"
fi

echo "# This template has been configured for clipboard access" > "${config_file}"
