#!/usr/bin/env bash
# Install a pinned Starship prompt release from the official GitHub tarball.

set -Eeuo pipefail

readonly STARSHIP_VERSION="${STARSHIP_VERSION:-1.25.1}"

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

fct_detect_starship_target() {
    local dpkg_arch=""

    dpkg_arch="$(dpkg --print-architecture)"
    case "${dpkg_arch}" in
    amd64)
        printf '%s\n' "x86_64-unknown-linux-musl"
        ;;
    arm64)
        printf '%s\n' "aarch64-unknown-linux-musl"
        ;;
    *)
        fct_die "Unsupported architecture for Starship: ${dpkg_arch}"
        ;;
    esac
}

fct_starship_sha256() {
    local starship_target="${1}"

    case "${STARSHIP_VERSION}:${starship_target}" in
    1.25.1:x86_64-unknown-linux-musl)
        printf '%s\n' "c6ddd3ecb9c0071a2ad38d98cee748160066b7c4f197421268058f4a5d6f8504"
        ;;
    1.25.1:aarch64-unknown-linux-musl)
        printf '%s\n' "01517aab398959ea9ea73bdb4f032ea4dbb51dff5c8e5eb05b4a1b9b7ab872b8"
        ;;
    *)
        fct_die "No pinned Starship SHA256 for ${STARSHIP_VERSION} on ${starship_target}."
        ;;
    esac
}

fct_install_starship() {
    local starship_archive=""
    local starship_sha256=""
    local starship_target=""
    local starship_url=""

    starship_target="$(fct_detect_starship_target)"
    starship_sha256="$(fct_starship_sha256 "${starship_target}")"
    starship_url="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-${starship_target}.tar.gz"

    TMP_DIR="$(mktemp -d)"
    starship_archive="${TMP_DIR}/starship.tar.gz"

    curl -fsSL --retry 3 -o "${starship_archive}" "${starship_url}"
    printf '%s  %s\n' "${starship_sha256}" "${starship_archive}" | sha256sum -c -

    tar -C "${TMP_DIR}" -xzf "${starship_archive}" starship
    install -m 0755 "${TMP_DIR}/starship" /usr/local/bin/starship

    starship --version >/dev/null
}

main() {
    trap fct_cleanup EXIT
    fct_install_starship
}

main "$@"
