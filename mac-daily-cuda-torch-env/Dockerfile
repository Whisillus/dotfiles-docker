FROM nvidia/cuda:12.9.1-devel-ubuntu22.04

ARG TORCH_VERSION=2.8.0
ARG TORCHVISION_VERSION=0.23.0
ARG TORCHAUDIO_VERSION=2.8.0
ARG USERNAME=Illus
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/${USERNAME} \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    SHELL=/usr/bin/zsh \
    USER=${USERNAME}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        python3 \
        python3-pip \
        python3-venv \
        python-is-python3 \
        sudo \
        zsh \
    && rm -rf /var/lib/apt/lists/*

RUN python -m pip install --upgrade pip setuptools wheel \
    && python -m pip install \
        --index-url https://download.pytorch.org/whl/cpu \
        "torch==${TORCH_VERSION}" \
        "torchvision==${TORCHVISION_VERSION}" \
        "torchaudio==${TORCHAUDIO_VERSION}"

RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /usr/bin/zsh "${USERNAME}" \
    && mkdir -p /workspace \
    && chown "${USER_UID}:${USER_GID}" /workspace \
    && printf '%s\n' 'PROMPT="%n@%m:%~%# "' > "/home/${USERNAME}/.zshrc" \
    && chown "${USER_UID}:${USER_GID}" "/home/${USERNAME}/.zshrc" \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}"

WORKDIR /workspace

USER ${USERNAME}

CMD ["/usr/bin/zsh"]
