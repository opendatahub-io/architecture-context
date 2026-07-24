# Bug: Arch Analyzer Accepts Incomplete CRD Patches

## Summary

`arch-analyzer` treats Kustomize patch documents whose kind is
`CustomResourceDefinition` as complete CRD definitions even when they have no
`spec.group`, version, kind, or scope. This produces a rendered CRD row with an
empty identity.

## Evidence

The analyzer snapshot for `rhods-operator` in full run
`rhoai-next-20260718T173838Z` contains two entries like this:

```json
{
  "group": "",
  "version": "",
  "kind": "",
  "scope": "",
  "source": "config/rhoai/crd/patches/cainjection_in_dscinitialization_dscinitializations.yaml:2"
}
```

The analyzer Markdown renders the two deduplicated entries as:

```markdown
|  |  |  |  | Custom resource managed by rhods-operator |
```

The evidence-gated merge drops the unusable row, leaving the final CRD table empty.
The older fixture contains 27 concrete CRD identities for this component.

No other analyzer snapshot in this 90-component run contains a CRD with a missing
identity field, so the malformed-row symptom is currently localized to
`rhods-operator`.

## Cause

`collectCRD()` appends a CRD unconditionally for every manifest object whose kind is
`CustomResourceDefinition`. It does not distinguish a full CRD from a strategic
merge patch and does not validate the required identity fields.

The repository does not commit its generated `config/*/crd/bases` files. Its real
CRD identities are available in Kubebuilder Go markers under `api/`, but the Go
source extractor does not currently extract them. The incomplete patch documents
are therefore the only manifest CRDs the analyzer sees.

## Expected

- Incomplete CRD patch documents must not become CRD facts.
- Renderers and structural validation must reject CRD rows without group, version,
  kind, or scope.
- Repositories with Kubebuilder API types but no committed generated CRD YAML should
  derive CRD identities from source or report the surface as incomplete.
- Readiness must not count invalid CRD rows as runtime facts.

## Impact

High for affected operators. The final architecture document silently omits all
CRDs while analyzer-preservation and structural gates still pass.

## Related

- [Extract Kubebuilder CRD identities](../../tasks/done/extract-kubebuilder-crd-identities.md)
- [Readiness-routed corpus comparison](../../notes/rhoai-next-readiness-routed-corpus-comparison-2026-07-18.md)

## Resolution

Fixed on 2026-07-18.

- Incomplete manifest CRDs are discarded before they become facts.
- Readiness counts only CRDs with group, version, kind, and scope.
- The Go source extractor derives Kubebuilder root identities, group/version, scope,
  source location, and a distinct `go_crds` coverage status.
- Complete manifest evidence takes precedence over equivalent source-derived facts.
- Normalization combines multiple versions into one canonical Markdown row.
- The renderer, production document validator, and corpus gate reject incomplete CRD
  identities.

The rebuilt analyzer recovered 30 versioned Kubebuilder identities from the recorded
`rhods-operator` checkout and rendered 27 canonical CRD rows. It exactly matched 26
of the fixture's 27 CRD identities. The remaining difference is source-backed: the
current Go API contains both `v1` and `v1alpha1` `HardwareProfile`, while the older
fixture lists only `v1`.
