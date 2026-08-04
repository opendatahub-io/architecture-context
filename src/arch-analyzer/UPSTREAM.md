# Upstream Provenance

This project is informed by:

- Repository: `https://github.com/ugiordan/architecture-analyzer`
- Initial reference commit: `5cdc2e7ec565badeff32ae2521e513ef8ac38639`
- Initial review date: 2026-07-17

## Imported Code

No implementation files have been copied. The compatibility model was independently
defined from stored `component-architecture.json` artifacts and documented JSON field
names. The manifest loader, kustomize resolver, fact collectors, normalizer, and
renderer were implemented independently in this repository. The Go AST and module
extractors were also implemented independently using Go standard-library APIs and
`golang.org/x/mod/modfile`. Embedded manifest discovery and Go-template sanitization
were implemented independently as well.

Update this file whenever code is copied or substantially derived from upstream.
Record the source path, source commit, destination path, import date, and material
local modifications.
