# Auth Signal Scan No-Inbound-Surfaces Fix Validation

**Date:** 2026-07-21
**Task:** skip-auth-signal-scan-when-no-inbound-surfaces
**Branch:** feat/scripted-architecture-summaries

## Summary

Fixed `authenticationCoverage()` in `categorycoverage.go` to not add a
blocking limitation for Python authentication signal scan matches when
`inboundRuntimeSurfaces()` returns 0. Auth constructs in components with
zero inbound surfaces are client-side by definition — they construct
outbound auth headers, not inbound auth enforcement.

This unblocks codeflare-sdk (50th analyzer-only component).

## Change

**File:** `src/arch-analyzer/internal/extractor/categorycoverage.go`

**Before (line 108):**
```go
if len(unaccounted) > 0 {
```

**After:**
```go
if len(unaccounted) > 0 && inbound > 0 {
```

The `inbound` variable is computed at line 63 and is always 0 at line 108
(because `inbound > 0` causes an early return at line 71). The added
condition makes the intent explicit: unaccounted Python auth signals are
only blocking when inbound runtime surfaces exist.

The signal scan itself still runs — evidence and completed checks are
unaffected. Only the blocking limitation is gated.

## Affected component

**codeflare-sdk** — pure Python SDK library for Ray/CodeFlare:
- 0 HTTP endpoints, 0 gRPC services, 0 webhooks
- Python auth signal scan found `"Authorization":` at
  `src/codeflare_sdk/ray/cluster/cluster.py:87`
- This is a client-side header construction for outbound Kubernetes API
  calls via `get_api_key_with_prefix("authorization")`

**Before fix:** auth category `status: "partial"`, limitation: "Python
authentication constructions require fact-level relationship accounting"

**After fix:** auth category `status: "complete"`, 0 limitations, evidence
still shows `cluster.py (authentication construction)`

## Unaffected components

**MLServer and caikit** — have 16 inbound gRPC surfaces each. They exit
early at the inbound surfaces check (line 71: `return coverage`) and never
reach the signal scan. The fix is structurally unreachable for them.

## Tests

### Go tests

Updated 2 existing tests and added 2 new tests in
`categorycoverage_test.go`:

- **Updated:** `TestAuthenticationCoverageCompleteForClientSideAuthWithNoInboundSurfaces`
  (was `TestAuthenticationCoveragePartialForPythonClientAuthentication`) —
  now expects `status: "complete"` and verifies evidence still contains
  the auth signal file.

- **Updated:** `TestAuthenticationCoverageNonBlockingUnaccountedSignalsWithNoInbound`
  (was `TestAuthenticationCoverageRetainsUnaccountedPythonSignals`) —
  now expects `status: "complete"` when partially-accounted signals exist
  with no inbound surfaces. Evidence still present.

- **New:** `TestAuthenticationCoveragePartialForInboundSurfacesWithAuthSignals` —
  verifies that components WITH inbound surfaces still get `status: "partial"`
  (the early return at line 71 blocks before the signal scan).

- **New:** `TestAuthenticationCoverageCompleteForSDKLibraryWithOutboundAuth` —
  tests the codeflare-sdk pattern: SDK library with `kubernetes` package,
  outbound `Authorization` header, zero inbound surfaces → `status: "complete"`
  with auth signal evidence retained.

```
cd src/arch-analyzer && go test ./... -count=1: 12 packages pass (1 no-test)
go vet ./...: clean
```

### 90-component corpus replay

- `uv run main.py static-analysis --platform=rhoai.next --force`:
  90 extracted, 0 failed, 0 skipped

### Eligibility audit

- 49 previously approved components: all still route correctly
  (zero regressions)
- 52 total eligible, 50 approved
- 0 false nominations
- codeflare-sdk: eligible=True, approved=True, routes to analyzer-only

### Approval

- Added `codeflare-sdk` to `lib/analyzer_only_approvals.json` (49 → 50)
- Verified: codeflare-sdk routes to `analyzer-only` after approval
