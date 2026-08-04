package gosource

import (
	"go/ast"
	"path"
	"strings"
	"unicode"

	"github.com/jctanner/arch-analyzer/internal/model"
)

type outboundGRPCClient struct {
	connVariable string
	packageAlias string
	packagePath  string
	serviceName  string
	fieldName    string
	receiverType string
	source       string
	plaintext    bool
	tls          bool
}

func extractOutboundGRPCClients(files []sourceFile) []model.RuntimeClient {
	reachable := runtimeReachableFunctions(files)
	var clients []outboundGRPCClient
	for _, file := range files {
		if !importsPackage(file, grpcPackage) {
			continue
		}
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil || !reachable[runtimeFunction(file, function)] {
				continue
			}
			clients = append(clients, extractFunctionOutboundGRPCClients(file, function)...)
		}
	}

	var result []model.RuntimeClient
	for _, client := range clients {
		if client.receiverType == "" || client.fieldName == "" {
			continue
		}
		if !outboundGRPCFieldHasMethodCalls(files, client.receiverType, client.fieldName) {
			continue
		}
		result = append(result, outboundGRPCRuntimeClient(client))
	}
	return result
}

func extractFunctionOutboundGRPCClients(file sourceFile, function *ast.FuncDecl) []outboundGRPCClient {
	dialVariables := map[string]*outboundGRPCClient{}

	ast.Inspect(function.Body, func(node ast.Node) bool {
		assignment, ok := node.(*ast.AssignStmt)
		if !ok || len(assignment.Lhs) == 0 || len(assignment.Rhs) == 0 {
			return true
		}
		for index, rhs := range assignment.Rhs {
			if index >= len(assignment.Lhs) {
				continue
			}
			call, callOK := rhs.(*ast.CallExpr)
			if !callOK {
				compositeLitGRPCClients(file, function, assignment, rhs, dialVariables)
				continue
			}

			if isGRPCDialCall(file, call) {
				variable, varOK := assignment.Lhs[index].(*ast.Ident)
				if !varOK {
					continue
				}
				client := &outboundGRPCClient{connVariable: variable.Name}
				classifyGRPCDialSecurity(file, call, client)
				dialVariables[variable.Name] = client
				continue
			}

			pkgAlias, pkgPath, serviceName := grpcClientConstructorCall(file, call)
			if serviceName == "" {
				continue
			}
			if len(call.Args) < 1 {
				continue
			}
			connArg, connOK := call.Args[0].(*ast.Ident)
			if !connOK {
				continue
			}
			dial, hasDial := dialVariables[connArg.Name]
			if !hasDial {
				continue
			}

			fieldName, receiverType := outboundGRPCFieldAssignment(file, function, assignment)

			dial.packageAlias = pkgAlias
			dial.packagePath = pkgPath
			dial.serviceName = serviceName
			dial.fieldName = fieldName
			dial.receiverType = receiverType
			dial.source = sourceAt(file, call.Fun.Pos())
		}
		return true
	})

	var result []outboundGRPCClient
	for _, client := range dialVariables {
		if client.serviceName != "" {
			result = append(result, *client)
		}
	}
	return result
}

func compositeLitGRPCClients(file sourceFile, function *ast.FuncDecl, assignment *ast.AssignStmt, rhs ast.Expr, dialVariables map[string]*outboundGRPCClient) {
	lit := compositeLitFromExpression(rhs)
	if lit == nil {
		return
	}
	typeName := runtimeTypeName(lit.Type)
	if typeName == "" {
		return
	}
	for _, element := range lit.Elts {
		kv, ok := element.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		fieldIdent, fieldOK := kv.Key.(*ast.Ident)
		if !fieldOK {
			continue
		}
		call, callOK := kv.Value.(*ast.CallExpr)
		if !callOK {
			continue
		}
		pkgAlias, pkgPath, serviceName := grpcClientConstructorCall(file, call)
		if serviceName == "" || len(call.Args) < 1 {
			continue
		}
		connArg, connOK := call.Args[0].(*ast.Ident)
		if !connOK {
			continue
		}
		dial, hasDial := dialVariables[connArg.Name]
		if !hasDial {
			continue
		}
		dial.packageAlias = pkgAlias
		dial.packagePath = pkgPath
		dial.serviceName = serviceName
		dial.fieldName = fieldIdent.Name
		dial.receiverType = typeName
		dial.source = sourceAt(file, call.Fun.Pos())
	}
}

func compositeLitFromExpression(expression ast.Expr) *ast.CompositeLit {
	switch value := expression.(type) {
	case *ast.CompositeLit:
		return value
	case *ast.UnaryExpr:
		return compositeLitFromExpression(value.X)
	}
	return nil
}

func isGRPCDialCall(file sourceFile, call *ast.CallExpr) bool {
	return isImportedCall(file, call, grpcPackage, "Dial") ||
		isImportedCall(file, call, grpcPackage, "DialContext") ||
		isImportedCall(file, call, grpcPackage, "NewClient")
}

func grpcClientConstructorCall(file sourceFile, call *ast.CallExpr) (string, string, string) {
	pkgPath, name, imported := importedCall(file, call)
	if !imported || !strings.HasPrefix(name, "New") || !strings.HasSuffix(name, "Client") {
		return "", "", ""
	}
	serviceName := strings.TrimPrefix(strings.TrimSuffix(name, "Client"), "New")
	if serviceName == "" {
		return "", "", ""
	}
	pkgAlias := path.Base(pkgPath)
	for alias, resolved := range file.imports {
		if resolved == pkgPath {
			pkgAlias = alias
			break
		}
	}
	return pkgAlias, pkgPath, serviceName
}

func outboundGRPCFieldAssignment(file sourceFile, function *ast.FuncDecl, assignment *ast.AssignStmt) (string, string) {
	for _, lhs := range assignment.Lhs {
		selector, ok := lhs.(*ast.SelectorExpr)
		if !ok {
			continue
		}
		owner, ownerOK := selector.X.(*ast.Ident)
		if !ownerOK {
			continue
		}
		if recv := receiverName(function); recv != "" && owner.Name == recv {
			return selector.Sel.Name, runtimeReceiverType(function)
		}
		if typeName := resolveLocalVariableType(function, owner.Name); typeName != "" {
			return selector.Sel.Name, typeName
		}
	}
	return "", ""
}

func resolveLocalVariableType(function *ast.FuncDecl, variableName string) string {
	var typeName string
	ast.Inspect(function.Body, func(node ast.Node) bool {
		assignment, ok := node.(*ast.AssignStmt)
		if !ok || len(assignment.Lhs) == 0 || len(assignment.Rhs) == 0 {
			return true
		}
		lhs, ok := assignment.Lhs[0].(*ast.Ident)
		if !ok || lhs.Name != variableName {
			return true
		}
		name := runtimeReceiverFromExpression(assignment.Rhs[0])
		if name != "" {
			typeName = name
			return false
		}
		return true
	})
	return typeName
}

func classifyGRPCDialSecurity(file sourceFile, call *ast.CallExpr, client *outboundGRPCClient) {
	if len(call.Args) == 0 {
		client.plaintext = true
		return
	}
	hasCredentials := false
	for _, arg := range call.Args {
		argCall, ok := arg.(*ast.CallExpr)
		if !ok {
			continue
		}
		argPath, argName, imported := importedCall(file, argCall)
		if !imported {
			continue
		}
		if argPath == grpcPackage && argName == "WithInsecure" {
			client.plaintext = true
			hasCredentials = true
			continue
		}
		if argPath == grpcPackage && argName == "WithTransportCredentials" && len(argCall.Args) == 1 {
			if isInsecureCredentials(file, argCall.Args[0]) {
				client.plaintext = true
			} else {
				client.tls = true
			}
			hasCredentials = true
		}
	}
	if !hasCredentials {
		client.plaintext = true
	}
}

func isInsecureCredentials(file sourceFile, expression ast.Expr) bool {
	call, ok := expression.(*ast.CallExpr)
	if !ok {
		return false
	}
	path, name, imported := importedCall(file, call)
	return imported && path == "google.golang.org/grpc/credentials/insecure" && name == "NewCredentials"
}

func outboundGRPCFieldHasMethodCalls(files []sourceFile, receiver, field string) bool {
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil || function.Recv == nil {
				continue
			}
			if runtimeReceiverType(function) != receiver {
				continue
			}
			recv := receiverName(function)
			found := false
			ast.Inspect(function.Body, func(node ast.Node) bool {
				call, callOK := node.(*ast.CallExpr)
				if !callOK {
					return true
				}
				selector, selectorOK := call.Fun.(*ast.SelectorExpr)
				if !selectorOK {
					return true
				}
				fieldAccess, fieldOK := selector.X.(*ast.SelectorExpr)
				if !fieldOK {
					return true
				}
				owner, ownerOK := fieldAccess.X.(*ast.Ident)
				if ownerOK && owner.Name == recv && fieldAccess.Sel.Name == field {
					found = true
					return false
				}
				return true
			})
			if found {
				return true
			}
		}
	}
	return false
}

func outboundGRPCRuntimeClient(client outboundGRPCClient) model.RuntimeClient {
	target := humanizeOutboundGRPCTarget(client.packageAlias, client.serviceName)

	security := "plaintext"
	if client.tls && client.plaintext {
		security = "optional TLS"
	} else if client.tls {
		security = "TLS"
	}

	return model.RuntimeClient{
		Target:        target,
		Client:        "outbound gRPC client",
		Configuration: "runtime gRPC connection (" + security + ")",
		Source:        client.source,
	}
}

func humanizeOutboundGRPCTarget(packageAlias, serviceName string) string {
	var words []rune
	for index, character := range serviceName {
		if index > 0 && unicode.IsUpper(character) {
			previous := rune(serviceName[index-1])
			if unicode.IsLower(previous) || unicode.IsDigit(previous) {
				words = append(words, ' ')
			}
		}
		words = append(words, character)
	}
	return packageAlias + " " + string(words)
}
