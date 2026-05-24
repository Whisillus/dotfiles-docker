#!/usr/bin/env bash
# Create the default non-root user and configure editor, git, and ssh defaults.

set -Eeuo pipefail

readonly USERNAME="${USERNAME:-illus}"
readonly USER_UID="${USER_UID:-1000}"
readonly USER_GID="${USER_GID:-1000}"

fct_die() {
    local message="${1}"

    printf 'ERROR: %s\n' "${message}" >&2
    exit 1
}

fct_create_user() {
    if ! getent group "${USER_GID}" >/dev/null; then
        groupadd --gid "${USER_GID}" "${USERNAME}"
    fi

    if ! id --user "${USERNAME}" >/dev/null 2>&1; then
        useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /usr/bin/zsh "${USERNAME}"
    fi
}

fct_write_shell_config() {
    local home_dir="/home/${USERNAME}"

    cat >"${home_dir}/.zshrc" <<'EOF'
export EDITOR=nvim
export VISUAL=nvim
export GIT_EDITOR=nvim

alias vi='nvim'
alias vim='nvim'
alias lg='lazygit'
alias ls='ls --color=auto'
alias ll='ls -alF'
alias l='ll'
alias s='ls'

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
EOF

    cat >"${home_dir}/.bashrc" <<'EOF'
export EDITOR=nvim
export VISUAL=nvim
export GIT_EDITOR=nvim

alias vi='nvim'
alias vim='nvim'
alias lg='lazygit'
alias ls='ls --color=auto'
alias ll='ls -alF'
alias l='ll'
alias s='ls'

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
EOF

    cat >"${home_dir}/.config/starship.toml" <<'EOF'
add_newline = false
format = "$username:$directory$git_branch$git_status$python$character"

[character]
success_symbol = ">"
error_symbol = ">"

[directory]
format = "[$path]($style)"
style = "bold yellow"
truncation_length = 3

[git_branch]
format = " on [$branch]($style)"
style = "bold purple"

[git_status]
format = " [$all_status$ahead_behind]($style)"
style = "bold red"

[python]
format = " [py $version]($style)"
style = "bold green"

[username]
format = "[$user]($style)"
show_always = true
style_user = "bold cyan"
EOF
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
        "${home_dir}/.config" \
        "${home_dir}/.ssh"
    chmod 700 "${home_dir}/.ssh"
}

fct_fix_ownership() {
    local home_dir="/home/${USERNAME}"

    chown -R "${USER_UID}:${USER_GID}" \
        "${home_dir}/workspace" \
        "${home_dir}/.cache" \
        "${home_dir}/.config" \
        "${home_dir}/.ssh" \
        "${home_dir}/.bashrc" \
        "${home_dir}/.gitconfig" \
        "${home_dir}/.zshrc"
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
