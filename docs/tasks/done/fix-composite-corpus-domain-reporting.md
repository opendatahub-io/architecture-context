# Task: Fix Composite Corpus Domain Reporting

## Goal

Ensure composite benchmark reports separate architecture, pipeline, and SME
context results and use only architecture-domain rows as the primary tree
comparison.

## Changes

- Preserve per-question `domain` metadata during scoring.
- Add per-domain aggregates and report tables.
- Prefer explicit domains over `required_scope` for primary selection and
  regression classification.
- Retain the required-scope fallback for legacy consumer corpora.

## Status

Accepted 2026-07-31 after rescoring the 60-question rhoai.next versus backup
artifact with a corrected 40-question architecture primary bucket.
