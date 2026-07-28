# Project Plan

## Current Milestone

Continue the analyzer-assisted track: valid analyzer artifacts default to the
bounded partial (extend-and-improve) route for all readiness classifications
(sufficient, partial, insufficient, unknown); synthesis is not selected for
normal generation; the synthesis migration allowlist is retained for audit
only; legacy is reserved for missing/invalid artifacts or explicit operator
override. External rollout gates remain separate. The next implementation
milestone is the [arch-analyzer optimization follow-up](docs/plans/arch-analyzer-optimization-follow-up.md),
driven by the completed 97-component run.
The analyzer gap evidence and read justification plan is complete; its replay
measurements are recorded in
[docs/notes/analyzer-gap-evidence-replay-2026-07-27.md](docs/notes/analyzer-gap-evidence-replay-2026-07-27.md).
The next focused milestone is the
[arch-analyzer evidence quality follow-up](docs/plans/arch-analyzer-evidence-quality-follow-up.md).

## Active Tasks

- [Add the Analyzer Gap Evidence Index](docs/tasks/done/add-analyzer-gap-evidence-index.md) — 2026-07-27 (bounded candidates and replay measurements)
- [Enrich arch-analyzer High-Demand Gap Categories](docs/tasks/done/enrich-analyzer-high-demand-gaps.md) — 2026-07-27 (high-demand fact families exposed as targeted candidates)
- [Add the Source-Read Justification Ledger](docs/tasks/done/add-source-read-justification-ledger.md) — 2026-07-27 (warning-only ledger/telemetry comparison; 96.2% replay coverage)

- [Allow Bounded Source Reads on the Partial Route](docs/tasks/done/allow-bounded-source-reads-on-partial-route.md) — implemented; next full run measures denial-rate change
- [Add a Compact Analyzer Context File](docs/tasks/done/add-compact-analyzer-context-file.md) — implemented; next full run measures oversized-read reduction

- [Generate Component Architecture Directly in the Architecture Tree](docs/tasks/done/direct-component-architecture-generation.md) — 2026-07-27, amended 2026-07-28 (analyzer inputs remain in component `.analyzer` directories, source reads remain checkout-scoped, component Markdown is promoted to the platform tree after validation, and collect was removed)
- [Store Static-Analysis Artifacts in the Architecture Output Tree](docs/tasks/done/store-static-analysis-artifacts-in-architecture.md) — 2026-07-27 (static analyzer JSON, Markdown, and schemas now write under `architecture/<platform>/<component>/.analyzer`; eligibility retains legacy fallback only)
- [Mine Partial-Run Logs for arch-analyzer Improvements](docs/tasks/pending/mine-partial-run-logs-for-analyzer-improvements.md) — completed demand inventory and accepted P1/P2 analyzer improvements; future full-run measurement remains follow-up
- [Add arch-analyzer Cross-Reference Maps](docs/tasks/done/add-analyzer-cross-reference-maps.md) — implemented source-linked endpoint/service/security/controller joins; production webhook replay remains follow-up
- [Add arch-analyzer Coverage and Complete-Empty Findings](docs/tasks/done/add-analyzer-coverage-findings.md) — implemented observed, confirmed-empty, and not-verified findings
- [Render Compact Analyzer Evidence Bundles](docs/tasks/done/render-compact-analyzer-evidence-bundles.md) — implemented bounded JSON/Markdown synthesis projections; full runtime comparison remains follow-up
- [Fix Insight Applicability Contract](docs/tasks/done/fix-insight-applicability-contract.md) — added cross-component applicability and regression coverage
- [Extend Analyzer Runtime and API Inventory from Demand Evidence](docs/tasks/done/extend-analyzer-runtime-and-api-inventory.md) — 2026-07-27 (implemented P1 runtime, API/transport, dependency-role, security-evidence extraction and routing coverage; replay report recorded)
- [Render Source-Linked Analyzer Narratives](docs/tasks/done/render-analyzer-factual-narratives.md) — 2026-07-27 (implemented bounded factual Purpose, Data Flows, Integration Points, and Architectural Analysis rendering with provenance)
- [Enable Partial Routing in the `all` Command](docs/tasks/done/enable-partial-routing-in-all-command.md) — 2026-07-27 (evidence-gated routing propagated through `main.py all`, enabled by default with explicit legacy opt-out; 4 focused tests added)
- [Route All Analyzer-Backed Runs Through Bounded Partial Synthesis](docs/tasks/done/default-analyzer-backed-runs-to-partial.md) — 2026-07-27 (all valid analyzer-backed readiness levels now use bounded partial synthesis; legacy is explicit or artifact-failure fallback)
- [Add Phase Context to Concurrent Progress Bars](docs/tasks/done/add-phase-context-to-progress-bars.md) — 2026-07-27 (multi-process status panels now identify their active pipeline phase)
- [Remove the Legacy Webhook Inventory Phase](docs/tasks/done/remove-webhook-inventory-phase.md) — 2026-07-27 (removed obsolete phase/subcommand while preserving analyzer-backed queries and aggregate synthesis)
- [Move Architecture Template into Skill Templates](docs/tasks/done/move-architecture-template-to-skill-templates.md) — 2026-07-27 (relocated the output template without changing its content or generated artifacts)
- [Move Platform Webhook Synthesis to Aggregate Platform Architecture](docs/tasks/done/move-platform-webhook-synthesis-to-aggregate.md) — 2026-07-27 (platform-level synthesis moved to aggregate skill; duplicate phase agent analysis removed)
- [Extract Webhook Synthesis Reference](docs/tasks/done/extract-webhook-synthesis-reference.md) — 2026-07-27 (consolidated webhook-specific skill guidance while preserving analyzer-owned inventory and bounded semantic enrichment)
- [Run First Allowlisted Analyzer-Assisted Migration](docs/tasks/done/run-first-allowlisted-analyzer-assisted-migration.md) — 2026-07-26 (accepted five-component bounded evidence set; `rhoai-mcp` live synthesis/merge validated; allowlist remains empty; no production rollout)
- [Run Next Optimized Analyzer-Assisted Migration](docs/tasks/done/run-next-optimized-analyzer-assisted-migration.md) — 2026-07-26 (container retry validated synthesis with 0 source reads and 0 discovery calls; tracked allowlist remains empty)
- [Run Bounded Multi-Component Optimized Migration](docs/tasks/done/run-bounded-multi-component-optimized-migration.md) — 2026-07-26 (synthesis, partial, and legacy matrix completed; all architecture artifacts validated)
- [Expand Provisional Analyzer-Assisted Synthesis Allowlist](docs/tasks/done/expand-provisional-analyzer-assisted-synthesis-allowlist.md) — 2026-07-26 (reviewed `rhoai-mcp` synthesis and `caikit-nlp` partial evidence; legacy fallback and external rollout gates remain)
- [Audit Existing Feedback Against Analyzer-Assisted Rollout Gates](docs/tasks/done/audit-existing-feedback-against-rollout-gates.md) — 2026-07-26 (existing staff-review package is directional evidence only; no 1:1 mapping to v1-ab labels)
- [Align Synthesis Skill With arch-analyzer Contract](docs/tasks/done/align-synthesis-skill-with-arch-analyzer-contract.md) — 2026-07-26 (explicitly documented `arch-analyzer extract`/`render` outputs, readiness handoff, provenance, and constrained-route fallback)
- [Make repo-to-architecture-summary Analyzer-First](docs/tasks/done/make-repo-summary-analyzer-first.md) — 2026-07-26 (all routes consume analyzer coverage before source inspection; source reads remain gap- and safety-driven)
- [Test Analyzer-First Summary on rhods-operator and odh-dashboard](docs/tasks/done/test-analyzer-first-summary-on-operator-and-dashboard.md) — 2026-07-26 (both sufficient/synthesis runs passed with zero source reads; analyzer schema/distribution limitations documented)
- [Verify Clean-Run Analyzer-Assisted Synthesis](docs/tasks/done/verify-clean-run-analyzer-assisted-synthesis.md) — 2026-07-26 (clean-run isolation verified; analyzer outputs are synthesis context and prior architecture documents remain comparison-only)
- [Refactor Analyzer-Assisted Targeted Synthesis](docs/tasks/done/refactor-analyzer-assisted-targeted-synthesis.md) — 2026-07-27 (analyzer-first narrative-gap routing, bounded targeted reads, clean-run isolation, and local validation report)
- [Run Real Analyzer-Assisted Synthesis on Operator and Dashboard](docs/tasks/done/run-real-analyzer-assisted-synthesis.md) — 2026-07-27 (real synthesis outputs validated with analyzer fact preservation and bounded partial evidence)
- [Migrate odh-dashboard to Analyzer-Assisted Synthesis](docs/tasks/done/migrate-odh-dashboard-to-analyzer-assisted-synthesis.md) — 2026-07-27 (removed inherited analyzer-only precedence; sufficient dashboard baselines now use analyzer-assisted synthesis)
- [Slim repo-to-architecture-summary Skill](docs/tasks/done/slim-repo-architecture-summary-skill.md) — 2026-07-27 (reduced always-loaded skill to 119 lines and extracted legacy procedures/quality guidance into linked references)
- [Remove Analyzer-Only Generation Route](docs/tasks/done/remove-analyzer-only-generation-route.md) — 2026-07-27 (all generation routes now combine analyzer evidence with agent synthesis or bounded enrichment)
- [Move Webhook Enumeration into arch-analyzer](docs/tasks/done/move-webhook-enumeration-to-arch-analyzer.md) — 2026-07-27 (analyzer is now the canonical deterministic webhook inventory producer)
- [Fix Platform Summary Analyzer Artifact Loading](docs/tasks/done/fix-platform-summary-analyzer-artifacts.md) — 2026-07-28 (`arch-query` now consumes component-local `.analyzer` artifacts and exposes webhook evidence to platform aggregation)
- [Harden Claude Runner Podman Runtime Fallback](docs/tasks/done/harden-claude-runner-podman-runtime.md) — 2026-07-28 (launcher falls back to writable `/tmp` runtime dir when `/run/user/$UID/libpod` is unavailable/read-only)
- [Fix Invalid Insight Applicability Regression](docs/tasks/done/fix-invalid-insight-applicability-regression.md) — 2026-07-28 (`cross-component implication` applicability is normalized before validation and archived artifacts preserve the repaired value)
- [Fix Architecture Phase Test Scaffolds](docs/tasks/done/fix-architecture-phase-test-scaffolds.md) — 2026-07-28 (`tests/test_architecture_phase.py` now matches direct-to-architecture output, `.generation` sidecars, and bounded partial routing; 18/18 pass)
- [Fix Source-Read Ledger Mismatch Diagnostics](docs/tasks/done/fix-source-read-ledger-mismatch-diagnostics.md) — 2026-07-28 (source-read ledger validation now repairs safe malformed records, normalizes paths, and categorizes remaining mismatch diagnostics)
- [Fix Partial Route Oversized Source Reads](docs/tasks/done/fix-partial-route-oversized-source-reads.md) — 2026-07-28 (partial-route source reads of large files now require bounded offset/limit ranges; oversized ledger records are grouped by gap category and require scope reasons)
- [Fix Partial Route Denied Tool Noise](docs/tasks/done/fix-partial-route-denied-tool-noise.md) — 2026-07-28 (restricted generation excludes unnecessary planning/shell tools, forbids `TodoWrite`, and classifies avoidable workflow denials separately)
- [Fix Duplicate Security Evidence Rendering](docs/tasks/done/fix-duplicate-security-evidence-rendering.md) — 2026-07-28 (repeated `crypto/tls` imports render as one dependency-signal row with retained provenance; Security Evidence labels signal type explicitly)
- [Add Component Runtime Breakdown Reports](docs/tasks/done/add-component-runtime-breakdown-reports.md) — 2026-07-28 (component `*.run.json` now separates agent activity counts and orchestrator validation/merge timings for partial-route runtime diagnosis; high-runtime bug remains open pending full-run comparison)
- [Fix Consumer V1 Inventory Source Citations](docs/tasks/done/fix-consumer-v1-inventory-source-citations.md) — 2026-07-28 (`benchmark/consumer-v1` no longer cites the removed generated `README.md`; corpus validates with 40 questions and 10 per tier)
- [Sync Bug Ledger State](docs/tasks/done/sync-bug-ledger-state.md) — 2026-07-28 (`docs/bugs/open/` now contains only the three still-open bugs, fixed bugs moved to `docs/bugs/fixed/`, and stale moved-path references updated)
- [Remove Source References from Final Architecture Markdown](docs/tasks/done/remove-source-references-from-final-markdown.md) — 2026-07-28 (final summaries no longer require or render files-read/source-search tables; detailed source-read audit remains in `.generation/SOURCE_READ_JUSTIFICATIONS.json`)
- [Move Architectural Analysis to the Top](docs/tasks/done/move-architectural-analysis-to-top.md) — 2026-07-28 (`Architectural Analysis` now appears immediately after `Metadata` and before `Provenance` in the template and analyzer baselines)
- [Move Purpose Below Architectural Analysis](docs/tasks/done/move-purpose-below-architectural-analysis.md) — 2026-07-28 (`Purpose` now follows `Architectural Analysis`; `Provenance` moves below the summary sections and above detailed component inventories)
- [Swap Purpose and Architectural Analysis](docs/tasks/done/swap-purpose-and-architectural-analysis.md) — 2026-07-28 (`Purpose` now precedes `Architectural Analysis`; `Provenance` remains below both narrative sections)
- [Stage Generation Artifacts Before Final Promotion](docs/tasks/done/stage-generation-artifacts-before-final-promotion.md) — 2026-07-28 (agents now work in `.generation/{preseed,candidate,merged}.md`; top-level component Markdown is promoted only after validation)
- [Expand Provisional Allowlist for rhods-operator](docs/tasks/done/expand-allowlist-rhods-operator.md) — 2026-07-27 (real synthesis evidence supports provisional synthesis routing; dashboard migration was subsequently corrected)
- [Resolve External Analyzer-Assisted Rollout Gates](docs/tasks/blocked/resolve-external-analyzer-assisted-rollout-gates.md) — promotion-only human/external inputs; does not block local implementation

## Recently Completed

- [Expand Provisional Analyzer-Assisted Synthesis Allowlist](docs/tasks/done/expand-provisional-analyzer-assisted-synthesis-allowlist.md) — 2026-07-26 (two restricted routes enabled under the operator-controlled allowlist; no full rollout or legacy retirement claim)

- [Run Bounded Multi-Component Optimized Migration](docs/tasks/done/run-bounded-multi-component-optimized-migration.md) — 2026-07-26 (three-route matrix completed; one partial-route discovery violation documented; full rollout gates remain)

- [Run Next Optimized Analyzer-Assisted Migration](docs/tasks/done/run-next-optimized-analyzer-assisted-migration.md) — 2026-07-26 (container retry validated `rhoai-mcp` synthesis output, merge, insights, and architecture schema; host SDK initialization attempt failed and was documented; no production rollout claim)

- [Optimize Analyzer-Sufficient Synthesis Discovery](docs/tasks/done/optimize-analyzer-sufficient-synthesis-discovery.md) — 2026-07-26 (route-aware skill contract, focused synthesis/partial/legacy tests, zero-source-read synthesis fixture, and architecture validation; one unrelated pre-existing validator test failure documented)

- [Reconcile Pilot Evidence Across Readiness Documentation](docs/tasks/done/reconcile-pilot-readiness-evidence.md) — 2026-07-26 (reconciled stale authorization/canary/evaluation claims in audit, evaluation contract, benchmark README, and rollout-track notes with 32-session pilot evidence; human-label, semantic-calibration, external-OTel, full-corpus, external-MLflow, and legacy-retirement gates remain incomplete; no full rollout success claimed)
- [Run Authorized Provisional 32-Session Pilot](docs/tasks/done/run-authorized-provisional-32-session-pilot.md) — 2026-07-26 (32/32 sessions, $8.1087, local MLflow read-back verified; directional four-question subset only)
- [Add Prior-Snapshot Deterministic Regression Report](docs/tasks/done/add-prior-snapshot-regression-report.md) — deterministic component-by-component comparison of `architecture/rhoai.next.bak` to `architecture/rhoai.next`; provisional structural metrics only, no human-data or model activity
- [Align INDEX.md with Canonical Evaluation Tree](docs/tasks/done/align-index-artifact-with-canonical-tree.md) — 2026-07-26 (regenerated INDEX.md from architecture/rhoai.next; version rhoai.next, 99 components, source revision c5c8201c; experiment manifest, provenance notes, and tests aligned; deterministic regeneration verified)
- [Define No-Human-Data Rollout Track](docs/tasks/done/define-no-human-data-rollout-track.md) — 2026-07-26 (provisional rollout track for the reality that additional human labels are unlikely; existing feedback is directional only; exact-match and regression testing measurable; LLM-judge and human-review claims not asserted; legacy route preserved; full rollout gates remain authoritative)
- [Reconcile Historical Feedback Provenance](docs/tasks/done/reconcile-historical-feedback-provenance.md) — 2026-07-25 (durable provenance note for ignored 94-question feedback package; documented internal inconsistencies in 84% baseline claim; checksums and limitations recorded; canonical 40-question corpus and plan Baseline provenance unchanged)
- [Audit Analyzer Plan Success Criteria](docs/tasks/done/audit-analyzer-plan-success-criteria.md) — 2026-07-25 (evidence matrix for all success criteria and rollout gates; local implementation complete, rollout pending external gates; five external inputs enumerated; legacy route preserved; plan completion not claimed)
- [Reconcile Plan Step 3 and Step 4 Status](docs/tasks/done/reconcile-plan-step3-step4-status.md) — 2026-07-25 (annotated Step 3 as 7/7 and Step 4 as 24/28 in architecture plan; updated MLflow gate to reflect committed local REST and file-backed validation; four external blockers preserved; linked audit evidence)
- [Fix MLflow REST Experiment Search](docs/tasks/done/fix-mlflow-rest-experiment-search.md) — 2026-07-25 (`max_results: 10` fix, regression test, ephemeral MLflow 2.22.0 REST end-to-end validation; accepted and committed)
- [Validate Local MLflow REST Registration](docs/tasks/done/validate-mlflow-rest-registration-local.md) — 2026-07-25 (ephemeral REST preflight and operation validation; discovered the search bug; follow-up fix completed full flow; external registration remains pending)

- [Reconcile Behavioral Contract Audit Evidence](docs/tasks/done/reconcile-behavioral-contract-audit.md) — 2026-07-25 (updated audit items 2.15–2.19 from locally blocked to implemented after commit `9f931a8b`; Step 2 now 19/19; plan Step 2 annotated with implementation note; external gates unchanged)
- [Extend Behavioral Evidence Contract Fields](docs/tasks/done/extend-behavioral-evidence-contract.md) — 2026-07-25 (added five structured Phase 1 behavioral-evidence categories with schema/renderer coverage; no unsupported values populated)
- [Audit Local Plan Implementation Gaps](docs/tasks/done/audit-local-plan-implementation-gaps.md) — 2026-07-25 (Steps 2–4 audited; added correction regression assertions; external gates remain)
- [Reconcile External-Gate Preparation Artifacts](docs/tasks/done/reconcile-plan-external-gate-artifacts.md) — 2026-07-25 (linked 24-question calibration template and 35-proposal adjudication template to plan/readiness docs; external gates remain)
- [Prepare Failure-Classification Adjudication Template](docs/tasks/done/prepare-failure-adjudication-template.md) — 2026-07-25 (35 proposals, v0.1.0, 44 tests; human adjudication blocked)
- [Improve Corpus V1 Scoring Accuracy](docs/tasks/done/improve-corpus-v1-scoring-accuracy.md) — 2026-07-25 (Phase 1 done; Phase 2 deferred)
- [Prepare Semantic-Judge Calibration Set Template](docs/tasks/done/prepare-judge-calibration-set-template.md) — 2026-07-25 (24 questions, v0.1.0, 49 tests; human labeling and authorization blocked)
- [Add LLM-as-Judge Scoring Dimension](docs/tasks/done/add-llm-judge-scoring-dimension.md) — 2026-07-25 (contract/protocol only; rationale required; 65 tests; execution blocked on authorization)
- [Re-author Retired Navigation Question NAV-006 (Deployment Topology)](docs/tasks/done/reauthor-retired-nav-006-deployment-topology.md) — 2026-07-25 (restored; deployment topology navigation)
- [Re-author Retired Integration Question INTG-006](docs/tasks/done/reauthor-retired-intg-006-operator-lifecycle.md) — 2026-07-25 (validated; clean operator lifecycle)
- [Re-author Retired Integration Question INTG-003](docs/tasks/done/reauthor-retired-intg-003-kserve-bridge.md) — 2026-07-25 (validated; clean KServe bridge)
- [Validate Context Telemetry in Canary Readiness](docs/tasks/done/validate-context-telemetry-canary-readiness.md) — 2026-07-25 (accepted)
- [Reconcile Context Provenance with the Evaluation Schema](docs/tasks/done/reconcile-context-provenance-schema.md) — 2026-07-25 (accepted)
- [Reconcile Evaluation Contract Readiness Documentation](docs/tasks/done/reconcile-evaluation-contract-readiness-docs.md) — 2026-07-25 (accepted)
- [Re-author Retired Integration Question INTG-008](docs/tasks/done/reauthor-retired-intg-008-training-flow.md) — 2026-07-25 (validated; clean PLATFORM workflow)
- [Re-author Retired Navigation Question NAV-010](docs/tasks/done/reauthor-retired-nav-010.md) — 2026-07-25 (validated)
- [Re-author Retired Integration Question INTG-010](docs/tasks/done/reauthor-retired-intg-010.md) — 2026-07-25 (validated)
- [Reconcile Plan State After Local MLflow Validation](docs/tasks/done/reconcile-plan-state-after-local-mlflow.md) — 2026-07-25 (validated)
- [Validate Local MLflow Tracking in Task Container](docs/tasks/done/validate-local-mlflow-tracking.md) — 2026-07-25 (validated; external server pending)

- [Reconcile Plan Evaluation Scope](docs/tasks/done/reconcile-plan-evaluation-scope.md) — 2026-07-25 (validated; external gates remain)
- [Add the OTel-Compatible File Export Boundary](docs/tasks/done/add-otel-file-export-boundary.md) — 2026-07-25 (validated; external producer pending)
- [Add Failure-Classification Proposals](docs/tasks/done/add-failure-classification-proposals.md) — 2026-07-25 (validated; human adjudication pending)
- [Configure Analyzer-Assisted Experiment Tracking](docs/tasks/done/configure-analyzer-assisted-experiment-tracking.md) — 2026-07-25 (validated; external registration pending)
- [Re-author Retired Integration Question INTG-002](docs/tasks/done/reauthor-retired-intg-002.md) — 2026-07-25 (validated)
- [Resolve INTG-002 Source-Document Conflicts](docs/tasks/done/resolve-intg-002-source-conflicts.md) — 2026-07-25 (accepted)
- [Reconcile Deterministic V1 Scoring Accuracy](docs/tasks/done/reconcile-v1-scoring-accuracy.md) — 2026-07-25 (accepted)
- [Integrate Evaluation Context Telemetry](docs/tasks/done/integrate-evaluation-context-telemetry.md) — 2026-07-25 (accepted)
- [Enable the Combined INDEX.md + arch-query Condition](docs/tasks/done/enable-combined-experiment-condition.md) — 2026-07-25 (accepted)
- [Pin INDEX.md Experiment Artifact](docs/tasks/done/pin-index-experiment-artifact.md) — 2026-07-25 (accepted)
- [Materialize the INDEX.md Evaluation Artifact](docs/tasks/done/materialize-index-evaluation-artifact.md) — 2026-07-25
- [Enable the Implemented arch-query Experiment Condition](docs/tasks/done/enable-arch-query-condition.md) — 2026-07-25
- [Add Context Access Telemetry for Evaluation](docs/tasks/done/add-context-access-telemetry.md) — 2026-07-25
- [Enforce Synthesis Routing and Source-Read Permissions](docs/tasks/done/enforce-synthesis-routing-permissions.md) — 2026-07-25
- [Define Bounded Synthesis Insights Contract](docs/tasks/done/define-synthesis-insights-contract.md) — 2026-07-24
- [Adapt the Evaluation Runner to the Condition Contract](docs/tasks/done/adapt-condition-aware-evaluation-runner.md) — 2026-07-25
- [Define a Condition-Aware Canary Report](docs/tasks/done/define-condition-canary-report.md) — 2026-07-25
- [Integrate Synthesis Insight Artifacts](docs/tasks/done/integrate-synthesis-insight-artifacts.md) — 2026-07-25
- [Enable the Query-Aware Evaluation Boundary](docs/tasks/done/enable-query-aware-evaluation-boundary.md) — 2026-07-25

- [Add Initial Machine-Readable Query Contract](docs/tasks/done/add-initial-query-contract.md) — 2026-07-24
- [Harvest Explicit Correction Proposals from Review Input](docs/tasks/done/harvest-correction-proposals.md) — 2026-07-24
- [Report Correction Frequency from Proposal Artifacts](docs/tasks/done/report-correction-frequency.md) — 2026-07-24
- [Define Reviewed Overlay Contract and Correction Proposals](docs/tasks/done/define-reviewed-overlay-contract.md) — 2026-07-24
- [Generate Context Index and Version-Diff Contract](docs/tasks/done/generate-context-index.md) — 2026-07-24
- [Define Analyzer Context Contract](docs/tasks/done/define-analyzer-context-contract.md) — 2026-07-24
- [Tag Corpus Questions by Required Scope](docs/tasks/done/tag-corpus-questions-by-required-scope.md) — 2026-07-24 (re-scored: arch-only primary 0.5357/0.5000)
- [Re-author Retired Navigation Question NAV-006](docs/tasks/done/reauthor-retired-nav-006.md) — 2026-07-24 (unresolved; evaluation scope recovery path recorded)
- [Re-author Retired Navigation Question NAV-003](docs/tasks/done/reauthor-retired-nav-003-dependency-graph.md) — 2026-07-25 (restored; dependency graph navigation)
- [Re-author Retired Consumer-v1 Questions (INV-005, INV-009)](docs/tasks/done/reauthor-retired-consumer-v1-questions.md) — 2026-07-24
- [Reconcile Analyzer-Assisted Corpus Baseline](docs/tasks/done/reconcile-analyzer-assisted-corpus-baseline.md) — 2026-07-24
- [Define Analyzer-Assisted Evaluation Contract](docs/tasks/done/define-analyzer-assisted-evaluation-contract.md) — 2026-07-24

## Open Bugs

- [Corpus V1 Exact Match Variants Too Strict](docs/bugs/open/corpus-v1-exact-match-variants-too-strict.md)
- [Corpus V1 Meta Questions Outside Architecture Tree](docs/bugs/open/corpus-v1-meta-questions-outside-architecture-tree.md)
- [Partial Route Component Runtime Remains High](docs/bugs/open/partial-route-component-runtime-remains-high.md)

## Plans

- [Architecture Diagram Implementation](docs/plans/000-architecture-diagram-implementation.md)
- [Analyzer-Assisted Agent Architecture](docs/plans/analyzer-assisted-agent-architecture.md)
- [arch-analyzer Evidence Quality Follow-up](docs/plans/arch-analyzer-evidence-quality-follow-up.md)

## Decisions

- [ADR-0001: Architecture Diagram Proposal](docs/decisions/ADR-0001-architecture-diagram-proposal.md)
- [ADR-0002: Skills-First MVP](docs/decisions/ADR-0002-skills-first-mvp.md)
- [ADR-0003: Python Orchestrator Pipeline](docs/decisions/ADR-0003-python-orchestrator.md)
- [ADR-0004: Kustomize Overlay Context Injection](docs/decisions/ADR-0004-kustomize-overlay-context.md)
- [ADR-0005: Architecture Context Overlays](docs/decisions/ADR-0005-architecture-context-overlays.md)
- [ADR-0006: platforms.yaml Configuration](docs/decisions/ADR-0006-platforms-yaml.md)
- [ADR-0007: component-map.json Intermediate Artifact](docs/decisions/ADR-0007-component-map-json.md)
- [ADR-0008: Pure Skill Invocation](docs/decisions/ADR-0008-pure-skill-invocation.md)
- [ADR-0009: Sub-Agent Dispatch](docs/decisions/ADR-0009-sub-agent-dispatch.md)
- [ADR-0010: arch-query Go CLI](docs/decisions/ADR-0010-arch-query-go-cli.md)
- [ADR-0011: rhoai.next Rolling Target](docs/decisions/ADR-0011-rhoai-next-rolling-target.md)
- [ADR-0012: Linting and CI](docs/decisions/ADR-0012-linting-and-ci.md)
- [ADR-0013: Webhook Inventory Phase](docs/decisions/ADR-0013-webhook-inventory-phase.md)
- [ADR-0014: Declarative exclude_files](docs/decisions/ADR-0014-exclude-files.md)
- [ADR-0015: Build Metadata Extraction](docs/decisions/ADR-0015-build-metadata-extraction.md)
- [ADR-0016: Image and Repo Provenance](docs/decisions/ADR-0016-image-and-repo-provenance.md)

## Notes

- [Agentic Work Ledger spec](docs/notes/agentic_work_ledger.md)
- [Architecture Diagram Requirements](docs/notes/architecture-diagram-requirements.md)
- [Webhook inventory](docs/notes/webhook-inventory.md)
- [Analyzer-Assisted Evaluation Contract](docs/notes/analyzer-assisted-evaluation-contract.md)
- [Analyzer-Assisted Corpus Baseline](docs/notes/analyzer-assisted-corpus-baseline.md)
- [Materialize INDEX.md Evaluation Artifact](docs/notes/materialize-index-evaluation-artifact.md)
- [Enable Combined Experiment Condition](docs/notes/enable-combined-experiment-condition.md)
- [Pin INDEX.md Experiment Artifact](docs/notes/pin-index-experiment-artifact.md)
- [Integrate Evaluation Context Telemetry](docs/notes/integrate-evaluation-context-telemetry.md)
- [Historical Feedback Package Provenance](docs/notes/historical-feedback-provenance.md)
- [No-Human-Data Provisional Rollout Track](docs/notes/no-human-data-provisional-rollout-track.md)
