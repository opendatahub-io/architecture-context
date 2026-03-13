# Architecture Scripts

Utility scripts for collecting and organizing ODH/RHOAI architecture documentation.

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
