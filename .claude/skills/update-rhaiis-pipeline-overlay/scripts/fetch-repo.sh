#!/usr/bin/env bash
# Locate or clone the rhaiis/pipeline repository.
# Prints the path to the repository root on stdout.
set -euo pipefail

LOCAL_CHECKOUT="../rhaiis/pipeline"
REMOTE_URL="https://gitlab.com/redhat/rhel-ai/rhaiis/pipeline.git"
REMOTE_URL_SSH="git@gitlab.com:redhat/rhel-ai/rhaiis/pipeline.git"
CLONE_DIR="./tmp/rhaiis-pipeline"

is_allowed_remote() {
    local remote="$1"
    [[ "${remote}" == "${REMOTE_URL}" || "${remote}" == "${REMOTE_URL_SSH}" ]]
}

if [[ -d "${LOCAL_CHECKOUT}/.git" ]]; then
    ACTUAL_REMOTE="$(git -C "${LOCAL_CHECKOUT}" remote get-url origin 2>/dev/null || true)"
    if ! is_allowed_remote "${ACTUAL_REMOTE}"; then
        echo "ERROR: ${LOCAL_CHECKOUT} remote is '${ACTUAL_REMOTE}', expected '${REMOTE_URL}'" >&2
        exit 1
    fi
    echo "Using local checkout at ${LOCAL_CHECKOUT}" >&2
    echo "${LOCAL_CHECKOUT}"
    exit 0
fi

mkdir -p "$(dirname "${CLONE_DIR}")"

if [[ -d "${CLONE_DIR}/.git" ]]; then
    ACTUAL_REMOTE="$(git -C "${CLONE_DIR}" remote get-url origin 2>/dev/null || true)"
    if ! is_allowed_remote "${ACTUAL_REMOTE}"; then
        echo "ERROR: ${CLONE_DIR} remote is '${ACTUAL_REMOTE}', expected '${REMOTE_URL}'" >&2
        exit 1
    fi
    echo "Updating existing clone at ${CLONE_DIR}..." >&2
    git -C "${CLONE_DIR}" pull --ff-only
else
    echo "Cloning ${REMOTE_URL} to ${CLONE_DIR}..." >&2
    git clone --depth=1 "${REMOTE_URL}" "${CLONE_DIR}"
fi

echo "${CLONE_DIR}"
