# Readiness-Routed Evidence Merge Pilot: 2026-07-18

## Decision

The live readiness matrix passed. Evidence-gated component generation is enabled by
default, with `--no-evidence-gated-merge` as the explicit all-legacy escape hatch.
Analyzer-insufficient components continue to select the legacy path automatically.

The final three-component corpus report is retained at
`tmp/readiness-routing-live-20260718/corpus-report.md`. It reports 323/323 analyzer
structured identities preserved, zero analyzer-to-final conflicts, three of three
structurally valid documents, and an overall gate result of PASS.

## Live Matrix

| Component | Commit | Readiness / route | Agent | Tools | Reads / source files | Output tokens | Cost | Merge |
|-----------|--------|-------------------|------:|------:|---------------------:|--------------:|-----:|------:|
| `odh-dashboard` | `f1cdd9f22ebd3b320de9cf45e9ba3fdb6a93e335` | sufficient / evidence-gated | 146.24s | 15 | 8 / 0 | 5,965 | $0.9772 | 0.08s |
| `caikit-tgis-backend` | `b2b0f67a2eaae6d2a15ca3570abacfb7ce3a0e8d` | partial / evidence-gated | 331.25s | 25 | 7 / 4 | 16,732 | $1.4890 | 0.01s |
| `must-gather` | `36dd46dbb94780f4b4c6355e4cf01e0ecd989723` | insufficient / legacy | 267.06s | 50 | 35 / 32 | 14,107 | $1.3318 | none |

The `must-gather` read count was reconstructed from the live SDK log because the
legacy hook initially returned before read accounting. The hook now records legacy
reads without restricting them.

## Quality Results

| Component | Raw fixture recall | Final fixture recall | Analyzer preservation | Merge decisions |
|-----------|-------------------:|---------------------:|----------------------:|-----------------|
| `odh-dashboard` | 162/166 (97.59%) | 162/166 (97.59%) | 314/314, 0 conflicts | 421 unchanged; 0 applied/rejected/restored |
| `caikit-tgis-backend` | 3/20 (15.00%) | 3/20 (15.00%) | 9/9, 0 conflicts | 18 unchanged; 15 applied; 0 rejected/restored |
| `must-gather` | n/a | 49/76 (64.47%) | Analyzer had 0 structured rows | Legacy output; no merge |

Raw and merged recall are identical for both evidence-gated components, so the
adapter introduced no fixture regression. The dashboard's four missing fixture
identities and its historical populated-cell differences were previously
source-adjudicated in
[the dashboard fidelity audit](arch-analyzer-dashboard-fidelity-audit.md); the
adjudicated result is 162/162.

The low exact-key result for `caikit-tgis-backend` is mostly fixture vocabulary, not
missing runtime behavior. The bounded agent recovered source-backed TGIS gRPC egress,
local health egress, TLS/mTLS, Caikit registration, DNS discovery, and local/remote
TGIS operation from four source files. The merge accepted eight architecture facts
plus four source-file and three search-evidence rows. Examples include:

- TGIS client creation and Caikit integration at
  `caikit_tgis_backend/tgis_backend.py:39-58,201-223,258`;
- TLS/mTLS and gRPC channel construction at
  `caikit_tgis_backend/tgis_connection.py:122-174,255-298`;
- DNS endpoint discovery at
  `caikit_tgis_backend/load_balancing_proxy.py:132-191`; and
- local TGIS health polling at
  `caikit_tgis_backend/managed_tgis_subprocess.py:306-321`.

The fixture names individual classes while the current analyzer and bounded route
use architectural roles, so exact identity recall remains 15%. This is not accepted
as replacement-level analyzer fidelity; it is accepted for this routing pilot
because source review found the intended behavior, the partial route added it through
parseable evidence records, and the final document preserved all analyzer facts.

## Runtime Result

Preseeding the sufficient output with analyzer Markdown changed `odh-dashboard` from
a full rewrite to targeted synthesis edits:

| Measure | Full rewrite | Preseeded | Change |
|---------|-------------:|----------:|-------:|
| Agent time | 339.79s | 146.24s | -56.96% |
| Output tokens | 19,804 | 5,965 | -69.88% |
| Cost | $1.0571 | $0.9772 | -7.56% |

The agent made no structured edits and emitted an empty, parseable Markdown change
table. Code-level hooks prohibited full output replacement and broad discovery.
Sufficient prompts now list the exact analyzer source files permitted by the guard.

The partial route received six explicit gap categories and an eight-file cap. It
read four source files and emitted eight parseable structured additions. The
insufficient route received no cap and performed the existing full discovery flow,
confirming that the fallback remains functional.

## Defects Found And Fixed

1. A single source surface could incorrectly make analyzer readiness sufficient.
   Sufficient runtime evidence now requires at least two distinct runtime surfaces.
2. The partial skill attempted broad globs and malformed row keys. Hooks now reject
   checkout-wide patterns, and the parser normalizes evidence shorthand and trailing
   display-only key cells.
3. Duplicate structured row keys caused false restored changes. The adapter now
   pairs duplicate occurrences by exact row content before evaluating changes.
4. Full Markdown regeneration wasted time and tokens. Evidence-gated outputs are now
   preseeded and can only be modified through targeted edits.
5. Legacy reads were not counted. The unrestricted hook now records them without
   changing permissions.

## Artifacts

Final live logs, candidates, change records, merge reports, and run telemetry are in
`tmp/readiness-routing-live-20260718/agents`. Failed and superseded prompt/parser
iterations are retained in sibling attempt directories. Component raw/final fixture
comparisons are under `tmp/readiness-routing-live-20260718/comparisons`, and the
three-component corpus inputs and reports are under
`tmp/readiness-routing-live-20260718/corpus*`.
