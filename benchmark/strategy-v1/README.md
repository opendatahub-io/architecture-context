# Strategy v1 Corpus

This is a composite 60-question corpus for evaluating strategy-oriented
consumers. It is separate from the 40-question architecture-only
`benchmark/consumer-v1/corpus.json` contract.

Each question has a `domain` field:

- `architecture`: the 40 architecture-context questions carried forward from
  `consumer-v1`.
- `pipeline`: deterministic `strat-creator` skill and workflow questions.
- `sme-context`: questions grounded in Jira and SME feedback.

The `pipeline` questions require a pinned `strat-creator` skill snapshot. The
`sme-context` questions require dated Jira/SME exports or another immutable
source artifact. Their `source_file` values identify those external sources;
they are not expected to resolve as files in this repository.

Scores must be reported by domain. A composite score is optional and must not
be compared with the architecture-only `consumer-v1` score.

The architecture questions are snapshot-relative when `rhoai.next` is
compared with `rhoai.next.bak`. Inventory values, deployment labels, and CRD
scopes may legitimately differ between the two documented trees; the corpus
enumerates the accepted value for each pinned snapshot instead of treating
that drift as a generation regression. Questions about a component with
multiple documented artifacts must name the specific service or operator.

The existing `benchmark/consumer-v1` runner does not load this corpus. A
strategy-specific runner and validator are required before this corpus is used
for reproducible evaluation. The rhoai tree comparison wrapper supports
`--all-domains` as an explicit diagnostic mode, but its architecture-only
access boundary cannot provide the external strategy/Jira context required by
the non-architecture questions.
