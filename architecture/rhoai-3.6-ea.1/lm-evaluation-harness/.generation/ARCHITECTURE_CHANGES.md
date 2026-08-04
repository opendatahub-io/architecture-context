# Architecture Changes: lm-evaluation-harness

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | Model serving endpoint | * | <empty> | <empty> | main.py builds OpenAI-compatible completions URLs and uses local-completions backend to call model serving endpoints for inference during evaluations | main.py:566-579, main.py:601-616 |
| add | internal_dependencies | EvalHub service | * | <empty> | <empty> | main.py imports evalhub.adapter SDK and implements FrameworkAdapter for job orchestration, status callbacks, and result reporting | main.py:228-241, main.py:619-643 |
