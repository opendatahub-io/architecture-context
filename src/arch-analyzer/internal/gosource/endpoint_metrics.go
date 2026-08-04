package gosource

import (
	"go/ast"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

// extractEndpointMetricsClients requires repository-wide convergence from endpoint
// address construction through a registered metrics datasource and an executed HTTP
// GET. Individual fields, factories, or request helpers are insufficient.
func extractEndpointMetricsClients(files []sourceFile) []model.RuntimeClient {
	hostSource := ""
	datasource := false
	endpointURL := false
	requestSource := ""
	pluginRegistered := false
	for _, file := range files {
		if hostSource == "" {
			hostSource = endpointMetricsHostSource(file)
		}
		datasource = datasource || constructsEndpointMetricsDatasource(file)
		endpointURL = endpointURL || constructsEndpointMetricsURL(file)
		if requestSource == "" {
			requestSource = executedHTTPGetSource(file)
		}
		pluginRegistered = pluginRegistered || registersEndpointMetricsPlugin(file)
	}
	if hostSource == "" || !datasource || !endpointURL || requestSource == "" || !pluginRegistered {
		return nil
	}
	return []model.RuntimeClient{{
		Target: "Model-serving endpoints", Client: "HTTP metrics data source",
		Configuration: "Discovered endpoint MetricsHost with configured HTTP scheme and path",
		Source:        requestSource,
	}}
}

func endpointMetricsHostSource(file sourceFile) string {
	source := ""
	ast.Inspect(file.file, func(node ast.Node) bool {
		entry, ok := node.(*ast.KeyValueExpr)
		if !ok || expressionIdentifier(entry.Key) != "MetricsHost" ||
			!isImportedCall(file, entry.Value, "net", "JoinHostPort") {
			return true
		}
		source = sourceAt(file, entry.Key.Pos())
		return false
	})
	return source
}

func constructsEndpointMetricsDatasource(file sourceFile) bool {
	found := false
	ast.Inspect(file.file, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		path, function, imported := importedCall(file, call)
		if !imported || function != "NewHTTPDataSource" || !strings.HasSuffix(path, "/datalayer/source/http") {
			return true
		}
		if expressionsContainName(call.Args, "MetricsDataSourceType") && expressionsContainName(call.Args, "parseMetrics") {
			found = true
		}
		return !found
	})
	return found
}

func constructsEndpointMetricsURL(file sourceFile) bool {
	found := false
	ast.Inspect(file.file, func(node ast.Node) bool {
		literal, ok := node.(*ast.CompositeLit)
		if !ok || !isImportedType(file, literal.Type, "net/url", "URL") {
			return true
		}
		for _, element := range literal.Elts {
			entry, ok := element.(*ast.KeyValueExpr)
			if ok && expressionIdentifier(entry.Key) == "Host" && expressionCallsMethod(entry.Value, "GetMetricsHost") {
				found = true
				return false
			}
		}
		return !found
	})
	return found
}

func executedHTTPGetSource(file sourceFile) string {
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		requests := map[string]string{}
		ast.Inspect(function.Body, func(node ast.Node) bool {
			assignment, ok := node.(*ast.AssignStmt)
			if !ok || len(assignment.Rhs) != 1 || len(assignment.Lhs) == 0 {
				return true
			}
			call, ok := assignment.Rhs[0].(*ast.CallExpr)
			if !ok || !isImportedCall(file, call, "net/http", "NewRequestWithContext") || len(call.Args) < 2 ||
				!isImportedType(file, call.Args[1], "net/http", "MethodGet") {
				return true
			}
			if identifier, ok := assignment.Lhs[0].(*ast.Ident); ok {
				requests[identifier.Name] = sourceAt(file, call.Pos())
			}
			return true
		})
		result := ""
		ast.Inspect(function.Body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok || len(call.Args) == 0 {
				return true
			}
			selector, ok := call.Fun.(*ast.SelectorExpr)
			if !ok || selector.Sel.Name != "Do" {
				return true
			}
			if identifier, ok := call.Args[0].(*ast.Ident); ok {
				result = requests[identifier.Name]
			}
			return result == ""
		})
		if result != "" {
			return result
		}
	}
	return ""
}

func registersEndpointMetricsPlugin(file sourceFile) bool {
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil || !functionReachableFromRuntimeRoot(file, function.Name.Name) {
			continue
		}
		found := false
		ast.Inspect(function.Body, func(node ast.Node) bool {
			if found {
				return false
			}
			call, ok := node.(*ast.CallExpr)
			if !ok || calledFunctionName(call.Fun) != "Register" {
				return true
			}
			if expressionsContainName(call.Args, "MetricsDataSourceType") &&
				expressionsContainName(call.Args, "MetricsDataSourceFactory") {
				found = true
				return false
			}
			return true
		})
		if found {
			return true
		}
	}
	return false
}

func functionReachableFromRuntimeRoot(file sourceFile, target string) bool {
	functions := uniqueFunctions(file.file)
	var queue []string
	for name := range functions {
		if name == "main" || name == "Run" {
			queue = append(queue, name)
		}
	}
	seen := map[string]bool{}
	for len(queue) > 0 {
		name := queue[0]
		queue = queue[1:]
		if seen[name] {
			continue
		}
		seen[name] = true
		if name == target {
			return true
		}
		function := functions[name]
		if function == nil || function.Body == nil {
			continue
		}
		ast.Inspect(function.Body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			called := calledFunctionName(call.Fun)
			if functions[called] != nil && !seen[called] {
				queue = append(queue, called)
			}
			return true
		})
	}
	return false
}

func expressionsContainName(expressions []ast.Expr, name string) bool {
	for _, expression := range expressions {
		found := false
		ast.Inspect(expression, func(node ast.Node) bool {
			switch typed := node.(type) {
			case *ast.Ident:
				found = found || typed.Name == name
			case *ast.SelectorExpr:
				found = found || typed.Sel.Name == name
			}
			return !found
		})
		if found {
			return true
		}
	}
	return false
}

func expressionCallsMethod(expression ast.Expr, name string) bool {
	found := false
	ast.Inspect(expression, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if ok && calledFunctionName(call.Fun) == name {
			found = true
		}
		return !found
	})
	return found
}
