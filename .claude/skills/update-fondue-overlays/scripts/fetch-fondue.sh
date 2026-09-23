#!/usr/bin/env bash
# Locate or clone the fondue monorepo.
# Prints the absolute path of the fondue monorepo root on stdout.
# If FONDUE_PATH is set, that checkout must be acceptable or the script fails.
# Otherwise prefers a local ../fondue checkout and falls back to the
# ./tmp/fondue cache, cloning it if absent. Every returned checkout must be the
# top level of a clean main at the freshly fetched origin/main; only the cache
# is ever updated, by fast-forward.
set -euo pipefail

DEFAULT_LOCAL="../fondue"
REMOTE_URL="https://gitlab.com/redhat/rhel-ai/wheels/fondue.git"
CLONE_DIR="./tmp/fondue"
DEFAULT_BRANCH="main"

# Normalize a git remote URL to a canonical "host/path" form so that HTTPS,
# scp-style SSH (git@host:path), ssh:// URLs, and an optional ".git" suffix all
# compare equal. glab and the GitLab UI hand out several of these forms.
normalize_remote() {
    local url="$1"
    url="${url%.git}"          # drop trailing .git
    url="${url%/}"             # drop trailing slash
    # Strip known secure schemes; http:// is intentionally excluded
    case "${url}" in
        ssh://*)   url="${url#ssh://}" ;;
        https://*) url="${url#https://}" ;;
    esac
    # Strip userinfo (user@) ONLY from the authority component (the part before
    # the first path separator). The old ${url#*@} matches any @ anywhere in the
    # URL and lets an attacker embed the real host in a path component.
    local authority path_rest
    if [[ "${url}" == */* ]]; then
        authority="${url%%/*}"   # everything before the first /
        path_rest="${url#*/}"    # everything after the first /
        if [[ "${authority}" == *@* ]]; then
            authority="${authority##*@}"
        fi
        url="${authority}/${path_rest}"
    else
        # No path separator — entire value is the authority (e.g. git@host:path)
        if [[ "${url}" == *@* ]]; then
            url="${url##*@}"
        fi
    fi
    url="${url/://}"           # scp-style host:path -> host/path (first colon)
    printf '%s' "${url}"
}

EXPECTED_REMOTE="$(normalize_remote "${REMOTE_URL}")"

# Strips userinfo (user:token@) from a scheme URL before it is printed. A git
# url.<base>.insteadOf rewrite can embed a credential in the effective remote.
redact_remote() {
    local url="$1" scheme rest authority
    if [[ "${url}" == *://* ]]; then
        scheme="${url%%://*}"
        rest="${url#*://}"
        authority="${rest%%/*}"
        if [[ "${authority}" == *@* ]]; then
            rest="${authority##*@}${rest#"${authority}"}"
        fi
        url="${scheme}://${rest}"
    fi
    printf '%s' "${url}"
}

is_allowed_remote() {
    local url="$1"
    # Reject plain HTTP — unencrypted transport is not an approved form
    if [[ "${url}" == http://* ]]; then
        return 1
    fi
    # Require an explicit remote URL form: an https:// or ssh:// scheme, or
    # scp-style [user@]host:path (a colon before the first slash). A scheme-less
    # "host/path" is a LOCAL folder path to git, so it must NOT satisfy the
    # allowlist even though it normalizes to the expected host/path string.
    if [[ "${url}" != https://* && "${url}" != ssh://* && "${url%%/*}" != *:* ]]; then
        return 1
    fi
    [[ "$(normalize_remote "$url")" == "${EXPECTED_REMOTE}" ]]
}

# Fetches the remote main branch into refs/remotes/origin/main and prints the
# fetched commit. Fails if the fetch or the ref lookup fails. Git's own output
# is discarded so that no remote URL (which may embed a credential) is printed.
fetch_main() {
    local dir="$1"
    git -C "${dir}" fetch --quiet origin \
        "+refs/heads/${DEFAULT_BRANCH}:refs/remotes/origin/${DEFAULT_BRANCH}" >/dev/null 2>&1 || return 1
    git -C "${dir}" rev-parse --verify --quiet "refs/remotes/origin/${DEFAULT_BRANCH}^{commit}"
}

# Returns 0 if the checkout is clean, on main and at the freshly fetched
# origin/main; 1 (with a warning) otherwise. With "fast-forward" as the second
# argument, a clean main that is only behind origin/main is fast-forwarded
# first. Never discards changes or switches branches, and any git failure
# counts as a rejection.
is_current_main() {
    local dir="$1" mode="${2:-strict}" target branch dirty ahead behind head
    if ! target="$(fetch_main "${dir}")"; then
        echo "WARNING: could not fetch origin/${DEFAULT_BRANCH} for ${dir}." >&2
        return 1
    fi
    if ! branch="$(git -C "${dir}" symbolic-ref --quiet --short HEAD)"; then
        echo "WARNING: ${dir} has a detached HEAD, not '${DEFAULT_BRANCH}'." >&2
        return 1
    fi
    if [[ "${branch}" != "${DEFAULT_BRANCH}" ]]; then
        echo "WARNING: ${dir} is on branch '${branch}', not '${DEFAULT_BRANCH}'." >&2
        return 1
    fi
    if ! dirty="$(git -C "${dir}" status --porcelain)"; then
        echo "WARNING: could not read the status of ${dir}." >&2
        return 1
    fi
    if [[ -n "${dirty}" ]]; then
        echo "WARNING: ${dir} has uncommitted local changes." >&2
        return 1
    fi
    if ! ahead="$(git -C "${dir}" rev-list --count "${target}..HEAD")" ||
        ! behind="$(git -C "${dir}" rev-list --count "HEAD..${target}")"; then
        echo "WARNING: could not compare ${dir} with origin/${DEFAULT_BRANCH}." >&2
        return 1
    fi
    if [[ "${ahead}" -gt 0 ]]; then
        echo "WARNING: ${dir} has local commits not on origin/${DEFAULT_BRANCH} (ahead=${ahead}, behind=${behind})." >&2
        return 1
    fi
    if [[ "${behind}" -gt 0 ]]; then
        if [[ "${mode}" != "fast-forward" ]]; then
            echo "WARNING: ${dir} is behind origin/${DEFAULT_BRANCH} (behind=${behind})." >&2
            return 1
        fi
        if ! git -C "${dir}" merge --ff-only --quiet "${target}" >&2; then
            echo "WARNING: could not fast-forward ${dir} to origin/${DEFAULT_BRANCH}." >&2
            return 1
        fi
    fi
    if ! head="$(git -C "${dir}" rev-parse --verify --quiet HEAD)" || [[ "${head}" != "${target}" ]]; then
        echo "WARNING: ${dir} is not at origin/${DEFAULT_BRANCH}." >&2
        return 1
    fi
    if ! dirty="$(git -C "${dir}" status --porcelain)" || [[ -n "${dirty}" ]]; then
        echo "WARNING: ${dir} is not clean at origin/${DEFAULT_BRANCH}." >&2
        return 1
    fi
    return 0
}

# Returns 0 if the directory has every subtree the overlays are built from.
has_fondue_layout() {
    local dir="$1" sub
    for sub in images/base images/builder builder rhai-pipeline releases; do
        [[ -d "${dir}/${sub}" ]] || return 1
    done
    return 0
}

# Returns 0 if the directory is the top level of its git checkout, so that an
# enclosing repository's origin cannot vouch for an arbitrary subdirectory.
is_repo_toplevel() {
    local dir="$1" top
    top="$(git -C "${dir}" rev-parse --show-toplevel 2>/dev/null)" || return 1
    [[ "$(cd "${dir}" && pwd -P)" == "$(cd "${top}" && pwd -P)" ]]
}

# Returns 0 if the directory is an acceptable fondue checkout; 1 (with a
# warning) otherwise. Applied to every checkout the script returns. The second
# argument is passed to is_current_main.
is_acceptable_checkout() {
    local dir="$1" mode="${2:-strict}" remote
    if ! is_repo_toplevel "${dir}"; then
        echo "WARNING: ${dir} is not the top level of a git checkout." >&2
        return 1
    fi
    remote="$(git -C "${dir}" remote get-url origin 2>/dev/null || true)"
    if ! is_allowed_remote "${remote}"; then
        echo "WARNING: ${dir} remote is '$(redact_remote "${remote}")', expected the fondue repo." >&2
        return 1
    fi
    is_current_main "${dir}" "${mode}" || return 1
    if ! has_fondue_layout "${dir}"; then
        echo "WARNING: ${dir} is missing part of the fondue layout (images/base, images/builder, builder, rhai-pipeline, releases)." >&2
        return 1
    fi
    return 0
}

# Prints the chosen checkout as an absolute path on stdout and exits.
use_checkout() {
    local dir="$1" label="$2" abs
    abs="$(cd "${dir}" && pwd -P)"
    echo "Using ${label} at ${abs} (HEAD $(git -C "${abs}" rev-parse --short HEAD))" >&2
    echo "${abs}"
    exit 0
}

if [[ -n "${FONDUE_PATH:-}" ]]; then
    if is_acceptable_checkout "${FONDUE_PATH}"; then
        use_checkout "${FONDUE_PATH}" "local fondue checkout"
    fi
    echo "ERROR: FONDUE_PATH=${FONDUE_PATH} is not an acceptable fondue checkout. Fix it or unset FONDUE_PATH." >&2
    exit 1
fi

if [[ -d "${DEFAULT_LOCAL}" ]]; then
    if is_acceptable_checkout "${DEFAULT_LOCAL}"; then
        use_checkout "${DEFAULT_LOCAL}" "local fondue checkout"
    fi
    echo "WARNING: local ${DEFAULT_LOCAL} is not an acceptable source; falling back to a clone." >&2
fi

mkdir -p "$(dirname "${CLONE_DIR}")"

# The cache is the only checkout this script updates, and only by
# fast-forwarding a clean main that is behind origin/main.
if [[ -e "${CLONE_DIR}" ]]; then
    echo "Updating existing fondue clone at ${CLONE_DIR}..." >&2
    if is_acceptable_checkout "${CLONE_DIR}" fast-forward; then
        use_checkout "${CLONE_DIR}" "fondue clone"
    fi
    echo "ERROR: ${CLONE_DIR} is not a clean fondue clone of ${DEFAULT_BRANCH}; local changes and branches were left as they are. Fix or remove ${CLONE_DIR} and re-run." >&2
    exit 1
fi

echo "Cloning ${REMOTE_URL} to ${CLONE_DIR}..." >&2
if ! git clone --quiet --depth=1 --single-branch --branch "${DEFAULT_BRANCH}" \
    "${REMOTE_URL}" "${CLONE_DIR}" >&2; then
    echo "ERROR: could not clone ${REMOTE_URL} into ${CLONE_DIR}." >&2
    exit 1
fi
if is_acceptable_checkout "${CLONE_DIR}"; then
    use_checkout "${CLONE_DIR}" "fondue clone"
fi
echo "ERROR: the fresh clone at ${CLONE_DIR} failed validation." >&2
exit 1
