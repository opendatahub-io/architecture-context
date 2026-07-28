# Analyzer Evidence-Quality Baseline — 2026-07-27

The completed `rhoai.next` generation run provides the baseline for the
evidence-quality follow-up. This note summarizes sidecar metadata only; raw
agent logs, transcripts, API dumps, and telemetry exports remain uncommitted.

## Read ledger

- 97 component sidecars
- 838 justification records
- 790 resolved, 40 partially resolved, 6 unhelpful, 2 contradicted
- Dominant categories: authentication (216), services (149), integration
  points (141), internal dependencies (134), HTTP endpoints (122), and gRPC
  services (61)

## Highest-priority read-scope findings

Several reads covered entire large files despite being tied to a narrow gap.
Examples include:

- `training_hub` algorithm source: 2,007 lines for integration evidence
- `kube-auth-proxy/oauthproxy.go`: 1,565 lines for HTTP/authentication
- `ml-metadata` gRPC proto: 1,548 lines for service inventory
- `caikit` HTTP server: 1,145 lines for endpoint evidence
- `MLServer/mlserver/settings.py`: 817 lines for port configuration

These are candidates for analyzer-provided symbols or bounded excerpts, not
automatic read denials.

## Low-value and unresolved reads

The non-resolved records cluster around service wiring, authentication
configuration, integration points, and HTTP/gRPC questions. The most useful
analyzer follow-up candidates are:

- distinguish production entrypoints from package/test/demo files;
- expose concrete Service-to-workload and listener mappings;
- expose AuthPolicy/provider wiring and conditional authentication;
- expose HTTPRoute and ingress configuration relationships;
- expose outbound integration targets and credential/TLS configuration.

The `contradicted` records include an authentication signal from a cached-build
test file and a Rust authentication finding that did not match the final
runtime interpretation. These should become analyzer negative controls.

## Follow-up implementation evidence

The analyzer now emits bounded `cross_cutting_evidence` families for security,
ingress, supply chain, disconnected deployment, high availability, and
deployment topology. The platform query summary exposes those records for
aggregation. Security import evidence is deduplicated by identity, retains all
source paths, and classifies generic imports as `dependency-signal` rather than
literal enforcement evidence.
