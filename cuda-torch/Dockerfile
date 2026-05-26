FROM nvcr.io/nvidia/cuda:12.9.1-devel-ubuntu22.04

ARG TORCH_VERSION=2.8.0
ARG TORCHVISION_VERSION=0.23.0
ARG TORCHAUDIO_VERSION=2.8.0
ARG TVM_FFI_VERSION=0.1.11
ARG TORCH_C_DLPACK_EXT_VERSION=0.1.5
ARG PRE_COMMIT_VERSION=4.6.0
ARG TORCH_VARIANT=cpu
ARG TORCH_CUDA_FLAVOR=cu128
ARG NEOVIM_VERSION=0.11.6
ARG LAZYGIT_VERSION=0.61.1
ARG STARSHIP_VERSION=1.25.1
ARG USERNAME=illus
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    CCACHE_DIR=/home/${USERNAME}/.cache/ccache \
    EDITOR=nvim \
    GIT_EDITOR=nvim \
    HOME=/home/${USERNAME} \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/home/${USERNAME}/.local/bin:${PATH} \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    SHELL=/usr/bin/zsh \
    USER=${USERNAME} \
    VISUAL=nvim

COPY utils/ /tmp/docker-utils/

RUN apt-get -o Acquire::Retries=5 update \
    && apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
        autojump \
        build-essential \
        ca-certificates \
        ccache \
        clang-format \
        clangd \
        cmake \
        curl \
        file \
        gdb \
        git \
        iproute2 \
        iputils-ping \
        less \
        locales \
        lsof \
        ninja-build \
        openssh-client \
        pkg-config \
        procps \
        psmisc \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        python-is-python3 \
        ripgrep \
        rsync \
        sudo \
        tmux \
        unzip \
        vim \
        zip \
        zsh \
        zsh-autosuggestions \
        zsh-completions \
        zsh-syntax-highlighting \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

RUN chmod +x /tmp/docker-utils/*.sh \
    && NEOVIM_VERSION="${NEOVIM_VERSION}" /tmp/docker-utils/install_neovim.sh \
    && LAZYGIT_VERSION="${LAZYGIT_VERSION}" /tmp/docker-utils/install_lazygit.sh \
    && STARSHIP_VERSION="${STARSHIP_VERSION}" /tmp/docker-utils/install_starship.sh

RUN set -eux; \
    python -m pip install --upgrade pip setuptools wheel; \
    case "${TORCH_VARIANT}" in \
        cpu) torch_index_url="https://download.pytorch.org/whl/cpu" ;; \
        cuda) torch_index_url="https://download.pytorch.org/whl/${TORCH_CUDA_FLAVOR}" ;; \
        *) echo "Unsupported TORCH_VARIANT: ${TORCH_VARIANT}" >&2; exit 1 ;; \
    esac; \
    python -m pip install \
        --index-url "${torch_index_url}" \
        "torch==${TORCH_VERSION}" \
        "torchvision==${TORCHVISION_VERSION}" \
        "torchaudio==${TORCHAUDIO_VERSION}"; \
    python -m pip install \
        "apache-tvm-ffi==${TVM_FFI_VERSION}" \
        "torch-c-dlpack-ext==${TORCH_C_DLPACK_EXT_VERSION}" \
        "pre-commit==${PRE_COMMIT_VERSION}"; \
    python -c 'import tvm_ffi'; \
    pre-commit --version

RUN /tmp/docker-utils/install_opencode.sh

RUN USERNAME="${USERNAME}" USER_UID="${USER_UID}" USER_GID="${USER_GID}" /tmp/docker-utils/setup_user_env.sh \
    && rm -rf /tmp/docker-utils

WORKDIR /home/${USERNAME}/workspace

USER ${USERNAME}

CMD ["/usr/bin/zsh"]
