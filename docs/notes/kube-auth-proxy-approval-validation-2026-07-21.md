# kube-auth-proxy Approval Validation

Date: 2026-07-21

## Changes Made

### Go code changes (categorycoverage.go)

1. `isSupportOnlyShellScript()`: Added `contrib`, `completions`, `packaging`
   directory exclusions; extended `scripts/` to use runtime-role check;
   added `build`/`dist`/`make`/`package`/`release` basename exclusions;
   added `autocomplete`/`completion` basename pattern exclusions.

2. `runtimeShellScriptRole()`: Added `start_*`, `start-*`, `start` basename
   patterns for detecting runtime start scripts.

### Unit tests (categorycoverage_test.go)

6 new test functions:
- `TestIsSupportOnlyShellScriptContribDir`
- `TestIsSupportOnlyShellScriptScriptsDir`
- `TestIsSupportOnlyShellScriptBasenames`
- `TestIsSupportOnlyShellScriptHackDir`
- `TestIsSupportOnlyShellScriptDeployDir`
- `TestRuntimeShellScriptRoleStartPatterns`

### Adjudication entries (analyzer_correction_adjudications.json)

Source-audited empty categories:
- kube-auth-proxy `authentication`: auth proxy with no registered endpoints
- mlflow `internal_dependencies`: Kubernetes API is core infrastructure
- rhaii-cluster-validation `internal_dependencies`: K8s node access is core infrastructure

### Approval (analyzer_only_approvals.json)

Added `kube-auth-proxy` (51st approved component).

## Verification

### Go tests
```
go test ./... -count=1    # 12 packages, all pass
go vet ./...              # clean
```

### 90-component replay
```
90 extracted, 0 failures
```

### Eligibility check

kube-auth-proxy:
- `architecture_components`: not empty (has facts)
- `authentication`: empty in markdown → source-audited (auth proxy has no endpoints)
- `integration_points`: not empty (1 fact: Redis/Valkey)
- `internal_dependencies`: empty → complete-empty (status=complete, fact_count=0)
- Result: **eligible=True**

### Regression check

Zero regressions on 51 approved components. The 2 regressions discovered
during validation (mlflow, rhaii-cluster-validation) were fixed with
source-audited entries before final approval.

### Side-effect check

12 additional components became eligible from the shell script fix.
Not approved in this task — separate review required.

## Final counts

- 68 sufficient-readiness components
- 62 eligible (51 approved + 11 newly eligible awaiting approval)
- 51 approved
- 6 not eligible (bounded correction gaps)
