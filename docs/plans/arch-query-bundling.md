# arch-query: Bundled Binary Distribution

**Date**: 2026-05-04
**Status**: Design
**Depends on**: `docs/plans/arch-query-design.md`, `src/arch-query/README.md`

---

## Problem

`arch-query` currently reads architecture data from a local `./architecture/` directory at runtime. This works when the binary runs inside the repo checkout, but breaks the distribution use case: Claude Code skills that want to fetch a released binary and query architecture data without cloning the full repository.

Today's workflow:
```
clone repo → cd repo → bin/arch-query component kserve
```

Target workflow:
```
curl -LO .../arch-query → chmod +x → ./arch-query component kserve
```

The binary needs to carry its own data.

---

## Go's `//go:embed` Mechanism

Go's `//go:embed` is a compiler directive that copies files into the binary at build time. The embedded data becomes part of the compiled binary — no extraction, no temp files, no external dependencies.

```go
import "embed"

//go:embed architecture/*
var embeddedData embed.FS
```

The comment `//go:embed` is parsed by the compiler, not a runtime annotation. At build time, every file matching the glob is baked into the binary as read-only data. The variable must be `embed.FS` (directory tree), `string` (single file), or `[]byte` (single file).

Key constraints:
- Paths are relative to the Go source file containing the directive
- Only files within the Go module directory tree can be embedded — you can't embed `../../architecture/`
- Hidden files (dotfiles) and `_`-prefixed files are excluded unless you use `all:` prefix
- **Symlinks are not followed** — `embed.FS` stores regular files only

### embed.FS implements fs.FS

This is the key design insight. `embed.FS` satisfies the same `fs.FS` interface that `os.DirFS()` returns:

```go
// From disk
var fsys fs.FS = os.DirFS("./architecture")

// From embedded data
//go:embed architecture/*
var embedded embed.FS
var fsys fs.FS = embedded
```

Any code written against `fs.FS` works transparently with both sources. The loader/parser code calls `fs.ReadFile(fsys, "rhoai.next/kserve.md")` — it doesn't know or care whether the data came from disk or was compiled in.

---

## Design: Dual-Mode Loader

### Precedence

```
1. --base-dir flag (explicit path)     → os.DirFS(path)      [always wins]
2. ./architecture/ exists in cwd       → os.DirFS("./architecture")
3. Embedded data compiled in           → embed.FS             [fallback]
4. None available                      → error + exit
```

A user in the repo checkout gets disk reads (current behavior, live data). A user with just the binary gets embedded data (snapshot from release). `--base-dir` overrides everything for testing or pointing at a different checkout.

```go
func resolveFS(baseDir string) fs.FS {
    if info, err := os.Stat(baseDir); err == nil && info.IsDir() {
        return os.DirFS(baseDir)
    }
    if embeddedArchitecture != nil {
        sub, _ := fs.Sub(embeddedArchitecture, "_embedded/architecture")
        return sub
    }
    fmt.Fprintf(os.Stderr, "no architecture data: %s not found and no embedded data\n", baseDir)
    os.Exit(1)
    return nil
}
```

### Build Tags

Build tags control whether embedded data is compiled in:

```go
// embedded_data.go
//go:build embedded

package main

import "embed"

//go:embed _embedded/architecture/*
var embeddedArchitecture embed.FS
```

```go
// embedded_data_none.go
//go:build !embedded

package main

// nil when built without embedded tag
var embeddedArchitecture *embed.FS
```

- `go build` — small binary, disk-only (development)
- `go build -tags embedded` — bundled binary with architecture data (distribution)

### Staging Step

`//go:embed` can only reference files inside the Go module directory. The architecture data lives at `../../architecture/` relative to `src/arch-query/`. The Makefile stages it before building:

```makefile
build-embedded:
	rm -rf _embedded/architecture
	cp -rL ../../architecture _embedded/architecture
	# Remove symlinks manifest will handle (see below)
	go build -tags embedded -o ../../bin/arch-query
	rm -rf _embedded/architecture

build:
	go build -o ../../bin/arch-query
```

`_embedded/` is gitignored — it only exists transiently during the embedded build.

---

## The Symlink Problem

The architecture directory uses symlinks heavily for version aliases:
```
current-ga       -> rhoai-3.3
future-ga        -> rhoai-3.4
newest           -> rhoai-3.4
latest-released  -> rhoai-3.4-ea.1
```

`embed.FS` does not support symlinks. Two options:

### Option A: Resolve at staging time

`cp -rL` follows symlinks, creating real copies. Simple but duplicates data — each alias becomes a full copy of the target version directory.

- ~10 symlink aliases pointing at 25 version directories
- Each version directory is ~1MB of markdown
- Resolving all symlinks roughly doubles the embedded size

### Option B: Symlink manifest (preferred)

Generate a manifest file during staging that maps alias names to targets. The loader reads this and synthesizes aliases at runtime.

```makefile
build-embedded:
	rm -rf _embedded/architecture
	mkdir -p _embedded/architecture
	# Copy only real directories (no symlinks)
	for d in ../../architecture/*/; do \
	    [ ! -L "$${d%/}" ] && cp -r "$$d" _embedded/architecture/; \
	done
	# Generate symlink manifest
	python3 -c "import os, json; \
	    d='../../architecture'; \
	    print(json.dumps({e: os.readlink(os.path.join(d,e)) \
	    for e in os.listdir(d) if os.path.islink(os.path.join(d,e))}))" \
	    > _embedded/architecture/symlinks.json
	go build -tags embedded -o ../../bin/arch-query
	rm -rf _embedded/architecture
```

Produces `_embedded/architecture/symlinks.json`:
```json
{
  "current-ga": "rhoai-3.3",
  "future-ga": "rhoai-3.4",
  "newest": "rhoai-3.4",
  "latest-released": "rhoai-3.4-ea.1",
  "early-access": "rhoai-3.4-ea.2"
}
```

The `versions.go` loader reads this manifest when running from embedded data and synthesizes alias entries. The rest of the code sees the same `VersionInfo` structs regardless of source.

---

## Loader Refactoring: os.* to fs.FS

The current loader uses OS-specific filesystem calls. These need to become `fs.FS`-based:

| Current (loader.go, versions.go) | fs.FS equivalent |
|----------------------------------|------------------|
| `os.ReadDir(path)` | `fs.ReadDir(fsys, path)` |
| `os.ReadFile(path)` | `fs.ReadFile(fsys, path)` |
| `os.Stat(path)` | `fs.Stat(fsys, path)` |
| `os.Readlink(path)` | No equivalent — use `symlinks.json` manifest |
| `filepath.EvalSymlinks(path)` | No equivalent — use `symlinks.json` manifest |

The markdown parser (`internal/markdown/`) operates on `[]byte` and `[]string` — no filesystem calls. Only the `internal/loader/` package needs changes.

### Changed function signatures

```go
// Before
func LoadVersion(baseDir, version string) (*VersionData, error)
func DiscoverVersions(baseDir string) ([]VersionInfo, error)

// After
func LoadVersion(fsys fs.FS, version string) (*VersionData, error)
func DiscoverVersions(fsys fs.FS) ([]VersionInfo, error)
```

Each `cmd/*.go` subcommand currently calls `loader.LoadVersion(baseDir, version)`. After refactoring, the root command resolves the `fs.FS` once and passes it down:

```go
// cmd/root.go
var archFS fs.FS

func init() {
    cobra.OnInitialize(func() {
        archFS = resolveFS(baseDir)
    })
}
```

---

## Binary Size

Only `.md` files are embedded — diagrams (70MB/version of PNGs), `component-map.json`, and other non-markdown files are excluded. The staging step uses `find -name '*.md'` instead of `cp -r`.

Measured binary size: **~21MB** with all 24 version directories embedded (vs ~9MB for the non-embedded binary). The markdown corpus is ~30MB raw across all versions; Go's binary format compresses it somewhat.

If size becomes a concern, the staging step can selectively embed only specific versions (e.g., only `rhoai.next` and the latest GA).

---

## Release Workflow

```
1. Architecture data updated (new version generated, overlays applied)
2. make build-embedded                    # stages data, builds binary
3. gh release create v0.X.Y bin/arch-query  # upload to GitHub release
4. Skills fetch:  curl -LO .../arch-query
```

The embedded data is a snapshot from the release. Users who need live data clone the repo and use the non-embedded build. The `--version` flag in output could include the build date to make freshness visible:

```
$ arch-query versions
25 versions available (embedded: 2026-05-04):
  ...
```

---

## What Does Not Change

- **Markdown files remain the source of truth** — embedding is read-only packaging
- **Parser code is identical** — same `ParseComponentDoc`, same table parser, same section extraction
- **All subcommands work the same** — the `fs.FS` abstraction is invisible to command implementations
- **`--base-dir` override still works** — always falls back to disk reads when a real directory is provided
- **Non-embedded builds are unchanged** — `make build` (without `-tags embedded`) produces the same binary as today

---

## Implementation Order

1. **Refactor loader to fs.FS** — Change `LoadVersion` and `DiscoverVersions` to accept `fs.FS` instead of `string` paths. Update all callers in `cmd/`. Verify existing tests pass (no behavior change).

2. **Add symlink manifest support** — When `symlinks.json` exists in the FS root, load it and inject alias entries into `DiscoverVersions` results. When running from disk, fall back to `os.Readlink` (current behavior).

3. **Add embedded build path** — Create `embedded_data.go` / `embedded_data_none.go` with build tags. Add `resolveFS()` to root command. Add `build-embedded` Makefile target with staging.

4. **Add build metadata** — Embed a `build-info.json` with build date and git SHA. Surface in `arch-query versions` output so users know how fresh the embedded data is.

5. **Test** — Verify: `make build && bin/arch-query versions` works (disk mode), `make build-embedded && bin/arch-query versions` works (embedded mode), `--base-dir /other/path` overrides embedded data.

---

## Open Questions

1. **All versions or subset?** — Embedding all 25 versions keeps the binary self-contained for any query. Embedding only `rhoai.next` + latest GA + `current-ga` would cut size by ~80% but limits `diff` across older versions.

2. **Auto-extract mode?** — Should the binary offer `arch-query extract --output ./architecture` to dump embedded data to disk? Useful for users who want to inspect the raw markdown or feed it to other tools.

3. **Update mechanism?** — Once a user has a bundled binary, how do they know a newer version is available? `arch-query versions --check-update` could compare the embedded build date against the latest GitHub release tag.
