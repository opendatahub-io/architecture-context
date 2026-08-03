package gosource

import (
	"fmt"
	"go/ast"
	"go/token"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

var kubernetesClientOperations = map[string]string{
	"Create": "create",
	"Delete": "delete",
	"Get":    "get",
	"List":   "list",
	"Patch":  "patch",
	"Update": "update",
}

const (
	controllerUtilPackage = "sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	unstructuredPackage   = "k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	schemaPackage         = "k8s.io/apimachinery/pkg/runtime/schema"
)

type goType struct {
	packagePath string
	name        string
}

func extractResourceOperations(file sourceFile) []model.ComponentRef {
	var references []model.ComponentRef
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		variables := functionVariables(function, file)
		controller := receiverType(function)
		dynamicResources := functionDynamicResources(function, variables, file)
		ast.Inspect(function.Body, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			if path, operation, imported := importedCall(file, call); imported &&
				path == controllerUtilPackage && operation == "CreateOrUpdate" {
				resourceType := operationTarget(call.Args, variables, file)
				if resourceType.name == "" || !isKubernetesAPI(resourceType.packagePath, file.modulePath) {
					return true
				}
				for _, operation := range []string{"create", "update"} {
					references = append(references, componentReference(resourceType, file, controller, operation, call.Pos()))
				}
				return true
			}
			selector, ok := call.Fun.(*ast.SelectorExpr)
			if !ok {
				return true
			}
			operation, supported := kubernetesClientOperations[selector.Sel.Name]
			if !supported {
				return true
			}
			if resource, ok := dynamicOperationTarget(call.Args, dynamicResources, call.Pos()); ok {
				references = append(references, model.ComponentRef{
					Component: resource.component, Type: "Kubernetes API",
					Reference: operationReference(operation, controller),
					Source:    sourceAt(file, selector.Sel.Pos()), Interaction: "Resource operation",
				})
				return true
			}
			resourceType := operationTarget(call.Args, variables, file)
			if resourceType.name == "" || !isKubernetesAPI(resourceType.packagePath, file.modulePath) {
				return true
			}
			references = append(references, componentReference(resourceType, file, controller, operation, selector.Sel.Pos()))
			return true
		})
	}
	return references
}

func componentReference(resourceType goType, file sourceFile, controller, operation string, position token.Pos) model.ComponentRef {
	reference := model.ComponentRef{
		Component:   formatGVK(resourceType.packagePath, resourceType.name, file.modulePath),
		Type:        "Kubernetes API",
		Reference:   operationReference(operation, controller),
		Source:      sourceAt(file, position),
		Interaction: "Resource operation",
	}
	return reference
}

func operationReference(operation, controller string) string {
	if controller != "" {
		return operation + " by " + controller
	}
	return operation
}

type dynamicResource struct {
	component string
	boundAt   token.Pos
}

func functionDynamicResources(function *ast.FuncDecl, variables map[string]goType, file sourceFile) map[string]dynamicResource {
	resources := map[string]dynamicResource{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok || len(call.Args) != 1 {
			return true
		}
		selector, ok := call.Fun.(*ast.SelectorExpr)
		if !ok || selector.Sel.Name != "SetGroupVersionKind" {
			return true
		}
		variable, ok := selector.X.(*ast.Ident)
		if !ok || variables[variable.Name] != (goType{packagePath: unstructuredPackage, name: "Unstructured"}) {
			return true
		}
		literal, ok := call.Args[0].(*ast.CompositeLit)
		if !ok || expressionType(literal.Type, variables, file) != (goType{packagePath: schemaPackage, name: "GroupVersionKind"}) {
			return true
		}
		group := compositeResolvedStringField(literal, "Group", nil)
		version := compositeResolvedStringField(literal, "Version", nil)
		kind := compositeResolvedStringField(literal, "Kind", nil)
		if version == "" || kind == "" {
			return true
		}
		component := group + "/" + version + "/" + kind
		if group == "" {
			component = "/" + version + "/" + kind
		}
		resources[variable.Name] = dynamicResource{component: component, boundAt: call.Pos()}
		return true
	})
	return resources
}

// extractGVRDynamicResourceOperations detects package-level or function-level
// schema.GroupVersionResource constructions with executed dynamic client
// operations (Get, Delete, Create, etc.) via dynamicClient.Resource(gvr).
func extractGVRDynamicResourceOperations(files []sourceFile) []model.ComponentRef {
	gvrDecls := discoverPackageGVRDeclarations(files)
	reachable := runtimeReachableFunctions(files)
	gvrPackages := gvrDeclarationPackages(files, gvrDecls)
	var references []model.ComponentRef
	for _, file := range files {
		if !importsPackage(file, "k8s.io/client-go/dynamic") {
			continue
		}
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil {
				continue
			}
			key := runtimeFunction(file, function)
			if !reachable[key] && !gvrPackages[key.packagePath] {
				continue
			}
			refs := gvrOperationsInFunction(file, function, gvrDecls)
			references = append(references, refs...)
		}
	}
	return references
}

func gvrDeclarationPackages(files []sourceFile, gvrDecls map[string]gvrIdentity) map[string]bool {
	result := map[string]bool{}
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			genDecl, ok := declaration.(*ast.GenDecl)
			if !ok || (genDecl.Tok != token.VAR && genDecl.Tok != token.CONST) {
				continue
			}
			for _, spec := range genDecl.Specs {
				value, ok := spec.(*ast.ValueSpec)
				if !ok {
					continue
				}
				for _, name := range value.Names {
					if gvr, exists := gvrDecls[name.Name]; exists && isPlatformAPIGroup(gvr.group) {
						result[packagePath(file)] = true
					}
				}
			}
		}
	}
	return result
}

func isPlatformAPIGroup(group string) bool {
	return strings.HasSuffix(group, ".opendatahub.io") ||
		strings.HasSuffix(group, ".openshift.io") ||
		strings.HasSuffix(group, ".kserve.io") ||
		strings.HasSuffix(group, ".kubeflow.org")
}

type gvrIdentity struct {
	group    string
	version  string
	resource string
}

func (g gvrIdentity) component() string {
	if g.group == "" {
		return "/" + g.version + "/" + g.resource
	}
	return g.group + "/" + g.version + "/" + g.resource
}

func discoverPackageGVRDeclarations(files []sourceFile) map[string]gvrIdentity {
	packageConstants := collectPackageConstants(files)
	result := map[string]gvrIdentity{}
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			genDecl, ok := declaration.(*ast.GenDecl)
			if !ok || (genDecl.Tok != token.VAR && genDecl.Tok != token.CONST) {
				continue
			}
			for _, spec := range genDecl.Specs {
				value, ok := spec.(*ast.ValueSpec)
				if !ok {
					continue
				}
				for i, name := range value.Names {
					if i >= len(value.Values) {
						continue
					}
					literal, ok := value.Values[i].(*ast.CompositeLit)
					if !ok || !isImportedType(file, literal.Type, schemaPackage, "GroupVersionResource") {
						continue
					}
					pkg := packagePath(file)
					gvr := resolveGVRLiteral(file, literal, packageConstants[pkg])
					if gvr.version != "" && gvr.resource != "" {
						result[name.Name] = gvr
					}
				}
			}
		}
	}
	return result
}

func collectPackageConstants(files []sourceFile) map[string]map[string]string {
	result := map[string]map[string]string{}
	for _, file := range files {
		pkg := packagePath(file)
		if result[pkg] == nil {
			result[pkg] = map[string]string{}
		}
		for _, declaration := range file.file.Decls {
			genDecl, ok := declaration.(*ast.GenDecl)
			if !ok || genDecl.Tok != token.CONST {
				continue
			}
			for _, spec := range genDecl.Specs {
				value, ok := spec.(*ast.ValueSpec)
				if !ok {
					continue
				}
				for i, name := range value.Names {
					if i < len(value.Values) {
						if v := stringLiteral(value.Values[i]); v != "" {
							result[pkg][name.Name] = v
						}
					}
				}
			}
		}
	}
	return result
}

func resolveGVRLiteral(file sourceFile, literal *ast.CompositeLit, constants map[string]string) gvrIdentity {
	group := resolveGVRField(file, literal, "Group", constants)
	version := resolveGVRField(file, literal, "Version", constants)
	resource := resolveGVRField(file, literal, "Resource", constants)
	return gvrIdentity{group: group, version: version, resource: resource}
}

func resolveGVRField(file sourceFile, literal *ast.CompositeLit, fieldName string, constants map[string]string) string {
	for _, element := range literal.Elts {
		kv, ok := element.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		name, nameOK := kv.Key.(*ast.Ident)
		if !nameOK || name.Name != fieldName {
			continue
		}
		if value := stringLiteral(kv.Value); value != "" {
			return value
		}
		if ident, ok := kv.Value.(*ast.Ident); ok {
			if v := resolveLocalConstant(file, ident.Name); v != "" {
				return v
			}
			if constants != nil {
				return constants[ident.Name]
			}
		}
	}
	return ""
}

func resolveLocalConstant(file sourceFile, name string) string {
	for _, declaration := range file.file.Decls {
		genDecl, ok := declaration.(*ast.GenDecl)
		if !ok || genDecl.Tok != token.CONST {
			continue
		}
		for _, spec := range genDecl.Specs {
			value, ok := spec.(*ast.ValueSpec)
			if !ok {
				continue
			}
			for i, constName := range value.Names {
				if constName.Name == name && i < len(value.Values) {
					if v := stringLiteral(value.Values[i]); v != "" {
						return v
					}
				}
			}
		}
	}
	return ""
}

func gvrOperationsInFunction(file sourceFile, function *ast.FuncDecl, gvrDecls map[string]gvrIdentity) []model.ComponentRef {
	controller := receiverType(function)
	var refs []model.ComponentRef
	ast.Inspect(function.Body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		selector, ok := call.Fun.(*ast.SelectorExpr)
		if !ok {
			return true
		}
		operation, supported := kubernetesClientOperations[selector.Sel.Name]
		if !supported {
			return true
		}
		if gvr, ok := gvrResourceChain(selector.X, gvrDecls); ok {
			refs = append(refs, model.ComponentRef{
				Component: gvr.component(), Type: "Kubernetes API",
				Reference: operationReference(operation, controller),
				Source:    sourceAt(file, selector.Sel.Pos()), Interaction: "Resource operation",
			})
		}
		return true
	})
	return refs
}

// gvrResourceChain walks a dynamic client chain like
// h.dynamicClient.Resource(gvr).Namespace(ns) to find the .Resource(gvr) call
// and resolve the GVR identity.
func gvrResourceChain(expression ast.Expr, gvrDecls map[string]gvrIdentity) (gvrIdentity, bool) {
	switch typed := expression.(type) {
	case *ast.CallExpr:
		selector, ok := typed.Fun.(*ast.SelectorExpr)
		if !ok {
			return gvrIdentity{}, false
		}
		if selector.Sel.Name == "Resource" && len(typed.Args) == 1 {
			if ident, ok := typed.Args[0].(*ast.Ident); ok {
				if gvr, found := gvrDecls[ident.Name]; found {
					return gvr, true
				}
			}
			return gvrIdentity{}, false
		}
		if selector.Sel.Name == "Namespace" {
			return gvrResourceChain(selector.X, gvrDecls)
		}
	}
	return gvrIdentity{}, false
}

func dynamicOperationTarget(arguments []ast.Expr, resources map[string]dynamicResource, callPosition token.Pos) (dynamicResource, bool) {
	for index := len(arguments) - 1; index >= 0; index-- {
		identifier, ok := arguments[index].(*ast.Ident)
		if !ok {
			continue
		}
		resource, ok := resources[identifier.Name]
		if ok && resource.boundAt < callPosition {
			return resource, true
		}
	}
	return dynamicResource{}, false
}

func functionVariables(function *ast.FuncDecl, file sourceFile) map[string]goType {
	variables := map[string]goType{}
	if function.Type.Params != nil {
		for _, field := range function.Type.Params.List {
			fieldType := expressionType(field.Type, variables, file)
			for _, name := range field.Names {
				variables[name.Name] = fieldType
			}
		}
	}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		switch typed := node.(type) {
		case *ast.AssignStmt:
			for index, left := range typed.Lhs {
				identifier, ok := left.(*ast.Ident)
				if !ok || index >= len(typed.Rhs) {
					continue
				}
				if inferred := expressionType(typed.Rhs[index], variables, file); inferred.name != "" {
					variables[identifier.Name] = inferred
				}
			}
		case *ast.DeclStmt:
			declaration, ok := typed.Decl.(*ast.GenDecl)
			if !ok {
				return true
			}
			for _, spec := range declaration.Specs {
				value, ok := spec.(*ast.ValueSpec)
				if !ok || value.Type == nil {
					continue
				}
				valueType := expressionType(value.Type, variables, file)
				for _, name := range value.Names {
					variables[name.Name] = valueType
				}
			}
		}
		return true
	})
	return variables
}

func operationTarget(arguments []ast.Expr, variables map[string]goType, file sourceFile) goType {
	for index := len(arguments) - 1; index >= 0; index-- {
		candidate := expressionType(arguments[index], variables, file)
		if candidate.name != "" && isKubernetesAPI(candidate.packagePath, file.modulePath) {
			return candidate
		}
	}
	return goType{}
}

func expressionType(expression ast.Expr, variables map[string]goType, file sourceFile) goType {
	switch typed := expression.(type) {
	case *ast.ParenExpr:
		return expressionType(typed.X, variables, file)
	case *ast.UnaryExpr:
		return expressionType(typed.X, variables, file)
	case *ast.StarExpr:
		return expressionType(typed.X, variables, file)
	case *ast.CompositeLit:
		return expressionType(typed.Type, variables, file)
	case *ast.SelectorExpr:
		alias, ok := typed.X.(*ast.Ident)
		if !ok {
			return goType{}
		}
		return goType{packagePath: file.imports[alias.Name], name: typed.Sel.Name}
	case *ast.Ident:
		if known := variables[typed.Name]; known.name != "" {
			return known
		}
		packagePath := file.modulePath
		if file.packageDir != "" {
			packagePath += "/" + file.packageDir
		}
		return goType{packagePath: packagePath, name: typed.Name}
	case *ast.CallExpr:
		if identifier, ok := typed.Fun.(*ast.Ident); ok && identifier.Name == "new" && len(typed.Args) == 1 {
			return expressionType(typed.Args[0], variables, file)
		}
	}
	return goType{}
}

func isKubernetesAPI(packagePath, modulePath string) bool {
	if strings.HasPrefix(packagePath, "k8s.io/api/") ||
		strings.HasPrefix(packagePath, "github.com/openshift/api/") ||
		strings.HasPrefix(packagePath, "github.com/cert-manager/cert-manager/pkg/apis/") {
		return true
	}
	if modulePath != "" && strings.HasPrefix(packagePath, modulePath+"/") {
		relative := strings.TrimPrefix(packagePath, modulePath+"/")
		return strings.HasPrefix(relative, "api/") || strings.HasPrefix(relative, "apis/")
	}
	return strings.Contains(packagePath, "gateway-api/apis/")
}

func mergeResourceOperations(references []model.ComponentRef) []model.ComponentRef {
	type aggregate struct {
		reference   model.ComponentRef
		operations  map[string]bool
		controllers map[string]bool
	}
	byResource := map[string]*aggregate{}
	var order []string
	for _, reference := range references {
		key := reference.Component
		item, ok := byResource[key]
		if !ok {
			item = &aggregate{reference: reference, operations: map[string]bool{}, controllers: map[string]bool{}}
			byResource[key] = item
			order = append(order, key)
		}
		parts := strings.SplitN(reference.Reference, " by ", 2)
		item.operations[parts[0]] = true
		if len(parts) == 2 {
			item.controllers[parts[1]] = true
		}
	}
	sort.Strings(order)
	result := make([]model.ComponentRef, 0, len(order))
	for _, key := range order {
		item := byResource[key]
		operations := mapKeys(item.operations)
		controllers := mapKeys(item.controllers)
		interaction := "Resource read"
		for _, operation := range operations {
			if operation != "get" && operation != "list" {
				interaction = "Resource CRUD"
				break
			}
		}
		item.reference.Interaction = interaction
		item.reference.Reference = fmt.Sprintf("%s operations", strings.Join(operations, ", "))
		if len(controllers) > 0 {
			item.reference.Reference += " by " + strings.Join(controllers, ", ")
		}
		result = append(result, item.reference)
	}
	return result
}

func mapKeys(values map[string]bool) []string {
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}
