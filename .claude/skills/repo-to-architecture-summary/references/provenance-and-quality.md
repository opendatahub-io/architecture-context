# Provenance, Output Quality, and Reporting

## Provenance

When `component-map.json` is available, follow its upstream/downstream chain
and render Repo Lineage and Aliases with URLs, sync mechanism, branch, and
detection method. Without it, inspect remote/workflow evidence only on the
legacy route and label the result `local_analysis`.

## Output quality

Read `architecture-template.md` before writing. Preserve headings and table
columns. Keep empty sections when required by the template and use explicit
`unknown`, `not-extracted`, or `inferred` coverage labels. Platform operators
need complete dynamic-resource inventories, integration points, controller
reconciliation flows, and ingress traffic chains. Do not replace these with a
bullet summary.

## Reporting

Report the output path, component, distribution, version, counts, source-file
and search totals, inferred sections, validation state, and next review step.
For synthesis/partial routes, emit a schema-valid InsightArtifact separately;
an empty insights array is valid. Insights are non-authoritative and require
exact analyzer, query, overlay, or source provenance.
