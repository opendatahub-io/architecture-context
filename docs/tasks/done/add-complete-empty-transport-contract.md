# Task: Add Complete-Empty Transport Contract

## Goal

Prevent bounded agents from rediscovering an absent transport surface when the
analyzer has completed a deterministic registration scan and can prove that
the surface is empty.

## Evidence

The MLflow replay routed grpc_services even though the agent ultimately found
no gRPC server. The analyzer emitted zero gRPC facts but marked the category
partial unconditionally, causing 27 discovery calls and 21 budget hits.

## Plan

1. [x] Emit language-neutral evidence when the literal gRPC registration scan
   completes without finding a runtime registration.
2. [x] Render that result as complete category coverage and confirmed-empty
   coverage finding.
3. [x] Teach routing and the complete-empty contract validator to honor the
   gRPC contract.
4. [x] Rebuild static analysis for MLflow and verify that grpc_services is not
   routed.
5. [x] Replay MLflow generation and verify that discovery activity declines.

## Acceptance Criteria

- A complete literal scan with no gRPC registration produces a source-backed
  complete-empty finding.
- Dynamic or incomplete scans remain partial/not-verified.
- The routing layer does not nominate grpc_services for a valid complete-empty
  artifact.
- Existing gRPC-positive extraction and transport findings remain unchanged.

## Status

Complete — 2026-08-02. The final MLflow replay routed only the remaining
authentication, integration, internal-dependency, and FIPS gaps. It completed
in 330.6 seconds with 53 agent turns, 22 targeted discovery calls, 12 source
reads, zero denied calls, zero rejected changes, and a 1.0 source-read
justification ratio. Compared with the prior 381-second replay, this is a
13.2% runtime reduction, with five fewer discovery calls, five fewer discovery
budget hits, and four fewer source reads. The gRPC category was complete-empty
and was not routed.
