package gosource

import (
	"go/ast"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

const metricsServerPackage = "sigs.k8s.io/controller-runtime/pkg/metrics/server"
const metricsFiltersPackage = "sigs.k8s.io/controller-runtime/pkg/metrics/filters"

type stringFlagBinding struct {
	name         string
	defaultValue string
}

type boolFlagBinding struct {
	name         string
	defaultValue bool
}

// extractBoundedProxyHandlerAuthentication recognizes a production handler only
// when the same invoked variable is wrapped by both authentication and
// authorization middleware from one filters package. Imports or either wrapper
// alone are deliberately insufficient.
func extractBoundedProxyHandlerAuthentication(file sourceFile) []model.AuthenticationFact {
	var result []model.AuthenticationFact
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		type handlerProof struct {
			authentication ast.Node
			authorization  ast.Node
			packagePath    string
			invoked        bool
		}
		proofs := map[string]*handlerProof{}
		ast.Inspect(function.Body, func(node ast.Node) bool {
			switch typed := node.(type) {
			case *ast.AssignStmt:
				for index, left := range typed.Lhs {
					variable, variableOK := left.(*ast.Ident)
					if !variableOK || index >= len(typed.Rhs) {
						continue
					}
					call, callOK := typed.Rhs[index].(*ast.CallExpr)
					if !callOK || len(call.Args) == 0 {
						continue
					}
					path, wrapper, imported := importedCall(file, call)
					if !imported || !strings.HasSuffix(path, "/pkg/filters") ||
						(wrapper != "WithAuthentication" && wrapper != "WithAuthorization") {
						continue
					}
					wrapped, ok := call.Args[len(call.Args)-1].(*ast.Ident)
					if !ok || wrapped.Name != variable.Name {
						continue
					}
					proof := proofs[variable.Name]
					if proof == nil {
						proof = &handlerProof{}
						proofs[variable.Name] = proof
					}
					if proof.packagePath != "" && proof.packagePath != path {
						continue
					}
					proof.packagePath = path
					if wrapper == "WithAuthentication" {
						proof.authentication = call
					} else {
						proof.authorization = call
					}
				}
			case *ast.CallExpr:
				if variable, ok := typed.Fun.(*ast.Ident); ok && proofs[variable.Name] != nil {
					proofs[variable.Name].invoked = true
				}
			}
			return true
		})
		for _, proof := range proofs {
			if proof.authentication == nil || proof.authorization == nil || !proof.invoked {
				continue
			}
			result = append(result, model.AuthenticationFact{
				Endpoint:         "Proxied HTTP requests",
				Methods:          "ALL",
				Mechanism:        "Configured request authentication (OIDC or Kubernetes TokenReview)",
				EnforcementPoint: "WithAuthentication and WithAuthorization handler chain",
				Policy:           "Non-bypassed requests require authentication and static or SubjectAccessReview authorization; configured ignore paths bypass these checks",
				Source:           sourceAt(file, proof.authentication.Pos()),
			})
		}
	}
	return result
}

// extractControllerRuntimeAuthentication handles only controller-runtime controls
// whose security behavior is explicit in source. Dynamic metrics settings remain
// unresolved instead of inheriting a controller-runtime default.
func extractControllerRuntimeAuthentication(file sourceFile, repository repositoryOptionBindings) []model.AuthenticationFact {
	values := sourceStringDefaults(file)
	for accessor, binding := range repository.strings {
		values[accessor] = binding.defaultValue
	}
	probeAddress := controllerRuntimeOptionString(file, "HealthProbeBindAddress", values)
	var result []model.AuthenticationFact

	ast.Inspect(file.file, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if ok {
			selector, selectorOK := call.Fun.(*ast.SelectorExpr)
			if selectorOK && len(call.Args) > 0 &&
				(selector.Sel.Name == "AddHealthzCheck" || selector.Sel.Name == "AddReadyzCheck") {
				name := stringLiteral(call.Args[0])
				if name != "" {
					endpoint := "/" + strings.TrimPrefix(name, "/")
					if probeAddress != "" {
						endpoint = strings.TrimSuffix(probeAddress, "/") + endpoint
					}
					purpose := "Kubernetes health probe; unauthenticated by design"
					if selector.Sel.Name == "AddReadyzCheck" {
						purpose = "Kubernetes readiness probe; unauthenticated by design"
					}
					result = append(result, model.AuthenticationFact{
						Endpoint: endpoint, Methods: "GET", Mechanism: "None",
						EnforcementPoint: "N/A", Policy: purpose,
						Source: sourceAt(file, selector.Sel.Pos()),
					})
				}
			}
		}

		literal, ok := node.(*ast.CompositeLit)
		if !ok || !isMetricsServerOptions(file, literal.Type) {
			return true
		}
		secure, securePosition, explicit := compositeBoolField(literal, "SecureServing")
		if !explicit || secure {
			return true
		}
		address := compositeResolvedStringField(literal, "BindAddress", values)
		if address == "" || address == "0" {
			return true
		}
		result = append(result, model.AuthenticationFact{
			Endpoint: strings.TrimSuffix(address, "/") + "/metrics", Methods: "GET",
			Mechanism: "None", EnforcementPoint: "N/A",
			Policy: "Metrics served over plaintext HTTP; SecureServing explicitly disabled in controller-runtime manager options",
			Source: sourceAt(file, securePosition.Pos()),
		})
		return true
	})

	return result
}

func extractControllerRuntimeSecurityControls(file sourceFile, repository repositoryOptionBindings) []model.RuntimeSecurityControl {
	stringFlags, boolFlags := staticFlagBindings(file)
	for name, binding := range repository.strings {
		stringFlags[name] = binding
	}
	for name, binding := range repository.bools {
		boolFlags[name] = binding
	}
	options := metricsOptionVariables(file)
	var result []model.RuntimeSecurityControl
	ast.Inspect(file.file, func(node ast.Node) bool {
		assignment, ok := node.(*ast.AssignStmt)
		if !ok || len(assignment.Lhs) != 1 || len(assignment.Rhs) != 1 {
			return true
		}
		field, ok := assignment.Lhs[0].(*ast.SelectorExpr)
		if !ok || field.Sel.Name != "FilterProvider" {
			return true
		}
		variable, ok := field.X.(*ast.Ident)
		if !ok || !isImportedSelector(file, assignment.Rhs[0], metricsFiltersPackage, "WithAuthenticationAndAuthorization") {
			return true
		}
		literal := options[variable.Name]
		if literal == nil {
			return true
		}

		address, addressFlag, addressOK := resolveStaticStringOption(
			compositeFieldExpression(literal, "BindAddress"), stringFlags,
		)
		secure, secureFlag, secureOK := resolveStaticBoolOption(
			compositeFieldExpression(literal, "SecureServing"), boolFlags,
		)
		if !addressOK || !secureOK {
			return true
		}
		certificatePath, certificateFlag, certificateMode := metricsCertificateConfiguration(
			file, variable.Name, stringFlags,
		)
		result = append(result, model.RuntimeSecurityControl{
			Surface: "controller-runtime metrics", AddressFlag: addressFlag,
			AddressDefault: address, SecureFlag: secureFlag, SecureDefault: secure,
			CertificatePathFlag: certificateFlag, CertificatePathDefault: certificatePath,
			CertificateMode:  certificateMode,
			Mechanism:        "Kubernetes TokenReview and SubjectAccessReview",
			EnforcementPoint: "controller-runtime metrics authn/authz filter",
			Source:           sourceAt(file, assignment.Pos()),
		})
		return true
	})
	return result
}

func staticFlagBindings(file sourceFile) (map[string]stringFlagBinding, map[string]boolFlagBinding) {
	stringsByVariable := map[string]stringFlagBinding{}
	boolsByVariable := map[string]boolFlagBinding{}
	ast.Inspect(file.file, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok || len(call.Args) < 3 {
			return true
		}
		path, function, ok := importedCall(file, call)
		if !ok || (path != "flag" && path != "github.com/spf13/pflag") ||
			(function != "StringVar" && function != "BoolVar") {
			return true
		}
		address, ok := call.Args[0].(*ast.UnaryExpr)
		if !ok {
			return true
		}
		variable, ok := address.X.(*ast.Ident)
		if !ok {
			return true
		}
		name := stringLiteral(call.Args[1])
		if name == "" {
			return true
		}
		if function == "StringVar" {
			if value, ok := staticStringLiteral(call.Args[2]); ok {
				stringsByVariable[variable.Name] = stringFlagBinding{name: name, defaultValue: value}
			}
			return true
		}
		value := expressionIdentifier(call.Args[2])
		if value == "true" || value == "false" {
			boolsByVariable[variable.Name] = boolFlagBinding{name: name, defaultValue: value == "true"}
		}
		return true
	})
	return stringsByVariable, boolsByVariable
}

func metricsOptionVariables(file sourceFile) map[string]*ast.CompositeLit {
	result := map[string]*ast.CompositeLit{}
	ast.Inspect(file.file, func(node ast.Node) bool {
		switch typed := node.(type) {
		case *ast.AssignStmt:
			for index, raw := range typed.Rhs {
				if index >= len(typed.Lhs) {
					continue
				}
				variable, variableOK := typed.Lhs[index].(*ast.Ident)
				literal, literalOK := raw.(*ast.CompositeLit)
				if variableOK && literalOK && isMetricsServerOptions(file, literal.Type) {
					result[variable.Name] = literal
				}
			}
		case *ast.ValueSpec:
			for index, raw := range typed.Values {
				if index >= len(typed.Names) {
					continue
				}
				literal, ok := raw.(*ast.CompositeLit)
				if ok && isMetricsServerOptions(file, literal.Type) {
					result[typed.Names[index].Name] = literal
				}
			}
		}
		return true
	})
	return result
}

func isImportedSelector(file sourceFile, expression ast.Expr, path, name string) bool {
	selector, ok := expression.(*ast.SelectorExpr)
	if !ok || selector.Sel.Name != name {
		return false
	}
	identifier, ok := selector.X.(*ast.Ident)
	return ok && file.imports[identifier.Name] == path
}

func compositeFieldExpression(literal *ast.CompositeLit, field string) ast.Expr {
	for _, raw := range literal.Elts {
		entry, ok := raw.(*ast.KeyValueExpr)
		if ok && expressionIdentifier(entry.Key) == field {
			return entry.Value
		}
	}
	return nil
}

func resolveStaticStringOption(expression ast.Expr, flags map[string]stringFlagBinding) (string, string, bool) {
	if value, ok := staticStringLiteral(expression); ok {
		return value, "", true
	}
	name := optionExpressionName(expression)
	if name == "" {
		return "", "", false
	}
	binding, ok := flags[name]
	return binding.defaultValue, binding.name, ok
}

func resolveStaticBoolOption(expression ast.Expr, flags map[string]boolFlagBinding) (bool, string, bool) {
	if value := expressionIdentifier(expression); value == "true" || value == "false" {
		return value == "true", "", true
	}
	name := optionExpressionName(expression)
	if name == "" {
		return false, "", false
	}
	binding, ok := flags[name]
	return binding.defaultValue, binding.name, ok
}

func optionExpressionName(expression ast.Expr) string {
	switch typed := expression.(type) {
	case *ast.Ident:
		return typed.Name
	case *ast.CallExpr:
		if len(typed.Args) != 0 {
			return ""
		}
		if selector, ok := typed.Fun.(*ast.SelectorExpr); ok {
			return selector.Sel.Name
		}
	}
	return ""
}

func staticStringLiteral(expression ast.Expr) (string, bool) {
	literal, ok := expression.(*ast.BasicLit)
	if !ok || literal.Kind.String() != "STRING" {
		return "", false
	}
	return stringLiteral(expression), true
}

func metricsCertificateConfiguration(
	file sourceFile,
	variable string,
	flags map[string]stringFlagBinding,
) (string, string, string) {
	mode := "controller-runtime-default"
	var path, flag string
	ast.Inspect(file.file, func(node ast.Node) bool {
		assignment, ok := node.(*ast.AssignStmt)
		if !ok || len(assignment.Lhs) != 1 || len(assignment.Rhs) != 1 {
			return true
		}
		field, ok := assignment.Lhs[0].(*ast.SelectorExpr)
		if !ok || expressionIdentifier(field.X) != variable {
			return true
		}
		switch field.Sel.Name {
		case "CertDir":
			resolved, resolvedFlag, resolvedOK := resolveStaticStringOption(assignment.Rhs[0], flags)
			if resolvedOK {
				path, flag, mode = resolved, resolvedFlag, "optional-external"
			} else {
				mode = "unresolved"
			}
		case "TLSOpts":
			if mode == "controller-runtime-default" {
				mode = "unresolved"
			}
		}
		return true
	})
	if mode == "unresolved" {
		if resolved, resolvedFlag, ok := optionalTLSPathForMutation(file, variable, flags); ok {
			path, flag, mode = resolved, resolvedFlag, "optional-external"
		}
	}
	return path, flag, mode
}

func optionalTLSPathForMutation(
	file sourceFile,
	variable string,
	flags map[string]stringFlagBinding,
) (string, string, bool) {
	var path, flag string
	found := false
	ast.Inspect(file.file, func(node ast.Node) bool {
		conditional, ok := node.(*ast.IfStmt)
		if !ok || conditional.Body == nil || !bodyMutatesField(conditional.Body, variable, "TLSOpts") {
			return true
		}
		ast.Inspect(conditional.Cond, func(conditionNode ast.Node) bool {
			call, ok := conditionNode.(*ast.CallExpr)
			if !ok {
				return true
			}
			name := optionExpressionName(call)
			binding, exists := flags[name]
			if !exists {
				return true
			}
			path, flag, found = binding.defaultValue, binding.name, true
			return false
		})
		return !found
	})
	return path, flag, found
}

func bodyMutatesField(body *ast.BlockStmt, variable, fieldName string) bool {
	found := false
	ast.Inspect(body, func(node ast.Node) bool {
		assignment, ok := node.(*ast.AssignStmt)
		if !ok {
			return true
		}
		for _, left := range assignment.Lhs {
			field, ok := left.(*ast.SelectorExpr)
			if ok && expressionIdentifier(field.X) == variable && field.Sel.Name == fieldName {
				found = true
				return false
			}
		}
		return !found
	})
	return found
}

func sourceStringDefaults(file sourceFile) map[string]string {
	result := map[string]string{}
	ast.Inspect(file.file, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok || len(call.Args) < 3 {
			return true
		}
		selector, ok := call.Fun.(*ast.SelectorExpr)
		if !ok || selector.Sel.Name != "StringVar" {
			return true
		}
		address, ok := call.Args[0].(*ast.UnaryExpr)
		if !ok {
			return true
		}
		identifier, ok := address.X.(*ast.Ident)
		if !ok {
			return true
		}
		if value := stringLiteral(call.Args[2]); value != "" {
			result[identifier.Name] = value
		}
		return true
	})
	return result
}

func controllerRuntimeOptionString(file sourceFile, field string, values map[string]string) string {
	result := ""
	ast.Inspect(file.file, func(node ast.Node) bool {
		literal, ok := node.(*ast.CompositeLit)
		if !ok || result != "" || !isControllerRuntimeOptions(file, literal.Type) {
			return true
		}
		result = compositeResolvedStringField(literal, field, values)
		return true
	})
	return result
}

func isControllerRuntimeOptions(file sourceFile, expression ast.Expr) bool {
	selector, ok := expression.(*ast.SelectorExpr)
	if !ok || selector.Sel.Name != "Options" {
		return false
	}
	identifier, ok := selector.X.(*ast.Ident)
	if !ok {
		return false
	}
	path := file.imports[identifier.Name]
	return path == "sigs.k8s.io/controller-runtime" || strings.HasSuffix(path, "/pkg/manager")
}

func isMetricsServerOptions(file sourceFile, expression ast.Expr) bool {
	selector, ok := expression.(*ast.SelectorExpr)
	if !ok || selector.Sel.Name != "Options" {
		return false
	}
	identifier, ok := selector.X.(*ast.Ident)
	return ok && file.imports[identifier.Name] == metricsServerPackage
}

func compositeResolvedStringField(literal *ast.CompositeLit, field string, values map[string]string) string {
	for _, raw := range literal.Elts {
		entry, ok := raw.(*ast.KeyValueExpr)
		if !ok || expressionIdentifier(entry.Key) != field {
			continue
		}
		if value := stringLiteral(entry.Value); value != "" {
			return value
		}
		if identifier, ok := entry.Value.(*ast.Ident); ok {
			return values[identifier.Name]
		}
		if name := optionExpressionName(entry.Value); name != "" {
			return values[name]
		}
	}
	return ""
}

func compositeBoolField(literal *ast.CompositeLit, field string) (bool, ast.Node, bool) {
	for _, raw := range literal.Elts {
		entry, ok := raw.(*ast.KeyValueExpr)
		if !ok || expressionIdentifier(entry.Key) != field {
			continue
		}
		identifier, ok := entry.Value.(*ast.Ident)
		if !ok || (identifier.Name != "true" && identifier.Name != "false") {
			return false, entry, false
		}
		return identifier.Name == "true", entry, true
	}
	return false, literal, false
}

func dedupeAuthentication(facts []model.AuthenticationFact) []model.AuthenticationFact {
	seen := make(map[string]bool, len(facts))
	result := make([]model.AuthenticationFact, 0, len(facts))
	for _, fact := range facts {
		key := strings.ToLower(fact.Endpoint) + "\x00" + strings.ToUpper(fact.Methods)
		if !seen[key] {
			seen[key] = true
			result = append(result, fact)
		}
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].Endpoint+result[i].Methods < result[j].Endpoint+result[j].Methods
	})
	return result
}

func dedupeRuntimeSecurityControls(controls []model.RuntimeSecurityControl) []model.RuntimeSecurityControl {
	seen := make(map[string]bool, len(controls))
	result := make([]model.RuntimeSecurityControl, 0, len(controls))
	for _, control := range controls {
		key := strings.ToLower(control.Surface) + "\x00" + control.Source
		if !seen[key] {
			seen[key] = true
			result = append(result, control)
		}
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].Surface+result[i].Source < result[j].Surface+result[j].Source
	})
	return result
}
