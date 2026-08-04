package gosource

import (
	"go/ast"
	"reflect"
	"sort"
	"strconv"
	"strings"
	"unicode"

	"github.com/jctanner/arch-analyzer/internal/model"
)

type sourceStruct struct {
	name     string
	typeSpec *ast.TypeSpec
	value    *ast.StructType
}

func extractConfigurableCRDAuthorization(file sourceFile) []model.AuthenticationFact {
	structures := sourceStructs(file.file)
	var result []model.AuthenticationFact
	for _, root := range structures {
		if !strings.HasSuffix(root.name, "Spec") || !structHasJSONField(root.value, "services") {
			continue
		}
		authType := structJSONFieldType(root.value, "authz")
		auth := structures[authType]
		if auth.value == nil || !hasExactlyOneValidation(file, auth.typeSpec) {
			continue
		}
		kubernetesType := structJSONFieldType(auth.value, "kubernetes")
		oidcType := structJSONFieldType(auth.value, "oidc")
		kubernetes := structures[kubernetesType]
		oidc := structures[oidcType]
		if kubernetes.value == nil || oidc.value == nil ||
			!structHasStringSliceField(kubernetes.value, "roles") ||
			!structHasLocalObjectReference(file, oidc.value, "secretRef") {
			continue
		}
		product := moduleProduct(file.modulePath)
		if product == "" {
			product = humanizeIdentifier(strings.TrimSuffix(root.name, "Spec"))
		}
		result = append(result, model.AuthenticationFact{
			Endpoint: product + " services (CRD-configured)", Methods: "ALL",
			Mechanism:        "Configurable: Kubernetes RBAC or OIDC",
			EnforcementPoint: "CRD-selected service authorization",
			Policy:           "Exactly one of Kubernetes RBAC roles or an OIDC Secret reference is required",
			Source:           sourceAt(file, auth.typeSpec.Pos()),
		})
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Endpoint < result[j].Endpoint })
	return result
}

func sourceStructs(file *ast.File) map[string]sourceStruct {
	result := map[string]sourceStruct{}
	for _, declaration := range file.Decls {
		general, ok := declaration.(*ast.GenDecl)
		if !ok {
			continue
		}
		for _, raw := range general.Specs {
			typeSpec, ok := raw.(*ast.TypeSpec)
			if !ok {
				continue
			}
			structure, ok := typeSpec.Type.(*ast.StructType)
			if ok {
				result[typeSpec.Name.Name] = sourceStruct{name: typeSpec.Name.Name, typeSpec: typeSpec, value: structure}
			}
		}
	}
	return result
}

func hasExactlyOneValidation(file sourceFile, typeSpec *ast.TypeSpec) bool {
	for _, group := range leadingCommentGroups(file, typeSpec.Pos()) {
		for _, line := range markerLines(group) {
			lower := strings.ToLower(line)
			if strings.Contains(lower, "+kubebuilder:validation:xvalidation:") &&
				strings.Contains(lower, "exists_one") && strings.Contains(lower, "kubernetes") && strings.Contains(lower, "oidc") {
				return true
			}
		}
	}
	return false
}

func structHasJSONField(structure *ast.StructType, jsonName string) bool {
	return structJSONField(structure, jsonName) != nil
}

func structJSONFieldType(structure *ast.StructType, jsonName string) string {
	field := structJSONField(structure, jsonName)
	if field == nil {
		return ""
	}
	return referencedTypeName(field.Type)
}

func structJSONField(structure *ast.StructType, jsonName string) *ast.Field {
	if structure == nil || structure.Fields == nil {
		return nil
	}
	for _, field := range structure.Fields.List {
		if fieldJSONName(field) == jsonName {
			return field
		}
	}
	return nil
}

func fieldJSONName(field *ast.Field) string {
	if field.Tag == nil {
		return ""
	}
	value, err := strconv.Unquote(field.Tag.Value)
	if err != nil {
		return ""
	}
	return strings.Split(reflect.StructTag(value).Get("json"), ",")[0]
}

func referencedTypeName(expression ast.Expr) string {
	switch typed := expression.(type) {
	case *ast.Ident:
		return typed.Name
	case *ast.StarExpr:
		return referencedTypeName(typed.X)
	case *ast.SelectorExpr:
		return typed.Sel.Name
	}
	return ""
}

func structHasStringSliceField(structure *ast.StructType, jsonName string) bool {
	field := structJSONField(structure, jsonName)
	array, ok := fieldType(field).(*ast.ArrayType)
	element, elementOK := arrayElement(array).(*ast.Ident)
	return ok && elementOK && element.Name == "string"
}

func structHasLocalObjectReference(file sourceFile, structure *ast.StructType, jsonName string) bool {
	field := structJSONField(structure, jsonName)
	selector, ok := fieldType(field).(*ast.SelectorExpr)
	alias, aliasOK := selectorReceiver(selector)
	return ok && aliasOK && selector.Sel.Name == "LocalObjectReference" && file.imports[alias] == "k8s.io/api/core/v1"
}

func fieldType(field *ast.Field) ast.Expr {
	if field == nil {
		return nil
	}
	return field.Type
}

func arrayElement(array *ast.ArrayType) ast.Expr {
	if array == nil {
		return nil
	}
	return array.Elt
}

func selectorReceiver(selector *ast.SelectorExpr) (string, bool) {
	if selector == nil {
		return "", false
	}
	identifier, ok := selector.X.(*ast.Ident)
	return identifierName(identifier), ok
}

func identifierName(identifier *ast.Ident) string {
	if identifier == nil {
		return ""
	}
	return identifier.Name
}

func extractEnumBasedCRDAuthentication(files []sourceFile) []model.AuthenticationFact {
	type packageKey struct {
		modulePath string
		packageDir string
	}
	byPackage := map[packageKey][]sourceFile{}
	for _, file := range files {
		key := packageKey{file.modulePath, file.packageDir}
		byPackage[key] = append(byPackage[key], file)
	}
	var result []model.AuthenticationFact
	for _, packageFiles := range byPackage {
		structures := map[string]sourceStruct{}
		structFile := map[string]sourceFile{}
		for _, file := range packageFiles {
			for name, s := range sourceStructs(file.file) {
				structures[name] = s
				structFile[name] = file
			}
		}
		for _, root := range structures {
			authField := findAuthField(root.value)
			if authField == nil {
				continue
			}
			authTypeName := referencedTypeName(authField.Type)
			auth := structures[authTypeName]
			if auth.value == nil {
				continue
			}
			authFile := structFile[authTypeName]
			enumValues := findEnumTypeField(authFile, auth)
			secretRef := hasSecretRefField(auth.value)
			if enumValues == "" || !secretRef {
				continue
			}
			file := structFile[root.name]
			product := moduleProduct(file.modulePath)
			if product == "" {
				product = humanizeIdentifier(strings.TrimSuffix(root.name, "Spec"))
			}
			result = append(result, model.AuthenticationFact{
				Endpoint: product + " (CRD-configured)", Methods: "ALL",
				Mechanism:        "Configurable: " + enumValues,
				EnforcementPoint: "CRD-specified authentication configuration",
				Policy:           "Authentication type selected by CRD enum with credential secret reference",
				Source:           sourceAt(authFile, auth.typeSpec.Pos()),
			})
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Endpoint < result[j].Endpoint })
	return result
}

func findAuthField(structure *ast.StructType) *ast.Field {
	if structure == nil || structure.Fields == nil {
		return nil
	}
	for _, field := range structure.Fields.List {
		jsonName := strings.ToLower(fieldJSONName(field))
		if jsonName == "auth" || jsonName == "authconfig" || jsonName == "authentication" || jsonName == "authmethod" {
			return field
		}
	}
	return nil
}

func findEnumTypeField(file sourceFile, auth sourceStruct) string {
	if auth.value == nil || auth.value.Fields == nil {
		return ""
	}
	for _, field := range auth.value.Fields.List {
		name := ""
		if len(field.Names) > 0 {
			name = field.Names[0].Name
		}
		if name != "Type" && name != "Mode" && name != "Method" {
			continue
		}
		ident, ok := field.Type.(*ast.Ident)
		if !ok || ident.Name != "string" {
			typeName := referencedTypeName(field.Type)
			if typeName == "" {
				continue
			}
		}
		for _, group := range leadingCommentGroups(file, field.Pos()) {
			for _, line := range markerLines(group) {
				lower := strings.ToLower(line)
				if strings.Contains(lower, "+kubebuilder:validation:enum") {
					start := strings.Index(lower, "enum")
					if start < 0 {
						continue
					}
					remainder := line[start:]
					eqIndex := strings.Index(remainder, "=")
					if eqIndex < 0 {
						continue
					}
					values := strings.TrimSpace(remainder[eqIndex+1:])
					values = strings.Trim(values, `"`)
					if values != "" {
						return values
					}
				}
			}
		}
	}
	return ""
}

func hasSecretRefField(structure *ast.StructType) bool {
	if structure == nil || structure.Fields == nil {
		return false
	}
	for _, field := range structure.Fields.List {
		jsonName := strings.ToLower(fieldJSONName(field))
		if strings.Contains(jsonName, "secret") {
			return true
		}
		if len(field.Names) > 0 {
			name := strings.ToLower(field.Names[0].Name)
			if strings.Contains(name, "secret") {
				return true
			}
		}
	}
	return false
}

func moduleProduct(modulePath string) string {
	parts := strings.Split(strings.TrimSuffix(modulePath, "/"), "/")
	if len(parts) < 3 {
		return ""
	}
	return humanizeIdentifier(strings.TrimSuffix(parts[2], ".git"))
}

func humanizeIdentifier(value string) string {
	words := strings.FieldsFunc(value, func(character rune) bool {
		return character == '-' || character == '_' || character == '.'
	})
	for index, word := range words {
		runes := []rune(strings.ToLower(word))
		if len(runes) > 0 {
			runes[0] = unicode.ToUpper(runes[0])
		}
		words[index] = string(runes)
	}
	return strings.Join(words, " ")
}
