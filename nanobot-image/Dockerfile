ARG NANOBOT_BASE_IMAGE

FROM ${NANOBOT_BASE_IMAGE}

USER root

# TODO install curl and htop?
RUN apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

USER root