# The build argument versions below are kept up to date by Updatecli,
# see .updatecli/manifests/dockerfile.yaml for the upstream source of each one.
ARG ALPINE_VERSION=3.24

FROM alpine:${ALPINE_VERSION} AS builder

ARG GO_VERSION=1.23.2
ARG HUGO_VERSION=0.165.0
ARG CADDY_VERSION=2.11.1
ARG XCADDY_VERSION=v0.4.5
ARG CADDY_EXEC_VERSION=master
ARG DART_SASS_VERSION=1.101.0

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

# Install build dependencies
RUN <<EOF
apk update
apk upgrade
apk add --no-cache \
    ca-certificates \
    libarchive-tools
EOF

RUN <<EOF
wget -nv -O- "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz" | bsdtar -xzf - -C /tmp
# editorconfig-checker-disable-next-line
wget -nv -O- "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz" \
  | bsdtar -xzf - -C /tmp
# editorconfig-checker-disable-next-line
wget -nv -O- "https://github.com/sass/dart-sass/releases/download/${DART_SASS_VERSION}/dart-sass-${DART_SASS_VERSION}-linux-x64.tar.gz" \
  | bsdtar --strip-components=1 -xzf - -C /tmp
EOF

ENV GOPATH="/tmp/go" \
    PATH="/tmp/go/bin:$PATH"

# Install xcaddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@${XCADDY_VERSION}

# Build Caddy with caddy-exec plugin using xcaddy
WORKDIR /caddy-build
RUN CADDY_VERSION=v${CADDY_VERSION} xcaddy build --with github.com/abiosoft/caddy-exec@${CADDY_EXEC_VERSION}

# Final runtime image
FROM alpine:${ALPINE_VERSION}

# Install runtime dependencies including full glibc for Hugo
RUN <<EOF
apk update
apk upgrade
apk add --no-cache \
    git \
    ca-certificates \
    curl \
    bash \
    gcompat \
    libstdc++ \
    libgcc \
    libcap-setcap
EOF

# Copy Hugo, Caddy, Go, Dart Sass
COPY --from=builder --chmod=0755 /tmp/go /opt/go
COPY --from=builder --chmod=0755 /tmp/hugo /usr/local/bin/hugo
COPY --from=builder --chmod=0755 /caddy-build/caddy /usr/local/bin/caddy
COPY --from=builder --chmod=0755 /tmp/sass /usr/local/bin/sass

RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy

ENV PATH="/opt/go/bin:/opt/node/bin:${PATH}"

# Create update script
COPY --chmod=0755 update-site.sh /usr/local/bin/update-site.sh

# Create startup script
COPY --chmod=0755 startup.sh /usr/local/bin/startup.sh

# Copy Caddy configuration
COPY Caddyfile /app/config/Caddyfile

# Create non-root user
RUN <<EOF
addgroup -g 1000 appuser
adduser -u 1000 -G appuser -s /bin/bash -D appuser
EOF

RUN <<EOF
mkdir -p /app/site /app/config /app/builds /home/appuser/.ssh /go
chown -R appuser:appuser /app /home/appuser
caddy validate --config /app/config/Caddyfile
EOF

# Switch to non-root user
USER appuser

# Set working directory
WORKDIR /app

# Note: GIT_TOKEN and API_KEY should be provided at runtime via docker-compose or kubernetes
# for security reasons, not baked into the image

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=60s --timeout=3s --start-period=5s --retries=5 \
  CMD curl -f http://localhost:80 || exit 1

# Start with startup script that then runs Caddy
ENTRYPOINT ["/usr/local/bin/startup.sh"]
CMD ["caddy", "run", "--config", "/app/config/Caddyfile"]
