# Task: Resolve Python SDK Authentication Gaps

## Goal

Resolve the `authentication` category gap for codeflare-sdk, MLServer,
and caikit — three Python components that are blocked from analyzer-only
approval solely because their authentication category is empty.

## Context

The Python import→category coverage wiring task (Task 8) added
`InternalDependency` and `IntegrationFact` entries from Python import
analysis, resolving `internal_dependencies` and `integration_points` gaps.
But these three components still have empty `authentication` categories.

The validation note at
`docs/notes/python-import-category-wiring-validation-2026-07-21.md`
(lines 88-91) notes: "these are SDKs/runtimes with no inbound auth
surfaces that the analyzer can detect. Would need
`source_audited_empty_categories` entries after manual verification."

The authentication coverage system (`categorycoverage.go:46`) checks:
1. Existing auth facts
2. gRPC service limitations (interceptors/credentials)
3. Inbound runtime surfaces (HTTP endpoints, gRPC services, webhooks,
   ingress, services, deployment probes)
4. Credential references
5. Manifest limitations
6. Unsupported runtime source surfaces
7. Language-specific extractor coverage
8. Python authentication signal scan

If a component has no inbound runtime surfaces and no auth constructs,
the category can legitimately be empty — but only if the Python
authentication signal scan confirms no unaccounted auth patterns exist.

## Source And Evidence

- Validation note: `docs/notes/python-import-category-wiring-validation-2026-07-21.md`
- Residual register: `docs/notes/analyzer-residual-agent-gaps.md`
- Adjudications: `lib/analyzer_correction_adjudications.json`
- Approvals: `lib/analyzer_only_approvals.json`
- Category coverage: `src/arch-analyzer/internal/extractor/categorycoverage.go`

## Target Components

| Component | Mutations | Auth status | Other gaps resolved? |
|-----------|----------:|-------------|---------------------|
| `codeflare-sdk` | 3 | Empty — Python SDK library for Ray/CodeFlare, likely no inbound HTTP/gRPC servers | `internal_dependencies` resolved (ray, kubernetes deps wired) |
| `MLServer` | 8 | Empty — Python inference server runtime with gRPC. Has gRPC services (GRPCInferenceService, ModelRepositoryService). Auth gap may be real if gRPC has auth surfaces. | `integration_points` and `internal_dependencies` gaps may remain |
| `caikit` | 8 | Empty — Python AI runtime with gRPC. Has gRPC services (Process, ModelRuntime, Health). Same consideration as MLServer. | `integration_points` and `internal_dependencies` gaps may remain |

**Important distinction**: codeflare-sdk is a pure SDK library with likely
no inbound surfaces. MLServer and caikit are runtime servers with gRPC
services — their authentication gap may be real (gRPC interceptor auth)
rather than a legitimately empty category. The agent must determine which
case applies for each component.

## Work

1. **Examine each component's architecture JSON**: Read the category
   coverage output for `authentication`. Check what limitations are
   reported and whether there are inbound runtime surfaces.

2. **Source audit codeflare-sdk authentication**: If no inbound runtime
   surfaces (HTTP endpoints, gRPC services, webhooks) exist and the
   Python auth signal scan found nothing, add a
   `source_audited_empty_categories` entry and approve.

3. **Assess MLServer and caikit authentication**: These have gRPC
   services. Check the `authenticationCoverage` output:
   - If gRPC services have no limitations (auth accounted), the category
     may already be complete or close to complete.
   - If the Python auth signal scan finds auth constructs, they need
     auth fact extraction (which may require new code).
   - If no auth constructs exist and gRPC services are the only inbound
     surfaces, determine whether absence-of-auth is the correct posture
     and whether a source-audited entry is justified.

4. **For components that become eligible**: Add to
   `lib/analyzer_only_approvals.json`.

5. **Validate**: Run a fresh 90-component replay. Verify zero false
   nominations and no regressions.

6. **Update documentation**: Update the residual register, write a
   validation note, move this task to `docs/tasks/done/`.

## Negative Controls

- Must not source-audit `authentication` as empty if inbound runtime
  surfaces exist and are not accounted for by auth facts.
- Must not add source-audited entries if the Python auth signal scan
  found unaccounted matches.
- Must not approve components that still have other unresolved category
  gaps (check ALL high-value categories, not just authentication).
- Must not break existing category coverage for the 47 approved components.

## Acceptance Criteria

- [x] Each component's authentication category coverage examined and
  disposition documented.
- [x] Source-audited entries added where authentication is provably
  legitimately empty. (None qualified — all three have negative control
  blockers preventing source-audit.)
- [x] Any components with real auth gaps (gRPC interceptors, Python auth
  constructs) documented with specific remaining limitations.
- [x] Eligible components added to `lib/analyzer_only_approvals.json`.
  (None became eligible — all three remain blocked by authentication.)
- [x] 90-component replay: zero false nominations.
- [x] No regressions on 49 previously approved components.
- [x] Validation note written.
- [x] Residual register updated.
- [x] Task moved to `docs/tasks/done/`.

## Likely Files

- `lib/analyzer_correction_adjudications.json`
- `lib/analyzer_only_approvals.json`
- `docs/notes/analyzer-residual-agent-gaps.md`
- `src/arch-analyzer/internal/extractor/categorycoverage.go` (read-only,
  for understanding auth coverage logic)

## Status

Done. All three components audited; none can be source-audited or approved
under the established negative controls. Authentication gaps documented as
remaining residuals. See [validation note](../../notes/python-sdk-authentication-validation-2026-07-21.md).
