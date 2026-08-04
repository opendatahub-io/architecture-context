# Webhook Synthesis

Use this reference whenever the analyzer inventory contains admission or CRD
conversion webhooks, or when a declared synthesis gap concerns webhook
behavior. `arch-analyzer` is the canonical producer of the deterministic
inventory. This reference describes the bounded semantic synthesis layered on
that inventory.

## Inputs and route rules

Read the analyzer JSON and rendered baseline first. Treat each analyzer webhook
as an inventory fact, preserving its name, type, path, rules, source evidence,
and coverage status. Do not re-enumerate kubebuilder markers or conversion
declarations in the skill.

For synthesis, use analyzer evidence only. Do not inspect source files or
invoke sub-agents. For partial analysis, inspect only files allowed by the
declared gap categories and file budget. For legacy analysis, use the analyzer
inventory to narrow source inspection, then inspect handler and deployment
configuration broadly enough to resolve behavior. Never read prior generated
architecture documents as evidence.

If the analyzer reports partial or missing webhook coverage, preserve that
limitation. Do not manufacture an inventory from absence. Source inspection may
add semantic detail or resolve a declared gap, but must identify the exact file
and line evidence.

## Semantic questions

For every inventoried webhook that has available handler evidence, determine:

- Which GVKs or API resources it intercepts.
- Whether it validates, mutates, defaults, or converts objects.
- Which fields, labels, annotations, or status values it reads or changes.
- Whether it injects sidecars, volumes, mounts, environment variables, or
  other workload configuration.
- Whether it calls another service, reads shared configuration, or depends on
  another component.
- What happens on invalid input and whether failure behavior is explicit or
  unknown.
- How it is registered, configured, and exposed at runtime when that is not
  already established by analyzer facts or manifests.

Prefer the handler named by analyzer provenance and the smallest relevant
registration/configuration files. Do not read test files. Keep unresolved
behavior as `unknown` or `not-extracted`.

## Output

Preserve the analyzer inventory and enrich the architecture summary with an
Admission Webhooks table:

| File | Line(s) | GVK Intercepted | Webhook Type | What It Does |
|------|---------|-----------------|--------------|--------------|

Use the analyzer source path and line as the inventory reference. Add handler
source references only for semantic claims supported by those files. Include
conversion webhooks even when no admission handler is available, labeling
their conversion behavior and any unknown runtime details explicitly.

Summarize webhook implications in the security section when they affect
request admission, mutation, defaulting, conversion, failure behavior, or
tenant isolation. Cross-reference integration points when a webhook calls or
depends on another component. Do not duplicate the same webhook as a new
inventory item merely because an overlay or prefetched manifest rehosts it;
describe ownership or deployment placement as enrichment.

## Aggregating delegated findings

When controller sub-agents are used, assign webhook files to a webhook-focused
group and have that group apply this reference. Merge findings by analyzer
webhook identity, then deduplicate semantic rows by source path, line, target,
and behavior. Retain all distinct handler evidence and record every file read
in the source references table.

Report separately:

1. Analyzer inventory facts and coverage limitations.
2. Handler semantics established by bounded source evidence.
3. Overlay/deployment ownership and cross-component references.
4. Remaining unknown or dynamic behavior.

This separation prevents source synthesis from silently replacing the
canonical analyzer inventory.
