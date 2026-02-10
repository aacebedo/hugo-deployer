# renovate: datasource=docker depName=aacebedo/devcontainer-base versioning=docker
ARG DEVCONTAINER_BASE_VERSION=1.8.0

# Stage 2: Final image
FROM ghcr.io/aacebedo/devcontainer-base:${DEVCONTAINER_BASE_VERSION} AS final

USER root

# Install base packages (including runtime environments)
RUN apk update && \
		apk upgrade && \
		apk add --no-cache \
		shadow \
		podman \
		podman-docker \
		fuse-overlayfs \
		iptables

COPY containers.conf /etc/containers/containers.conf

# hadolint ignore=DL3022
COPY --from=workspace --chown=${DEVCONTAINER_USERNAME}:${DEVCONTAINER_USERNAME} .mise/config.toml \
		"/home/${DEVCONTAINER_USERNAME}/.config/mise/config.toml"

ENV MISE_NODE_MIRROR_URL="https://unofficial-builds.nodejs.org/download/release/" \
		MISE_NODE_FLAVOR="musl"

USER ${DEVCONTAINER_USERNAME}

# hadolint ignore=SC2155
RUN --mount=type=secret,id=MISE_GITHUB_TOKEN,uid=${DEVCONTAINER_UID} \
		MISE_GITHUB_TOKEN="$(cat /run/secrets/MISE_GITHUB_TOKEN)" \
		mise install

