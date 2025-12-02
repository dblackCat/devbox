FROM node:22.12-alpine


ARG USER_ID=1000
ARG GROUP_ID=1000

RUN apk add --no-cache shadow && \
    if getent group ${GROUP_ID}; then groupmod -g ${GROUP_ID} node; else groupadd -g ${GROUP_ID} node; fi && \
    if getent passwd ${USER_ID}; then usermod -u ${USER_ID} node; else useradd -u ${USER_ID} -g ${GROUP_ID} node; fi && \
    mkdir -p /var/www && \
    chown -R ${USER_ID}:${GROUP_ID} /var/www

USER node

WORKDIR /var/www
