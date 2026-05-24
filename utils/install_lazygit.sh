#!/usr/bin/env bash
# Install a pinned Lazygit release from the official GitHub release tarball.

set -Eeuo pipefail

readonly LAZYGIT_VERSION="${LAZYGIT_VERSION:-0.61.1}"

TMP_DIR=""

fct_die() {
    local message="${1}"

    printf 'ERROR: %s\n' "${message}" >&2
    exit 1
}

fct_cleanup() {
    if [[ -n "${TMP_DIR}" && -d "${TMP_DIR}" ]]; then
        rm -rf "${TMP_DIR}"
    fi
}

fct_detect_lazygit_arch() {
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
        fct_die "Unsupported architecture for Lazygit: ${dpkg_arch}"
        ;;
    esac
}

fct_lazygit_sha256() {
    local lazygit_arch="${1}"

    case "${LAZYGIT_VERSION}:${lazygit_arch}" in
    0.61.1:x86_64)
        printf '%s\n' "1b91e660700f2332696726b635202576b543e2bc49b639830dccd26bc5160d5d"
        ;;
    0.61.1:arm64)
        printf '%s\n' "20b1abb2bee5dfd46173b9047353eb678bc51a23839e821958d0b1863ab1655e"
        ;;
    *)
        fct_die "No pinned Lazygit SHA256 for ${LAZYGIT_VERSION} on ${lazygit_arch}."
        ;;
    esac
}

fct_install_lazygit() {
    local lazygit_arch=""
    local lazygit_archive=""
    local lazygit_sha256=""
    local lazygit_url=""

    lazygit_arch="$(fct_detect_lazygit_arch)"
    lazygit_sha256="$(fct_lazygit_sha256 "${lazygit_arch}")"
    lazygit_url="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_${lazygit_arch}.tar.gz"

    TMP_DIR="$(mktemp -d)"
    lazygit_archive="${TMP_DIR}/lazygit.tar.gz"

    curl -fsSL --retry 3 -o "${lazygit_archive}" "${lazygit_url}"
    printf '%s  %s\n' "${lazygit_sha256}" "${lazygit_archive}" | sha256sum -c -

    tar -C "${TMP_DIR}" -xzf "${lazygit_archive}" lazygit
    install -m 0755 "${TMP_DIR}/lazygit" /usr/local/bin/lazygit
    ln -sf /usr/local/bin/lazygit /usr/local/bin/lg

    lazygit --version >/dev/null
    lg --version >/dev/null
}

main() {
    trap fct_cleanup EXIT
    fct_install_lazygit
}

main "$@"
