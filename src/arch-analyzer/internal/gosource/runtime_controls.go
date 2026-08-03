package gosource

import (
	"go/ast"
	"go/token"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

const controllerRuntimeWebhookPackage = "sigs.k8s.io/controller-runtime/pkg/webhook"

type sourceContainer struct {
	variable     string
	name         string
	args         []string
	ports        map[string]int
	volumeMounts []string
	source       string
}

type sourcePod struct {
	serviceAccount string
	containers     []string
	secretVolumes  map[string]string
}

type sourceServicePort struct {
	port       int
	targetPort int
	targetName string
	affinity   string
	source     string
}

// extractConstructedKubeRBACProxyControls recognizes only complete source-built
// proxy paths. A container literal alone is deliberately insufficient: the proxy
// must be in a PodSpec with an application peer and ServiceAccount, have TLS and
// config arguments backed by a mounted Secret, match a created Service port, and
// have a ServiceAccount-bound review role binding in the same package.
func extractConstructedKubeRBACProxyControls(files []sourceFile, bindings []model.Binding) []model.RuntimeProxyControl {
	byPackage := sourceFilesByPackage(files)
	var result []model.RuntimeProxyControl
	for _, packageFiles := range byPackage {
		if !packageContainsLiteral(packageFiles, "kube-rbac-proxy") {
			continue
		}
		values := packageStaticValues(packageFiles)
		returns := packageStaticReturns(packageFiles, values)
		arguments := packageFunctionArguments(packageFiles, values, returns)
		services := packageConstructedServicePorts(packageFiles, values, returns, arguments)
		packageBindings := bindingsForPackage(bindings, packageFiles)

		for _, file := range packageFiles {
			for _, declaration := range file.file.Decls {
				function, ok := declaration.(*ast.FuncDecl)
				if !ok || function.Body == nil {
					continue
				}
				functionValues := mergedStringValues(values, arguments[function.Name.Name])
				functionValues = functionStringValuesResolved(function, functionValues, returns)
				containers := constructedContainers(function, file, functionValues, returns)
				pods := constructedPods(function, file, functionValues, returns)
				for _, proxy := range containers {
					flags := proxyFlags(proxy.args)
					listenPort := addressPort(flags["secure-listen-address"])
					if !isKubeRBACProxy(proxy, flags) || listenPort == 0 {
						continue
					}
					pod, app, tlsSecret, ok := proxyPodProof(proxy, containers, pods, flags)
					if !ok {
						continue
					}
					affinity := sourceAffinity(file.path, function.Name.Name, app.name)
					service, ok := matchingConstructedService(services, affinity, listenPort, proxy.ports)
					if !ok {
						continue
					}
					binding, ok := matchingReviewBinding(packageBindings, pod.serviceAccount)
					if !ok {
						continue
					}
					surface := proxySurface(file, function, app.name)
					result = append(result, model.RuntimeProxyControl{
						Surface: surface, Methods: proxySurfaceMethods(surface),
						Workload: function.Name.Name, ServiceAccount: pod.serviceAccount,
						ListenPort: listenPort, Upstream: flags["upstream"], ConfigFile: flags["config-file"],
						TLSCertFile: flags["tls-cert-file"], TLSPrivateKeyFile: flags["tls-private-key-file"],
						TLSSecret: tlsSecret, ServicePort: service.port, ServiceTargetPort: service.targetPort,
						ReviewRole: binding.RoleRef, ReviewBinding: binding.Name,
						AuthorizationScope: packageAuthorizationScope(packageFiles, affinity), Source: proxy.source,
					})
				}
			}
		}
	}
	return result
}

func extractConstructedClusterRoleBindings(files []sourceFile) []model.Binding {
	byPackage := sourceFilesByPackage(files)
	var result []model.Binding
	for _, packageFiles := range byPackage {
		if !packageConstructsType(packageFiles, "ClusterRoleBinding") {
			continue
		}
		values := packageStaticValues(packageFiles)
		returns := packageStaticReturns(packageFiles, values)
		arguments := packageFunctionArguments(packageFiles, values, returns)
		for _, file := range packageFiles {
			for _, declaration := range file.file.Decls {
				function, ok := declaration.(*ast.FuncDecl)
				if !ok || function.Body == nil {
					continue
				}
				functionValues := mergedStringValues(values, arguments[function.Name.Name])
				functionValues = functionStringValuesResolved(function, functionValues, returns)
				created := functionCreatedVariables(function)
				ast.Inspect(function.Body, func(node ast.Node) bool {
					assignment, ok := node.(*ast.AssignStmt)
					if !ok {
						return true
					}
					for index, left := range assignment.Lhs {
						identifier, ok := left.(*ast.Ident)
						if !ok || index >= len(assignment.Rhs) || !created[identifier.Name] {
							continue
						}
						literal := compositeLiteral(assignment.Rhs[index])
						if literal == nil || expressionType(literal.Type, nil, file).name != "ClusterRoleBinding" {
							continue
						}
						if binding, ok := bindingFromLiteral(literal, file, functionValues, returns); ok {
							result = append(result, binding)
						}
					}
					return true
				})
			}
		}
	}
	return dedupeConstructedBindings(result)
}

func bindingFromLiteral(literal *ast.CompositeLit, file sourceFile, values, returns map[string]string) (model.Binding, bool) {
	binding := model.Binding{RoleKind: "ClusterRole", Source: sourceAt(file, literal.Pos())}
	for _, raw := range literal.Elts {
		entry, ok := raw.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		switch expressionIdentifier(entry.Key) {
		case "ObjectMeta":
			if metadata := compositeLiteral(entry.Value); metadata != nil {
				binding.Name, _ = staticSourceString(compositeFieldExpression(metadata, "Name"), values, returns)
			}
		case "RoleRef":
			if roleRef := compositeLiteral(entry.Value); roleRef != nil {
				binding.RoleRef, _ = staticSourceString(compositeFieldExpression(roleRef, "Name"), values, returns)
				if kind, ok := staticSourceString(compositeFieldExpression(roleRef, "Kind"), values, returns); ok {
					binding.RoleKind = kind
				}
			}
		case "Subjects":
			list := compositeLiteral(entry.Value)
			if list == nil {
				continue
			}
			for _, rawSubject := range list.Elts {
				subjectLiteral := compositeLiteral(rawSubject)
				if subjectLiteral == nil {
					continue
				}
				subject := model.Subject{}
				subject.Kind, _ = staticSourceString(compositeFieldExpression(subjectLiteral, "Kind"), values, returns)
				subject.Name, _ = staticSourceString(compositeFieldExpression(subjectLiteral, "Name"), values, returns)
				subject.Namespace, _ = staticSourceString(compositeFieldExpression(subjectLiteral, "Namespace"), values, returns)
				if subject.Name != "" {
					binding.Subjects = append(binding.Subjects, subject)
				}
			}
		}
	}
	return binding, binding.RoleRef != "" && len(binding.Subjects) > 0
}

func extractRuntimeWebhookServers(file sourceFile) []model.RuntimeWebhookServer {
	var result []model.RuntimeWebhookServer
	ast.Inspect(file.file, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		path, function, imported := importedCall(file, call)
		if !imported || path != controllerRuntimeWebhookPackage || function != "NewServer" || len(call.Args) != 1 {
			return true
		}
		options := compositeLiteral(call.Args[0])
		if options == nil || expressionType(options.Type, nil, file).name != "Options" {
			return true
		}
		port := staticInteger(compositeFieldExpression(options, "Port"), nil)
		if port == 0 {
			return true
		}
		result = append(result, model.RuntimeWebhookServer{
			Port: port, Conditional: positionIsConditional(file.file, call.Pos()), Source: sourceAt(file, call.Pos()),
		})
		return true
	})
	return result
}

func sourceFilesByPackage(files []sourceFile) map[string][]sourceFile {
	result := map[string][]sourceFile{}
	for _, file := range files {
		key := file.modulePath + "\x00" + file.packageDir + "\x00" + file.file.Name.Name
		result[key] = append(result[key], file)
	}
	return result
}

func packageStaticValues(files []sourceFile) map[string]string {
	values := map[string]string{}
	for pass := 0; pass < 6; pass++ {
		for _, file := range files {
			for _, declaration := range file.file.Decls {
				general, ok := declaration.(*ast.GenDecl)
				if !ok || general.Tok != token.CONST {
					continue
				}
				for _, raw := range general.Specs {
					spec, ok := raw.(*ast.ValueSpec)
					if !ok {
						continue
					}
					for index, name := range spec.Names {
						if index >= len(spec.Values) {
							continue
						}
						if value, ok := staticString(spec.Values[index], values); ok {
							values[name.Name] = value
						} else if value := staticInteger(spec.Values[index], values); value != 0 {
							values[name.Name] = strconv.Itoa(value)
						}
					}
				}
			}
		}
	}
	return values
}

func packageStaticReturns(files []sourceFile, values map[string]string) map[string]string {
	result := map[string]string{}
	for pass := 0; pass < 4; pass++ {
		for _, file := range files {
			for _, declaration := range file.file.Decls {
				function, ok := declaration.(*ast.FuncDecl)
				if !ok || function.Body == nil {
					continue
				}
				functionValues := functionStringValuesResolved(function, values, result)
				for _, statement := range function.Body.List {
					returned, ok := statement.(*ast.ReturnStmt)
					if !ok || len(returned.Results) != 1 {
						continue
					}
					if value, ok := staticSourceString(returned.Results[0], functionValues, result); ok {
						result[function.Name.Name] = value
					}
				}
			}
		}
	}
	return result
}

func packageFunctionArguments(files []sourceFile, values, returns map[string]string) map[string]map[string]string {
	declarations := map[string]*ast.FuncDecl{}
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			if function, ok := declaration.(*ast.FuncDecl); ok {
				declarations[function.Name.Name] = function
			}
		}
	}
	result := map[string]map[string]string{}
	for pass := 0; pass < 5; pass++ {
		for _, file := range files {
			for _, declaration := range file.file.Decls {
				caller, ok := declaration.(*ast.FuncDecl)
				if !ok || caller.Body == nil {
					continue
				}
				callerValues := mergedStringValues(values, result[caller.Name.Name])
				callerValues = functionStringValuesResolved(caller, callerValues, returns)
				ast.Inspect(caller.Body, func(node ast.Node) bool {
					call, ok := node.(*ast.CallExpr)
					if !ok {
						return true
					}
					calleeName := callableName(call.Fun)
					callee := declarations[calleeName]
					if callee == nil || callee.Type.Params == nil {
						return true
					}
					parameters := functionParameterNames(callee)
					for index, parameter := range parameters {
						if index >= len(call.Args) {
							break
						}
						value, ok := staticSourceString(call.Args[index], callerValues, returns)
						if !ok {
							continue
						}
						if result[calleeName] == nil {
							result[calleeName] = map[string]string{}
						}
						if current := result[calleeName][parameter]; current == "" || current == value {
							result[calleeName][parameter] = value
						}
					}
					return true
				})
			}
		}
	}
	return result
}

func functionParameterNames(function *ast.FuncDecl) []string {
	var result []string
	if function.Type.Params == nil {
		return result
	}
	for _, field := range function.Type.Params.List {
		for _, name := range field.Names {
			result = append(result, name.Name)
		}
	}
	return result
}

func callableName(expression ast.Expr) string {
	switch callable := expression.(type) {
	case *ast.Ident:
		return callable.Name
	case *ast.SelectorExpr:
		return callable.Sel.Name
	default:
		return ""
	}
}

func functionStringValuesResolved(function *ast.FuncDecl, base, returns map[string]string) map[string]string {
	values := mergedStringValues(base, nil)
	for pass := 0; pass < 5; pass++ {
		ast.Inspect(function.Body, func(node ast.Node) bool {
			switch statement := node.(type) {
			case *ast.AssignStmt:
				for index, left := range statement.Lhs {
					identifier, ok := left.(*ast.Ident)
					if ok && index < len(statement.Rhs) {
						if value, ok := staticSourceString(statement.Rhs[index], values, returns); ok {
							values[identifier.Name] = value
						}
					}
				}
			case *ast.ValueSpec:
				for index, name := range statement.Names {
					if index < len(statement.Values) {
						if value, ok := staticSourceString(statement.Values[index], values, returns); ok {
							values[name.Name] = value
						}
					}
				}
			}
			return true
		})
	}
	return values
}

func staticSourceString(expression ast.Expr, values, returns map[string]string) (string, bool) {
	if expression == nil {
		return "", false
	}
	switch typed := expression.(type) {
	case *ast.ParenExpr:
		return staticSourceString(typed.X, values, returns)
	case *ast.BinaryExpr:
		if typed.Op != token.ADD {
			return "", false
		}
		left, leftOK := staticSourceString(typed.X, values, returns)
		right, rightOK := staticSourceString(typed.Y, values, returns)
		return left + right, leftOK && rightOK
	case *ast.CallExpr:
		if value := returns[callableName(typed.Fun)]; value != "" {
			return value, true
		}
		if callableName(typed.Fun) == "Itoa" && len(typed.Args) == 1 {
			return staticSourceString(typed.Args[0], values, returns)
		}
		if callableName(typed.Fun) == "Sprintf" && len(typed.Args) > 0 {
			format, ok := staticSourceString(typed.Args[0], values, returns)
			if !ok {
				return "", false
			}
			for _, argument := range typed.Args[1:] {
				value, resolved := staticSourceString(argument, values, returns)
				if !resolved {
					return "", false
				}
				format = sprintfVerb.ReplaceAllStringFunc(format, func(verb string) string {
					if value == "" {
						return verb
					}
					replacement := value
					value = ""
					return replacement
				})
			}
			return format, true
		}
	}
	return staticString(expression, values)
}

func mergedStringValues(left, right map[string]string) map[string]string {
	result := make(map[string]string, len(left)+len(right))
	for key, value := range left {
		result[key] = value
	}
	for key, value := range right {
		result[key] = value
	}
	return result
}

func constructedContainers(function *ast.FuncDecl, file sourceFile, values, returns map[string]string) map[string]sourceContainer {
	result := map[string]sourceContainer{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		assignment, ok := node.(*ast.AssignStmt)
		if !ok {
			return true
		}
		for index, left := range assignment.Lhs {
			identifier, ok := left.(*ast.Ident)
			if !ok || index >= len(assignment.Rhs) {
				continue
			}
			literal := compositeLiteral(assignment.Rhs[index])
			if literal == nil || expressionType(literal.Type, nil, file).name != "Container" {
				continue
			}
			container := sourceContainer{variable: identifier.Name, ports: map[string]int{}, source: sourceAt(file, literal.Pos())}
			container.name, _ = staticSourceString(compositeFieldExpression(literal, "Name"), values, returns)
			container.args = compositeStringList(compositeFieldExpression(literal, "Args"), values, returns)
			container.ports = compositeNamedPorts(compositeFieldExpression(literal, "Ports"), values)
			container.volumeMounts = compositeNamedItems(compositeFieldExpression(literal, "VolumeMounts"), "Name", values, returns)
			result[identifier.Name] = container
		}
		return true
	})
	return result
}

func constructedPods(function *ast.FuncDecl, file sourceFile, values, returns map[string]string) []sourcePod {
	volumeLists := constructedVolumeLists(function, file, values, returns)
	var result []sourcePod
	ast.Inspect(function.Body, func(node ast.Node) bool {
		literal, ok := node.(*ast.CompositeLit)
		if !ok || expressionType(literal.Type, nil, file).name != "PodSpec" {
			return true
		}
		pod := sourcePod{secretVolumes: map[string]string{}}
		pod.serviceAccount, _ = staticSourceString(compositeFieldExpression(literal, "ServiceAccountName"), values, returns)
		if list := compositeLiteral(compositeFieldExpression(literal, "Containers")); list != nil {
			for _, item := range list.Elts {
				if identifier, ok := item.(*ast.Ident); ok {
					pod.containers = append(pod.containers, identifier.Name)
				}
			}
		}
		volumesExpression := compositeFieldExpression(literal, "Volumes")
		if identifier, ok := volumesExpression.(*ast.Ident); ok {
			for name, secret := range volumeLists[identifier.Name] {
				pod.secretVolumes[name] = secret
			}
		}
		if list := compositeLiteral(volumesExpression); list != nil {
			for _, item := range list.Elts {
				volume := compositeLiteral(item)
				if volume == nil {
					continue
				}
				name, _ := staticSourceString(compositeFieldExpression(volume, "Name"), values, returns)
				volumeSource := compositeLiteral(compositeFieldExpression(volume, "VolumeSource"))
				if volumeSource == nil {
					continue
				}
				secret := compositeLiteral(compositeFieldExpression(volumeSource, "Secret"))
				if secret != nil {
					secretName, _ := staticSourceString(compositeFieldExpression(secret, "SecretName"), values, returns)
					if name != "" && secretName != "" {
						pod.secretVolumes[name] = secretName
					}
				}
			}
		}
		result = append(result, pod)
		return true
	})
	return result
}

func constructedVolumeLists(function *ast.FuncDecl, file sourceFile, values, returns map[string]string) map[string]map[string]string {
	result := map[string]map[string]string{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		assignment, ok := node.(*ast.AssignStmt)
		if !ok {
			return true
		}
		for index, left := range assignment.Lhs {
			identifier, ok := left.(*ast.Ident)
			if !ok || index >= len(assignment.Rhs) {
				continue
			}
			list := compositeLiteral(assignment.Rhs[index])
			if list == nil || compositeElementTypeName(list, file) != "Volume" {
				continue
			}
			secrets := map[string]string{}
			for _, item := range list.Elts {
				volume := compositeLiteral(item)
				if volume == nil {
					continue
				}
				name, _ := staticSourceString(compositeFieldExpression(volume, "Name"), values, returns)
				volumeSource := compositeLiteral(compositeFieldExpression(volume, "VolumeSource"))
				if volumeSource == nil {
					continue
				}
				secret := compositeLiteral(compositeFieldExpression(volumeSource, "Secret"))
				if secret == nil {
					continue
				}
				secretName, _ := staticSourceString(compositeFieldExpression(secret, "SecretName"), values, returns)
				if name != "" && secretName != "" {
					secrets[name] = secretName
				}
			}
			result[identifier.Name] = secrets
		}
		return true
	})
	return result
}

func compositeElementTypeName(literal *ast.CompositeLit, file sourceFile) string {
	if literal == nil {
		return ""
	}
	expression := literal.Type
	if array, ok := expression.(*ast.ArrayType); ok {
		expression = array.Elt
	}
	return expressionType(expression, nil, file).name
}

func packageConstructedServicePorts(files []sourceFile, values, returns map[string]string, arguments map[string]map[string]string) []sourceServicePort {
	called := map[string]bool{}
	for _, file := range files {
		ast.Inspect(file.file, func(node ast.Node) bool {
			if call, ok := node.(*ast.CallExpr); ok {
				called[callableName(call.Fun)] = true
			}
			return true
		})
	}
	var result []sourceServicePort
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil || !called[function.Name.Name] {
				continue
			}
			functionValues := mergedStringValues(values, arguments[function.Name.Name])
			functionValues = functionStringValuesResolved(function, functionValues, returns)
			ast.Inspect(function.Body, func(node ast.Node) bool {
				literal, ok := node.(*ast.CompositeLit)
				if !ok || expressionType(literal.Type, nil, file).name != "ServiceSpec" {
					return true
				}
				ports := compositeLiteral(compositeFieldExpression(literal, "Ports"))
				if ports == nil {
					return true
				}
				for _, item := range ports.Elts {
					portLiteral := compositeLiteral(item)
					if portLiteral == nil {
						continue
					}
					port := staticInteger(compositeFieldExpression(portLiteral, "Port"), functionValues)
					targetExpression := compositeFieldExpression(portLiteral, "TargetPort")
					target := staticIntOrString(targetExpression, functionValues)
					targetName := staticIntOrStringName(targetExpression, functionValues, returns)
					if port != 0 {
						result = append(result, sourceServicePort{
							port: port, targetPort: target, targetName: targetName,
							affinity: sourceAffinity(file.path, function.Name.Name, ""),
							source:   sourceAt(file, portLiteral.Pos()),
						})
					}
				}
				return true
			})
		}
	}
	return result
}

func compositeStringList(expression ast.Expr, values, returns map[string]string) []string {
	literal := compositeLiteral(expression)
	if literal == nil {
		return nil
	}
	var result []string
	for _, item := range literal.Elts {
		if value, ok := staticSourceString(item, values, returns); ok {
			result = append(result, value)
		}
	}
	return result
}

func compositeNamedPorts(expression ast.Expr, values map[string]string) map[string]int {
	result := map[string]int{}
	literal := compositeLiteral(expression)
	if literal == nil {
		return result
	}
	for _, item := range literal.Elts {
		port := compositeLiteral(item)
		if port == nil {
			continue
		}
		name, _ := staticString(compositeFieldExpression(port, "Name"), values)
		number := staticInteger(compositeFieldExpression(port, "ContainerPort"), values)
		if number != 0 {
			result[name] = number
		}
	}
	return result
}

func compositeNamedItems(expression ast.Expr, field string, values, returns map[string]string) []string {
	literal := compositeLiteral(expression)
	if literal == nil {
		return nil
	}
	var result []string
	for _, item := range literal.Elts {
		candidate := compositeLiteral(item)
		if candidate == nil {
			continue
		}
		if value, ok := staticSourceString(compositeFieldExpression(candidate, field), values, returns); ok {
			result = append(result, value)
		}
	}
	return result
}

func staticInteger(expression ast.Expr, values map[string]string) int {
	if expression == nil {
		return 0
	}
	switch typed := expression.(type) {
	case *ast.BasicLit:
		if typed.Kind == token.INT {
			value, _ := strconv.Atoi(typed.Value)
			return value
		}
	case *ast.Ident:
		value, _ := strconv.Atoi(values[typed.Name])
		return value
	case *ast.CallExpr:
		if len(typed.Args) > 0 {
			return staticInteger(typed.Args[len(typed.Args)-1], values)
		}
	}
	return 0
}

func staticIntOrString(expression ast.Expr, values map[string]string) int {
	if value := staticInteger(expression, values); value != 0 {
		return value
	}
	call, ok := expression.(*ast.CallExpr)
	if !ok || len(call.Args) == 0 {
		return 0
	}
	if callableName(call.Fun) == "FromInt" {
		return staticInteger(call.Args[0], values)
	}
	return 0
}

func staticIntOrStringName(expression ast.Expr, values, returns map[string]string) string {
	call, ok := expression.(*ast.CallExpr)
	if !ok || callableName(call.Fun) != "FromString" || len(call.Args) != 1 {
		return ""
	}
	value, _ := staticSourceString(call.Args[0], values, returns)
	return value
}

func proxyFlags(args []string) map[string]string {
	result := map[string]string{}
	for _, argument := range args {
		argument = strings.TrimPrefix(argument, "--")
		if key, value, ok := strings.Cut(argument, "="); ok {
			result[key] = value
		}
	}
	return result
}

func addressPort(address string) int {
	index := strings.LastIndex(address, ":")
	if index < 0 {
		return 0
	}
	port, _ := strconv.Atoi(strings.TrimSuffix(address[index+1:], "/"))
	return port
}

func isKubeRBACProxy(container sourceContainer, flags map[string]string) bool {
	name := strings.ToLower(container.name)
	return (name == "kube-rbac-proxy" || name == "odh-kube-auth-proxy") &&
		flags["secure-listen-address"] != "" && flags["upstream"] != "" && flags["config-file"] != "" &&
		flags["tls-cert-file"] != "" && flags["tls-private-key-file"] != ""
}

func proxyPodProof(proxy sourceContainer, containers map[string]sourceContainer, pods []sourcePod, flags map[string]string) (sourcePod, sourceContainer, string, bool) {
	for _, pod := range pods {
		if pod.serviceAccount == "" || !containsString(pod.containers, proxy.variable) {
			continue
		}
		app := sourceContainer{}
		for _, variable := range pod.containers {
			candidate := containers[variable]
			if variable != proxy.variable && candidate.name != "" {
				app = candidate
				break
			}
		}
		if app.name == "" {
			continue
		}
		for _, mount := range proxy.volumeMounts {
			secret := pod.secretVolumes[mount]
			if secret != "" && (strings.Contains(strings.ToLower(secret), "tls") ||
				strings.Contains(flags["tls-cert-file"], "/"+mount+"/")) {
				return pod, app, secret, true
			}
		}
	}
	return sourcePod{}, sourceContainer{}, "", false
}

func matchingConstructedService(services []sourceServicePort, affinity string, listenPort int, proxyPorts map[string]int) (sourceServicePort, bool) {
	var fallback sourceServicePort
	fallbackCount := 0
	for index := range services {
		service := &services[index]
		targetMatches := service.targetPort == listenPort ||
			(service.targetName == "https" && proxyPorts["https"] == listenPort)
		if !targetMatches && service.port != listenPort {
			continue
		}
		if service.targetPort == 0 && targetMatches {
			service.targetPort = listenPort
		}
		if service.affinity == affinity {
			return *service, true
		}
		fallback = *service
		fallbackCount++
	}
	if fallbackCount == 1 {
		return fallback, true
	}
	return sourceServicePort{}, false
}

func packageContainsLiteral(files []sourceFile, wanted string) bool {
	for _, file := range files {
		found := false
		ast.Inspect(file.file, func(node ast.Node) bool {
			if found {
				return false
			}
			literal, ok := node.(*ast.BasicLit)
			if !ok || literal.Kind != token.STRING {
				return true
			}
			value, err := strconv.Unquote(literal.Value)
			if err == nil && strings.Contains(strings.ToLower(value), strings.ToLower(wanted)) {
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

func packageConstructsType(files []sourceFile, wanted string) bool {
	for _, file := range files {
		found := false
		ast.Inspect(file.file, func(node ast.Node) bool {
			if found {
				return false
			}
			literal, ok := node.(*ast.CompositeLit)
			if ok && expressionType(literal.Type, nil, file).name == wanted {
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

func bindingsForPackage(bindings []model.Binding, files []sourceFile) []model.Binding {
	directories := map[string]bool{}
	for _, file := range files {
		directories[filepath.ToSlash(filepath.Dir(file.path))] = true
	}
	var result []model.Binding
	for _, binding := range bindings {
		path := strings.Split(binding.Source, ":")[0]
		if directories[filepath.ToSlash(filepath.Dir(path))] {
			result = append(result, binding)
		}
	}
	return result
}

func matchingReviewBinding(bindings []model.Binding, serviceAccount string) (model.Binding, bool) {
	var result []model.Binding
	for _, binding := range bindings {
		for _, subject := range binding.Subjects {
			if strings.EqualFold(subject.Kind, "ServiceAccount") && subject.Name == serviceAccount {
				result = append(result, binding)
				break
			}
		}
	}
	if len(result) != 1 {
		return model.Binding{}, false
	}
	return result[0], true
}

func sourceAffinity(parts ...string) string {
	joined := strings.ToLower(strings.Join(parts, " "))
	if strings.Contains(joined, "mcp") {
		return "mcp"
	}
	return "default"
}

func proxySurface(file sourceFile, function *ast.FuncDecl, app string) string {
	surface := humanizeIdentifier(app)
	if sourceAffinity(file.path, function.Name.Name, app) == "mcp" {
		if !strings.HasSuffix(strings.ToLower(surface), " service") {
			surface += " Service"
		}
		return surface
	}
	if strings.EqualFold(app, file.file.Name.Name) {
		surface += " API"
	}
	return surface
}

func proxySurfaceMethods(surface string) string {
	if strings.Contains(strings.ToLower(surface), "mcp") {
		return "HTTP"
	}
	return "REST"
}

func packageAuthorizationScope(files []sourceFile, affinity string) string {
	for _, file := range files {
		if sourceAffinity(file.path, "", "") != affinity && affinity == "mcp" {
			continue
		}
		found := ""
		ast.Inspect(file.file, func(node ast.Node) bool {
			literal, ok := node.(*ast.BasicLit)
			if !ok || literal.Kind != token.STRING {
				return true
			}
			value, err := strconv.Unquote(literal.Value)
			if err != nil {
				return true
			}
			lower := strings.ToLower(value)
			if strings.Contains(lower, "subresource: proxy") && strings.Contains(lower, "verb: get") && strings.Contains(lower, "verb: create") {
				found = "RBAC get/create on evalhubs/proxy"
			} else if strings.Contains(lower, "authorization:") && strings.Contains(lower, "resourceattributes:") && found == "" {
				found = "Per-endpoint Kubernetes SubjectAccessReview"
			}
			return found == ""
		})
		if found != "" {
			return found
		}
	}
	return "Kubernetes SubjectAccessReview delegation"
}

func positionIsConditional(file *ast.File, position token.Pos) bool {
	conditional := false
	ast.Inspect(file, func(node ast.Node) bool {
		if conditional || node == nil || position < node.Pos() || position > node.End() {
			return !conditional
		}
		switch node.(type) {
		case *ast.IfStmt, *ast.ForStmt, *ast.RangeStmt, *ast.CaseClause, *ast.CommClause:
			conditional = true
			return false
		default:
			return true
		}
	})
	return conditional
}

func dedupeConstructedBindings(bindings []model.Binding) []model.Binding {
	seen := map[string]bool{}
	var result []model.Binding
	for _, binding := range bindings {
		key := binding.RoleRef + "\x00" + binding.Name + "\x00" + binding.Source
		if !seen[key] {
			seen[key] = true
			result = append(result, binding)
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Source < result[j].Source })
	return result
}

func dedupeRuntimeProxyControls(controls []model.RuntimeProxyControl) []model.RuntimeProxyControl {
	seen := map[string]bool{}
	var result []model.RuntimeProxyControl
	for _, control := range controls {
		key := strings.ToLower(control.Surface) + "\x00" + strconv.Itoa(control.ListenPort) + "\x00" + control.Source
		if !seen[key] {
			seen[key] = true
			result = append(result, control)
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Surface+result[i].Source < result[j].Surface+result[j].Source })
	return result
}

func dedupeRuntimeWebhookServers(servers []model.RuntimeWebhookServer) []model.RuntimeWebhookServer {
	seen := map[string]bool{}
	var result []model.RuntimeWebhookServer
	for _, server := range servers {
		key := strconv.Itoa(server.Port) + "\x00" + server.Source
		if !seen[key] {
			seen[key] = true
			result = append(result, server)
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Source < result[j].Source })
	return result
}

func containsString(values []string, candidate string) bool {
	for _, value := range values {
		if value == candidate {
			return true
		}
	}
	return false
}
