# syntax=docker/dockerfile:1
# Dockerfile Simplified: Attempt to run only SearXNG without Caddy/Redis

# stage: build searxng (Still needed to get artifacts)
FROM docker.io/searxng/searxng:latest as build

# stage: final searxng image (Based directly on the official image)
FROM docker.io/searxng/searxng:latest

# copy artifacts ONLY from the searxng build stage
COPY --from=build /usr/local/searxng/ /usr/local/searxng/

# copy ONLY local searxng configuration files
# IMPORTANT: Ensure your settings.yml is compatible with running without Redis if needed.
COPY --chown=searxng:searxng ./searxng/ /etc/searxng/
# We DO NOT copy Caddyfile anymore

# set permissions (Simplified - Remove Redis parts)
RUN \
    # create group and user if not exists (only relevant in rootless mode)
    addgroup -g ${GID:-1000} searxng 2> /dev/null || true \
    && adduser -u ${UID:-1000} -G searxng -h /usr/local/searxng -D searxng 2> /dev/null || true \
    # change ownership for searxng related files/dirs
    && chown -R searxng:searxng \
        /etc/searxng \
        /usr/local/searxng \
    # create and change ownership of log directory
    && mkdir -p /var/log/searxng \
    && chown searxng:searxng /var/log/searxng \
    # DO NOT create redis directory anymore
    # && mkdir -p /var/lib/redis \
    # && chown searxng:searxng /var/lib/redis
    && echo "Simplified setup complete." # Added for clarity

# expose port (SearXNG uwsgi usually listens on 8080)
EXPOSE 8080

# set user
USER searxng:searxng

# **MODIFIED STARTUP COMMAND**
# Remove original ENTRYPOINT and CMD ["all"]
# Directly execute uWSGI using the standard config file
# This bypasses the original entrypoint script that tried to start Caddy/Redis
CMD ["uwsgi", "--ini", "/etc/searxng/uwsgi.ini"]
