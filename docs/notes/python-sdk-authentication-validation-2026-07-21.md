# Python SDK Authentication Gap Validation

**Date:** 2026-07-21
**Task:** resolve-python-sdk-authentication-gaps
**Branch:** feat/scripted-architecture-summaries

## Summary

Source audit of the `authentication` category gap for three Python
components — codeflare-sdk, MLServer, and caikit. All three have
`authentication` as their sole empty high-value category blocking
analyzer-only eligibility. The audit determined that none can be
source-audited as empty under the established negative controls.

## Methodology

1. Examined each component's `component-architecture.json` in the checkout
   directory (the artifact used by the routing system).
2. Read the `ANALYZER_ARCHITECTURE.md` to confirm which categories are
   empty in the baseline inventory.
3. Verified the `authenticationCoverage` logic in
   `categorycoverage.go:46-117` — specifically `inboundRuntimeSurfaces()`
   (counts HTTP endpoints, gRPC services, webhooks, etc.) and the Python
   authentication signal scan.
4. Inspected source code in the checkout directories to verify the nature
   of any detected auth constructions.
5. Applied negative controls from the task definition to determine whether
   source-audited entries are justified.

## Negative Controls Applied

1. **Must not source-audit `authentication` as empty if inbound runtime
   surfaces exist and are not accounted for by auth facts.** Applies to
   MLServer and caikit (16 inbound gRPC surfaces each).
2. **Must not add source-audited entries if the Python auth signal scan
   found unaccounted matches.** Applies to codeflare-sdk (cluster.py
   client-side auth construction).

## Component Dispositions

### codeflare-sdk

**Disposition:** Authentication legitimately empty for inbound purposes,
but cannot be source-audited.

**Auth coverage status:**
- `status: "partial"`, `fact_count: 0`
- Completed checks: `normalized-authentication-facts`,
  `no-inbound-runtime-surfaces`, `credential-reference-inventory`,
  `supported-language-surface-inventory`,
  `applicable-language-runtime-inventory`,
  `python-authentication-signal-scan`
- Limitation: "Python authentication constructions require fact-level
  relationship accounting"
- Evidence: `src/codeflare_sdk/ray/cluster/cluster.py (authentication
  construction)`

**Source audit finding:** The Python auth signal match is at
`cluster.py:87` — an `"Authorization"` header dictionary key used for
**outbound** Kubernetes API authentication:
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
This constructs a client-side auth header for the SDK's outbound calls to
the Kubernetes API server. It is not an inbound authentication surface —
codeflare-sdk exposes no HTTP endpoints, no gRPC services, and no
webhooks.

**Why blocked:** The Python auth signal scan regex
`(?i)["'](?:authorization|...)["']\s*:` matches `"Authorization":` in the
header dict. The `filterUnaccountedAuthSignals` function finds no auth
fact with source in `cluster.py`, so it remains unaccounted. Negative
control 2 prevents source-auditing.

**Resolution path:** Analyzer enhancement to distinguish client-side auth
header construction (outbound) from server-side auth enforcement
(inbound). The `no-inbound-runtime-surfaces` completed check already
confirms no inbound surfaces exist — the auth signal scan could be
skipped or downgraded when inbound count is zero.

### MLServer

**Disposition:** Authentication gap is real from the analyzer's
perspective. Cannot source-audit.

**Auth coverage status:**
- `status: "partial"`, `fact_count: 0`
- Completed checks: `normalized-authentication-facts` (only)
- Limitation: "16 inbound runtime surfaces are not fully accounted for by
  authentication facts"
- Evidence: proto/dataplane.proto references

**Inbound surfaces:** 16 gRPC services registered:
- 11 `inference.GRPCInferenceService/*` RPCs (ModelInfer,
  ModelStreamInfer, ServerLive, ServerReady, ModelReady, etc.)
- 3 `inference.model_repository.ModelRepositoryService/*` RPCs
- 2 Python gRPC service registrations (GRPCInferenceService,
  ModelRepositoryService from `mlserver/grpc/server.py`)

**Auth posture:** Authentication is platform-delegated to KServe
infrastructure. In RHOAI 3.x, a kube-rbac-proxy sidecar handles auth
before requests reach MLServer. The MLServer process itself has no gRPC
interceptors or auth middleware. This is a deliberate architecture choice
documented in the agent-generated markdown.

**Python auth signals:** None. The regex scan found zero matches in
`mlserver/` source files. However, the scan was never reached — the
`authenticationCoverage` function returns early at the inbound surfaces
check (line 71).

**Why blocked:** 16 inbound gRPC surfaces exist and are not accounted for
by auth facts. Negative control 1 prevents source-auditing.

**Resolution path:** Would require either:
1. Auth facts representing "platform-delegated" auth posture for each gRPC
   service (new fact type or convention)
2. A `grpcAuthenticationAccounted` match for each service name
3. Analyzer support for platform-delegated auth patterns

### caikit

**Disposition:** Authentication gap is real from the analyzer's
perspective. Cannot source-audit.

**Auth coverage status:**
- `status: "partial"`, `fact_count: 0`
- Completed checks: `normalized-authentication-facts` (only)
- Limitation: "16 inbound runtime surfaces are not fully accounted for by
  authentication facts"
- Evidence: proto/model-mesh.proto references

**Inbound surfaces:** 16 gRPC services registered:
- 7 `mmesh.ModelMesh/*` RPCs (registerModel, unregisterModel,
  getModelStatus, ensureLoaded, setVModel, deleteVModel, getVModelStatus)
- 5 `mmesh.ModelRuntime/*` RPCs (loadModel, unloadModel, predictModelSize,
  modelSize, runtimeStatus)
- 1 `processproto.Process/Run` RPC
- 3 Python gRPC service registrations (Process, ModelRuntime, Health from
  `caikit/runtime/grpc_server.py`)

**Auth posture:** Authentication is delegated to the ModelMesh/runtime
infrastructure:
- `mmesh.ModelRuntime/*` — pod-local sidecar API; ModelMesh and caikit are
  co-located containers communicating over localhost
- `mmesh.ModelMesh/*` — client-side connection to ModelMesh cluster; TLS
  configurable via alchemy-config
- `processproto.Process/Run` — training workflow; auth configured
  externally

**Python auth signals:** None. The regex scan found zero matches in
`caikit/` source files. The scan was never reached (early return at
inbound surfaces check).

**Why blocked:** 16 inbound gRPC surfaces exist and are not accounted for
by auth facts. Negative control 1 prevents source-auditing.

**Resolution path:** Same as MLServer — would require platform-delegated
auth fact type or `grpcAuthenticationAccounted` matches.

## Other High-Value Categories

All three components have their other high-value categories populated
(not empty) in the ANALYZER_ARCHITECTURE.md:

| Component | architecture_components | integration_points | internal_dependencies |
|-----------|:-:|:-:|:-:|
| codeflare-sdk | populated | empty but contract-complete | populated (2 facts) |
| MLServer | populated | populated (1 fact) | populated (1 fact) |
| caikit | populated | populated (2 facts) | populated (2 facts) |

The `authentication` gap is the **sole** blocker for all three.

## Eligibility Verification

```
=== codeflare-sdk ===
  Empty HV: ['authentication']
  Correction gaps: ['authentication']
  Eligible: False
  Reason: bounded correction gaps: authentication

=== MLServer ===
  Empty HV: ['authentication']
  Correction gaps: ['authentication']
  Eligible: False
  Reason: bounded correction gaps: authentication

=== caikit ===
  Empty HV: ['authentication']
  Correction gaps: ['authentication']
  Eligible: False
  Reason: bounded correction gaps: authentication
```

## 90-Component Replay

- `uv run main.py static-analysis --platform=rhoai.next --force`:
  90 extracted, 0 failed, 0 skipped
- 49 previously approved components: all still route correctly
  (zero regressions)
- 51 total eligible, 49 approved
- 0 false nominations

## Outcome

No approvals added (49 remains). All three components documented as
remaining residuals with audited authentication dispositions. The
authentication gap for each is real from the analyzer's perspective,
even though the runtime auth posture is understood (client-side for
codeflare-sdk, platform-delegated for MLServer/caikit).

Future resolution requires analyzer enhancements:
- Client-side vs server-side auth signal distinction (codeflare-sdk)
- Platform-delegated gRPC auth fact type (MLServer, caikit)
