# Task: Fix Consumer V1 Inventory Source Citations

## Goal

Close the resolved corpus-count bug and keep `benchmark/consumer-v1` valid
after generated architecture output stopped producing a top-level
`README.md` inventory.

## Bug

- `docs/bugs/fixed/corpus-v1-below-minimum-question-count.md`

## Scope

- Verify the corpus still has 40 questions with 10 per tier.
- Retarget stale Inventory source citations away from
  `architecture/rhoai.next/README.md`.
- Move the resolved corpus-count bug from `open/` to `fixed/`.

## Execution record

- `INV-003` now cites `architecture/rhoai.next/training-hub.md` for the
  InstructLab backend/dependency evidence.
- `INV-004` now cites `architecture/rhoai.next/model-registry.md`.
- `INV-005` now cites `architecture/rhoai.next/codeflare-sdk.md`.
- `INV-006` now cites
  `architecture/rhoai.next/llama-stack-provider-trustyai-garak.md` for the
  `sdg-hub` dependency evidence.

## Validation

```bash
python3 benchmark/consumer-v1/validate.py
```

Result: 40 questions validated, 10 per tier.

## Status

Completed 2026-07-28.
