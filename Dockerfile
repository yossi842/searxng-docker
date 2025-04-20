# syntax=docker/dockerfile:1

# stage: build searxng
FROM docker.io/searxng/searxng:latest as build

# stage: caddy
# hadolint ignore=DL3006
FROM docker.io/library/caddy:2-alpine as caddy

# stage: redis/valkey
# hadolint ignore=DL3006
FROM docker.io/valkey/valkey:7-alpine as redis

# stage: final searxng image
FROM docker.io/searxng/searxng:latest

# copy artifacts from other stages
COPY --from=build /usr/local/searxng/ /usr/local/searxng/
COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY --from=redis /usr/local/bin/valkey-server /usr/local/bin/redis-server

# copy local files
COPY --chown=searxng:searxng ./searxng/ /etc/searxng/
COPY ./Caddyfile /etc/caddy/Caddyfile

# set permissions
RUN \
    # create group and user if not exists (only relevant in rootless mode)
    addgroup -g ${GID:-1000} searxng 2> /dev/null || true \
    && adduser -u ${UID:-1000} -G searxng -h /usr/local/searxng -D searxng 2> /dev/null || true \
    # change ownership
    && chown -R searxng:searxng \
        /etc/searxng \
        /usr/local/searxng \
    # create and change ownership of log directory
    && mkdir -p /var/log/searxng \
    && chown searxng:searxng /var/log/searxng \
    # create and change ownership of redis data directory
    && mkdir -p /var/lib/redis \
    && chown searxng:searxng /var/lib/redis

# expose port
EXPOSE 8080

# set user
USER searxng:searxng

# set entrypoint
ENTRYPOINT ["/usr/local/searxng/dockerfiles/entrypoint.sh"]

# set default command
CMD ["all"]
