# Unify the Fondue overlay skills

Tracked in [RHAI-2466](https://redhat.atlassian.net/browse/RHAI-2466).
Completed 2026-09-23.

Replaced `update-aipcc-base-images-overlay`, `update-wheels-builder-overlay`
and `update-rhai-pipeline-overlay` with `update-fondue-overlays`. The three
skills read the same Fondue monorepo but had drifted: the builder rules read a
missing `builder/release.yaml`, checked for a removed aiu-monitor guard,
referenced a retired `SPYRE_VERSION` build arg, and claimed rhai-pipeline pins
a builder release. The new skill fetches Fondue once, keeps those shared facts
in one table, keeps per-overlay rules in `references/`, and ends with a
cross-overlay consistency check against source.

Scope: skill tooling only. Overlays 0017, 0019 and 0020 stay separate files:
each is 370-500 lines with its own author and provenance, and downstream
lookups are per topic. Their content was not regenerated; the only overlay
edit is 0019's "updated by running" pointer, which named a removed skill.
Known-wrong overlay text is tracked in
[regenerate-fondue-overlays](../pending/regenerate-fondue-overlays.md).
`update-rhaiis-pipeline-overlay` is unchanged until `rhaiis/pipeline` moves
into Fondue.

Validation: `shellcheck`, `skillsaw lint`, `make lint-overlays`,
`make lint-python`, `make lint-platforms` and `make lint-architecture-docs`
pass. The fetch script was exercised against a real checkout, relative and
spaced paths, a non-Fondue directory, a wrong remote, an ignored subdirectory
of a Fondue clone, and the clone fallback. `tests/test_fetch_fondue.py` runs
the script against isolated Git fixtures: every returned checkout, including
the `./tmp/fondue` cache and a fresh clone, must be a clean `main` at the
fetched `origin/main`; dirty, untracked, non-main, detached, ahead and
diverged caches are rejected untouched, and fetch or clone failures fail
closed. Every path and fact the skill cites was checked against Fondue
`ee083a373`.

Review: independent code and architecture reviews both
returned REQUEST_CHANGES with no blocking findings. Their confirmed findings
were fixed, and a third independent review verified the fixes; its follow-up
findings were fixed too. The exception is the two
`update-rhaiis-pipeline-overlay` lines, deferred to the pending task above to
keep that skill out of scope.
