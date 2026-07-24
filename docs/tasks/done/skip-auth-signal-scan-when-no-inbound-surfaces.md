# Task: Skip Auth Signal Scan Limitation When No Inbound Surfaces

## Goal

When `inboundRuntimeSurfaces()` returns 0, do not treat Python
authentication signal scan matches as blocking limitations. Auth
constructs in components with zero inbound surfaces are client-side by
definition (outbound API calls), not server-side authentication
enforcement.

This unblocks codeflare-sdk (50th analyzer-only component).

## Context

The `authenticationCoverage()` function in `categorycoverage.go`
runs several checks sequentially. When the inbound runtime surfaces
check passes (count == 0), it appends `no-inbound-runtime-surfaces`
to `CompletedChecks` — confirming the component has no HTTP endpoints,
gRPC services, webhooks, ingress, Kubernetes services, or deployment
probes.

Later (line 100-112), the Python authentication signal scan runs and
finds auth-related patterns via regex (e.g., `"Authorization":`,
`Bearer`, `OAuth2PasswordBearer`). If any matches are not accounted
for by existing auth facts, it adds a blocking limitation:
"Python authentication constructions require fact-level relationship
accounting."

For codeflare-sdk, the scan finds `"Authorization":` in
`src/codeflare_sdk/ray/cluster/cluster.py:87` — a client-side header
construction for outbound Kubernetes API calls:
```python
@property
def _client_headers(self):
    k8_client = get_api_client()
    return {
        "Authorization": k8_client.configuration.get_api_key_with_prefix(
            "authorization"
        )
    }
```

This is not inbound auth. The component exposes no servers. But the
signal scan doesn't distinguish client-side from server-side auth
patterns, so it blocks the category from completing.

See: `docs/notes/python-sdk-authentication-validation-2026-07-21.md`
(lines 41-86) for the full source audit.

## Source And Evidence

- Validation note: `docs/notes/python-sdk-authentication-validation-2026-07-21.md`
- Category coverage: `src/arch-analyzer/internal/extractor/categorycoverage.go`
- Adjudications: `lib/analyzer_correction_adjudications.json`
- Approvals: `lib/analyzer_only_approvals.json`

## Fix

In `authenticationCoverage()` at `categorycoverage.go`, when the
inbound runtime surfaces check has already confirmed `inbound == 0`,
skip the `filterUnaccountedAuthSignals` limitation. The signal scan
can still run (for evidence/coverage reporting), but its unaccounted
matches should not be blocking.

The change is small — approximately:
```go
// After the inbound == 0 branch (line 73), when the signal scan runs:
unaccounted := filterUnaccountedAuthSignals(matches, input.Authentication)
if len(unaccounted) > 0 && inbound > 0 {
    // Only block when inbound surfaces exist
    coverage.Limitations = append(coverage.Limitations,
        "Python authentication constructions require fact-level relationship accounting")
}
```

The `inbound` variable is already computed earlier in the function.
Hoist it or restructure so the signal scan can see it.

## Negative Controls

- Must NOT skip the signal scan itself — only the blocking limitation.
  The scan evidence should still appear in `coverage.Evidence` for
  transparency.
- Must NOT affect components that DO have inbound surfaces. MLServer
  and caikit (16 gRPC services each) must remain blocked — they exit
  early at the inbound surfaces check before reaching the signal scan.
- Must NOT change the early-return behavior when `inbound > 0`.
- Must NOT break existing category coverage for the 49 approved
  components.

## Acceptance Criteria

- [x] `authenticationCoverage()` no longer adds a blocking limitation
  for Python auth signal matches when `inboundRuntimeSurfaces() == 0`.
- [x] Auth signal scan evidence still appears in coverage output.
- [x] Unit test: component with zero inbound surfaces and a Python auth
  signal match gets `status: "complete"` for authentication.
- [x] Unit test: component WITH inbound surfaces and auth signal match
  still gets `status: "partial"`.
- [x] `go test ./...` and `go vet ./...` pass in `src/arch-analyzer`.
- [x] codeflare-sdk added to `lib/analyzer_only_approvals.json`.
- [x] 90-component replay: zero false nominations, 50 route analyzer-only.
- [x] No regressions on 49 previously approved components.
- [x] Residual register updated.
- [x] Validation note written.
- [x] Task moved to `docs/tasks/done/`.

## Likely Files

- `src/arch-analyzer/internal/extractor/categorycoverage.go` (the fix)
- `src/arch-analyzer/internal/extractor/categorycoverage_test.go` (new tests)
- `lib/analyzer_only_approvals.json`
- `docs/notes/analyzer-residual-agent-gaps.md`

## Status

Done. `authenticationCoverage()` fixed, codeflare-sdk approved (50th).
See [validation note](../../notes/auth-signal-scan-no-inbound-validation-2026-07-21.md).
