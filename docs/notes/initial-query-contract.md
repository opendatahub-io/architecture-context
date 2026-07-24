# Initial Query Contract

`arch-query query` emits contract `v1` responses with query identity, argument
echoing, snapshot version, status, reason, evidence, and bounded result data.
Statuses are `ok`, `unknown`, and `not-extracted`.

The supported initial forms are:

```text
query callers-of --function X --package Y
query consumers-of --type X
query config-sources --component X
query crds --component X
query dependency-status --component X --release R
query diff --component X --from R1 --to R2
```

CRD and diff results reuse existing parsers and include architecture snapshot
evidence. Dependency facts are returned, but lifecycle status is explicitly
`unknown` when the snapshot has no release evidence. Callers, consumers, and
configuration sources return `not-extracted` until source-level extraction is
implemented; an empty result is never presented as proof of absence.
