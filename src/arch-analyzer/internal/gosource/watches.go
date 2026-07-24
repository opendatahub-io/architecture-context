package gosource

import (
	"go/ast"
	"go/token"
	"path/filepath"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func extractWatches(file sourceFile) []model.ControllerWatch {
	var watches []model.ControllerWatch
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		controller := receiverType(function)
		conditionalRanges := functionConditionalRanges(function)
		ast.Inspect(function.Body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			selector, ok := call.Fun.(*ast.SelectorExpr)
			if !ok || len(call.Args) == 0 {
				return true
			}
			watchType := selector.Sel.Name
			if watchType != "For" && watchType != "Owns" && watchType != "Watches" {
				return true
			}
			if containsCall(selector.X, "NewWebhookManagedBy") {
				return true
			}
			packagePath, typeName := watchedType(call.Args[0], file)
			if typeName == "" {
				return true
			}
			watches = append(watches, model.ControllerWatch{
				Type:        watchType,
				GVK:         formatGVK(packagePath, typeName, file.modulePath),
				Controller:  controller,
				Source:      sourceAt(file, selector.Sel.Pos()),
				Conditional: positionInRanges(selector.Sel.Pos(), conditionalRanges),
			})
			return true
		})
	}
	return watches
}

type sourceRange struct {
	start token.Pos
	end   token.Pos
}

func functionConditionalRanges(function *ast.FuncDecl) []sourceRange {
	var result []sourceRange
	ast.Inspect(function.Body, func(node ast.Node) bool {
		conditional, ok := node.(*ast.IfStmt)
		if ok && conditional.Body != nil {
			result = append(result, sourceRange{start: conditional.Body.Pos(), end: conditional.Body.End()})
		}
		return true
	})
	return result
}

func positionInRanges(position token.Pos, ranges []sourceRange) bool {
	for _, candidate := range ranges {
		if candidate.start <= position && position <= candidate.end {
			return true
		}
	}
	return false
}

func conditionalControllerRegistrations(files []sourceFile) map[string]bool {
	result := map[string]bool{}
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil {
				continue
			}
			variables := functionVariables(function, file)
			for _, conditionalRange := range functionConditionalRanges(function) {
				ast.Inspect(function.Body, func(node ast.Node) bool {
					call, ok := node.(*ast.CallExpr)
					if !ok || !positionInRanges(call.Pos(), []sourceRange{conditionalRange}) {
						return true
					}
					selector, ok := call.Fun.(*ast.SelectorExpr)
					if !ok || selector.Sel.Name != "SetupWithManager" {
						return true
					}
					if receiver := expressionType(selector.X, variables, file); receiver.name != "" {
						result[receiver.name] = true
					}
					return true
				})
			}
		}
	}
	return result
}

func applyConditionalControllerRegistrations(watches []model.ControllerWatch, registrations map[string]bool) {
	for index := range watches {
		if registrations[watches[index].Controller] {
			watches[index].Conditional = true
		}
	}
}

func containsCall(expression ast.Expr, name string) bool {
	found := false
	ast.Inspect(expression, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		switch function := call.Fun.(type) {
		case *ast.Ident:
			found = function.Name == name
		case *ast.SelectorExpr:
			found = function.Sel.Name == name
		}
		return !found
	})
	return found
}

func receiverType(function *ast.FuncDecl) string {
	if function.Recv == nil || len(function.Recv.List) == 0 {
		return ""
	}
	typeExpression := function.Recv.List[0].Type
	if pointer, ok := typeExpression.(*ast.StarExpr); ok {
		typeExpression = pointer.X
	}
	switch typed := typeExpression.(type) {
	case *ast.Ident:
		return typed.Name
	case *ast.IndexExpr:
		if identifier, ok := typed.X.(*ast.Ident); ok {
			return identifier.Name
		}
	}
	return ""
}

func watchedType(expression ast.Expr, file sourceFile) (string, string) {
	var found ast.Expr
	ast.Inspect(expression, func(node ast.Node) bool {
		if found != nil {
			return false
		}
		if literal, ok := node.(*ast.CompositeLit); ok {
			found = literal.Type
			return false
		}
		return true
	})
	if found == nil {
		return "", ""
	}
	switch typed := found.(type) {
	case *ast.SelectorExpr:
		alias, ok := typed.X.(*ast.Ident)
		if !ok {
			return "", ""
		}
		return file.imports[alias.Name], typed.Sel.Name
	case *ast.Ident:
		packagePath := file.modulePath
		if file.packageDir != "" {
			packagePath += "/" + file.packageDir
		}
		return packagePath, typed.Name
	default:
		return "", ""
	}
}

func formatGVK(packagePath, typeName, modulePath string) string {
	typeName = strings.TrimSuffix(typeName, "List")
	if packagePath == "" {
		return typeName
	}
	if strings.HasPrefix(packagePath, "k8s.io/api/") {
		path := strings.TrimPrefix(packagePath, "k8s.io/api/")
		parts := strings.Split(path, "/")
		if len(parts) >= 2 {
			group := kubernetesGroup(parts[0])
			return group + "/" + parts[1] + "/" + typeName
		}
	}
	if strings.HasPrefix(packagePath, "github.com/openshift/api/") {
		parts := strings.Split(strings.TrimPrefix(packagePath, "github.com/openshift/api/"), "/")
		if len(parts) >= 2 {
			return parts[0] + ".openshift.io/" + parts[1] + "/" + typeName
		}
	}
	if strings.HasPrefix(packagePath, "sigs.k8s.io/gateway-api/apis/") {
		version := strings.TrimPrefix(packagePath, "sigs.k8s.io/gateway-api/apis/")
		return "gateway.networking.k8s.io/" + version + "/" + typeName
	}
	if strings.HasPrefix(packagePath, "github.com/cert-manager/cert-manager/pkg/apis/certmanager/") {
		version := strings.TrimPrefix(packagePath, "github.com/cert-manager/cert-manager/pkg/apis/certmanager/")
		return "cert-manager.io/" + version + "/" + typeName
	}
	if strings.HasPrefix(packagePath, "github.com/kedacore/keda/v2/apis/keda/") {
		version := strings.TrimPrefix(packagePath, "github.com/kedacore/keda/v2/apis/keda/")
		return "keda.sh/" + version + "/" + typeName
	}
	if strings.HasPrefix(packagePath, "sigs.k8s.io/lws/api/leaderworkerset/") {
		version := strings.TrimPrefix(packagePath, "sigs.k8s.io/lws/api/leaderworkerset/")
		return "leaderworkerset.x-k8s.io/" + version + "/" + typeName
	}
	if strings.HasPrefix(packagePath, "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/") {
		version := strings.TrimPrefix(packagePath, "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/")
		return "monitoring.coreos.com/" + version + "/" + typeName
	}
	if strings.HasPrefix(packagePath, "sigs.k8s.io/gateway-api-inference-extension/api/") {
		version := strings.TrimPrefix(packagePath, "sigs.k8s.io/gateway-api-inference-extension/api/")
		return "inference.networking.k8s.io/" + version + "/" + typeName
	}
	if strings.HasPrefix(packagePath, "sigs.k8s.io/gateway-api-inference-extension/apix/") {
		version := strings.TrimPrefix(packagePath, "sigs.k8s.io/gateway-api-inference-extension/apix/")
		return "inference.networking.x-k8s.io/" + version + "/" + typeName
	}
	if strings.HasPrefix(packagePath, "github.com/kserve/kserve/pkg/apis/serving/") {
		version := strings.TrimPrefix(packagePath, "github.com/kserve/kserve/pkg/apis/serving/")
		return "serving.kserve.io/" + version + "/" + typeName
	}
	if strings.HasPrefix(packagePath, modulePath+"/") {
		path := strings.TrimPrefix(packagePath, modulePath+"/")
		path = strings.TrimPrefix(path, "apis/")
		return path + "/" + typeName
	}
	parts := strings.Split(packagePath, "/")
	if len(parts) >= 2 {
		return filepath.Join(parts[len(parts)-2], parts[len(parts)-1], typeName)
	}
	return packagePath + "/" + typeName
}

func kubernetesGroup(group string) string {
	switch group {
	case "core":
		return ""
	case "rbac":
		return "rbac.authorization.k8s.io"
	case "networking":
		return "networking.k8s.io"
	case "scheduling":
		return "scheduling.k8s.io"
	case "apiextensions":
		return "apiextensions.k8s.io"
	default:
		return group
	}
}
