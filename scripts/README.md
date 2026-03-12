# Architecture Scripts

Utility scripts for collecting and organizing ODH/RHOAI architecture documentation.

## parse_manifests_script.py

Parses `get_all_manifests.sh` from the operator repository to extract the authoritative list of platform components.

### Usage

```bash
python scripts/parse_manifests_script.py --platform=odh [--format=list|paths|json]
```

### Arguments

- `--platform`: Platform to parse (odh or rhoai)
- `--manifest-script`: Path to get_all_manifests.sh (default: auto-detect)
- `--checkouts-dir`: Checkouts directory (default: ./checkouts)
- `--format`: Output format (default: list)
  - `list`: Human-readable list with repo names
  - `paths`: Just checkout paths (for scripting)
  - `json`: Full component info as JSON

### Output

Returns only components that:
1. Are defined in get_all_manifests.sh
2. Have a matching checkout directory

### Example

```bash
$ python scripts/parse_manifests_script.py --platform=odh --format=list

Found 16 ODH component(s) with checkouts:

  - dashboard                 odh-dashboard                            (checkouts/opendatahub-io/odh-dashboard)
  - kserve                    kserve                                   (checkouts/opendatahub-io/kserve)
  - modelregistry             model-registry-operator                  (checkouts/opendatahub-io/model-registry-operator)
  ...
```

### Integration with Skills

This script is used by the `/analyze-platform-components` skill to discover which components to analyze.

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
