#!/usr/bin/env bash
# Create the default non-root user and configure editor, git, and ssh defaults.

set -Eeuo pipefail

readonly USERNAME="${USERNAME:-illus}"
readonly USER_UID="${USER_UID:-1000}"
readonly USER_GID="${USER_GID:-1000}"
readonly SCRIPT_PATH="${BASH_SOURCE[0]}"

fct_die() {
    local message="${1}"

    printf 'ERROR: %s\n' "${message}" >&2
    exit 1
}

fct_get_script_dir() {
    local dir=""
    local source="${SCRIPT_PATH}"

    dir="${source%/*}"
    if [[ "${dir}" == "${source}" ]]; then
        dir="."
    fi

    (cd "${dir}" >/dev/null 2>&1 && pwd -P)
}

SCRIPT_DIR="$(fct_get_script_dir)"
readonly SCRIPT_DIR

fct_create_user() {
    if ! getent group "${USER_GID}" >/dev/null; then
        groupadd --gid "${USER_GID}" "${USERNAME}"
    fi

    if id --user "${USERNAME}" >/dev/null 2>&1; then
        return 0
    fi

    if getent passwd "${USER_UID}" >/dev/null; then
        fct_die "USER_UID already exists in the image: ${USER_UID}"
    fi

    useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /usr/bin/zsh "${USERNAME}"
}

fct_write_shell_config() {
    local config_dir="${SCRIPT_DIR}/config"
    local home_dir="/home/${USERNAME}"

    install -m 0644 "${config_dir}/zshrc" "${home_dir}/.zshrc"
    install -m 0644 "${config_dir}/bashrc" "${home_dir}/.bashrc"
    install -m 0644 "${config_dir}/starship.toml" "${home_dir}/.config/starship.toml"
}

fct_configure_git() {
    local home_dir="/home/${USERNAME}"
    local gitconfig="${home_dir}/.gitconfig"

    git config --file "${gitconfig}" core.editor nvim
    git config --file "${gitconfig}" init.defaultBranch main
}

fct_configure_ssh() {
    local home_dir="/home/${USERNAME}"
    local ssh_config="${home_dir}/.ssh/config"

    cat >"${ssh_config}" <<'EOF'
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
    chmod 600 "${ssh_config}"
}

fct_configure_sudo() {
    local sudoers_file="/etc/sudoers.d/${USERNAME}"

    printf '%s ALL=(ALL) NOPASSWD:ALL\n' "${USERNAME}" >"${sudoers_file}"
    chmod 0440 "${sudoers_file}"
}

fct_prepare_home() {
    local home_dir="/home/${USERNAME}"

    mkdir -p \
        "${home_dir}/workspace" \
        "${home_dir}/.cache/ccache" \
        "${home_dir}/.config/opencode" \
        "${home_dir}/.ssh"
    chmod 700 "${home_dir}/.ssh"
}

fct_fix_ownership() {
    local home_dir="/home/${USERNAME}"

    chown -R "${USER_UID}:${USER_GID}" "${home_dir}"
}

fct_validate_inputs() {
    if [[ ! "${USER_UID}" =~ ^[0-9]+$ ]]; then
        fct_die "USER_UID must be numeric: ${USER_UID}"
    fi
    if [[ ! "${USER_GID}" =~ ^[0-9]+$ ]]; then
        fct_die "USER_GID must be numeric: ${USER_GID}"
    fi
}

main() {
    fct_validate_inputs
    fct_create_user
    fct_prepare_home
    fct_write_shell_config
    fct_configure_git
    fct_configure_ssh
    fct_configure_sudo
    fct_fix_ownership
}

main "$@"
