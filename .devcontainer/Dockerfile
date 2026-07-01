# renovate: datasource=docker depName=aacebedo/devcontainer-base versioning=docker
ARG DEVCONTAINER_BASE_VERSION="1.16.0"

FROM ghcr.io/aacebedo/devcontainer-base:${DEVCONTAINER_BASE_VERSION}
SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

USER root
COPY <<"EOF" /etc/containers/containers.conf
[containers]
netns="host"
userns="host"
ipcns="host"
utsns="host"
cgroupns="host"
cgroups="disabled"
log_driver = "k8s-file"
[engine]
cgroup_manager = "cgroupfs"
events_logger="file"
runtime="crun"
EOF

RUN <<EOF \
echo "${DEVCONTAINER_USERNAME}:100000:64536" > /etc/subuid 
echo "${DEVCONTAINER_USERNAME}:100000:64536" > /etc/subgid
cat /etc/subuid
EOF

USER ${DEVCONTAINER_UID}
