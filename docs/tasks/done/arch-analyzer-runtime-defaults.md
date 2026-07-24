# Task: Resolve Runtime Defaults and Go-Constructed Resources

## Goal

Improve controller-created resource facts by resolving source-declared API defaults
used by embedded templates and by recovering Kubernetes resources constructed
directly in Go.

## Acceptance Criteria

- [x] Extract scalar `+kubebuilder:default` markers from Go API structs.
- [x] Resolve nested template field paths through local and imported struct fields.
- [x] Substitute resolved defaults without executing repository code.
- [x] Extract named Secrets constructed in Go only when source shows a create or
      create-or-update operation.
- [x] Preserve source file and line evidence for defaults and constructed resources.
- [x] Exclude empty probe objects and objects used only for reads or deletes.
- [x] Add focused AST, template, and end-to-end fixtures.
- [x] Record exact-commit Kueue and Model Registry coverage and timing changes.

## Status

Done on 2026-07-17.

## Boundaries

This milestone performs lightweight, syntax-based constant propagation. It does not
execute defaulting webhooks, evaluate arbitrary Go functions, perform pointer or
call-graph analysis, or claim a conditional runtime branch was selected. Constructed
object extraction begins with high-confidence Secrets; other Kubernetes kinds can be
added after the creation-evidence rule is measured.

## Results

The default resolver builds a struct graph across packages in the root Go module. It
handles kubebuilder markers attached to fields and standalone marker comment groups,
retains marker-line evidence, rejects structured defaults, and omits conflicting path
values. Embedded templates consume defaults by exact field path; unused API defaults
are not emitted or added to Markdown source references.

Constructed Secret extraction performs lightweight local string propagation for
literals, concatenation, selectors, and `fmt.Sprintf`. A named Secret is emitted only
when its variable reaches `Create`, create-or-update, or create-or-patch source. A
unique placeholder-name suffix can join a Go-created Secret with its template
reference without assuming a repository-specific placeholder spelling.

| Component | Extract | Render | Retained rows | Conflicts |
|-----------|--------:|-------:|--------------:|----------:|
| Kueue | ~0.23s | <0.01s | 27/121 (22.31%) | 6 |
| Model Registry Operator | ~0.04s | <0.01s | 36/121 (29.75%) | 5 |

Kueue has no source-referenced embedded resource templates at the measured commit, so
its result remains unchanged. Model Registry resolves `Spec.Rest.Port` to 8080,
`Spec.KubeRBACProxy.Port` to 8443, and `Spec.KubeRBACProxy.RoutePort` to 443. Service
conflicts fall from four to one. Two constructed PostgreSQL Secrets are recovered;
the per-registry credential Secret merges with its template reference, becomes
`Opaque`, and removes the prior Secret conflict.

Both exact-commit documents pass structural Markdown validation. Conditional service
branches remain separate possible facts rather than being collapsed into a fabricated
runtime selection.
