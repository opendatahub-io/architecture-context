#!/usr/bin/env bash
# Locate or clone the fondue monorepo.
# Prints the fondue root path on stdout.
# The builder content spans two subdirectories:
#   {FONDUE_ROOT}/builder/        - plugins, overrides, pipeline-api, release.yaml
#   {FONDUE_ROOT}/images/builder/ - Containerfiles, build-args, gitlab-ci/images.yml
set -euo pipefail

FONDUE_LOCAL="../fondue"
REMOTE_URL="https://gitlab.com/redhat/rhel-ai/wheels/fondue.git"
REMOTE_URL_SSH="git@gitlab.com:redhat/rhel-ai/wheels/fondue.git"
CLONE_DIR="./tmp/fondue"

is_allowed_remote() {
    local remote="$1"
    [[ "${remote}" == "${REMOTE_URL}" || "${remote}" == "${REMOTE_URL_SSH}" ]]
}

if [[ -d "${FONDUE_LOCAL}/builder" && -d "${FONDUE_LOCAL}/images/builder" ]]; then
    ACTUAL_REMOTE="$(git -C "${FONDUE_LOCAL}" remote get-url origin 2>/dev/null || true)"
    if ! is_allowed_remote "${ACTUAL_REMOTE}"; then
        echo "ERROR: ${FONDUE_LOCAL} remote is '${ACTUAL_REMOTE}', expected '${REMOTE_URL}'" >&2
        exit 1
    fi
    echo "Using local fondue checkout at ${FONDUE_LOCAL}" >&2
    echo "${FONDUE_LOCAL}"
    exit 0
fi

mkdir -p "$(dirname "${CLONE_DIR}")"

if [[ -d "${CLONE_DIR}/.git" ]]; then
    ACTUAL_REMOTE="$(git -C "${CLONE_DIR}" remote get-url origin 2>/dev/null || true)"
    if ! is_allowed_remote "${ACTUAL_REMOTE}"; then
        echo "ERROR: ${CLONE_DIR} remote is '${ACTUAL_REMOTE}', expected '${REMOTE_URL}'" >&2
        exit 1
    fi
    echo "Updating existing fondue clone at ${CLONE_DIR}..." >&2
    git -C "${CLONE_DIR}" pull --ff-only
else
    echo "Cloning ${REMOTE_URL} to ${CLONE_DIR}..." >&2
    git clone --depth=1 "${REMOTE_URL}" "${CLONE_DIR}"
fi

echo "${CLONE_DIR}"
