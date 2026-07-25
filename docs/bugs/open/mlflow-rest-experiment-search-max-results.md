# MLflow REST experiment search omits required `max_results`

## Symptom

Against a real MLflow 2.22.0 tracking server, REST preflight succeeds but
`track_result()` fails during experiment lookup with HTTP 400:
`INVALID_PARAMETER_VALUE: Invalid value 0 for parameter 'max_results'`.

## Evidence

The live-server validation task
`docs/tasks/current/validate-mlflow-rest-registration-local.md` reproduced the
failure. `MLflowRESTClient.ping()` already sends `max_results: 1`;
`get_or_create_experiment()` does not. The mock server tests accept any search
body and therefore did not catch the defect.

## Expected fix

Send a positive bounded `max_results` value in the experiments/search request
and add a regression assertion that validates the request body and completes a
realistic REST tracking flow.

## Status

Closed on 2026-07-25. Added `"max_results": 10` to the search body in
`get_or_create_experiment()`. Regression test
`test_experiment_search_includes_positive_max_results` asserts the
request body includes a positive integer `max_results`. Full REST
end-to-end flow (preflight, track_result, read-back, cleanup) validated
against ephemeral MLflow 2.22.0 server. 95 tests pass. Accepted in the
scoped driver commit.
