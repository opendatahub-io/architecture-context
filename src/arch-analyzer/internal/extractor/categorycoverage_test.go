package extractor

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestAuthenticationCoverageCompleteEmptyForNonServerPythonPackage(t *testing.T) {
	input := model.Input{
		DataCoverage: map[string]string{
			"manifests": "complete", "kustomize": "not_used",
			"source": "not_applicable", "rust": "not_applicable",
			"web_workspace": "not_applicable",
			"python":        "partial: package metadata and literal routes; dynamic composition unresolved",
		},
		Dependencies: model.Dependencies{Packages: []model.LanguagePackage{{Name: "numpy"}}},
	}

	got := authenticationCoverage(t.TempDir(), input)

	if got.Status != "complete" || got.FactCount != 0 || len(got.Limitations) != 0 {
		t.Fatalf("authentication coverage = %#v, want complete empty", got)
	}
}

func TestGRPCServicesCoverageCompleteEmptyWhenLiteralScanProvesAbsence(t *testing.T) {
	input := model.Input{DataCoverage: map[string]string{
		"source": "not_applicable",
		"python": "partial: protobuf service definitions; literal gRPC server registration scan: no runtime registration detected",
	}}

	got := categoryCoverage(t.TempDir(), input)["grpc_services"]
	if got.Status != "complete" || got.FactCount != 0 || len(got.Limitations) != 0 {
		t.Fatalf("gRPC coverage = %#v, want complete empty", got)
	}
}

func TestGRPCServicesCoverageRemainsPartialWithoutAbsenceProof(t *testing.T) {
	input := model.Input{DataCoverage: map[string]string{
		"source": "not_applicable",
		"python": "partial: protobuf service definitions; dynamic registration unresolved",
	}}

	got := categoryCoverage(t.TempDir(), input)["grpc_services"]
	if got.Status != "partial" || len(got.Limitations) == 0 {
		t.Fatalf("gRPC coverage = %#v, want unresolved partial coverage", got)
	}
}

func TestAuthenticationCoverageIgnoresDocsDirectoryInboundSurfaces(t *testing.T) {
	input := model.Input{
		DataCoverage: map[string]string{
			"source": "not_applicable", "python": "not_applicable",
			"rust": "not_applicable", "web_workspace": "not_applicable",
		},
		HTTPEndpoints: []model.HTTPEndpoint{
			{Path: "/health", Source: "docs/guides/e2e-deploy/modelserver/patch-vllm.yaml:1"},
		},
		Deployments: []model.Deployment{{
			Name: "decode", Source: "docs/guides/e2e-deploy/modelserver/patch-vllm.yaml:1",
			Containers: []model.Container{{
				LivenessProbe: &model.Probe{Path: "/health"},
			}},
		}},
	}
	coverage := authenticationCoverage(t.TempDir(), input)
	if coverage.Status != "complete" {
		t.Fatalf("coverage = %#v, docs/ directory surfaces must not block authentication completeness", coverage)
	}
}

func TestAuthenticationCoverageIgnoresTestOnlyInboundSurfaces(t *testing.T) {
	input := model.Input{
		DataCoverage: map[string]string{
			"source": "not_applicable", "python": "not_applicable",
			"rust": "not_applicable", "web_workspace": "not_applicable",
		},
		IngressRouting: []model.Ingress{{
			Name: "fixture", Source: "conformance/tests/route.yaml:1",
		}},
	}
	coverage := authenticationCoverage(t.TempDir(), input)
	if coverage.Status != "complete" {
		t.Fatalf("coverage = %#v, test-only ingress must not block authentication completeness", coverage)
	}
}

func TestAuthenticationCoverageAccountsForHTTPEndpointWithMatchingAuthFact(t *testing.T) {
	input := model.Input{
		DataCoverage: map[string]string{
			"source": "not_applicable", "python": "not_applicable",
			"rust": "not_applicable", "web_workspace": "not_applicable",
		},
		HTTPEndpoints: []model.HTTPEndpoint{
			{Path: "/healthz", Source: "internal/health/health.go:40"},
			{Path: "/readyz", Source: "internal/health/health.go:41"},
		},
		Authentication: []model.AuthenticationFact{
			{Endpoint: "/healthz", Methods: "HTTP", Mechanism: "platform-delegated", Source: "health.go:40"},
			{Endpoint: "/readyz", Methods: "HTTP", Mechanism: "platform-delegated", Source: "health.go:41"},
		},
	}
	coverage := authenticationCoverage(t.TempDir(), input)
	if strings.Contains(strings.Join(coverage.Limitations, "; "), "inbound runtime surfaces") {
		t.Fatalf("coverage = %#v, HTTP endpoints with matching auth facts should be accounted for", coverage)
	}
}

func TestAuthenticationCoveragePartialForHTTPEndpointWithoutAuthFact(t *testing.T) {
	input := model.Input{
		DataCoverage: map[string]string{},
		HTTPEndpoints: []model.HTTPEndpoint{
			{Path: "/healthz", Source: "internal/health/health.go:40"},
		},
	}
	coverage := authenticationCoverage(t.TempDir(), input)
	if !strings.Contains(strings.Join(coverage.Limitations, "; "), "inbound runtime surfaces") {
		t.Fatalf("coverage = %#v, HTTP endpoint without auth fact should remain as inbound surface", coverage)
	}
}

func TestAuthenticationCoverageCompletePopulatedWithoutInboundSurface(t *testing.T) {
	input := model.Input{
		DataCoverage: map[string]string{
			"manifests": "complete", "kustomize": "not_used",
			"source": "not_applicable", "python": "not_applicable",
			"rust": "not_applicable", "web_workspace": "not_applicable",
		},
		Authentication: []model.AuthenticationFact{{Endpoint: "outbound client"}},
	}

	got := authenticationCoverage(t.TempDir(), input)

	if got.Status != "complete" || got.FactCount != 1 {
		t.Fatalf("authentication coverage = %#v, want complete populated", got)
	}
}

func TestAuthenticationCoveragePartialForInboundAndUnsupportedSurfaces(t *testing.T) {
	tests := []struct {
		name  string
		input model.Input
		want  string
	}{
		{
			name: "inbound endpoint",
			input: model.Input{
				DataCoverage:  map[string]string{},
				HTTPEndpoints: []model.HTTPEndpoint{{Path: "/metrics", Source: "main.go:10"}},
			},
			want: "inbound runtime surfaces",
		},
		{
			name: "go source",
			input: model.Input{DataCoverage: map[string]string{
				"manifests": "complete", "kustomize": "not_used",
				"source": "partial: dynamic routes unresolved",
			}},
			want: "Go source authentication",
		},
		{
			name: "python server",
			input: model.Input{
				DataCoverage: map[string]string{
					"manifests": "complete", "kustomize": "not_used",
					"python": "partial: dependency injection unresolved",
				},
				Dependencies: model.Dependencies{Packages: []model.LanguagePackage{{Name: "fastapi"}}},
			},
			want: "Python server framework",
		},
		{
			name: "runtime manifest parse failure",
			input: model.Input{DataCoverage: map[string]string{
				"manifests": "partial: unparseable or templated YAML skipped during repository-wide discovery: deploy/api.yaml",
				"kustomize": "not_used",
			}},
			want: "manifest discovery is partial",
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			root := t.TempDir()
			if test.name == "python server" {
				mustWriteCoverageFile(t, root, "app.py", "from fastapi import FastAPI\napp = FastAPI()\n")
			}
			got := authenticationCoverage(root, test.input)
			if got.Status != "partial" || !strings.Contains(strings.Join(got.Limitations, "; "), test.want) {
				t.Fatalf("authentication coverage = %#v, want partial containing %q", got, test.want)
			}
		})
	}
}

func TestAuthenticationCoverageAccountsForRegisteredGRPCFactAndRetainsLimitations(t *testing.T) {
	input := model.Input{
		DataCoverage: map[string]string{
			"manifests": "complete", "kustomize": "not_used", "source": "not_applicable",
			"python": "not_applicable", "rust": "not_applicable", "web_workspace": "not_applicable",
		},
		GRPCServices: []model.GRPCService{{Service: "ExternalProcessor", Source: "server.go:10"}},
		Authentication: []model.AuthenticationFact{{
			Endpoint: "External Processor gRPC", Methods: "gRPC", Mechanism: "None", Source: "server.go:10",
		}},
	}
	got := authenticationCoverage(t.TempDir(), input)
	if got.Status != "complete" || strings.Contains(strings.Join(got.Limitations, "; "), "inbound runtime surfaces") {
		t.Fatalf("authentication coverage = %#v, exact gRPC fact should account for runtime surface", got)
	}

	input.GRPCServices[0].Limitation = "gRPC server options include unresolved interceptors or credentials"
	input.Authentication = nil
	got = authenticationCoverage(t.TempDir(), input)
	joined := strings.Join(got.Limitations, "; ")
	if got.Status != "partial" || !strings.Contains(joined, "unresolved interceptors or credentials") ||
		!strings.Contains(joined, "inbound runtime surfaces") {
		t.Fatalf("authentication coverage = %#v, unresolved reachable service must remain visible", got)
	}
}

func TestAuthenticationCoveragePartialForMixedExtractorSurfaces(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "client.py", "print('client')\n")
	input := model.Input{DataCoverage: map[string]string{
		"manifests": "complete", "kustomize": "not_used",
		"source": "partial: Go call graphs unresolved",
		"python": "partial: Python call graphs unresolved",
		"rust":   "not_applicable", "web_workspace": "not_applicable",
	}}

	got := authenticationCoverage(root, input)

	if got.Status != "partial" || !strings.Contains(strings.Join(got.Limitations, "; "), "Go source authentication") {
		t.Fatalf("authentication coverage = %#v, want mixed Go/Python partial result", got)
	}
	if !strings.Contains(strings.Join(got.CompletedChecks, "; "), "python-authentication-signal-scan") {
		t.Fatalf("completed checks = %#v, want applicable Python check to run", got.CompletedChecks)
	}
}

func TestAuthenticationCoverageIgnoresNonRuntimeManifestFailure(t *testing.T) {
	got := authenticationCoverage(t.TempDir(), model.Input{DataCoverage: map[string]string{
		"manifests": "partial: unparseable or templated YAML skipped during repository-wide discovery: .github/ISSUE_TEMPLATE/question.yml",
		"kustomize": "not_used",
	}})

	if got.Status != "complete" || len(got.Limitations) != 0 {
		t.Fatalf("authentication coverage = %#v, want irrelevant template ignored", got)
	}
}

func TestAuthenticationCoveragePartialForUnsupportedRuntimeLanguage(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "src/App.java", "class App {}\n")
	input := model.Input{DataCoverage: map[string]string{
		"manifests": "complete", "kustomize": "not_used",
		"source": "not_applicable", "python": "not_applicable",
		"rust": "not_applicable", "web_workspace": "not_applicable",
	}}

	got := authenticationCoverage(root, input)

	if got.Status != "partial" || !strings.Contains(strings.Join(got.Evidence, "; "), "App.java") {
		t.Fatalf("authentication coverage = %#v, want unsupported-language limitation", got)
	}
}

func TestAuthenticationCoverageCompleteWhenOnlyCredentialReferencesWithNoInbound(t *testing.T) {
	input := model.Input{
		DataCoverage: map[string]string{
			"manifests": "complete", "kustomize": "not_used",
			"source": "not_applicable", "python": "not_applicable",
			"rust": "not_applicable", "web_workspace": "not_applicable",
		},
		Secrets: []model.Secret{{Name: "OPENAI_API_KEY", Source: "app.py:12"}},
	}

	got := authenticationCoverage(t.TempDir(), input)

	if got.Status != "complete" {
		t.Fatalf("authentication coverage status = %q, want complete when only outbound credential references with no inbound surfaces", got.Status)
	}
	if strings.Contains(strings.Join(got.Limitations, "; "), "credential references") {
		t.Fatalf("authentication coverage limitations = %v, want no credential limitation when no inbound surfaces", got.Limitations)
	}
	if !strings.Contains(strings.Join(got.Evidence, "; "), "credential OPENAI_API_KEY") {
		t.Fatalf("authentication coverage evidence = %v, want credential evidence preserved for transparency", got.Evidence)
	}
}

func TestAuthenticationCoveragePartialForCredentialReferenceWithInbound(t *testing.T) {
	input := model.Input{
		DataCoverage: map[string]string{
			"manifests": "complete", "kustomize": "not_used",
			"source": "not_applicable", "python": "not_applicable",
			"rust": "not_applicable", "web_workspace": "not_applicable",
		},
		Secrets:       []model.Secret{{Name: "OPENAI_API_KEY", Source: "app.py:12"}},
		HTTPEndpoints: []model.HTTPEndpoint{{Path: "/api/v1/predict", Source: "server.py:50"}},
	}

	got := authenticationCoverage(t.TempDir(), input)

	if got.Status != "partial" || !strings.Contains(strings.Join(got.Limitations, "; "), "inbound runtime surfaces") {
		t.Fatalf("authentication coverage = %#v, want partial with inbound limitation (credential check skipped)", got)
	}
}

func TestAuthenticationCoverageAccountsForExtractedPythonAuthFacts(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "server/auth.py", `headers = {"Authorization": "Bearer " + key}`)
	input := model.Input{
		DataCoverage: map[string]string{
			"manifests": "complete", "kustomize": "not_used",
			"source": "not_applicable", "python": "partial: dynamic calls unresolved",
			"rust": "not_applicable", "web_workspace": "not_applicable",
		},
		Authentication: []model.AuthenticationFact{{
			Endpoint: "HTTP API", Mechanism: "Bearer token",
			EnforcementPoint: "ASGI middleware", Source: "server/auth.py:10",
		}},
		Dependencies: model.Dependencies{Packages: []model.LanguagePackage{{Name: "starlette"}}},
	}

	got := authenticationCoverage(root, input)

	joined := strings.Join(got.Limitations, "; ")
	if strings.Contains(joined, "Python authentication constructions require fact-level relationship accounting") {
		t.Fatalf("authentication coverage = %#v, want accounted signal to suppress fact-level limitation", got)
	}
	if strings.Contains(joined, "Python server framework is present") {
		t.Fatalf("authentication coverage = %#v, want language limitation suppressed with extracted facts", got)
	}
}

func TestAuthenticationCoverageNonBlockingUnaccountedSignalsWithNoInbound(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "server/auth.py", `headers = {"Authorization": "Bearer " + key}`)
	mustWriteCoverageFile(t, root, "client/api.py", `headers = {"Authorization": "Bearer " + token}`)
	input := model.Input{
		DataCoverage: map[string]string{
			"manifests": "complete", "kustomize": "not_used",
			"source": "not_applicable", "python": "partial: dynamic calls unresolved",
			"rust": "not_applicable", "web_workspace": "not_applicable",
		},
		Authentication: []model.AuthenticationFact{{
			Endpoint: "HTTP API", Mechanism: "Bearer token",
			EnforcementPoint: "ASGI middleware", Source: "server/auth.py:10",
		}},
		Dependencies: model.Dependencies{Packages: []model.LanguagePackage{{Name: "starlette"}}},
	}

	got := authenticationCoverage(root, input)

	if got.Status != "complete" {
		t.Fatalf("authentication coverage = %#v, want complete when no inbound surfaces", got)
	}
	joined := strings.Join(got.Evidence, "; ")
	if !strings.Contains(joined, "client/api.py") {
		t.Fatalf("evidence = %#v, want unaccounted signal still in evidence for transparency", got.Evidence)
	}
}

func TestAuthenticationCoverageCompleteForClientSideAuthWithNoInboundSurfaces(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "client.py", `headers = {"Authorization": "Bearer " + key}`)
	input := model.Input{DataCoverage: map[string]string{
		"manifests": "complete", "kustomize": "not_used",
		"source": "not_applicable", "python": "partial: dynamic calls unresolved",
		"rust": "not_applicable", "web_workspace": "not_applicable",
	}}

	got := authenticationCoverage(root, input)

	if got.Status != "complete" {
		t.Fatalf("authentication coverage = %#v, want complete when no inbound surfaces (client-side auth is non-blocking)", got)
	}
	if !strings.Contains(strings.Join(got.Evidence, "; "), "client.py") {
		t.Fatalf("evidence = %#v, want auth signal still in evidence for transparency", got.Evidence)
	}
}

func TestAuthenticationCoveragePartialForInboundSurfacesWithAuthSignals(t *testing.T) {
	input := model.Input{
		DataCoverage: map[string]string{
			"manifests": "complete", "kustomize": "not_used",
			"source": "not_applicable", "python": "partial: dynamic calls unresolved",
			"rust": "not_applicable", "web_workspace": "not_applicable",
		},
		HTTPEndpoints: []model.HTTPEndpoint{{Path: "/api/v1/predict", Source: "server.py:50"}},
	}

	got := authenticationCoverage(t.TempDir(), input)

	if got.Status != "partial" || !strings.Contains(strings.Join(got.Limitations, "; "), "inbound runtime surfaces") {
		t.Fatalf("authentication coverage = %#v, want partial for inbound surfaces (signal scan never reached)", got)
	}
}

func TestAuthenticationCoverageCompleteForSDKLibraryWithOutboundAuth(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "src/sdk/cluster.py", `
k8_client = get_api_client()
headers = {"Authorization": k8_client.configuration.get_api_key_with_prefix("authorization")}
`)
	input := model.Input{
		DataCoverage: map[string]string{
			"manifests": "complete", "kustomize": "not_used",
			"source": "not_applicable",
			"python": "partial: structured Python package metadata",
			"rust":   "not_applicable", "web_workspace": "not_applicable",
		},
		Dependencies: model.Dependencies{Packages: []model.LanguagePackage{{Name: "kubernetes"}}},
	}

	got := authenticationCoverage(root, input)

	if got.Status != "complete" || got.FactCount != 0 || len(got.Limitations) != 0 {
		t.Fatalf("authentication coverage = %#v, want complete for SDK library with only outbound auth", got)
	}
	if !strings.Contains(strings.Join(got.Evidence, "; "), "cluster.py") {
		t.Fatalf("evidence = %#v, want auth signal evidence retained even when non-blocking", got.Evidence)
	}
	if !strings.Contains(strings.Join(got.CompletedChecks, "; "), "no-inbound-runtime-surfaces") {
		t.Fatalf("completed checks = %#v, want no-inbound-runtime-surfaces", got.CompletedChecks)
	}
}

func TestInternalDependencyCoverageCompleteWhenBoundedAliasScanIsEmpty(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "src/main.py", "print('standalone')\n")
	mustWriteCoverageFile(t, root, "tests/test_main.py", "opendatahub.io\n")

	got := internalDependencyCoverage(root, model.Input{})

	if got.Status != "complete" || got.FactCount != 0 || len(got.Limitations) != 0 {
		t.Fatalf("internal coverage = %#v, want complete empty", got)
	}
	if len(got.Evidence) == 0 || !strings.Contains(got.Evidence[0], "scanned 1") {
		t.Fatalf("evidence = %#v, want bounded scan summary", got.Evidence)
	}
}

func TestInternalDependencyCoverageIgnoresStructuredBenchmarkCorpus(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "lm_eval/tasks/history/prompt.json", `{"question":"Describe a volcano"}`)
	mustWriteCoverageFile(t, root, "lm_eval/tasks/history/runner.py", "VOLCANO_API = 'runtime reference'\n")

	got := internalDependencyCoverage(root, model.Input{})

	if got.Status != "partial" {
		t.Fatalf("internal coverage = %#v, want source code scanned and corpus data ignored", got)
	}
	joined := strings.Join(got.Evidence, "; ")
	if strings.Contains(joined, "prompt.json") || !strings.Contains(joined, "runner.py") {
		t.Fatalf("evidence = %#v, want only source-code alias match", got.Evidence)
	}
}

func TestInternalDependencyCoveragePartialWhenPlatformAliasIsUnaccounted(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "src/client.go", "const PlatformAPI = \"serving.kserve.io\"\n")

	got := internalDependencyCoverage(root, model.Input{})

	if got.Status != "partial" || len(got.Limitations) == 0 {
		t.Fatalf("internal coverage = %#v, want partial alias limitation", got)
	}
	if len(got.Evidence) < 2 || !strings.Contains(got.Evidence[1], "src/client.go") {
		t.Fatalf("evidence = %#v, want matching source", got.Evidence)
	}
}

func TestInternalDependencyCoverageClassifiesCommentedKustomizeAliasAsNegative(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "config/default/kustomization.yaml", `resources:
- manager.yaml
# - certificate.yaml
# group: cert-manager.io
`)

	got := internalDependencyCoverage(root, model.Input{DataCoverage: map[string]string{
		"manifests": "complete",
		"kustomize": "partial: image transforms not resolved",
	}})

	if got.Status != "complete" || len(got.Limitations) != 0 {
		t.Fatalf("internal coverage = %#v, want complete commented negative", got)
	}
	if !strings.Contains(strings.Join(got.Evidence, "; "), "cert-manager.io; commented configuration") {
		t.Fatalf("evidence = %#v, want classified comment", got.Evidence)
	}
}

func TestInternalDependencyCoverageKeepsSelectedManifestAliasPartial(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "deploy/role.yaml", `apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
rules:
- apiGroups: ["serving.kserve.io"]
`)
	input := model.Input{
		DataCoverage: map[string]string{"manifests": "complete", "kustomize": "complete"},
		RBAC: model.RBAC{ClusterRoles: []model.Role{{
			Name: "manager", Source: "deploy/role.yaml",
		}}},
	}

	got := internalDependencyCoverage(root, input)

	if got.Status != "partial" || !strings.Contains(strings.Join(got.Evidence, "; "), "selected manifest relationship") {
		t.Fatalf("internal coverage = %#v, want selected relationship limitation", got)
	}
}

func TestInternalDependencyCoverageAcceptsAccountedSelectedManifestAlias(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "deploy/role.yaml", `apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
rules:
- apiGroups: ["serving.kserve.io"]
`)
	input := model.Input{
		DataCoverage: map[string]string{"manifests": "complete", "kustomize": "complete"},
		RBAC: model.RBAC{ClusterRoles: []model.Role{{
			Name: "manager", Source: "deploy/role.yaml",
		}}},
		Dependencies: model.Dependencies{Internal: []model.InternalDependency{{
			Component: "KServe InferenceService", Source: "deploy/role.yaml",
		}}},
	}

	got := internalDependencyCoverage(root, input)

	if got.Status != "complete" || got.FactCount != 1 {
		t.Fatalf("internal coverage = %#v, want complete accounted relationship", got)
	}
}

func TestInternalDependencyCoverageTreatsDependencyImportAsNegative(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "src/client.go", `package client
import "github.com/opendatahub-io/odh-platform-utilities/pkg/cluster"
`)

	got := internalDependencyCoverage(root, model.Input{})

	if got.Status != "complete" || !strings.Contains(strings.Join(got.Evidence, "; "), "dependency declaration") {
		t.Fatalf("internal coverage = %#v, want import-only negative", got)
	}
}

func TestInternalDependencyCoverageTreatsOwnedAPIAsNegative(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "api/types.go", `package api
const Group = "trustyai.opendatahub.io"
`)
	input := model.Input{CRDs: []model.CRD{{Group: "trustyai.opendatahub.io", Kind: "TrustyAIService"}}}

	got := internalDependencyCoverage(root, input)

	if got.Status != "complete" || !strings.Contains(strings.Join(got.Evidence, "; "), "self-owned API") {
		t.Fatalf("internal coverage = %#v, want self-owned API negative", got)
	}
}

func TestInternalDependencyCoverageTreatsUnusedGVKDeclarationAsNegative(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "internal/gvk/gvk.go", `package gvk
import "k8s.io/apimachinery/pkg/runtime/schema"
var Notebook = schema.GroupVersionKind{Group: "kubeflow.org", Version: "v1", Kind: "Notebook"}
`)

	got := internalDependencyCoverage(root, model.Input{})

	if got.Status != "complete" || !strings.Contains(strings.Join(got.Evidence, "; "), "unused GVK declaration") {
		t.Fatalf("internal coverage = %#v, want unused GVK negative", got)
	}
}

func TestInternalDependencyCoverageKeepsUsedGVKDeclarationPartial(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "internal/gvk/gvk.go", `package gvk
import "k8s.io/apimachinery/pkg/runtime/schema"
var Notebook = schema.GroupVersionKind{Group: "kubeflow.org", Version: "v1", Kind: "Notebook"}
`)
	mustWriteCoverageFile(t, root, "internal/controller/controller.go", `package controller
import "example.test/internal/gvk"
var notebook = gvk.Notebook
`)

	got := internalDependencyCoverage(root, model.Input{})

	if got.Status != "partial" || !strings.Contains(strings.Join(got.Evidence, "; "), "runtime source/config reference") {
		t.Fatalf("internal coverage = %#v, want used GVK unresolved", got)
	}
}

func TestInternalDependencyCoverageExcludesMockAndSampleDirectories(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "k8mocks/base_testenv.go", `package k8mocks
const API = "kubeflow.org"
`)
	mustWriteCoverageFile(t, root, "__mocks__/mockModelRegistryKind.ts", `export const group = "modelregistry.opendatahub.io"`)
	mustWriteCoverageFile(t, root, "cmd/csi/samples/sample_job.yaml", `apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
`)

	got := internalDependencyCoverage(root, model.Input{})

	if got.Status != "complete" || len(got.Limitations) != 0 {
		t.Fatalf("internal coverage = %#v, want mock/sample directories excluded", got)
	}
}

func TestInternalDependencyCoverageClassifiesSubdomainAliasAsNonBlocking(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "cmd/controller/main.go", `package main
const leaderElectionID = "modelregistry.kubeflow.org"
func main() {
    labels := map[string]string{"modelregistry.kubeflow.org/component": "controller"}
}
`)

	got := internalDependencyCoverage(root, model.Input{})

	if got.Status != "complete" || len(got.Limitations) != 0 {
		t.Fatalf("internal coverage = %#v, want subdomain alias non-blocking", got)
	}
	if !strings.Contains(strings.Join(got.Evidence, "; "), "naming convention (subdomain)") {
		t.Fatalf("evidence = %#v, want subdomain classification", got.Evidence)
	}
}

func TestInternalDependencyCoverageKeepsStandaloneAliasBlocking(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "src/client.go", `package client
const API = "kubeflow.org"
`)

	got := internalDependencyCoverage(root, model.Input{})

	if got.Status != "partial" || len(got.Limitations) == 0 {
		t.Fatalf("internal coverage = %#v, want standalone alias blocking", got)
	}
}

func TestInternalDependencyCoverageClassifiesGoIdentifierAliasAsNonBlocking(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "internal/settings/handler.go", `package settings
type GatewayConfig struct {
    Domain string
}
func handleGatewayConfig(cfg *GatewayConfig) {}
`)

	got := internalDependencyCoverage(root, model.Input{})

	if got.Status != "complete" || len(got.Limitations) != 0 {
		t.Fatalf("internal coverage = %#v, want Go identifier alias non-blocking", got)
	}
	if !strings.Contains(strings.Join(got.Evidence, "; "), "naming convention (Go identifier)") {
		t.Fatalf("evidence = %#v, want Go identifier classification", got.Evidence)
	}
}

func TestInternalDependencyCoverageKeepsGoStringLiteralAliasBlocking(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "internal/settings/handler.go", `package settings
const configGroup = "gatewayconfig"
`)

	got := internalDependencyCoverage(root, model.Input{})

	if got.Status != "partial" || len(got.Limitations) == 0 {
		t.Fatalf("internal coverage = %#v, want string literal alias blocking", got)
	}
}

func TestInternalDependencyCoverageExcludesSupportScriptsButRetainsRuntimeScripts(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, ".devcontainer/post-install.sh", "echo setup\n")
	mustWriteCoverageFile(t, root, "hack/mkdocs/image/entrypoint.sh", "echo docs\n")
	mustWriteCoverageFile(t, root, "deploy/ci-e2e-openshift/deploy-infrastructure.sh", "echo test\n")
	mustWriteCoverageFile(t, root, "hack/deploy-hook.sh", "echo deploy\n")
	mustWriteCoverageFile(t, root, "deploy/operator/entrypoint.sh", "echo runtime\n")

	got := internalDependencyCoverage(root, model.Input{})

	joined := strings.Join(got.Evidence, "; ")
	if got.Status != "partial" || !strings.Contains(joined, "hack/deploy-hook.sh") ||
		!strings.Contains(joined, "deploy/operator/entrypoint.sh") {
		t.Fatalf("internal coverage = %#v, want runtime deployment scripts retained", got)
	}
	if strings.Contains(joined, ".devcontainer") || strings.Contains(joined, "mkdocs") || strings.Contains(joined, "ci-e2e") {
		t.Fatalf("evidence = %#v, want support scripts excluded", got.Evidence)
	}
}

func TestInternalDependencyCoverageKeepsRelationshipChangingKustomizeWarning(t *testing.T) {
	input := model.Input{DataCoverage: map[string]string{
		"manifests": "complete",
		"kustomize": "partial: image transforms not resolved; remote resources skipped",
	}}

	got := internalDependencyCoverage(t.TempDir(), input)

	joined := strings.Join(got.Limitations, "; ")
	if got.Status != "partial" || strings.Contains(joined, "image transforms") || !strings.Contains(joined, "remote resources") {
		t.Fatalf("internal coverage = %#v, want only relationship-changing warning", got)
	}
}

func TestInternalDependencyCoveragePartialForUnsupportedRuntimeLanguage(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "src/Client.kt", "class Client\n")

	got := internalDependencyCoverage(root, model.Input{})

	if got.Status != "partial" || !strings.Contains(strings.Join(got.Evidence, "; "), "Client.kt") {
		t.Fatalf("internal coverage = %#v, want unsupported-language limitation", got)
	}
}

func TestInternalDependencyCoveragePartialForRuntimeManifestFailure(t *testing.T) {
	input := model.Input{DataCoverage: map[string]string{
		"manifests": "partial: unparseable or templated YAML skipped during repository-wide discovery: deploy/api.yaml",
		"kustomize": "not_used",
	}}

	got := internalDependencyCoverage(t.TempDir(), input)

	if got.Status != "partial" || !strings.Contains(strings.Join(got.Limitations, "; "), "manifest discovery is partial") {
		t.Fatalf("internal coverage = %#v, want manifest limitation", got)
	}
}

func TestInternalDependencyCoverageCompletePopulatedWithoutUnresolvedAlias(t *testing.T) {
	root := t.TempDir()
	input := model.Input{Dependencies: model.Dependencies{Internal: []model.InternalDependency{{
		Component: "platform-api", Source: "generated inventory",
	}}}}

	got := internalDependencyCoverage(root, input)

	if got.Status != "complete" || got.FactCount != 1 {
		t.Fatalf("internal coverage = %#v, want complete populated", got)
	}
}

func TestIntegrationPointsCoverageCompleteEmptyStandaloneService(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "src/main.rs", "fn main() { println!(\"server\"); }\n")
	input := model.Input{
		DataCoverage: map[string]string{
			"manifests": "complete", "kustomize": "not_used",
			"source": "not_applicable", "python": "not_applicable",
			"rust": "partial: routes resolved", "web_workspace": "not_applicable",
		},
	}

	got := integrationPointsCoverage(root, input)

	if got.Status != "complete" || got.FactCount != 0 || len(got.Limitations) != 0 {
		t.Fatalf("integration points coverage = %#v, want complete empty for standalone service", got)
	}
	if got.DiscoveryContract != "integration-points/v1" {
		t.Fatalf("discovery contract = %q, want integration-points/v1", got.DiscoveryContract)
	}
}

func TestIntegrationPointsCoveragePartialForUnaccountedOutboundHTTPClient(t *testing.T) {
	input := model.Input{
		RuntimeClients: []model.RuntimeClient{
			{Target: "PostgreSQL", Client: "pgxpool.Pool", Source: "cmd/main.go:45"},
		},
	}

	got := integrationPointsCoverage(t.TempDir(), input)

	if got.Status != "partial" || !strings.Contains(strings.Join(got.Limitations, "; "), "outbound runtime client") {
		t.Fatalf("integration points coverage = %#v, want partial for unaccounted client", got)
	}
}

func TestIntegrationPointsCoverageCompleteWhenClientsAreAccountedFor(t *testing.T) {
	input := model.Input{
		RuntimeClients: []model.RuntimeClient{
			{Target: "Redis", Client: "go-redis", Source: "cmd/main.go:50"},
		},
		IntegrationPoints: []model.IntegrationFact{
			{Component: "Redis", InteractionType: "data caching", Protocol: "Redis"},
		},
	}

	got := integrationPointsCoverage(t.TempDir(), input)

	if got.Status != "complete" || got.FactCount != 1 {
		t.Fatalf("integration points coverage = %#v, want complete with accounted client", got)
	}
	if !strings.Contains(strings.Join(got.CompletedChecks, "; "), "outbound-runtime-client-accounting") {
		t.Fatalf("completed checks = %#v, want outbound-runtime-client-accounting", got.CompletedChecks)
	}
}

func TestIntegrationPointsCoveragePartialForUnaccountedExternalConnection(t *testing.T) {
	input := model.Input{
		ExternalConnections: []model.ExternalConnection{
			{Service: "Prometheus", Target: "/metrics", Protocol: "HTTP", Source: "pkg/server.go:12"},
		},
	}

	got := integrationPointsCoverage(t.TempDir(), input)

	if got.Status != "partial" || !strings.Contains(strings.Join(got.Limitations, "; "), "external connections") {
		t.Fatalf("integration points coverage = %#v, want partial for unaccounted external connection", got)
	}
}

func TestIntegrationPointsCoverageCompleteWhenExternalConnectionsAccountedFor(t *testing.T) {
	input := model.Input{
		ExternalConnections: []model.ExternalConnection{
			{Service: "Prometheus", Target: "/metrics", Protocol: "HTTP", Source: "pkg/server.go:12"},
		},
		IntegrationPoints: []model.IntegrationFact{
			{Component: "Prometheus", InteractionType: "metrics scraping", Protocol: "HTTP"},
		},
	}

	got := integrationPointsCoverage(t.TempDir(), input)

	if got.Status != "complete" || got.FactCount != 1 {
		t.Fatalf("integration points coverage = %#v, want complete with accounted connection", got)
	}
}

func TestIntegrationPointsCoveragePartialForUnsupportedLanguage(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "src/Client.java", "class Client {}\n")

	got := integrationPointsCoverage(root, model.Input{})

	if got.Status != "partial" || !strings.Contains(strings.Join(got.Evidence, "; "), "Client.java") {
		t.Fatalf("integration points coverage = %#v, want unsupported-language limitation", got)
	}
}

func TestIntegrationPointsCoveragePartialForManifestParseFailure(t *testing.T) {
	input := model.Input{DataCoverage: map[string]string{
		"manifests": "partial: unparseable or templated YAML skipped during repository-wide discovery: deploy/api.yaml",
		"kustomize": "not_used",
	}}

	got := integrationPointsCoverage(t.TempDir(), input)

	if got.Status != "partial" || !strings.Contains(strings.Join(got.Limitations, "; "), "manifest discovery is partial") {
		t.Fatalf("integration points coverage = %#v, want manifest parse failure limitation", got)
	}
}

func TestIntegrationPointsCoverageIgnoresTestOnlyClient(t *testing.T) {
	input := model.Input{
		RuntimeClients: []model.RuntimeClient{
			{Target: "PostgreSQL", Client: "pgxpool.Pool", Source: "tests/integration/db_test.go:10"},
		},
	}

	got := integrationPointsCoverage(t.TempDir(), input)

	if got.Status != "complete" || len(got.Limitations) != 0 {
		t.Fatalf("integration points coverage = %#v, want test-only client filtered", got)
	}
}

func TestIntegrationPointsCoverageIgnoresExampleOnlyConnection(t *testing.T) {
	input := model.Input{
		ExternalConnections: []model.ExternalConnection{
			{Service: "MinIO", Target: "s3:9000", Protocol: "S3", Source: "examples/demo/main.go:30"},
		},
	}

	got := integrationPointsCoverage(t.TempDir(), input)

	if got.Status != "complete" || len(got.Limitations) != 0 {
		t.Fatalf("integration points coverage = %#v, want example-only connection filtered", got)
	}
}

func TestIntegrationPointsCoveragePartialForDynamicEndpointDispatch(t *testing.T) {
	input := model.Input{
		RuntimeClients: []model.RuntimeClient{
			{Target: "dynamic-service", Client: "http.Client", Source: "pkg/proxy.go:88"},
		},
	}

	got := integrationPointsCoverage(t.TempDir(), input)

	if got.Status != "partial" || !strings.Contains(strings.Join(got.Limitations, "; "), "outbound runtime client") {
		t.Fatalf("integration points coverage = %#v, want partial for dynamic dispatch", got)
	}
}

func TestIsSupportOnlyShellScriptContribDir(t *testing.T) {
	if !isSupportOnlyShellScript("contrib/oauth2-proxy_autocomplete.sh") {
		t.Error("contrib/ shell scripts should be support-only")
	}
}

func TestIsSupportOnlyShellScriptScriptsDir(t *testing.T) {
	for _, tc := range []struct {
		path string
		want bool
	}{
		{"scripts/fmt.sh", true},
		{"scripts/check_deps.sh", true},
		{"scripts/keycloak_aws_instance.sh", true},
		{"scripts/publish.sh", true},
		{"scripts/entrypoint.sh", false},
		{"scripts/deploy.sh", false},
		{"scripts/start_server.sh", false},
		{"scripts/startup.sh", false},
	} {
		got := isSupportOnlyShellScript(tc.path)
		if got != tc.want {
			t.Errorf("isSupportOnlyShellScript(%q) = %v, want %v", tc.path, got, tc.want)
		}
	}
}

func TestIsSupportOnlyShellScriptBasenames(t *testing.T) {
	for _, tc := range []struct {
		path string
		want bool
	}{
		{"dist.sh", true},
		{"build.sh", true},
		{"make.sh", true},
		{"release.sh", true},
		{"oauth2_autocomplete.sh", true},
		{"bash_completion.sh", true},
		{"build_rust.sh", true},
		{"build_vllm_ppc64le.sh", true},
		{"build-image.sh", true},
		{"run.sh", false},
		{"entrypoint.sh", false},
		{"deploy.sh", false},
	} {
		got := isSupportOnlyShellScript(tc.path)
		if got != tc.want {
			t.Errorf("isSupportOnlyShellScript(%q) = %v, want %v", tc.path, got, tc.want)
		}
	}
}

func TestIsSupportOnlyShellScriptTasksDir(t *testing.T) {
	for _, tc := range []struct {
		path string
		want bool
	}{
		{"lm_eval/tasks/afrimgsm/gen_yaml.sh", true},
		{"lm_eval/tasks/afrimgsm/run.sh", true},
		{"lm_eval/tasks/afrimmlu/fewshot.sh", true},
		{"lm_eval/tasks/score/non_greedy.sh", true},
		{"tasks/deploy.sh", false},
		{"tasks/entrypoint.sh", false},
		{"tasks/startup.sh", false},
	} {
		got := isSupportOnlyShellScript(tc.path)
		if got != tc.want {
			t.Errorf("isSupportOnlyShellScript(%q) = %v, want %v", tc.path, got, tc.want)
		}
	}
}

func TestIsSupportOnlyShellScriptToolsDir(t *testing.T) {
	for _, tc := range []struct {
		path string
		want bool
	}{
		{"tools/install_protoc.sh", true},
		{"tools/flashinfer-build.sh", true},
		{"tools/check_repo.sh", true},
		{"tools/pre_commit/png-lint.sh", true},
		{"tools/deploy.sh", false},
		{"tools/entrypoint.sh", false},
	} {
		got := isSupportOnlyShellScript(tc.path)
		if got != tc.want {
			t.Errorf("isSupportOnlyShellScript(%q) = %v, want %v", tc.path, got, tc.want)
		}
	}
}

func TestIsSupportOnlyShellScriptGitHooks(t *testing.T) {
	for _, tc := range []struct {
		path string
		want bool
	}{
		{"hooks/pre-commit.sh", true},
		{"pre-commit.sh", true},
		{".githooks/commit-msg.sh", true},
		{"pre-push.sh", true},
		{"hooks/deploy-hook.sh", false},
	} {
		got := isSupportOnlyShellScript(tc.path)
		if got != tc.want {
			t.Errorf("isSupportOnlyShellScript(%q) = %v, want %v", tc.path, got, tc.want)
		}
	}
}

func TestIsSupportOnlyShellScriptHackDir(t *testing.T) {
	if !isSupportOnlyShellScript("hack/build.sh") {
		t.Error("hack/build.sh should be support-only")
	}
	if isSupportOnlyShellScript("hack/deploy.sh") {
		t.Error("hack/deploy.sh has runtime role, should NOT be support-only")
	}
}

func TestIsSupportOnlyShellScriptDeployDir(t *testing.T) {
	if isSupportOnlyShellScript("deploy/install.sh") {
		t.Error("deploy/install.sh has runtime directory, should NOT be support-only")
	}
}

func TestRuntimeShellScriptRoleStartPatterns(t *testing.T) {
	for _, tc := range []struct {
		path string
		want bool
	}{
		{"scripts/start_server.sh", true},
		{"scripts/start-mcp.sh", true},
		{"scripts/start.sh", true},
		{"scripts/startup.sh", true},
		{"scripts/fmt.sh", false},
		{"scripts/check_deps.sh", false},
	} {
		parts := strings.Split(strings.ToLower(tc.path), "/")
		got := runtimeShellScriptRole(parts)
		if got != tc.want {
			t.Errorf("runtimeShellScriptRole(%q) = %v, want %v", tc.path, got, tc.want)
		}
	}
}

func TestIsSupportOnlyNativeSource(t *testing.T) {
	for _, tc := range []struct {
		path string
		want bool
	}{
		{"scripts/clean_training_data/janitor_util.cpp", true},
		{"hack/tools/parser.c", true},
		{"ci/build/helper.hpp", true},
		{"tasks/data/processor.cpp", true},
		{"contrib/utils/format.h", true},
		{"src/server.cpp", false},
		{"pkg/storage/backend.cpp", false},
		{"internal/handler.c", false},
	} {
		got := isSupportOnlyNativeSource(tc.path)
		if got != tc.want {
			t.Errorf("isSupportOnlyNativeSource(%q) = %v, want %v", tc.path, got, tc.want)
		}
	}
}

func TestIgnoredCoverageDirCsrc(t *testing.T) {
	if !ignoredCoverageDir("csrc") {
		t.Error("ignoredCoverageDir(csrc) = false, want true — native extension source directory")
	}
}

func TestUnsupportedRuntimeSourceExcludesCsrcAndSupportDirs(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "csrc/storage/backend.cpp", "void store() {}\n")
	mustWriteCoverageFile(t, root, "csrc/attention/kernel.h", "int compute();\n")
	mustWriteCoverageFile(t, root, "scripts/clean/janitor.cpp", "#include <string>\n")
	mustWriteCoverageFile(t, root, "src/main.py", "print('hello')\n")

	got := unsupportedRuntimeSourceSurfaces(root)

	for _, evidence := range got {
		if strings.Contains(evidence, "csrc/") || strings.Contains(evidence, "scripts/") {
			t.Fatalf("unsupported surfaces = %v, want csrc/ and scripts/ C++ files excluded", got)
		}
	}
}

func TestUnsupportedRuntimeSourceRetainsNonSupportDirCpp(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "pkg/storage/backend.cpp", "void store() {}\n")

	got := unsupportedRuntimeSourceSurfaces(root)

	if len(got) == 0 || !strings.Contains(got[0], "backend.cpp") {
		t.Fatalf("unsupported surfaces = %v, want non-support-dir C++ file retained", got)
	}
}

func TestIgnoredCoverageDirBuildkite(t *testing.T) {
	if !ignoredCoverageDir(".buildkite") {
		t.Error("ignoredCoverageDir(.buildkite) = false, want true — CI pipeline directory")
	}
}

func TestIgnoredCoverageDirBenchmarks(t *testing.T) {
	if !ignoredCoverageDir("benchmarks") {
		t.Error("ignoredCoverageDir(benchmarks) = false, want true — benchmark directory")
	}
}

func TestExpandSupplementalAuthWildcardGRPC(t *testing.T) {
	services := []model.GRPCService{
		{Service: "inference.GRPCInferenceService/ModelInfer", Source: "proto/dataplane.proto:32"},
		{Service: "ModelRepositoryService", Source: "mlserver/grpc/server.py:84"},
	}
	supplemental := []model.AuthenticationFact{{
		Endpoint:         "*",
		Methods:          "gRPC",
		Mechanism:        "kube-rbac-proxy sidecar (platform-delegated)",
		EnforcementPoint: "KServe pod",
		Source:           "platform-delegated:kube-rbac-proxy",
	}}

	result := expandSupplementalAuth(services, supplemental)

	if len(result) != 2 {
		t.Fatalf("expandSupplementalAuth returned %d facts, want 2", len(result))
	}
	if result[0].Endpoint != "inference.GRPCInferenceService/ModelInfer" {
		t.Errorf("result[0].Endpoint = %q, want service name", result[0].Endpoint)
	}
	if result[0].Mechanism != "kube-rbac-proxy sidecar (platform-delegated)" {
		t.Errorf("result[0].Mechanism = %q, want kube-rbac-proxy", result[0].Mechanism)
	}
	if result[1].Endpoint != "ModelRepositoryService" {
		t.Errorf("result[1].Endpoint = %q, want service name", result[1].Endpoint)
	}
}

func TestExpandSupplementalAuthPassthroughNonWildcard(t *testing.T) {
	supplemental := []model.AuthenticationFact{{
		Endpoint:  "specific-service",
		Methods:   "gRPC",
		Mechanism: "mTLS",
		Source:    "manual",
	}}

	result := expandSupplementalAuth(nil, supplemental)

	if len(result) != 1 || result[0].Endpoint != "specific-service" {
		t.Fatalf("non-wildcard fact should pass through unchanged, got %v", result)
	}
}

func TestAuthenticationCoverageCompleteWithSupplementalGRPCAuth(t *testing.T) {
	services := []model.GRPCService{
		{Service: "inference.GRPCInferenceService/ModelInfer", Source: "proto/dataplane.proto:32"},
		{Service: "GRPCInferenceService", Source: "mlserver/grpc/server.py:81"},
	}
	supplemental := []model.AuthenticationFact{{
		Endpoint: "*", Methods: "gRPC",
		Mechanism: "kube-rbac-proxy sidecar (platform-delegated)",
		Source:    "platform-delegated:kube-rbac-proxy",
	}}
	expanded := expandSupplementalAuth(services, supplemental)

	input := model.Input{
		DataCoverage: map[string]string{
			"manifests": "complete", "kustomize": "not_used",
			"source": "not_applicable",
			"python": "partial: structured Python package metadata",
			"rust":   "not_applicable", "web_workspace": "not_applicable",
		},
		GRPCServices:   services,
		Authentication: expanded,
	}

	got := authenticationCoverage(t.TempDir(), input)

	if strings.Contains(strings.Join(got.Limitations, "; "), "inbound runtime surfaces") {
		t.Fatalf("authentication coverage = %#v, supplemental auth should account for all gRPC surfaces", got)
	}
	if got.FactCount != 2 {
		t.Errorf("fact_count = %d, want 2 (one per gRPC service)", got.FactCount)
	}
}

func mustWriteCoverageFile(t *testing.T, root, relative, content string) {
	t.Helper()
	path := filepath.Join(root, filepath.FromSlash(relative))
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}
