ARG ALPINE_VERSION=3.21

# Build arguments for tool versions
ARG HADOLINT_VERSION="2.12.0"
ARG YAMLLINT_VERSION="1.37.1"
ARG MARKDOWNLINT_VERSION="0.18.1"
ARG PRECOMMIT_VERSION="4.3.0"
ARG UV_VERSION="0.8.11"
ARG JSONLINT_VERSION="1.6.0"
ARG EDITORCONFIG_CHECKER_VERSION="3.4.0"
ARG JUST_VERSION="1.42.4"
ARG TRIVY_VERSION="0.65.0"
ARG SEMANTIC_RELEASE_VERSION="24.2.7"
ARG SEMANTIC_RELEASE_CHANGELOG_VERSION="6.0.3"
ARG SEMANTIC_RELEASE_EXEC_VERSION="7.1.0"
ARG SEMANTIC_RELEASE_DOCKER_VERSION="5.1.1"
ARG SEMANTIC_RELEASE_GIT_VERSION="10.0.1"
ARG VALE_VERSION="3.12.0"
ARG SEMANTIC_RELEASE_PLUS_DOCKER="v3.1.3"

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
	uv tool install "yamllint==${YAMLLINT_VERSION}"

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
ARG SEMANTIC_RELEASE_DOCKER_VERSION
ARG SEMANTIC_RELEASE_GIT_VERSION

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
		make \
		g++ \
		openssh \
		libc6-compat \
		libstdc++ \
		libgcc \
		patch \
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

# Set up UV environment
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python
ENV UV_TOOL_BIN_DIR=/usr/local/bin
ENV UV_TOOL_DIR=/opt/uv/venv

# Install Node.js tools
RUN npm install -g \
		"jsonlint@${JSONLINT_VERSION}" \
		"markdownlint-cli2@${MARKDOWNLINT_VERSION}" \
		"semantic-release@${SEMANTIC_RELEASE_VERSION}" \
		"@semantic-release/changelog@${SEMANTIC_RELEASE_CHANGELOG_VERSION}" \
		"@semantic-release/exec@${SEMANTIC_RELEASE_EXEC_VERSION}" \
		"@semantic-release/git@${SEMANTIC_RELEASE_GIT_VERSION}" \
		"@semantic-release-plus/docker@${SEMANTIC_RELEASE_PLUS_DOCKER}" \
		"@codedependant/semantic-release-docker@${SEMANTIC_RELEASE_DOCKER_VERSION}" && \
	npm cache clean --force

COPY patches/001-no-network.patch /tmp
RUN patch -p1 -d "/usr/local/lib/node_modules/@codedependant/semantic-release-docker/" \
		< /tmp/001-no-network.patch \
		&& rm -f /tmp/001-no-network.patch

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
