#!/usr/bin/env bash
# Install repo helper scripts into the user's local bin directory.

set -Eeuo pipefail

readonly SCRIPT_PATH="${BASH_SOURCE[0]}"
readonly SCRIPT_NAME="${SCRIPT_PATH##*/}"
readonly INSTALL_DIR="${HOME}/.local/bin"

fct_get_script_dir() {
    local source="${SCRIPT_PATH}"
    local dir="${source%/*}"

    if [[ "${dir}" == "${source}" ]]; then
        dir="."
    fi

    (cd "${dir}" >/dev/null 2>&1 && pwd -P)
}

SCRIPT_DIR="$(fct_get_script_dir)"
readonly SCRIPT_DIR

fct_usage() {
    cat <<EOF
Usage:
  ${SCRIPT_NAME}

Installs:
  launch_container.sh

Target:
  ${INSTALL_DIR}

Options:
  -h, --help  Show this help and exit
EOF
}

fct_die() {
    local message="${1}"

    printf 'ERROR: %s\n' "${message}" >&2
    exit 1
}

fct_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
        -h | --help)
            fct_usage
            exit 0
            ;;
        *)
            fct_die "Unknown argument: ${1}"
            ;;
        esac
    done
}

fct_install_script() {
    local script_name="${1}"
    local source_path="${SCRIPT_DIR}/${script_name}"
    local target_path="${INSTALL_DIR}/${script_name}"

    if [[ ! -f "${source_path}" ]]; then
        fct_die "Required script not found: ${source_path}"
    fi

    install -m 0755 "${source_path}" "${target_path}"
    printf 'Installed: %s\n' "${target_path}" >&2
}

fct_shell_rc_file() {
    local shell_name=""

    shell_name="${SHELL##*/}"
    case "${shell_name}" in
    zsh)
        printf '%s\n' "${HOME}/.zshrc"
        ;;
    bash)
        printf '%s\n' "${HOME}/.bashrc"
        ;;
    *)
        printf '%s\n' "${HOME}/.profile"
        ;;
    esac
}

fct_configure_path() {
    local rc_file=""

    case ":${PATH}:" in
    *":${INSTALL_DIR}:"*)
        printf 'PATH already includes: %s\n' "${INSTALL_DIR}" >&2
        return 0
        ;;
    *)
        ;;
    esac

    rc_file="$(fct_shell_rc_file)"
    touch "${rc_file}"

    if grep -Fqs "\${HOME}/.local/bin" "${rc_file}" || grep -Fqs "${INSTALL_DIR}" "${rc_file}"; then
        printf 'PATH entry already configured in: %s\n' "${rc_file}" >&2
    else
        printf '\n# Added by dotfiles-docker install.sh\n' >>"${rc_file}"
        printf '%s\n' "export PATH=\"\${HOME}/.local/bin:\${PATH}\"" >>"${rc_file}"
        printf 'Added PATH entry to: %s\n' "${rc_file}" >&2
    fi

    printf '%s\n' "Restart your shell or run: export PATH=\"\${HOME}/.local/bin:\${PATH}\"" >&2
}

fct_install_helpers() {
    mkdir -p "${INSTALL_DIR}"

    fct_install_script "launch_container.sh"
    fct_configure_path
}

main() {
    fct_parse_args "$@"
    fct_install_helpers
}

main "$@"
