# Refresh the Fondue overlays for el9.8 channels

No ticket. Completed 2026-10-07.

Since the last refresh (Fondue `18d0c049d`), Fondue renamed every content
channel from `-ubi9` to `-el9.8` and gave each catalog row an explicit builder
`variant` (AIPCC-32814, AIPCC-32816), added 14 channel-aware Konflux
base-image pipelines, four of them disabled (AIPCC-31700), moved the builder
collection cache from Pulp to GitLab projects (AIPCC-32847), moved the CUDA
13.0 base images to 13.0.3 and NCCL 2.30.7 (RHAI-2634), added a temporary
`backfill` collection (AIPCC-32962), started building RHEL 10.2 LLVM/Triton
images (RHAI-5549) and syncs `main` into `release/trailing` for Konflux
releases (RHAI-5222). Overlays 0017, 0019, 0020 and 0030 described the
`-ubi9` names, the `builder-cache/` path and Konflux pipelines that built no
channel, and several skill rules encoded those states.

Decisions:

- **Skill rules first, then a frozen skill.** The rules now take the channel
  OS token from the catalog `os` and the builder variant from the catalog
  `variant`; read every Konflux `build-args` value as well as the
  `build-args-file` conf and report differing values without claiming which
  one wins; check disabled triggers, how the image label resolves and which
  branch Konflux release builds come from; leave the builder cache location to
  overlay 0019; and keep a collection that its definition declares a
  temporary rebuild of legacy pins out of the release-defining heuristics. All
  are checks, not results.
- **Per-claim Fact edits.** The run re-read every Fact claim and changed only
  claims whose value changed, so unchanged wording stays byte-identical.
- **Konflux in 0017.** The legacy pipeline table stays; one grouped table adds
  the channel pipelines per accelerator with their naming pattern, disabled
  state and the Rubin exception. A channel conf that a Konflux channel
  pipeline also builds keeps one row naming both builders. Where `build-args`
  differ from the conf (`NAME`, `INDEX_VERSION`, Rubin's `INDEX_VARIANT`), the
  overlay states both and not which one the build uses.
- **Dated and anchored claims.** The 0030 live-check bullet keeps its `-ubi9`
  probe names, marked as predating AIPCC-32814. The 0030 consumer cut-over
  bullet is re-anchored to Fondue `18d0c049d` because release tags and index
  content cannot be checked from a `main` clone.

Scope: overlays 0017, 0019, 0020 and 0030, refreshed with
`/update-fondue-overlays all` against Fondue `d57f272`, plus the channel names
in [align-rhaiis-overlay-with-fondue](../pending/align-rhaiis-overlay-with-fondue.md).
The skill fixes are a separate commit. Front matter and release labels (3.6,
3.7, next) are unchanged. Untouched: 0014, 0021, 0025,
`0019-rhel-9.8-rebase-*`, team-docs, `PLAN.md` and the generated
`architecture/`.

Validation: `make lint-overlays` (36 pass), `make lint-platforms` (18 pass),
`make lint-architecture-docs` (912 pass), `uv run pytest
tests/test_fetch_fondue.py tests/test_index_metadata_validation.py` (26
passed), and skillsaw 0.21.0 `lint` on the skill (0 errors, the existing
context-budget warning). The plan's post-run content checks pass: no stale
`-ubi9` channel name outside the dated bullet, no uncatalogued channel name
except the Rubin Konflux `rubin-torch2.11-el9.8`, positive checks for every
expected change, front matter and the Accelerator Summary header
byte-identical, and three `## ` sections per overlay. The Go targets did not
run locally (no Go toolchain).

Review: the implementer reviewed every overlay hunk against Fondue `d57f272`
(accuracy, ownership, Impact and Context bullets, front matter). Three
independent reviews followed: an architecture and security review with two
skeptics per finding, a fact-check of every changed claim against Fondue
source, and a general code review. They found one wrong fact (how an explicit
`CHANNEL` override is checked), a wrong OS-stream recipe (side-by-side RHEL
minors need new variants), stale or missing consumer facts (the `-ubi9`
indexes stop receiving uploads, backfill pins newer than release-defining
ones, the Rubin channel pipeline) and four skill rules that were too broad or
stated results. All were fixed in both the skill and the overlays; the
dismissed findings were out of Fondue's scope (Konflux build-arg precedence)
or low value.

Raise with owners:

- `rhai-pipeline/src/rhai_pipeline/channel.py:104,148` and
  `builder/pipeline-api/ci-wheelhouse.yml:88` still show `-ubi9` channel
  examples; the catalog uses `-el9.8`. `ci-wheelhouse.yml:88` also says the
  channel is "Computed by regen-ci.py from variant + torch_version"; it is now
  resolved through the catalog (`bin/regen-ci.py:113-144`).
- `channel.py:131`'s error message still says "Expected a single token such
  as ubi9 or el10", although `_OS_RE` now accepts `el9.8`.
- `builder/pipeline-api/ci-wheelhouse.yml:102-104` describes `PULP_CACHE` as
  "Builder collections only"; builder collections now set it to `"false"`
  and most `rhai-pipeline/` jobs set it to `"true"`.
- `images/builder/build-args/cuda12.9-ubi9.conf:36-37` and
  `cuda13.0-ubi9.conf:39-40` pin `LIBNCCL_VERSION=2.30.4-1` with the comment
  "Pin NCCL to ensure builder and base image versions match (AIPCC-19609)",
  but the base images now lock NCCL 2.30.7
  (`images/base/context/cuda-*/rpms.in.yaml`).

Follow-ups (out of scope):

- `fetch-fondue.sh` has no HTTPS-to-SSH clone fallback; this run used an
  SSH-seeded cache because the HTTPS clone failed to authenticate.
- `repo-to-architecture-summary` matches 0017 version cells, which now read
  CUDA 13.0.3.
- The OS Pins scan does not search RHEL 10 tokens, so files that pin only
  `10.2` may be missing from the 0030 table.
- No skill rule bug was found during the run, so none was deferred under the
  skill freeze.
