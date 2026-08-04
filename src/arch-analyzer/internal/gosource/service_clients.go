package gosource

import (
	"go/ast"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

type serviceClientKind struct {
	target        string
	client        string
	configuration string
}

var standardServiceClientConstructors = map[string]map[string]serviceClientKind{
	"github.com/jackc/pgx/v5/pgxpool": {
		"NewWithConfig": {target: "PostgreSQL", client: "pgx connection pool", configuration: "runtime PostgreSQL pool configuration"},
	},
	"github.com/redis/go-redis/v9": {
		"NewClient": {target: "Redis/Valkey", client: "go-redis client", configuration: "runtime Redis-compatible connection options"},
	},
	"github.com/aws/aws-sdk-go-v2/service/s3": {
		"NewFromConfig": {target: "S3-compatible storage", client: "AWS SDK S3 client", configuration: "runtime AWS SDK and endpoint configuration"},
	},
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc": {
		"New": {target: "OpenTelemetry Collector", client: "OTLP/gRPC trace exporter", configuration: "standard OpenTelemetry environment configuration"},
	},
	"cloud.google.com/go/storage": {
		"NewClient": {target: "Google Cloud Storage", client: "GCS storage client", configuration: "runtime Google Cloud credentials and bucket configuration"},
	},
	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob": {
		"NewClient":                              {target: "Azure Blob Storage", client: "Azure Blob Storage client", configuration: "runtime Azure identity and storage account configuration"},
		"NewClientWithNoCredential":              {target: "Azure Blob Storage", client: "Azure Blob Storage client", configuration: "runtime anonymous Azure storage configuration"},
		"NewClientFromConnectionString":          {target: "Azure Blob Storage", client: "Azure Blob Storage client", configuration: "runtime Azure storage connection string configuration"},
		"NewContainerClient":                     {target: "Azure Blob Storage", client: "Azure Blob Storage client", configuration: "runtime Azure identity and storage account configuration"},
		"NewContainerClientWithNoCredential":     {target: "Azure Blob Storage", client: "Azure Blob Storage client", configuration: "runtime anonymous Azure storage configuration"},
		"NewContainerClientFromConnectionString": {target: "Azure Blob Storage", client: "Azure Blob Storage client", configuration: "runtime Azure storage connection string configuration"},
	},
	"github.com/IBM/ibm-cos-sdk-go/service/s3": {
		"New": {target: "IBM Cloud Object Storage", client: "IBM COS S3 client", configuration: "runtime IBM Cloud Object Storage SDK configuration"},
	},
}

var standardServiceClientPackageNames = map[string]string{
	"github.com/jackc/pgx/v5/pgxpool":                                 "pgxpool",
	"github.com/redis/go-redis/v9":                                    "redis",
	"github.com/aws/aws-sdk-go-v2/service/s3":                         "s3",
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc": "otlptracegrpc",
}

func extractRuntimeServiceClients(files []sourceFile) []model.RuntimeClient {
	reachable := runtimeReachableFunctions(files)
	var result []model.RuntimeClient
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil || !reachable[runtimeFunction(file, function)] {
				continue
			}
			ast.Inspect(function.Body, func(node ast.Node) bool {
				call, ok := node.(*ast.CallExpr)
				if !ok {
					return true
				}
				path, name, imported := importedServiceClientCall(file, call)
				kind, supported := standardServiceClientConstructors[path][name]
				if !imported || !supported {
					return true
				}
				result = append(result, model.RuntimeClient{
					Target: kind.target, Client: kind.client, Configuration: kind.configuration,
					Source: sourceAt(file, call.Fun.Pos()),
				})
				return true
			})
		}
	}
	return result
}

func importedServiceClientCall(file sourceFile, call *ast.CallExpr) (string, string, bool) {
	if path, name, imported := importedCall(file, call); imported {
		return path, name, true
	}
	selector, ok := call.Fun.(*ast.SelectorExpr)
	if !ok {
		return "", "", false
	}
	identifier, ok := selector.X.(*ast.Ident)
	if !ok {
		return "", "", false
	}
	for _, spec := range file.file.Imports {
		if spec.Name != nil {
			continue
		}
		path := strings.Trim(spec.Path.Value, `"`)
		if standardServiceClientPackageNames[path] == identifier.Name {
			return path, selector.Sel.Name, true
		}
	}
	return "", "", false
}
