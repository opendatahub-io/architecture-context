# Correction Proposal Harvester

The harvester consumes the checked-in
`tmp/feedback-data/corpus/extraction/staff-corrections.yaml` fixture. A record
qualifies only when `human_review_type` is `sme_input`, `sme_content` is
non-empty, and explicit components and correction types are present.

Source correction types map to the existing proposal contract v1 as follows:

| Source type | Proposal category |
|---|---|
| `scope_correction`, `component_scope` | `scope-correction` |
| `architecture_constraint` | `architecture-update` |
| `team_ownership` | `ownership-correction` |
| `maturity_correction` | `maturity-correction` |
| `upstream_correction` | `dependency-correction` |
| `priority_correction`, `general_refinement`, unknown values | `unknown` |

Example invocation:

```text
arch-analyzer harvest-proposals tmp/feedback-data/corpus/extraction/staff-corrections.yaml \
  --created-date 2026-07-24 --output proposals.json
```

The output is compatible with `arch-query proposals validate`:

```json
{
  "contract_version": "v1",
  "generated_at": "",
  "proposals": [{
    "id": "prop-...",
    "component": "AI Safety",
    "category": "maturity-correction",
    "status": "pending",
    "claim": "<exact sme_content>",
    "provenance": [
      "source:tmp/feedback-data/corpus/extraction/staff-corrections.yaml",
      "record:7", "yaml-line:267", "jira:RHAISTRAT-1526"
    ],
    "author": "unknown",
    "created_date": "2026-07-24"
  }]
}
```

Every emitted proposal is pending. The harvester never applies corrections or
promotes human input to an authoritative overlay.
