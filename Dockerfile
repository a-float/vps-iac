ARG NANOBOT_BASE_IMAGE

FROM ${NANOBOT_BASE_IMAGE}

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends gh curl nano htop \
    && rm -rf /var/lib/apt/lists/*

USER root