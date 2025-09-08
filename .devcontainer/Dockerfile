ARG ALPINE_VERSION=3.22

# Build arguments for tool versions

# renovate: datasource=github-releases depName=hadolint/hadolint extractVersion=^v(?<version>.*)$
ARG HADOLINT_VERSION=2.12.0
# renovate: datasource=pypi depName=yamllint extractVersion=^v(?<version>.*)$ extractVersion=^v(?<version>.*)$
ARG YAMLLINT_VERSION=1.37.1
# renovate: datasource=npm depName=markdownlint-cli2 extractVersion=^(?<version>.*)$
ARG MARKDOWNLINT_CLI2_VERSION=0.18.1
# renovate: datasource=pypi depName=pre-commit extractVersion=^(?<version>.*)$
ARG PRECOMMIT_VERSION=4.3.0
# renovate: datasource=github-tags depName=astral-sh/uv extractVersion=^(?<version>.*)$
ARG UV_VERSION=0.8.15
# renovate: datasource=npm depName=@prantlf/jsonlint extractVersion=^(?<version>.*)$
ARG JSONLINT_VERSION=16.0.0
# editorconfig-checker-disable-next-line
# renovate: datasource=github-releases depName=editorconfig-checker/editorconfig-checker extractVersion=^v(?<version>.*)$
ARG EDITORCONFIG_CHECKER_VERSION=3.4.0
# renovate: datasource=github-releases depName=casey/just extractVersion=^v(?<version>.*)$
ARG JUST_VERSION=1.42.4
# renovate: datasource=github-releases depName=aquasecurity/trivy extractVersion=^v(?<version>.*)$
ARG TRIVY_VERSION=0.65.0
# renovate: datasource=npm depName=semantic-release extractVersion=^(?<version>.*)$
ARG SEMANTIC_RELEASE_VERSION=24.2.7
# renovate: datasource=npm depName=@semantic-release/changelog extractVersion=^(?<version>.*)$
ARG SEMANTIC_RELEASE_CHANGELOG_VERSION=6.0.3
# renovate: datasource=npm depName=@semantic-release/exec extractVersion=^(?<version>.*)$
ARG SEMANTIC_RELEASE_EXEC_VERSION=7.1.0
# renovate: datasource=npm depName=@semantic-release/git extractVersion=^(?<version>.*)$
ARG SEMANTIC_RELEASE_GIT_VERSION=10.0.1
# renovate: datasource=github-releases depName=errata-ai/vale extractVersion=^v(?<version>.*)$
ARG VALE_VERSION=3.12.0
# renovate: datasource=npm depName=@semantic-release-plus/docker extractVersion=^(?<version>.*)$
ARG SEMANTIC_RELEASE_PLUS_DOCKER_VERSION=v3.1.3
# renovate: datasource=pypi depName=podman-compose extractVersion=^(?<version>.*)$
ARG PODMAN_COMPOSE_VERSION=1.5.0
# renovate: datasource=npm depName=renovate extractVersion=^(?<version>.*)$
ARG RENOVATE_VERSION=41.97.9

ARG USERNAME="devcontaineruser"
ARG USERUID="1000"
ARG USERGID="1000"

# Stage 1: Build tools installer
FROM alpine:${ALPINE_VERSION} AS installer

ARG HADOLINT_VERSION
ARG YAMLLINT_VERSION
ARG MARKDOWNLINT_VERSION
ARG PRECOMMIT_VERSION
ARG UV_VERSION
ARG EDITORCONFIG_CHECKER_VERSION
ARG JUST_VERSION
ARG TRIVY_VERSION
ARG VALE_VERSION
ARG PODMAN_COMPOSE_VERSION

# Install base packages
RUN apk add --no-cache \
		curl \
		git \
		ca-certificates \
		wget \
		bash \
		shadow \
		python3 && \
	update-ca-certificates

# Install uv
RUN wget --progress=dot:giga -O /tmp/uv.tar.gz \
		# editorconfig-checker-disable-next-line
		"https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-musl.tar.gz" && \
	tar -xzf /tmp/uv.tar.gz -C /tmp && \
	mv /tmp/uv-x86_64-unknown-linux-musl/uv /usr/local/bin/ && \
	chmod +x /usr/local/bin/uv && \
	rm -rf /tmp/uv.tar.gz /tmp/uv-x86_64-unknown-linux-musl

# Install editorconfig-checker
RUN wget --progress=dot:giga -O /tmp/editorconfig-checker.tar.gz \
		# editorconfig-checker-disable-next-line
		"https://github.com/editorconfig-checker/editorconfig-checker/releases/download/v${EDITORCONFIG_CHECKER_VERSION}/editorconfig-checker-linux-amd64.tar.gz" && \
	tar -xzf /tmp/editorconfig-checker.tar.gz -C /tmp && \
	mv /tmp/editorconfig-checker /usr/local/bin/ && \
	chmod +x /usr/local/bin/editorconfig-checker && \
	rm -rf /tmp/editorconfig-checker.tar.gz /tmp/editorconfig-checker

# Install hadolint
RUN wget --progress=dot:giga -O /usr/local/bin/hadolint \
		# editorconfig-checker-disable-next-line
		"https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64" && \
	chmod +x /usr/local/bin/hadolint

# Install just
RUN wget --progress=dot:giga -O /tmp/just.tar.gz \
		# editorconfig-checker-disable-next-line
		"https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz" && \
	tar -xzf /tmp/just.tar.gz -C /tmp && \
	mv /tmp/just /usr/local/bin/ && \
	chmod +x /usr/local/bin/just && \
	rm -rf /tmp/just.tar.gz

# Install trivy
RUN wget --progress=dot:giga -O /tmp/trivy.tar.gz \
		# editorconfig-checker-disable-next-line
		"https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" && \
	tar -xzf /tmp/trivy.tar.gz -C /tmp && \
	mv /tmp/trivy /usr/local/bin/ && \
	chmod +x /usr/local/bin/trivy && \
	rm -rf /tmp/trivy.tar.gz

# Install vale
RUN wget --progress=dot:giga -O /tmp/vale.tar.gz \
		# editorconfig-checker-disable-next-line
		"https://github.com/errata-ai/vale/releases/download/v${VALE_VERSION}/vale_${VALE_VERSION}_Linux_64-bit.tar.gz" && \
	tar -xzf /tmp/vale.tar.gz -C /tmp && \
	mv /tmp/vale /usr/local/bin/ && \
	chmod +x /usr/local/bin/vale && \
	rm -rf /tmp/vale.tar.gz

# Set up UV environment and install Python tools
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python
ENV UV_TOOL_BIN_DIR=/usr/local/bin
ENV UV_TOOL_DIR=/opt/uv/venv

RUN uv tool install "pre-commit==${PRECOMMIT_VERSION}" && \
	uv tool install "yamllint==${YAMLLINT_VERSION}" && \
	uv tool install "podman-compose==${PODMAN_COMPOSE_VERSION}"

# Stage 2: Final image
FROM alpine:${ALPINE_VERSION} AS final

ARG USERNAME
ARG USERUID
ARG USERGID
ARG JSONLINT_VERSION
ARG MARKDOWNLINT_VERSION
ARG SEMANTIC_RELEASE_VERSION
ARG SEMANTIC_RELEASE_CHANGELOG_VERSION
ARG SEMANTIC_RELEASE_EXEC_VERSION
ARG SEMANTIC_RELEASE_GIT_VERSION
ARG SEMANTIC_RELEASE_PLUS_DOCKER_VERSION
ARG RENOVATE_VERSION

# Install base packages (including runtime environments)
RUN apk add --no-cache \
		curl \
		git \
		shellcheck \
		ca-certificates \
		wget \
		bash \
		sudo \
		shadow \
		nodejs \
		npm \
		python3 \
		podman \
		podman-docker \
		fuse-overlayfs \
		iptables \
		make \
		g++ \
		openssh \
		libc6-compat \
		libstdc++ \
		libgcc \
		&& update-ca-certificates

# Copy installed binary tools from installer stage
COPY --from=installer /usr/local/bin/uv /usr/local/bin/uv
COPY --from=installer /usr/local/bin/editorconfig-checker /usr/local/bin/editorconfig-checker
COPY --from=installer /usr/local/bin/hadolint /usr/local/bin/hadolint
COPY --from=installer /usr/local/bin/just /usr/local/bin/just
COPY --from=installer /usr/local/bin/trivy /usr/local/bin/trivy
COPY --from=installer /usr/local/bin/vale /usr/local/bin/vale

# Copy UV tools and environment from installer stage
COPY --from=installer /opt/uv /opt/uv
COPY --from=installer /usr/local/bin/pre-commit /usr/local/bin/pre-commit
COPY --from=installer /usr/local/bin/yamllint /usr/local/bin/yamllint
COPY --from=installer /usr/local/bin/podman-compose /usr/local/bin/podman-compose

COPY containers.conf /etc/containers/containers.conf

# Set up UV environment
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python
ENV UV_TOOL_BIN_DIR=/usr/local/bin
ENV UV_TOOL_DIR=/opt/uv/venv

# Install Node.js tools
# hadolint ignore=DL3016
RUN npm install -g \
		"@prantlf/jsonlint@${JSONLINT_VERSION}" \
		"markdownlint-cli2@${MARKDOWNLINT_CLI2_VERSION}" \
		"semantic-release@${SEMANTIC_RELEASE_VERSION}" \
		"@semantic-release/changelog@${SEMANTIC_RELEASE_CHANGELOG_VERSION}" \
		"@semantic-release/exec@${SEMANTIC_RELEASE_EXEC_VERSION}" \
		"@semantic-release/git@${SEMANTIC_RELEASE_GIT_VERSION}" \
		"@semantic-release-plus/docker@${SEMANTIC_RELEASE_PLUS_DOCKER_VERSION}" \
		"renovate@${RENOVATE_VERSION}" && \
	npm cache clean --force

# Create/configure non-root user
RUN addgroup -g "$USERGID" "$USERNAME" && \
	adduser -u "$USERUID" -G "$USERNAME" -s /bin/bash -D "$USERNAME" && \
	echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME" && \
	chmod 0440 "/etc/sudoers.d/$USERNAME" && \
	echo "$USERNAME:100000:65536" >> /etc/subuid && \
	echo "$USERNAME:100000:65536" >> /etc/subgid

USER ${USERNAME}

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
	CMD [ "sh", "-c", "command -v sh" ]
