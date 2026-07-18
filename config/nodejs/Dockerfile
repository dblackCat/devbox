FROM node:22.12-slim

ARG USER_ID=1000
ARG GROUP_ID=1000

RUN apt-get update && apt-get install -y bash && \
    if getent group ${GROUP_ID}; then groupmod -g ${GROUP_ID} node; else groupadd -g ${GROUP_ID} node; fi && \
    if getent passwd ${USER_ID}; then usermod -u ${USER_ID} node; else useradd -u ${USER_ID} -g ${GROUP_ID} node; fi && \
    mkdir -p /var/www && \
    chown -R ${USER_ID}:${GROUP_ID} /var/www && \
    rm -rf /var/lib/apt/lists/*

USER node

WORKDIR /var/www
