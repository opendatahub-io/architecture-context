# Reviewed Overlay Contract

Correction proposal contract `v1` is a review boundary, not an authority
override. A proposal records the component, correction category, claim and
optional replacement, provenance, author, release applicability, dates,
review status, and supersession relationship. Supported statuses are
`pending`, `reviewed`, `rejected`, and `superseded`; `unknown` and
`not-extracted` are supported correction categories for explicit gaps.

`arch-query proposals generate` converts existing overlays to pending proposal
records without changing architecture output. `arch-query proposals validate`
validates a standalone proposal set. Generation sorts proposals by stable ID
and leaves `generated_at` empty by default; an explicit RFC3339 timestamp may
be supplied with `--generated-at`.

Missing source dates remain missing and fail proposal validation when required;
they are never replaced with a guessed historical date. Superseded overlays
are not emitted as active candidates.
