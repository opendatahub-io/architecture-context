package pythonsource

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
	"github.com/jctanner/arch-analyzer/scripts"
)

type ImportAnalysis struct {
	Status            string                           `json:"status,omitempty"`
	Used              []ImportedPackage                `json:"used"`
	TestOnly          []string                         `json:"test_only"`
	DeclaredUnused    []string                         `json:"declared_unused"`
	OptionalGroups    map[string]OptionalGroupAnalysis `json:"optional_groups"`
	GRPCServer        bool                             `json:"grpc_server"`
	GRPCRegistrations []GRPCRegistration               `json:"grpc_registrations"`
}

type ImportedPackage struct {
	Package string   `json:"package"`
	Imports []string `json:"imports"`
	Source  string   `json:"source"`
}

type OptionalGroupAnalysis struct {
	Used   []string `json:"used"`
	Unused []string `json:"unused"`
}

type GRPCRegistration struct {
	Servicer string `json:"servicer"`
	Source   string `json:"source"`
}

func extractImportAnalysis(root string) *ImportAnalysis {
	script, err := os.CreateTemp("", "python_import_analyzer*.py")
	if err != nil {
		return nil
	}
	defer os.Remove(script.Name())
	if _, err := script.WriteString(scripts.PythonImportAnalyzer); err != nil {
		script.Close()
		return nil
	}
	script.Close()

	output, err := exec.Command("python3", script.Name(), root).Output()
	if err != nil {
		return nil
	}

	var result ImportAnalysis
	if err := json.Unmarshal(output, &result); err != nil {
		return nil
	}
	if result.Status == "no_dependencies_found" {
		return nil
	}
	return &result
}

func importAnalysisGRPCServices(analysis *ImportAnalysis) []model.GRPCService {
	if analysis == nil || !analysis.GRPCServer {
		return nil
	}
	seen := map[string]bool{}
	var result []model.GRPCService
	for _, reg := range analysis.GRPCRegistrations {
		name := strings.TrimSuffix(reg.Servicer, "Servicer")
		if seen[name] {
			continue
		}
		seen[name] = true
		result = append(result, model.GRPCService{
			Service:  name,
			Protocol: "gRPC",
			Purpose:  "Python gRPC service registration",
			Source:   reg.Source,
		})
	}
	return result
}

type pythonPlatformMapping struct {
	Component   string
	Interaction string
	Purpose     string
}

type pythonIntegrationMapping struct {
	Component       string
	InteractionType string
	Protocol        string
	Encryption      string
	Purpose         string
}

var pythonPlatformPackages = map[string]pythonPlatformMapping{
	"kubernetes":    {"Kubernetes API", "Python client library", "Kubernetes resource operations via Python SDK"},
	"ray":          {"Ray", "Python client library", "Distributed compute orchestration via Ray SDK"},
	"kserve":       {"KServe", "Python client library", "Model serving operations via KServe SDK"},
	"caikit":       {"Caikit Runtime", "Python library", "Caikit AI runtime framework"},
	"caikit-nlp":   {"Caikit Runtime", "Python library", "Caikit NLP runtime module"},
	"kfp":          {"Kubeflow Pipelines SDK", "Python client library", "Pipeline definition and execution"},
	"grpcio":       {"gRPC framework", "Python library", "gRPC transport for service communication"},
}

var pythonIntegrationPackages = map[string]pythonIntegrationMapping{
	"openai":               {"OpenAI API", "Python SDK client", "HTTPS", "TLS", "LLM inference via OpenAI SDK"},
	"boto3":                {"AWS (S3-compatible storage)", "Python SDK client", "HTTPS", "TLS", "AWS service operations via boto3"},
	"botocore":             {"AWS (S3-compatible storage)", "Python SDK client", "HTTPS", "TLS", "AWS service operations via botocore"},
	"azure-identity":       {"Azure services", "Python SDK client", "HTTPS", "TLS", "Azure authentication via SDK"},
	"azure-storage-blob":   {"Azure Blob Storage", "Python SDK client", "HTTPS", "TLS", "Azure blob storage operations"},
	"google-cloud-storage": {"Google Cloud Storage", "Python SDK client", "HTTPS", "TLS", "GCS operations via Python SDK"},
}

func importAnalysisInternalDependencies(analysis *ImportAnalysis) []model.InternalDependency {
	if analysis == nil {
		return nil
	}
	var result []model.InternalDependency
	seen := map[string]bool{}
	for _, pkg := range analysis.Used {
		mapping, exists := pythonPlatformPackages[strings.ToLower(pkg.Package)]
		if !exists || seen[mapping.Component] {
			continue
		}
		if mapping.Component == "gRPC framework" && !analysis.GRPCServer {
			continue
		}
		seen[mapping.Component] = true
		source := pkg.Source
		if source == "" && len(pkg.Imports) > 0 {
			source = "import:" + pkg.Imports[0]
		}
		result = append(result, model.InternalDependency{
			Component:   mapping.Component,
			Interaction: mapping.Interaction,
			Purpose:     mapping.Purpose,
			Source:       source,
		})
	}
	return result
}

func importAnalysisIntegrationFacts(analysis *ImportAnalysis) []model.IntegrationFact {
	if analysis == nil {
		return nil
	}
	var result []model.IntegrationFact
	seen := map[string]bool{}
	for _, pkg := range analysis.Used {
		mapping, exists := pythonIntegrationPackages[strings.ToLower(pkg.Package)]
		if !exists || seen[mapping.Component] {
			continue
		}
		seen[mapping.Component] = true
		source := pkg.Source
		if source == "" && len(pkg.Imports) > 0 {
			source = "import:" + pkg.Imports[0]
		}
		result = append(result, model.IntegrationFact{
			Component:       mapping.Component,
			InteractionType: mapping.InteractionType,
			Port:            "Configured by runtime",
			Protocol:        mapping.Protocol,
			Encryption:      mapping.Encryption,
			Purpose:         mapping.Purpose,
			Source:           source,
		})
	}
	return result
}

func importAnalysisCoverage(analysis *ImportAnalysis) string {
	if analysis == nil {
		return ""
	}
	parts := []string{
		fmt.Sprintf("%d imported in shipped source", len(analysis.Used)),
		fmt.Sprintf("%d test-only", len(analysis.TestOnly)),
		fmt.Sprintf("%d declared but unused", len(analysis.DeclaredUnused)),
	}
	if analysis.GRPCServer {
		parts = append(parts, fmt.Sprintf("%d gRPC service registrations verified", len(analysis.GRPCRegistrations)))
	}
	return strings.Join(parts, ", ")
}

func parseImportAnalysis(data []byte) (*ImportAnalysis, error) {
	var result ImportAnalysis
	if err := json.Unmarshal(data, &result); err != nil {
		return nil, fmt.Errorf("parse Python import analysis: %w", err)
	}
	if result.Status == "no_dependencies_found" {
		return nil, nil
	}
	return &result, nil
}
