# renovate: datasource=docker depName=alpine versioning=docker
ARG ALPINE_VERSION=3.22

FROM alpine:${ALPINE_VERSION} AS builder

# Build arguments for other versions
# renovate: datasource=github-releases depName=golang/go extractVersion=^go(?<version>.*)$
ARG GO_VERSION=1.23.2
# renovate: datasource=github-releases depName=gohugoio/hugo extractVersion=^v(?<version>.*)$
ARG HUGO_VERSION=0.151.1
# renovate: datasource=github-releases depName=caddyserver/caddy extractVersion=^v(?<version>.*)$
ARG CADDY_VERSION=2.10.2
# renovate: datasource=github-releases depName=caddyserver/xcaddy extractVersion=^v(?<version>.*)$
ARG XCADDY_VERSION=v0.4.5
# renovate: datasource=git-refs depName=https://github.com/abiosoft/caddy-exec extractVersion=^(?<version>.*)$
ARG CADDY_EXEC_VERSION=master
# renovate: datasource=github-tags depName=sass/dart-sass extractVersion=^(?<version>.*)$
ARG DART_SASS_VERSION=1.93.2
# renovate: datasource=github-releases depName=cloudcannon/pagefind extractVersion=^v(?<version>.*)$
ARG PAGEFIND_VERSION=1.4.0

# Install build dependencies
RUN apk add --no-cache \
	git \
	ca-certificates \
	wget \
	&& update-ca-certificates

# Install Go manually
RUN wget --progress=dot:giga -O go.tar.gz \
	# editorconfig-checker-disable-next-line
	"https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
	&& tar -C /usr/local -xzf go.tar.gz \
	&& rm go.tar.gz

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

# Environment variables for Go
ENV GOROOT="/usr/local/go"
ENV GOPATH="/opt/go"
ENV PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

# Install xcaddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@${XCADDY_VERSION}

# Build Caddy with caddy-exec plugin using xcaddy
WORKDIR /caddy-build
RUN CADDY_VERSION=v${CADDY_VERSION} xcaddy build \
	--with github.com/abiosoft/caddy-exec@${CADDY_EXEC_VERSION}

# Final runtime image
FROM alpine:${ALPINE_VERSION}

# Install runtime dependencies including full glibc for Hugo
RUN apk add --no-cache \
	git \
	openssh-client \
	ca-certificates \
	curl \
	bash \
	nodejs \
	npm \
	libc6-compat \
	libstdc++ \
	libgcc \
	libcap-setcap \
	&& update-ca-certificates

# Copy Hugo, Caddy, Go, Dart Sass, and Pagefind from builder
COPY --from=builder /usr/local/go /usr/local/go
COPY --from=builder /usr/local/bin/hugo /usr/local/bin/hugo
COPY --from=builder /caddy-build/caddy /usr/local/bin/caddy
COPY --from=builder /usr/local/bin/sass /usr/local/bin/sass
COPY --from=builder /usr/local/bin/pagefind /usr/local/bin/pagefind

RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy

# Test that Hugo works
RUN hugo version

# Create non-root user
RUN addgroup -g 1000 appuser && \
	adduser -u 1000 -G appuser -s /bin/bash -D appuser

# Environment variables for Go
ENV GOROOT="/usr/local/go"
ENV GOPATH="/opt/go"
ENV PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

# Create directories
RUN mkdir -p /app/site /app/config /app/builds /home/appuser/.ssh /go && \
	chown -R appuser:appuser /app

# Set ownership of directories to appuser
RUN chown -R appuser:appuser /app /home/appuser

# Create update script
COPY update-site.sh /usr/local/bin/update-site.sh
RUN chmod +x /usr/local/bin/update-site.sh

# Create startup script
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Copy Caddy configuration
COPY Caddyfile /app/config/Caddyfile

RUN chown -R appuser /app/config && \
	caddy validate --config /app/config/Caddyfile

# Switch to non-root user
USER appuser

# Set working directory
WORKDIR /app

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
