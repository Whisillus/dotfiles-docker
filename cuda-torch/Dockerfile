FROM nvidia/cuda:12.9.1-devel-ubuntu22.04

ARG TORCH_VERSION=2.8.0
ARG TORCHVISION_VERSION=0.23.0
ARG TORCHAUDIO_VERSION=2.8.0
ARG USERNAME=illus
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    CCACHE_DIR=/home/${USERNAME}/.cache/ccache \
    HOME=/home/${USERNAME} \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/home/${USERNAME}/.local/bin:${PATH} \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    SHELL=/usr/bin/zsh \
    USER=${USERNAME}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
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
        rsync \
        sudo \
        tmux \
        unzip \
        vim \
        zip \
        zsh \
    && rm -rf /var/lib/apt/lists/*

RUN python -m pip install --upgrade pip setuptools wheel \
    && python -m pip install \
        --index-url https://download.pytorch.org/whl/cpu \
        "torch==${TORCH_VERSION}" \
        "torchvision==${TORCHVISION_VERSION}" \
        "torchaudio==${TORCHAUDIO_VERSION}"

RUN if ! getent group "${USER_GID}" >/dev/null; then groupadd --gid "${USER_GID}" "${USERNAME}"; fi \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /usr/bin/zsh "${USERNAME}" \
    && mkdir -p "/home/${USERNAME}/workspace" "/home/${USERNAME}/.cache/ccache" \
    && chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}/workspace" "/home/${USERNAME}/.cache" \
    && printf '%s\n' 'PROMPT="%n@%m:%~%# "' > "/home/${USERNAME}/.zshrc" \
    && chown "${USER_UID}:${USER_GID}" "/home/${USERNAME}/.zshrc" \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}"

WORKDIR /home/${USERNAME}/workspace

USER ${USERNAME}

CMD ["/usr/bin/zsh"]
