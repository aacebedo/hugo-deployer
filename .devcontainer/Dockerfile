# renovate: datasource=docker depName=alpine versioning=docker
ARG ALPINE_VERSION=3.23

# Build arguments for tool versions

# renovate: datasource=github-releases depName=hadolint/hadolint extractVersion=^v(?<version>.*)$
ARG HADOLINT_VERSION=2.14.0
# renovate: datasource=pypi depName=yamllint extractVersion=^v(?<version>.*)$ extractVersion=^v(?<version>.*)$
ARG YAMLLINT_VERSION=1.37.1
# renovate: datasource=npm depName=markdownlint-cli2 extractVersion=^(?<version>.*)$
ARG MARKDOWNLINT_CLI2_VERSION=0.20.0
# renovate: datasource=pypi depName=pre-commit extractVersion=^(?<version>.*)$
ARG PRECOMMIT_VERSION=4.5.0
# renovate: datasource=github-tags depName=astral-sh/uv extractVersion=^(?<version>.*)$
ARG UV_VERSION=0.9.17
# renovate: datasource=npm depName=@prantlf/jsonlint extractVersion=^(?<version>.*)$
ARG JSONLINT_VERSION=16.0.0
# editorconfig-checker-disable-next-line
# renovate: datasource=github-releases depName=editorconfig-checker/editorconfig-checker extractVersion=^v(?<version>.*)$
ARG EDITORCONFIG_CHECKER_VERSION=3.6.0
# renovate: datasource=github-releases depName=casey/just extractVersion=^v(?<version>.*)$
ARG JUST_VERSION=1.42.4
# renovate: datasource=github-releases depName=aquasecurity/trivy extractVersion=^v(?<version>.*)$
ARG TRIVY_VERSION=0.68.1
# renovate: datasource=npm depName=semantic-release extractVersion=^(?<version>.*)$
ARG SEMANTIC_RELEASE_VERSION=25.0.2
# renovate: datasource=npm depName=@semantic-release/changelog extractVersion=^(?<version>.*)$
ARG SEMANTIC_RELEASE_CHANGELOG_VERSION=6.0.3
# renovate: datasource=npm depName=@semantic-release/exec extractVersion=^(?<version>.*)$
ARG SEMANTIC_RELEASE_EXEC_VERSION=7.1.0
# renovate: datasource=npm depName=@semantic-release/git extractVersion=^(?<version>.*)$
ARG SEMANTIC_RELEASE_GIT_VERSION=10.0.1
# renovate: datasource=github-releases depName=errata-ai/vale extractVersion=^v(?<version>.*)$
ARG VALE_VERSION=3.13.0
# renovate: datasource=npm depName=@semantic-release-plus/docker extractVersion=^(?<version>.*)$
ARG SEMANTIC_RELEASE_PLUS_DOCKER_VERSION=v3.1.3
# renovate: datasource=pypi depName=podman-compose extractVersion=^(?<version>.*)$
ARG PODMAN_COMPOSE_VERSION=1.5.0
# renovate: datasource=npm depName=renovate extractVersion=^(?<version>.*)$
ARG RENOVATE_VERSION=42.47.0
# renovate: datasource=github-releases depName=helm/helm extractVersion=^v(?<version>.*)$
ARG HELM_VERSION=3.19.2
# renovate: datasource=github-releases depName=stackrox/kube-linter extractVersion=^v(?<version>.*)$
ARG KUBE_LINTER_VERSION=0.7.6
# renovate: datasource=pypi depName=checkov extractVersion=^(?<version>.*)$
ARG CHECKOV_VERSION=3.2.495
# renovate: datasource=github-releases depName=yannh/kubeconform extractVersion=^v(?<version>.*)$
ARG KUBECONFORM_VERSION=0.7.0
# renovate: datasource=github-releases depName=jj-vcs/jj extractVersion=^v(?<version>.*)$
ARG JJ_VERSION=0.36.0
# renovate: datasource=github-releases depName=koalaman/shellcheck extractVersion=^v(?<version>.*)$
ARG SHELLCHECK_VERSION=0.11.0

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
ARG HELM_VERSION
ARG CHECKOV_VERSION
ARG KUBECONFORM_VERSION
ARG JJ_VERSION
ARG SHELLCHECK_VERSION
ARG KUBE_LINTER_VERSION

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

# Install shellcheck
RUN wget --progress=dot:giga -O /tmp/shellcheck.tar.xz \
	# editorconfig-checker-disable-next-line
	"https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" && \
	tar -xJf /tmp/shellcheck.tar.xz -C /tmp && \
	mv /tmp/shellcheck-v${SHELLCHECK_VERSION}/shellcheck /usr/local/bin/ && \
	chmod +x /usr/local/bin/shellcheck && \
	rm -rf /tmp/shellcheck.tar.xz /tmp/shellcheck-v${SHELLCHECK_VERSION}

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

# Install helm
RUN wget --progress=dot:giga -O /tmp/helm.tar.gz \
	# editorconfig-checker-disable-next-line
	"https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" && \
	tar -xzf /tmp/helm.tar.gz -C /tmp && \
	mv /tmp/linux-amd64/helm /usr/local/bin/ && \
	chmod +x /usr/local/bin/helm && \
	rm -rf /tmp/helm.tar.gz /tmp/linux-amd64

# Install kube-linter
RUN wget --progress=dot:giga -O /usr/local/bin/kube-linter \
	# editorconfig-checker-disable-next-line
	"https://github.com/stackrox/kube-linter/releases/download/v${KUBE_LINTER_VERSION}/kube-linter-linux" && \
	chmod +x /usr/local/bin/kube-linter

# Install kubeconform
RUN wget --progress=dot:giga -O /tmp/kubeconform.tar.gz \
	# editorconfig-checker-disable-next-line
	"https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz" && \
	tar -xzf /tmp/kubeconform.tar.gz -C /tmp && \
	mv /tmp/kubeconform /usr/local/bin/ && \
	chmod +x /usr/local/bin/kubeconform && \
	rm -rf /tmp/kubeconform.tar.gz

# Install jujutsu (jj)
RUN wget --progress=dot:giga -O /tmp/jj.tar.gz \
	# editorconfig-checker-disable-next-line
	"https://github.com/jj-vcs/jj/releases/download/v${JJ_VERSION}/jj-v${JJ_VERSION}-x86_64-unknown-linux-musl.tar.gz" && \
	tar -xzf /tmp/jj.tar.gz -C /tmp && \
	mv /tmp/jj /usr/local/bin/ && \
	chmod +x /usr/local/bin/jj && \
	rm -rf /tmp/jj.tar.gz

# Install uv
RUN wget --progress=dot:giga -O /tmp/uv.tar.gz \
		# editorconfig-checker-disable-next-line
		"https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-musl.tar.gz" && \
	tar -xzf /tmp/uv.tar.gz -C /tmp && \
	mv /tmp/uv-x86_64-unknown-linux-musl/uv /usr/local/bin/ && \
	chmod +x /usr/local/bin/uv && \
	rm -rf /tmp/uv.tar.gz /tmp/uv-x86_64-unknown-linux-musl

# Set up UV environment
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python
ENV UV_TOOL_BIN_DIR=/usr/local/bin
ENV UV_TOOL_DIR=/opt/uv/venvs

RUN uv tool install "pre-commit==${PRECOMMIT_VERSION}" && \
	uv tool install "yamllint==${YAMLLINT_VERSION}" && \
	uv tool install "podman-compose==${PODMAN_COMPOSE_VERSION}" && \
	uv tool install "checkov==${CHECKOV_VERSION}"

ENV HELM_DATA_HOME="/opt/helm/data"

RUN helm plugin install https://github.com/jtyr/kubeconform-helm

# Stage 2: Final image
FROM alpine:${ALPINE_VERSION} AS final

ARG JSONLINT_VERSION
ARG MARKDOWNLINT_VERSION
ARG SEMANTIC_RELEASE_VERSION
ARG SEMANTIC_RELEASE_CHANGELOG_VERSION
ARG SEMANTIC_RELEASE_EXEC_VERSION
ARG SEMANTIC_RELEASE_GIT_VERSION
ARG SEMANTIC_RELEASE_PLUS_DOCKER_VERSION
ARG RENOVATE_VERSION

ARG USERNAME="devcontaineruser"
ARG USERUID="1000"
ARG USERGID="1000"

# Install base packages (including runtime environments)
RUN apk update && \
		apk upgrade && \
		apk add --no-cache \
		curl \
		git \
		ca-certificates \
		wget \
		bash \
		sudo \
		shadow \
		nodejs \
		npm \
		python3 \
		py3-yaml \
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
COPY --from=installer /usr/local/bin/kube-linter /usr/local/bin/kube-linter
COPY --from=installer /usr/local/bin/kubeconform /usr/local/bin/kubeconform
COPY --from=installer /usr/local/bin/jj /usr/local/bin/jj
COPY --from=installer /usr/local/bin/shellcheck /usr/local/bin/shellcheck
COPY --from=installer /usr/local/bin/helm /usr/local/bin/helm
COPY --from=installer /opt/helm /opt/helm

# Copy UV tools and environment from installer stage
COPY --from=installer /opt/uv /opt/uv
COPY --from=installer /usr/local/bin/pre-commit /usr/local/bin/pre-commit
COPY --from=installer /usr/local/bin/yamllint /usr/local/bin/yamllint
COPY --from=installer /usr/local/bin/podman-compose /usr/local/bin/podman-compose
COPY --from=installer /usr/local/bin/checkov /usr/local/bin/checkov

COPY containers.conf /etc/containers/containers.conf

# Set up UV environment
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python
ENV UV_TOOL_BIN_DIR=/usr/local/bin
ENV UV_TOOL_DIR=/opt/uv/venvs

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
