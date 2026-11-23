# Update Data Registry architecture status

Status: complete 2026-11-23.

## Request

Replace the stale in-review statement in overlay 0031 after confirming the
Data Registry capability configuration, namespace provisioning, and shared
operator lifecycle work has merged.

## Evidence and change

- Feast module-operator [PR #27](https://github.com/opendatahub-io/feast-module-operator/pull/27) merged on 2026-10-09. Its merged work projects capability configuration, provisions and labels `rhoai-data-registry`, and defers shared cleanup while either capability remains enabled.
- Platform operator [PR #4232](https://github.com/opendatahub-io/opendatahub-operator/pull/4232) is on upstream `main` and projects the DSC capability states to the Feast module operator. The DSC API contains independent Feature Store and Data Registry states.
- Updated overlay 0031 to label this code path merged and cite both PRs. Release availability remains a target-build question.

## Verification

- `/opt/homebrew/bin/python3.14 scripts/lint_overlays.py`: all 37 overlays passed.
- `git diff --check`: passed.
- Independent review was not performed for this documentation-only change.
