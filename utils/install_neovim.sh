#!/usr/bin/env bash
# Install a pinned Neovim release from the official GitHub release tarball.

set -Eeuo pipefail

readonly NEOVIM_VERSION="${NEOVIM_VERSION:-0.11.6}"

fct_die() {
    local message="${1}"

    printf 'ERROR: %s\n' "${message}" >&2
    exit 1
}

fct_detect_neovim_arch() {
    local dpkg_arch=""

    dpkg_arch="$(dpkg --print-architecture)"
    case "${dpkg_arch}" in
    amd64)
        printf '%s\n' "x86_64"
        ;;
    arm64)
        printf '%s\n' "arm64"
        ;;
    *)
        fct_die "Unsupported architecture for Neovim: ${dpkg_arch}"
        ;;
    esac
}

fct_neovim_sha256() {
    local nvim_arch="${1}"

    case "${NEOVIM_VERSION}:${nvim_arch}" in
    0.11.6:x86_64)
        printf '%s\n' "2fc90b962327f73a78afbfb8203fd19db8db9cdf4ee5e2bef84704339add89cc"
        ;;
    0.11.6:arm64)
        printf '%s\n' "8ddc0c101846145e830b17bbca50782ca9307eee4fab539d9e2ddaf8793c06f1"
        ;;
    *)
        fct_die "No pinned Neovim SHA256 for ${NEOVIM_VERSION} on ${nvim_arch}."
        ;;
    esac
}

fct_install_neovim() {
    local nvim_arch=""
    local nvim_sha256=""
    local nvim_url=""
    local nvim_archive="/tmp/nvim.tar.gz"
    local nvim_dir=""

    nvim_arch="$(fct_detect_neovim_arch)"
    nvim_sha256="$(fct_neovim_sha256 "${nvim_arch}")"
    nvim_dir="/opt/nvim-linux-${nvim_arch}"
    nvim_url="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-${nvim_arch}.tar.gz"

    curl -fsSL --retry 3 -o "${nvim_archive}" "${nvim_url}"
    printf '%s  %s\n' "${nvim_sha256}" "${nvim_archive}" | sha256sum -c -

    rm -rf "${nvim_dir}"
    tar -C /opt -xzf "${nvim_archive}"
    ln -sf "${nvim_dir}/bin/nvim" /usr/local/bin/nvim
    ln -sf /usr/local/bin/nvim /usr/local/bin/vi
    ln -sf /usr/local/bin/nvim /usr/local/bin/vim
    update-alternatives --install /usr/bin/editor editor /usr/local/bin/nvim 100
    update-alternatives --set editor /usr/local/bin/nvim
    rm -f "${nvim_archive}"

    nvim --version >/dev/null
    vim --version >/dev/null
}

main() {
    fct_install_neovim
}

main "$@"
