package extractor

import (
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

var goModuleRoles = map[string]string{
	"sigs.k8s.io/controller-runtime":      "runtime-framework",
	"k8s.io/client-go":                    "runtime-integration",
	"k8s.io/apimachinery":                 "runtime-integration",
	"k8s.io/api":                          "runtime-integration",
	"k8s.io/apiserver":                    "runtime-framework",
	"github.com/spf13/cobra":              "build-tool",
	"github.com/spf13/viper":              "runtime-config",
	"google.golang.org/grpc":              "runtime-transport",
	"google.golang.org/protobuf":          "runtime-transport",
	"github.com/go-logr/logr":             "runtime-observability",
	"go.uber.org/zap":                     "runtime-observability",
	"github.com/prometheus/client_golang": "runtime-observability",
	"crypto/tls":                          "runtime-security",
	"github.com/gorilla/mux":              "runtime-transport",
	"github.com/gin-gonic/gin":            "runtime-transport",
	"github.com/go-chi/chi":               "runtime-transport",
	"net/http":                            "runtime-transport",
}

var pythonPackageRoles = map[string]string{
	"fastapi":           "runtime-framework",
	"flask":             "runtime-framework",
	"starlette":         "runtime-framework",
	"django":            "runtime-framework",
	"uvicorn":           "runtime-transport",
	"gunicorn":          "runtime-transport",
	"hypercorn":         "runtime-transport",
	"grpcio":            "runtime-transport",
	"grpcio-tools":      "build-tool",
	"protobuf":          "runtime-transport",
	"kubernetes":        "runtime-integration",
	"openshift-client":  "runtime-integration",
	"pyjwt":             "runtime-security",
	"python-jose":       "runtime-security",
	"authlib":           "runtime-security",
	"cryptography":      "runtime-security",
	"pyopenssl":         "runtime-security",
	"prometheus-client": "runtime-observability",
	"opentelemetry-api": "runtime-observability",
	"opentelemetry-sdk": "runtime-observability",
	"celery":            "runtime-framework",
	"sqlalchemy":        "runtime-integration",
	"psycopg2":          "runtime-integration",
	"redis":             "runtime-integration",
	"boto3":             "runtime-integration",
	"requests":          "runtime-integration",
	"httpx":             "runtime-integration",
	"aiohttp":           "runtime-integration",
	"numpy":             "runtime-library",
	"pandas":            "runtime-library",
	"torch":             "runtime-library",
	"tensorflow":        "runtime-library",
	"scikit-learn":      "runtime-library",
	"transformers":      "runtime-library",
	"pytest":            "build-tool",
	"mypy":              "build-tool",
	"ruff":              "build-tool",
	"black":             "build-tool",
	"setuptools":        "build-tool",
}

var rustCrateRoles = map[string]string{
	"tokio":     "runtime-framework",
	"actix-web": "runtime-framework",
	"axum":      "runtime-framework",
	"tonic":     "runtime-transport",
	"prost":     "runtime-transport",
	"hyper":     "runtime-transport",
	"reqwest":   "runtime-integration",
	"serde":     "runtime-library",
	"tracing":   "runtime-observability",
	"rustls":    "runtime-security",
}

func classifyDependencyRoles(input *model.Input) {
	for i := range input.Dependencies.GoModules {
		dep := &input.Dependencies.GoModules[i]
		if role, ok := goModuleRoles[dep.Module]; ok {
			dep.Role = role
			if dep.Category == "" || dep.Category == "Unknown" {
				dep.Category = role
			}
		}
	}
	for i := range input.Dependencies.Packages {
		pkg := &input.Dependencies.Packages[i]
		if pkg.Role != "" {
			continue
		}
		lower := strings.ToLower(pkg.Name)
		switch strings.ToLower(pkg.Ecosystem) {
		case "go":
			if role, ok := goModuleRoles[pkg.Name]; ok {
				pkg.Role = role
			}
		case "pypi", "pip", "python", "":
			if role, ok := pythonPackageRoles[lower]; ok {
				pkg.Role = role
			}
		case "cargo":
			if role, ok := rustCrateRoles[lower]; ok {
				pkg.Role = role
			}
		case "npm":
			if strings.Contains(lower, "webpack") || strings.Contains(lower, "eslint") || strings.Contains(lower, "typescript") {
				pkg.Role = "build-tool"
			} else if strings.Contains(lower, "react") || strings.Contains(lower, "vue") || strings.Contains(lower, "angular") {
				pkg.Role = "runtime-framework"
			} else if strings.Contains(lower, "express") || strings.Contains(lower, "koa") || strings.Contains(lower, "fastify") {
				pkg.Role = "runtime-transport"
			}
		}
	}
	for i := range input.Dependencies.Internal {
		dependency := &input.Dependencies.Internal[i]
		if dependency.Role == "" {
			dependency.Role = roleForInteraction(dependency.Interaction)
		}
	}
	for i := range input.IntegrationPoints {
		if input.IntegrationPoints[i].Role == "" {
			input.IntegrationPoints[i].Role = roleForInteraction(input.IntegrationPoints[i].InteractionType)
		}
	}
}

func roleForInteraction(interaction string) string {
	lower := strings.ToLower(interaction)
	switch {
	case strings.Contains(lower, "watch"), strings.Contains(lower, "kubernetes"), strings.Contains(lower, "resource"), strings.Contains(lower, "client"):
		return "runtime-integration"
	case strings.Contains(lower, "http"), strings.Contains(lower, "https"), strings.Contains(lower, "rest"), strings.Contains(lower, "grpc"), strings.Contains(lower, "service"):
		return "runtime-transport"
	case strings.Contains(lower, "library"), strings.Contains(lower, "module"):
		return "runtime-library"
	default:
		return "unknown"
	}
}
