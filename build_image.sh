#!/usr/bin/env bash
# Build one Docker image from a folder in this repo.

set -Eeuo pipefail

readonly SCRIPT_PATH="${BASH_SOURCE[0]}"
readonly SCRIPT_NAME="${SCRIPT_PATH##*/}"

IMAGE_NAME=""

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
  ${SCRIPT_NAME} -n <folder-name>

Options:
  -n, --name <folder-name>  Folder to build and image tag to create
  -h, --help                Show this help and exit

Example:
  ${SCRIPT_NAME} -n cuda-torch
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
        -n | --name)
            if [[ $# -lt 2 ]]; then
                fct_die "Option ${1} requires a folder name."
            fi
            if [[ "${2}" == -* ]]; then
                fct_die "Option ${1} requires a folder name."
            fi
            IMAGE_NAME="${2}"
            shift 2
            ;;
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

fct_build_image() {
    local context_dir="${SCRIPT_DIR}/${IMAGE_NAME}"
    local dockerfile_path="${context_dir}/Dockerfile"

    if [[ -z "${IMAGE_NAME}" ]]; then
        fct_usage
        exit 1
    fi
    if [[ ! -d "${context_dir}" ]]; then
        fct_die "Docker context folder not found: ${context_dir}"
    fi
    if [[ ! -f "${dockerfile_path}" ]]; then
        fct_die "Dockerfile not found: ${dockerfile_path}"
    fi
    if ! command -v docker >/dev/null 2>&1; then
        fct_die "docker command not found."
    fi

    printf 'Building Docker image: %s\n' "${IMAGE_NAME}" >&2
    docker build -t "${IMAGE_NAME}" "${context_dir}"
}

main() {
    fct_parse_args "$@"
    fct_build_image
}

main "$@"
