#!/usr/bin/env bash
# Launch an interactive development container from a local Docker image.

set -Eeuo pipefail

readonly SCRIPT_PATH="${BASH_SOURCE[0]}"
readonly SCRIPT_NAME="${SCRIPT_PATH##*/}"
readonly CONTAINER_OPENCODE_CONFIG_DIR="${CONTAINER_OPENCODE_CONFIG_DIR:-/home/illus/.config/opencode}"
readonly CONTAINER_WORKSPACE_ROOT="${CONTAINER_WORKSPACE_ROOT:-/home/illus/workspace}"
readonly CONTAINER_TERM="${CONTAINER_TERM:-xterm-256color}"

ENABLE_GPU=0
CONTAINER_NAME="dev-env"
ENABLE_SSH=1
IMAGE_NAME="cuda-torch"
PROJECT_DIR=""

fct_usage() {
    cat <<EOF
Usage:
  ${SCRIPT_NAME} [options]

Options:
  -n, --name <name>        Container name (default: dev-env)
  -i, --image <image>      Docker image to launch (default: cuda-torch)
  -p, --project <path>     Project directory to mount (default: current directory)
      --no-ssh             Do not forward SSH agent into the container
      --gpu                Pass --gpus all to docker run
  -h, --help               Show this help and exit

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} -n my-dev-env
  ${SCRIPT_NAME} -i cuda-torch -p ~/workspace/my-project
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
                fct_die "Option ${1} requires a container name."
            fi
            if [[ "${2}" == -* ]]; then
                fct_die "Option ${1} requires a container name."
            fi
            CONTAINER_NAME="${2}"
            shift 2
            ;;
        -i | --image)
            if [[ $# -lt 2 ]]; then
                fct_die "Option ${1} requires an image name."
            fi
            if [[ "${2}" == -* ]]; then
                fct_die "Option ${1} requires an image name."
            fi
            IMAGE_NAME="${2}"
            shift 2
            ;;
        -p | --project)
            if [[ $# -lt 2 ]]; then
                fct_die "Option ${1} requires a project path."
            fi
            if [[ "${2}" == -* ]]; then
                fct_die "Option ${1} requires a project path."
            fi
            PROJECT_DIR="${2}"
            shift 2
            ;;
        --no-ssh)
            ENABLE_SSH=0
            shift
            ;;
        --gpu)
            ENABLE_GPU=1
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

fct_resolve_project_dir() {
    local project_path="${1}"

    if [[ -z "${project_path}" ]]; then
        project_path="."
    fi
    if [[ ! -d "${project_path}" ]]; then
        fct_die "Project directory not found: ${project_path}"
    fi

    (cd "${project_path}" >/dev/null 2>&1 && pwd -P)
}

fct_append_ssh_args() {
    local host_os=""
    local ssh_auth_sock=""

    host_os="$(uname -s)"
    if [[ "${host_os}" == "Darwin" ]]; then
        DOCKER_COMMAND+=(
            --mount "type=bind,src=/run/host-services/ssh-auth.sock,target=/run/host-services/ssh-auth.sock"
            -e "SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock"
        )
        return 0
    fi

    ssh_auth_sock="${SSH_AUTH_SOCK:-}"
    if [[ -z "${ssh_auth_sock}" || ! -S "${ssh_auth_sock}" ]]; then
        fct_die "SSH_AUTH_SOCK is not set to a valid socket."
    fi

    DOCKER_COMMAND+=(
        -v "${ssh_auth_sock}:/ssh-agent"
        -e "SSH_AUTH_SOCK=/ssh-agent"
    )
}

fct_append_opencode_config_args() {
    local host_config_dir=""

    if [[ -n "${HOST_OPENCODE_CONFIG_DIR:-}" ]]; then
        host_config_dir="${HOST_OPENCODE_CONFIG_DIR}"
    elif [[ -n "${HOME:-}" ]]; then
        host_config_dir="${HOME}/.config/opencode"
    else
        fct_die "HOME is not set; cannot locate opencode config."
    fi

    if [[ ! -d "${host_config_dir}" ]]; then
        fct_die "opencode config directory not found: ${host_config_dir}"
    fi

    DOCKER_COMMAND+=(
        --mount "type=bind,src=${host_config_dir},target=${CONTAINER_OPENCODE_CONFIG_DIR}"
    )
    printf 'Mounting opencode config: %s -> %s\n' "${host_config_dir}" "${CONTAINER_OPENCODE_CONFIG_DIR}" >&2
}

fct_launch_container() {
    local container_workdir=""
    local container_id=""
    local project_basename=""
    local resolved_project_dir=""

    if ! command -v docker >/dev/null 2>&1; then
        fct_die "docker command not found."
    fi

    resolved_project_dir="$(fct_resolve_project_dir "${PROJECT_DIR}")"
    project_basename="${resolved_project_dir##*/}"
    if [[ -z "${project_basename}" ]]; then
        project_basename="project"
    fi
    container_workdir="${CONTAINER_WORKSPACE_ROOT}/${project_basename}"
    if docker container inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
        fct_die "Container already exists: ${CONTAINER_NAME}. Use 'docker exec -it ${CONTAINER_NAME} zsh' or remove it first."
    fi

    DOCKER_COMMAND=(docker run -dit --rm --init --name "${CONTAINER_NAME}")
    if [[ "${ENABLE_GPU}" -eq 1 ]]; then
        DOCKER_COMMAND+=(--gpus all)
    fi
    DOCKER_COMMAND+=(
        # Use a common terminfo entry so zsh line editing works in minimal images.
        -e "TERM=${CONTAINER_TERM}"
        -v "${resolved_project_dir}:${container_workdir}"
        -w "${container_workdir}"
    )
    if [[ "${ENABLE_SSH}" -eq 1 ]]; then
        fct_append_ssh_args
    fi
    fct_append_opencode_config_args
    DOCKER_COMMAND+=("${IMAGE_NAME}")

    printf 'Launching Docker image: %s\n' "${IMAGE_NAME}" >&2
    printf 'Container name: %s\n' "${CONTAINER_NAME}" >&2
    printf 'Mounting project: %s -> %s\n' "${resolved_project_dir}" "${container_workdir}" >&2
    container_id="$("${DOCKER_COMMAND[@]}")"
    printf 'Container started: %s\n' "${container_id}" >&2
    printf 'Enter with: docker exec -it %s zsh\n' "${CONTAINER_NAME}" >&2
}

main() {
    fct_parse_args "$@"
    fct_launch_container
}

DOCKER_COMMAND=()

main "$@"
