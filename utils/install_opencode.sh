#!/usr/bin/env bash
# Install the latest opencode CLI release from the official GitHub tarball.

set -Eeuo pipefail

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

fct_detect_opencode_asset() {
    local dpkg_arch=""

    dpkg_arch="$(dpkg --print-architecture)"
    case "${dpkg_arch}" in
    amd64)
        printf '%s\n' "opencode-linux-x64.tar.gz"
        ;;
    arm64)
        printf '%s\n' "opencode-linux-arm64.tar.gz"
        ;;
    *)
        fct_die "Unsupported architecture for opencode: ${dpkg_arch}"
        ;;
    esac
}

fct_install_opencode() {
    local installed_version=""
    local opencode_archive=""
    local opencode_asset=""
    local opencode_url=""

    opencode_asset="$(fct_detect_opencode_asset)"
    opencode_url="https://github.com/anomalyco/opencode/releases/latest/download/${opencode_asset}"

    TMP_DIR="$(mktemp -d)"
    opencode_archive="${TMP_DIR}/opencode.tar.gz"

    curl -fsSL --retry 3 -o "${opencode_archive}" "${opencode_url}"

    tar -C "${TMP_DIR}" -xzf "${opencode_archive}" opencode
    install -m 0755 "${TMP_DIR}/opencode" /usr/local/bin/opencode

    installed_version="$(opencode --version)"
    printf 'Installed opencode %s\n' "${installed_version}"
}

main() {
    trap fct_cleanup EXIT
    fct_install_opencode
}

main "$@"
