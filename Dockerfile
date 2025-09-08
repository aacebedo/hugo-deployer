# Multi-stage build for Hugo site with Caddy and Git integration
# Build arguments for versions (must come before FROM to be used in FROM)
ARG GO_VERSION=1.25-alpine

FROM golang:${GO_VERSION} AS builder

# Build arguments for other versions
# renovate: datasource=github-releases depName=gohugoio/hugo extractVersion=^v(?<version>.*)$
ARG HUGO_VERSION=0.149.0
# renovate: datasource=github-releases depName=caddyserver/caddy extractVersion=^v(?<version>.*)$
ARG CADDY_VERSION=2.10.2
# renovate: datasource=github-releases depName=caddyserver/xcaddy extractVersion=^v(?<version>.*)$
ARG XCADDY_VERSION=v0.4.5
# renovate: datasource=git-refs depName=https://github.com/abiosoft/caddy-exec extractVersion=^(?<version>.*)$
ARG CADDY_EXEC_VERSION=master
# renovate: datasource=github-tags depName=sass/dart-sass extractVersion=^(?<version>.*)$
ARG DART_SASS_VERSION=1.91.0
# renovate: datasource=github-releases depName=cloudcannon/pagefind extractVersion=^v(?<version>.*)$
ARG PAGEFIND_VERSION=1.4.0

# Install build dependencies
RUN apk add --no-cache \
		git \
		ca-certificates \
		wget \
		&& update-ca-certificates

# Install Hugo - Use regular Linux version with glibc compatibility
RUN wget --progress=dot:giga -O hugo.tar.gz \
		# editorconfig-checker-disable-next-line
		"https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz" \
		&& tar -xzf hugo.tar.gz \
		&& mv hugo /usr/local/bin/ \
		&& rm hugo.tar.gz

# Install Dart Sass
RUN wget --progress=dot:giga -O dart-sass.tar.gz \
		# editorconfig-checker-disable-next-line
		"https://github.com/sass/dart-sass/releases/download/${DART_SASS_VERSION}/dart-sass-${DART_SASS_VERSION}-linux-x64.tar.gz" \
		&& tar -xzf dart-sass.tar.gz \
		&& mv dart-sass/sass /usr/local/bin/ \
		&& rm -rf dart-sass dart-sass.tar.gz

# Install Pagefind
RUN wget --progress=dot:giga -O pagefind.tar.gz \
		# editorconfig-checker-disable-next-line
		"https://github.com/cloudcannon/pagefind/releases/download/v${PAGEFIND_VERSION}/pagefind-v${PAGEFIND_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
		&& tar -xzf pagefind.tar.gz \
		&& mv pagefind /usr/local/bin/ \
		&& rm pagefind.tar.gz

# Install xcaddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@${XCADDY_VERSION}

# Build Caddy with caddy-exec plugin using xcaddy
WORKDIR /caddy-build
RUN CADDY_VERSION=v${CADDY_VERSION} xcaddy build \
		--with github.com/abiosoft/caddy-exec@${CADDY_EXEC_VERSION}

# Final runtime image
FROM alpine:3.22

# Install runtime dependencies including full glibc for Hugo
RUN apk add --no-cache \
		git \
		openssh-client \
		ca-certificates \
		curl \
		bash \
		libc6-compat \
		libstdc++ \
		libgcc \
		libcap-setcap \
		&& update-ca-certificates

# Copy Hugo, Caddy, Go, Dart Sass, and Pagefind from builder
COPY --from=builder /usr/local/bin/hugo /usr/local/bin/hugo
COPY --from=builder /caddy-build/caddy /usr/local/bin/caddy
COPY --from=builder /usr/local/bin/sass /usr/local/bin/sass
COPY --from=builder /usr/local/bin/pagefind /usr/local/bin/pagefind
COPY --from=builder /usr/local/go/bin/go /usr/local/bin/go
COPY --from=builder /usr/local/go /usr/local/go

RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy

# Test that Hugo works
RUN hugo version

# Create non-root user
RUN addgroup -g 1000 appuser && \
		adduser -u 1000 -G appuser -s /bin/bash -D appuser

# Create directories
RUN mkdir -p /app/site /app/config /app/builds /home/appuser/.ssh /go && \
		chown -R appuser:appuser /app/site /app/builds

# Set ownership of directories to appuser
RUN chown -R appuser:appuser /app /go /home/appuser

# Create update script
COPY update-site.sh /usr/local/bin/update-site.sh
RUN chmod +x /usr/local/bin/update-site.sh

# Create startup script
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Copy Caddy configuration
COPY Caddyfile /app/config/Caddyfile

RUN caddy validate --config /app/config/Caddyfile

# Switch to non-root user
USER appuser

# Set working directory
WORKDIR /app

# Environment variables for runtime configuration
ENV GOROOT="/usr/local/go"
ENV GOPATH="/go"
ENV PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

# Note: GIT_TOKEN and API_KEY should be provided at runtime via docker-compose or kubernetes
# for security reasons, not baked into the image

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
		CMD curl -f http://localhost:80 || exit 1

# Start with startup script that then runs Caddy
ENTRYPOINT ["/usr/local/bin/startup.sh"]
CMD ["caddy", "run", "--config", "/app/config/Caddyfile"]
