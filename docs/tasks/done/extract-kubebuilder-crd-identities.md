# Task: Extract Kubebuilder CRD Identities

## Goal

Recover deterministic CRD identities from Go source when generated CRD YAML is not
committed, while preventing incomplete Kustomize patches from producing blank rows.

## Context

`rhods-operator` defines its APIs with Kubebuilder markers under `api/`, but its
generated `config/*/crd/bases` files are absent from the checkout. The analyzer sees
two CA-injection patches as CRDs, emits blank identities, and the final document has
0/27 fixture CRD recall.

This is deterministic analyzer work and should precede further agent-synthesis
tuning.

## Acceptance Criteria

- [x] Ignore manifest CRD objects unless group, version, kind, and scope are all
      present after extraction.
- [x] Add tests covering complete CRDs, incomplete strategic-merge patches, and
      mixed full-definition/patch inputs.
- [x] Extract Kubebuilder root API types, group/version metadata, resource scope, and
      source location from Go modules without invoking repository build scripts.
- [x] Exclude list types and ordinary structs from CRD identities.
- [x] Prefer complete manifest CRD facts when both source-derived and manifest facts
      describe the same group/version/kind.
- [x] Deduplicate multi-version and distribution-overlay facts according to the
      canonical Markdown contract.
- [x] Report a distinct Go CRD coverage status so readiness can distinguish complete,
      partial, and unavailable CRD discovery.
- [x] Make structural validation reject non-empty CRD rows with blank required
      identity cells.
- [x] Add a `rhods-operator` fixture from its recorded commit covering representative
      component, service, infrastructure, cloud-manager, and primary platform CRDs.
- [x] Re-run static analysis for `rhods-operator` and compare its CRD table with
      `architecture/rhoai.next.bak/rhods-operator.md`.
- [x] Confirm no regression in existing manifest-derived CRD tests or the dashboard
      fidelity fixture.

## Non-Goals

- Do not run `controller-gen`, `make manifests`, or arbitrary repository build hooks.
- Do not use an agent to recover facts available in deterministic Kubebuilder source.
- Do not launch another full paid corpus run for this task.

## Related

- [Incomplete CRD patch bug](../../bugs/fixed/arch-analyzer-accepts-incomplete-crd-patches.md)
- [Component analyzer migration plan](../../plans/component-analyzer-migration.md)

## Status

Completed on 2026-07-18.

## Results

The analyzer now extracts 30 versioned Kubebuilder CRD identities from the recorded
`rhods-operator` checkout and reports:

```text
go_crds: complete: extracted 30 Kubebuilder CRD identities
```

Normalization renders those facts as 27 canonical rows. The comparison with
`architecture/rhoai.next.bak/rhods-operator.md` retains 26/27 exact identities. The
only mismatch is an intentional source-backed enrichment: `HardwareProfile` is
rendered as `v1, v1alpha1`, while the older fixture contains only `v1`.

Verification passed with 86 Python tests, both Go project suites, Ruff, gofmt,
`go vet`, golangci-lint, 20 overlay checks, 15 platform checks, and 769 architecture
document checks.
