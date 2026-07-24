# Architecture Scripts

Utility scripts for collecting and organizing ODH/RHOAI architecture documentation.

## run_rhoai_next_architecture.sh

Runs the analyzer-first component workflow for `rhoai.next` and measures the fresh
output against `architecture/rhoai.next.bak`. The script runs only static analysis,
component architecture generation, and collection. It does not generate
`PLATFORM.md` or diagrams.

The destination must not already exist. The baseline and candidate directories are
resolved before execution and the script refuses any overlap.

```bash
scripts/run_rhoai_next_architecture.sh \
  --run-dir tmp/architecture-corpus-runs/rhoai-next-full \
  --baseline architecture/rhoai.next.bak \
  --model opus \
  --workers 10
```

Use `--dry-run` to create the run manifest, capture platform configuration and
repository revisions, and print the commands without starting static analysis or
agents:

```bash
scripts/run_rhoai_next_architecture.sh \
  --run-dir tmp/architecture-corpus-runs/rhoai-next-preflight \
  --dry-run
```

Use `--components` for a bounded matrix that keeps the same snapshots, telemetry,
merge audit, and quality gates as the full corpus workflow:

```bash
scripts/run_rhoai_next_architecture.sh \
  --run-dir tmp/architecture-corpus-runs/rhoai-next-routing-matrix \
  --components batch-gateway,eval-hub,odh-dashboard \
  --model opus \
  --workers 3
```

The full run requires the same `.env` and Claude credentials as
`generate-architecture`. Its output tree is self-contained:

```text
<run-dir>/
  run.json                         # config, revisions, commands, timings, failures
  preservation-adjudications.json # reviewed agent cell refinements
  architecture/rhoai.next/         # freshly collected final Markdown and JSON
  analyzer/rhoai.next/             # analyzer Markdown and JSON before agent edits
  logs/
    static-analysis.log
    component-generation.log
    collection.log
    comparison.log
    agents/                         # per-component agent logs
  reports/
    analyzer-snapshot.json
    comparison.json                 # complete machine-readable corpus report
    comparison.md                   # concise review report
```

`comparison.json` and `comparison.md` report micro and median structured recall,
per-component results, the components below 95%, populated-cell conflicts, missing
and additional documents, readiness classifications, revision drift, structural
validation, and phase timing. Recent Git history and source-file inventory are
reported separately from architecture fidelity.

Fixture recall does not fail the command automatically because the backup is a
regression fixture that can be stale or incorrect. The command does fail when a
fresh final document is missing its analyzer input, loses an analyzer structured
identity, changes a populated analyzer cell without an evidence-bearing entry in
`preservation-adjudications.json`, or fails structural validation. Each accepted
conflict must identify the component, category, key, column, exact analyzer and
generated values, a reason, and one or more source evidence references.
An analyzer row may be removed only through an exact, evidence-backed `delete`
change record; the report records these separately as accepted analyzer row
corrections. Missing rows without such an adjudication still fail the gate.

The required quality gates also reject a document that contains at least 80 words of
synthesis while its architecture-component table and at least two other high-value
agent-owned tables remain empty. This catches detailed prose that was not converted
into evidence-gated structured facts without treating fixture equality as truth.
Analyzer-only documents have an additional gate: all deterministic synthesis
sections must contain at least 200 words in aggregate and may not contain pending
synthesis placeholders.

The analyzer-only eligibility policy can be audited against a completed run without
starting agents:

```bash
uv run python scripts/analyze_analyzer_only_eligibility.py \
  tmp/architecture-corpus-runs/rhoai-next-20260718T200215Z \
  --output-json tmp/eligibility.json \
  --output-markdown tmp/eligibility.md
```

The command classifies every sufficient component, reports false nominations,
captures synthesis work and agent telemetry, and projects cost and FIFO worker-wall
savings. It exits nonzero if the policy nominates a component that made a
source-backed structured mutation in the reference run that is still absent from the
fresh analyzer document.

Production analyzer-only routing also requires the component to appear in
`lib/analyzer_only_approvals.json`. This rollout registry is updated only after a
fresh 90-component replay proves correction coverage and zero false nominations.
Populating one previously empty category therefore creates an offline candidate; it
does not automatically bypass the component agent.

The lower-level comparator can also be run independently:

```bash
uv run python scripts/compare_architecture_corpus.py compare \
  --baseline architecture/rhoai.next.bak \
  --candidate tmp/run/architecture/rhoai.next \
  --analyzer tmp/run/analyzer/rhoai.next \
  --preservation-adjudications tmp/run/preservation-adjudications.json \
  --run-manifest tmp/run/run.json \
  --output-json tmp/run/reports/comparison.json \
  --output-markdown tmp/run/reports/comparison.md
```

## Evidence-gated component merge

The component generator can keep analyzer-owned tables deterministic while allowing
agent synthesis and explicitly evidenced structured changes. This readiness-routed
behavior is enabled by default:

```bash
uv run main.py generate-architecture \
  --platform rhoai.next \
  --component MLServer \
  --force \
  --log-dir tmp/evidence-gated-MLServer
```

Use `--no-evidence-gated-merge` only when an operator explicitly needs the former
legacy generation behavior for every readiness level. Analyzer-insufficient
repositories already select the legacy fallback automatically.

The agent writes `ARCHITECTURE_CHANGES.md` beside its candidate. The pipeline keeps
the final merged document at `GENERATED_ARCHITECTURE.md` and archives these audit
artifacts under `--log-dir`:

```text
MLServer.candidate.md  # unmodified agent document
MLServer.changes.md    # Markdown evidence records, when present
MLServer.merge.json    # machine-readable decisions and comparator adjudications
MLServer.merge.md      # human-readable applied, rejected, and restored changes
```

An existing analyzer baseline, candidate, and change record can be replayed without
another agent run:

```bash
uv run python scripts/rebase_architecture_synthesis.py \
  ANALYZER_ARCHITECTURE.md RAW_GENERATED_ARCHITECTURE.md MERGED.md \
  --evidence-gated \
  --generated-by='Claude Opus 4.6' \
  --component=MLServer \
  --changes=ARCHITECTURE_CHANGES.md \
  --report-json=MLServer.merge.json \
  --report-markdown=MLServer.merge.md
```

## get_git_changes.py

Extracts comprehensive git information from a repository including version, branch, remote URL, and commit history. Wrapper around multiple git commands that allows single permission grant for multiple invocations.

### Usage

```bash
# Get commit history (text format)
python scripts/get_git_changes.py /path/to/repo [--since="3 months ago"] [--limit=20]

# Get all git metadata in one call (recommended for skills)
python scripts/get_git_changes.py /path/to/repo --format=metadata

# Get structured JSON output
python scripts/get_git_changes.py /path/to/repo --format=json
```

### Arguments

- `repo_path`: Path to the git repository (positional)
- `--since`: Time period to look back (default: "3 months ago")
- `--limit`: Maximum number of commits (default: 20)
- `--format`: Output format:
  - `text`: Commit list only (default, same as `git log --pretty=format:"%h %s"`)
  - `count`: Number of commits only
  - `metadata`: Human-readable comprehensive output with version, branch, remote, and commits
  - `json`: JSON output with all metadata (structured data)

### Version Detection

The script uses the same priority order as `collect_architectures.py`:

1. **Makefile VERSION** (primary - developer's intended version)
   - Matches: `VERSION = 3.3.0`, `VERSION ?= 3.3.0`, `VERSION := 3.3.0`
   - Handles indented VERSION (inside `ifeq` blocks)
2. **VERSION** or **version.txt** file
3. **git describe --tags --always** (fallback - current checkout state)
4. **"unknown"** if all methods fail

**Why Makefile first?** In development branches, git tags may show `v2.8.0-1325-gfa1fcdc0` (1325 commits past v2.8.0 tag), but the Makefile shows `VERSION = 3.3.0` which is the developer's intended version for the current code.

### Benefits

- **Single permission grant**: Permission is for the script, not each unique git command
- **Comprehensive data**: Get version, branch, remote URL, and commits in one call
- **Correct version detection**: Uses Makefile VERSION (same as collect_architectures.py)
- **Multiple formats**: Choose between human-readable or structured JSON output
- **Error handling**: Graceful failures with helpful error messages

### Examples

#### Text format (commit list)
```bash
$ python scripts/get_git_changes.py checkouts/opendatahub-io/kserve --since="6 months ago" --limit=3

a1b2c3d Add new inference runtime
e4f5g6h Fix scaling issue
i7j8k9l Update documentation
```

#### Metadata format (comprehensive)
```bash
$ python scripts/get_git_changes.py checkouts/opendatahub-io/opendatahub-operator --format=metadata --limit=3

Repository: checkouts/opendatahub-io/opendatahub-operator
Version: 3.3.0
Branch: main
Remote: https://github.com/opendatahub-io/opendatahub-operator.git

Recent commits (3):
  23dab7a1 RHAIENG-414: chore(workbenches): move manifests
  1d1f55b4 fix: updated spark image map var
  6d541e8f owners: add rinaldodev to platform alias
```

**Note**: Version is `3.3.0` from Makefile (not `v2.8.0-1325-gfa1fcdc0` from git describe).

#### JSON format (structured)
```bash
$ python scripts/get_git_changes.py checkouts/opendatahub-io/opendatahub-operator --format=json --limit=3

{
  "version": "3.3.0",
  "branch": "main",
  "remote_url": "https://github.com/opendatahub-io/opendatahub-operator.git",
  "recent_commits": [
    "23dab7a1 RHAIENG-414: chore(workbenches): move manifests",
    "1d1f55b4 fix: updated spark image map var",
    "6d541e8f owners: add rinaldodev to platform alias"
  ],
  "commit_count": 3,
  "repo_path": "checkouts/opendatahub-io/opendatahub-operator"
}
```

### Integration with Skills

Used by `/analyze-platform-components` and `/repo-to-architecture-summary` to extract all git information without requiring permission for each component or each git command.

## parse_manifests_script.py

Parses `get_all_manifests.sh` from the operator repository to extract the authoritative list of platform components and their analysis status.

### Usage

```bash
python scripts/parse_manifests_script.py --platform=odh [--format=list|paths|json]
python scripts/parse_manifests_script.py --platform=odh --filter-missing
```

### Arguments

- `--platform`: Platform to parse (odh or rhoai)
- `--manifest-script`: Path to get_all_manifests.sh (default: auto-detect)
- `--checkouts-dir`: Checkouts directory (default: ./checkouts)
- `--format`: Output format (default: list)
  - `list`: Human-readable list with status indicators and repo names
  - `paths`: Just checkout paths (for scripting)
  - `json`: Full component info as JSON with has_architecture field
- `--filter-missing`: Only show components without GENERATED_ARCHITECTURE.md

### Output

Returns only components that:
1. Are defined in get_all_manifests.sh
2. Have a matching checkout directory

**New**: Each component includes analysis status (whether GENERATED_ARCHITECTURE.md exists)

### Examples

#### List format (with status indicators)
```bash
$ python scripts/parse_manifests_script.py --platform=odh --format=list

Found 16 ODH component(s) with checkouts:
  Analyzed: 7, Missing: 9

  ✓ dashboard                 odh-dashboard                            (checkouts/opendatahub-io/odh-dashboard)
  ✓ kserve                    kserve                                   (checkouts/opendatahub-io/kserve)
  ✗ modelregistry             model-registry-operator                  (checkouts/opendatahub-io/model-registry-operator)
  ...
```

Legend: ✓ = GENERATED_ARCHITECTURE.md exists, ✗ = needs analysis

#### Paths format with filter (only missing)
```bash
$ python scripts/parse_manifests_script.py --platform=odh --format=paths --filter-missing

checkouts/opendatahub-io/mlflow-operator
checkouts/opendatahub-io/model-registry-operator
checkouts/opendatahub-io/kuberay
...
```

#### JSON format (with has_architecture field)
```bash
$ python scripts/parse_manifests_script.py --platform=odh --format=json

{
  "dashboard": {
    "repo_org": "opendatahub-io",
    "repo_name": "odh-dashboard",
    "ref": "main@b46b6a5d",
    "source_folder": "manifests",
    "checkout_path": "checkouts/opendatahub-io/odh-dashboard",
    "has_architecture": true
  },
  "modelregistry": {
    ...
    "has_architecture": false
  }
}
```

### Integration with Skills

This script is used by the `/analyze-platform-components` skill to:
1. Discover which components to analyze
2. Check analysis status without separate ls commands
3. Skip already-analyzed components (when has_architecture is true)

## collect_architectures.py

Collects `GENERATED_ARCHITECTURE.md` files from repository checkouts and organizes them by platform and version.

### Usage

```bash
python scripts/collect_architectures.py [--checkouts-dir=<path>] [--output-dir=<path>]
```

### Arguments

- `--checkouts-dir`: Directory containing platform checkouts (default: `./checkouts`)
- `--output-dir`: Output directory for organized files (default: `./architecture`)
- `--test-version`: Test version detection only, don't copy files (useful for debugging)

### Platform Detection

The script automatically detects platforms based on directory structure:
- `checkouts/opendatahub-io/*` → ODH components
- `checkouts/red-hat-data-services/*` → RHOAI components

### Version Detection

Platform version is determined from operator repositories with this priority:

1. **Makefile** `VERSION` variable (primary - developer's intended version)
   - Regex: `^\s*VERSION\s*[\?:]?=\s*([^\s#]+)`
   - Matches: `VERSION = 3.3.0`, `VERSION ?= 3.3.0`, `VERSION := 3.3.0`
   - Handles indented VERSION (e.g., inside `ifeq` blocks): `		VERSION = 3.3.0`
   - Stops at whitespace or comments (e.g., `VERSION = 3.3.0 # comment` → `3.3.0`)
   - Strips quotes and parentheses
2. **VERSION** or **version.txt** file
3. **git describe --tags --always** (fallback - current checkout state)
4. **"unknown"** if all methods fail

**Why Makefile first?** In development branches, git tags may show `v2.8.0-1325-gfa1fcdc0` (1325 commits past v2.8.0 tag), but the Makefile shows `VERSION = 3.3.0` which is the developer's intended version for the current code.

**Indentation handling:** Many Makefiles set VERSION inside conditional blocks (e.g., `ifeq ($(VERSION), )`), which adds leading tabs/spaces. The regex `^\s*` handles this correctly.

### Output Structure

```
architecture/
├── odh-3.3.0/
│   ├── README.md
│   ├── kserve.md
│   ├── model-registry.md
│   └── ...
└── rhoai-2.19/
    ├── README.md
    ├── kserve.md
    └── ...
```

### Examples

```bash
# Collect all architectures with defaults
python scripts/collect_architectures.py

# Custom directories
python scripts/collect_architectures.py \
  --checkouts-dir=./repos \
  --output-dir=./docs/architecture

# Test version detection (debugging)
python scripts/collect_architectures.py --test-version
```

### Debugging Version Detection

If the script is detecting the wrong version, use `--test-version` to see detailed debug output:

```bash
$ python scripts/collect_architectures.py --test-version
Testing version detection...

Detecting ODH version from checkouts/opendatahub-io/opendatahub-operator
  Checking Makefile: checkouts/opendatahub-io/opendatahub-operator/Makefile
  ✓ Found version in Makefile: 3.3.0

Detected platforms:
  - ODH: 3.3.0
    Checkout dir: checkouts/opendatahub-io
    Operator dir: checkouts/opendatahub-io/opendatahub-operator
```

This shows exactly which version detection method succeeded and what value was found.

### Integration with Skills

This script is called by the `/collect-component-architectures` skill:

```bash
/collect-component-architectures
/collect-component-architectures --checkouts-dir=./repos --output-dir=./docs
```

### Return Codes

- `0`: Success (at least one platform processed)
- `1`: No platforms found or error occurred

### Requirements

- Python 3.10+
- Git (for version detection via `git describe`)
- Platform operator repositories must be checked out

## generate_diagram_pngs.py

Generate high-resolution PNG files from Mermaid (.mmd) diagrams using mmdc (Mermaid CLI). Automatically detects Chrome/Chromium and processes all diagrams in a directory.

### Usage

```bash
# Generate PNGs for all .mmd files in a directory
python scripts/generate_diagram_pngs.py /path/to/diagrams --width=3000

# Generate PNG for a single .mmd file
python scripts/generate_diagram_pngs.py diagram.mmd --width=3000

# Use custom Chrome path
python scripts/generate_diagram_pngs.py /path/to/diagrams --chrome-path=/usr/bin/chromium
```

### Arguments

- `path`: Path to .mmd file or directory containing .mmd files (positional, required)
- `--width`: PNG width in pixels (default: 3000, height auto-adjusts)
- `--chrome-path`: Path to Chrome/Chromium executable (default: auto-detect)

### Requirements

- **mmdc** (Mermaid CLI): `npm install -g @mermaid-js/mermaid-cli`
- **Chrome/Chromium**: Usually pre-installed on most systems

### Chrome Detection

The script automatically detects Chrome/Chromium in this priority:
1. `/usr/bin/google-chrome` (most common)
2. `/usr/bin/chromium`
3. `/usr/bin/chromium-browser`
4. `which google-chrome`
5. `which chromium`

### Benefits

- **Single permission grant**: Permission for the script covers all PNG generation
- **Auto-detection**: Finds Chrome/Chromium automatically
- **Batch processing**: Processes all .mmd files in a directory
- **Error handling**: Clear error messages if dependencies missing
- **High resolution**: 3000px width default for presentations

### Examples

```bash
# Generate PNGs for all diagrams in architecture/odh-3.3.0/diagrams/
$ python scripts/generate_diagram_pngs.py architecture/odh-3.3.0/diagrams/

Generating PNGs for 5 Mermaid diagram(s)...
Width: 3000px, Chrome: /usr/bin/google-chrome

  feast-component.mmd → feast-component.png
  feast-dataflow.mmd → feast-dataflow.png
  feast-security-network.mmd → feast-security-network.png
  feast-dependencies.mmd → feast-dependencies.png
  feast-rbac.mmd → feast-rbac.png

============================================================
✅ PNG generation complete!
============================================================
Successful: 5
Failed: 0
Width: 3000px
```

### Integration with Skills

This script is used by the `/generate-architecture-diagrams` skill to automatically convert all Mermaid diagrams to high-resolution PNG files.

### Return Codes

- `0`: Success (all PNGs generated)
- `1`: Error (mmdc not found, Chrome not found, or PNG generation failed)
