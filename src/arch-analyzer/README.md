# arch-analyzer

Project-owned static architecture analyzer for ODH and RHOAI component repositories.

The analyzer resolves repository manifests and source into project-owned compatibility
JSON and renders that JSON into the canonical component Markdown structure used by
agents.

## Build

```bash
make -C src/arch-analyzer build
```

## Render Existing JSON

```bash
bin/arch-analyzer render \
  --input architecture/rhoai.next/kueue.json \
  --output /tmp/kueue.md \
  --distribution RHOAI
```

Omit `--output` to write Markdown to stdout.

## Extract A Repository

```bash
bin/arch-analyzer extract /path/to/repository \
  --distribution rhoai.next \
  --output /tmp/component-architecture.json
```

Use `--overlay path/to/overlay` when automatic distribution selection is ambiguous.

The resolver currently handles local resources/bases/components, strategic merge
patches, modern and legacy targeted JSON6902 patches, and scoped name/namespace transforms.
Unsupported generators, replacements, legacy vars, image transforms, remote
resources, and inline patches are reported in `data_coverage.kustomize`.

For Go repositories, extraction discovers all nested modules without double-scanning
module boundaries and scans non-test, non-generated Go source for controller-runtime
watches, literal HTTP routes, controller-manager health checks, and statically typed
Kubernetes client operations. A bounded package- and receiver-qualified call graph
rooted at executable `main` functions proves supported standard runtime-client
constructors. Project-owned HTTP wrappers additionally require a runtime-configured
Resty transport, a concrete outbound request method, a single ancestor whose
package, signature, or documentation proves the target semantics, and recognized
module ownership. Dynamic interfaces, reflection, and full Go type checking remain
explicit partial coverage.

Repository-level `net/http` Authentication extraction closes helper-registered
`ServeMux` boundaries only when concrete handler constructors, static `GetRoutes`
inventories, complete variadic middleware arguments, inspected local wrappers,
returned server fields, and an invoked serving lifecycle all correlate. Imported or
dynamic middleware, partial route providers, credential enforcement, and disconnected
muxes remain unresolved.

Go `//go:embed` directives are also inspected for Kubernetes YAML and `.yaml.tmpl`
resources. Template actions are sanitized without executing repository code;
conditional branches are represented as possible facts, dynamic values use explicit
placeholders, and emitted workloads and routes are marked as controller-created.

Scalar `+kubebuilder:default` markers are resolved through local and imported Go
struct fields when embedded templates reference those paths. Only defaults consumed
by resource templates are persisted with their source evidence. The Go pass also
extracts named Secret composite literals when source shows the object being passed to
a create or create-or-update call; empty, read-only, and delete-only objects are
excluded.

Root Rust packages are inspected for Cargo metadata and direct dependencies, literal
Axum routes, Clap listen-port defaults, binary HTTP listeners, configuration-backed
HTTP/gRPC downstreams, and source-declared TLS, token, and header authentication
controls. Rust macros and call graphs are not expanded and are reported as partial
coverage.

npm workspaces are decoded as structured JSON. The web pass recovers host frontend
and backend components, shipped BFF modules, shared architecture libraries, normalized
runtime/framework dependencies, Fastify surfaces, module federation proxy routes,
and per-port TLS/authentication facts. ODH/RHOAI semantic adaptation remains separate
from the language extractors.

Python repositories are inspected through structured `pyproject.toml` and
requirements parsing. The bounded source pass recovers literal
FastAPI/Flask/Starlette routes, router prefixes, literal HTTP client destinations,
environment-backed secret references, and applicable protobuf services. Dynamic
route composition, dependency injection, imports, and call graphs remain explicit
partial coverage.

Each result includes an `agent_baseline` readiness value. `sufficient` baselines have
enough runtime evidence to prohibit broad agent discovery. When all four high-value
tables are populated or backed by a recognized complete-empty contract and no
bounded correction gap is nominated, the pipeline uses
the analyzer-only route and does not invoke a component agent. Other `sufficient`
baselines retain the constrained evidence-gated pass, `partial` baselines permit one
bounded language-specific gap pass, and `insufficient` baselines retain analyzer
facts but allow the legacy exploration fallback. Dependency inventory without
runtime facts is intentionally only `partial`.

Recent changes come directly from Git. Canonical Kubebuilder module configuration is
loaded alongside the selected product overlay, and source-backed semantic adapters
translate high-value platform resources, egress, integrations, and authentication
controls into the agent-facing vocabulary.

## Category Completeness Contracts

`category_coverage` keeps fact presence separate from discovery completeness. Each
record contains a status (`complete`, `partial`, or `unknown`), normalized fact
count, versioned discovery contract, completed checks, explicit limitations, and
evidence. Missing records in older analyzer JSON are treated as `unknown` by routing.

`authentication/v1` inventories normalized Authentication facts, analyzer-discovered
inbound services and endpoints, credential-bearing secret references, relevant
manifest and kustomize failures, supported and unsupported runtime languages, and
bounded Python authentication constructions. Go, Rust, web, Python server, unreadable,
unsupported-language, credential, or unresolved authentication surfaces produce
`partial`. An empty category is `complete` only when every applicable v1 check ran
and none of those surfaces remains unresolved.

`internal-platform-dependencies/v1` inventories normalized dependency facts and scans
runtime source and configuration against the dependency-bearing aliases shared with
`internal/platformfacts`. It excludes tests, documentation, examples, generated
analyzer output, and structured benchmark corpora. Alias matches, relevant manifest
or kustomize failures, unreadable files, and unsupported runtime languages produce
`partial`. A zero-fact result is `complete` only when the bounded scan has no such
limitations.

The Python router recognizes only these exact contract versions. A complete-empty
claim must also have zero facts in both the coverage record and analyzer payload,
nonempty completed checks and evidence, and no limitations. The claim can satisfy an
otherwise empty high-value table; it does not bypass readiness, preservation,
structure, or synthesis-quality gates.

The renderer deterministically populates Purpose, Data Flows, and Architectural
Analysis from typed facts, explicit counts, and coverage limits. It does not infer
ordering or behavior that is absent from structured evidence. The component-summary
skill copies `analyzer_architecture.md` for non-eligible sufficient and partial
results, then edits bounded synthesis or structured gaps instead of regenerating
populated tables.

## Extract CRD Schemas

```bash
bin/arch-analyzer extract-schema /path/to/repository \
  --output-dir /tmp/contracts/schemas
```

Each served CRD version with an OpenAPI v3 schema is written as formatted JSON.
Unrelated or templated YAML does not fail schema extraction.

## Test

```bash
make -C src/arch-analyzer test
make -C src/arch-analyzer smoke
```

See `UPSTREAM.md` for provenance requirements when upstream implementation code is
ported into this module.
