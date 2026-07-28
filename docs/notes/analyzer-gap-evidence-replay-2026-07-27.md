# Analyzer Gap Evidence and Read-Justification Replay

Date: 2026-07-27

This is a sanitized summary of four containerized analyzer-assisted synthesis
replays. Raw Claude streams remain in `/tmp` and are not part of the
repository artifacts.

## Results

| Component | Shape | Unique source files read | Ledger records | Justified ratio | Architecture validation |
|---|---|---:|---:|---:|---|
| rhods-operator | Go operator/webhooks | 8 | 8 | 100% | pass |
| MLServer | Python/multi-runtime | 5 | 6 | 100% | pass |
| argo-workflows | Go/controller/gRPC | 7 | 8 | 85.7% | pass |
| odh-dashboard | web/Go/Python-adjacent | 6 | 8 | 100% | pass |
| **total** |  | **26** | **30** | **96.2%** | **4/4 pass** |

The ratio is calculated over unique source files observed in the stream. A
duplicate ledger record is harmless; an observed file without a ledger record
is a warning. Argo Workflows omitted `api/jsonschema/schema.json`, proving that
the warning-only comparison catches incomplete agent accounting without
blocking the generated document.

The replays also exercised the new analyzer gap categories for HTTP, gRPC,
authentication, integrations, egress, services, Kubernetes relationships,
authorization, configuration/lifecycle, and webhooks. Temporary merge checks
preserved analyzer-backed rows and validated all four generated documents.

## Interpretation and limits

The current host-run reports for the same component names recorded 30 source
files total (7, 8, 7, and 8 respectively); the replay observed 26. This is an
indicative reduction, not a controlled before/after experiment because the
container replay and host run used different execution environments and model
sessions.

The standalone container runner recorded zero `Glob`/`Grep` calls, but MLServer
and Argo used Bash for some discovery/verification actions because the
standalone runner does not install the orchestrator's tool guard. Those Bash
calls are therefore not evidence that the restricted host route permits broad
discovery. Controlled discovery-call comparison remains a follow-up for a
containerized generate-architecture runner.

## Follow-up

Keep sidecar enforcement warning-only. The next improvement should either
route containerized generation through the same execution guard or add
equivalent tool restrictions, then repeat this replay with directly comparable
telemetry and merge reports.
