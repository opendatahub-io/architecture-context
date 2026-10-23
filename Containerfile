# Sandbox image for the arch-context harness (ladder rung 2+).
# Pattern from the workflow-engine PoC's Containerfile: the pi process
# runs in the container with its own config state; nothing from the
# host ~/.pi is mounted. pi pinned to the version under test — match
# the host this port was verified on (1.3.0; the PoC used 1.1.0).
#
# The plugin tree is NOT baked in: the fullsend runtime uploads declared
# plugins to a runner-owned extensions dir at sandbox setup (ADR 0094).
# This image only provides the runtime prerequisites.
#
# Build (rung 2, from the repo root):
#   podman build -t localhost/fullsend-archctx:v1 -f Containerfile .
#
# Base is trixie, not bookworm: the podman driver injects the
# openshell-sandbox supervisor binary into the sandbox container, and
# the binary (built on a current Fedora host) needs glibc >= 2.39 —
# bookworm ships 2.36, trixie 2.41. The upstream-faithful alternative
# is a musl-static supervisor build, which makes the base irrelevant.
# Base pinned by digest (supply chain): the mutable tag can silently
# change under us; the digest is the content we validated rungs 2-3 on.
FROM docker.io/library/node@sha256:43b9ba1142b8dcf33fa8f922ca1be85714adc444e0586c7cf7726daaeabc1bea

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash ca-certificates git ripgrep python3 iproute2 nftables iptables \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent@1.3.0

# OpenShell requires a non-root OCI USER ("OCI USER is required because
# run_as_user is omitted" — the supervisor refuses root sandboxes). The
# node base ships a uid-1000 `node` user.
#
# WORKDIR is load-bearing at openshell >= 0.1: the podman driver resolves
# the managed workspace root from the image's OCI WorkingDir
# (resolve_oci_workspace_root) — /sandbox matches fullsend's
# SandboxWorkspace constant. The dir must exist and be writable by USER.
RUN mkdir -p /sandbox && chown node:node /sandbox
USER node
WORKDIR /sandbox
