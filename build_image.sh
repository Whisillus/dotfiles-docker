#!/usr/bin/env bash
# Build one Docker image from a folder in this repo.

set -Eeuo pipefail

readonly SCRIPT_PATH="${BASH_SOURCE[0]}"
readonly SCRIPT_NAME="${SCRIPT_PATH##*/}"
readonly DEFAULT_PROXY_URL="http://host.docker.internal:7890"

IMAGE_NAME=""
USE_PROXY=0

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
      --proxy               Use host.docker.internal:7890 for docker build proxy
  -h, --help                Show this help and exit

Example:
  ${SCRIPT_NAME} -n cuda-torch
  ${SCRIPT_NAME} -n cuda-torch --proxy
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
        --proxy)
            USE_PROXY=1
            shift
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
    local -a docker_command=()
    local -a proxy_vars=(
        http_proxy https_proxy all_proxy
    )
    local proxy_name=""

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
    docker_command=(docker build -t "${IMAGE_NAME}" -f "${dockerfile_path}")

    if [[ "${USE_PROXY}" -eq 1 ]]; then
        for proxy_name in "${proxy_vars[@]}"; do
            docker_command+=(--build-arg "${proxy_name}=${DEFAULT_PROXY_URL}")
        done
        printf 'Using docker build proxy: %s\n' "${DEFAULT_PROXY_URL}" >&2
    fi

    docker_command+=("${SCRIPT_DIR}")
    "${docker_command[@]}"
}

main() {
    fct_parse_args "$@"
    fct_build_image
}

main "$@"
