package gosource

import (
	"go/ast"
	"go/token"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"unicode"

	"github.com/jctanner/arch-analyzer/internal/model"
)

type constructedSecret struct {
	variable string
	fact     model.Secret
}

var sprintfVerb = regexp.MustCompile(`%[-+#0-9.]*[sdv]`)

func extractConstructedSecrets(file sourceFile) []model.Secret {
	var result []model.Secret
	for _, declaration := range file.file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		values := functionStringValues(function)
		candidates := functionConstructedSecrets(function, file, values)
		created := functionCreatedVariables(function)
		for _, candidate := range candidates {
			if created[candidate.variable] {
				result = append(result, candidate.fact)
			}
		}
	}
	return result
}

func functionStringValues(function *ast.FuncDecl) map[string]string {
	values := map[string]string{}
	for pass := 0; pass < 4; pass++ {
		ast.Inspect(function.Body, func(node ast.Node) bool {
			switch statement := node.(type) {
			case *ast.AssignStmt:
				for index, left := range statement.Lhs {
					identifier, ok := left.(*ast.Ident)
					if !ok || index >= len(statement.Rhs) {
						continue
					}
					if value, ok := staticString(statement.Rhs[index], values); ok {
						values[identifier.Name] = value
					}
				}
			case *ast.ValueSpec:
				for index, name := range statement.Names {
					if index >= len(statement.Values) {
						continue
					}
					if value, ok := staticString(statement.Values[index], values); ok {
						values[name.Name] = value
					}
				}
			}
			return true
		})
	}
	return values
}

func functionConstructedSecrets(function *ast.FuncDecl, file sourceFile, values map[string]string) []constructedSecret {
	var result []constructedSecret
	ast.Inspect(function.Body, func(node ast.Node) bool {
		switch statement := node.(type) {
		case *ast.AssignStmt:
			for index, left := range statement.Lhs {
				identifier, ok := left.(*ast.Ident)
				if !ok || index >= len(statement.Rhs) {
					continue
				}
				if fact, ok := secretFromExpression(statement.Rhs[index], file, values); ok {
					result = append(result, constructedSecret{variable: identifier.Name, fact: fact})
				}
			}
		case *ast.ValueSpec:
			for index, name := range statement.Names {
				if index >= len(statement.Values) {
					continue
				}
				if fact, ok := secretFromExpression(statement.Values[index], file, values); ok {
					result = append(result, constructedSecret{variable: name.Name, fact: fact})
				}
			}
		}
		return true
	})
	return result
}

func functionCreatedVariables(function *ast.FuncDecl) map[string]bool {
	created := map[string]bool{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok || !creationCall(call.Fun) {
			return true
		}
		for _, argument := range call.Args {
			if identifier := expressionIdentifier(argument); identifier != "" {
				created[identifier] = true
			}
		}
		return true
	})
	return created
}

func creationCall(expression ast.Expr) bool {
	name := ""
	switch callable := expression.(type) {
	case *ast.Ident:
		name = callable.Name
	case *ast.SelectorExpr:
		name = callable.Sel.Name
	}
	normalized := strings.ToLower(name)
	return normalized == "create" || strings.Contains(normalized, "createorupdate") ||
		strings.Contains(normalized, "createorpatch") || strings.HasPrefix(normalized, "reconcile")
}

func expressionIdentifier(expression ast.Expr) string {
	switch typed := expression.(type) {
	case *ast.Ident:
		return typed.Name
	case *ast.UnaryExpr:
		return expressionIdentifier(typed.X)
	case *ast.ParenExpr:
		return expressionIdentifier(typed.X)
	}
	return ""
}

func secretFromExpression(expression ast.Expr, file sourceFile, values map[string]string) (model.Secret, bool) {
	literal := compositeLiteral(expression)
	if literal == nil {
		return model.Secret{}, false
	}
	resourceType := expressionType(literal.Type, nil, file)
	if resourceType.name != "Secret" || !isKubernetesAPI(resourceType.packagePath, file.modulePath) {
		return model.Secret{}, false
	}
	name := ""
	secretType := "Opaque"
	for _, rawElement := range literal.Elts {
		element, ok := rawElement.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		key, _ := element.Key.(*ast.Ident)
		if key == nil {
			continue
		}
		switch key.Name {
		case "ObjectMeta":
			if metadata := compositeLiteral(element.Value); metadata != nil {
				name = compositeStringField(metadata, "Name", values)
			}
		case "Type":
			if value, ok := staticString(element.Value, values); ok {
				secretType = value
			}
		}
	}
	if name == "" {
		return model.Secret{}, false
	}
	return model.Secret{
		Name:          name,
		Type:          secretType,
		ProvisionedBy: "controller Go source",
		Source:        sourceAt(file, literal.Pos()),
	}, true
}

func compositeLiteral(expression ast.Expr) *ast.CompositeLit {
	switch typed := expression.(type) {
	case *ast.CompositeLit:
		return typed
	case *ast.UnaryExpr:
		return compositeLiteral(typed.X)
	case *ast.ParenExpr:
		return compositeLiteral(typed.X)
	}
	return nil
}

func compositeStringField(literal *ast.CompositeLit, field string, values map[string]string) string {
	for _, rawElement := range literal.Elts {
		element, ok := rawElement.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		key, _ := element.Key.(*ast.Ident)
		if key != nil && key.Name == field {
			value, _ := staticString(element.Value, values)
			return value
		}
	}
	return ""
}

func staticString(expression ast.Expr, values map[string]string) (string, bool) {
	switch typed := expression.(type) {
	case *ast.BasicLit:
		if typed.Kind != token.STRING {
			return "", false
		}
		value, err := strconv.Unquote(typed.Value)
		return value, err == nil
	case *ast.Ident:
		value, ok := values[typed.Name]
		return value, ok
	case *ast.ParenExpr:
		return staticString(typed.X, values)
	case *ast.BinaryExpr:
		if typed.Op != token.ADD {
			return "", false
		}
		left, leftOK := staticString(typed.X, values)
		right, rightOK := staticString(typed.Y, values)
		return left + right, leftOK && rightOK
	case *ast.SelectorExpr:
		switch typed.Sel.Name {
		case "SecretTypeOpaque":
			return "Opaque", true
		case "SecretTypeTLS":
			return "kubernetes.io/tls", true
		case "SecretTypeDockerConfigJson":
			return "kubernetes.io/dockerconfigjson", true
		case "Name":
			return "{name}", true
		default:
			return "{" + kebabCase(typed.Sel.Name) + "}", true
		}
	case *ast.CallExpr:
		selector, ok := typed.Fun.(*ast.SelectorExpr)
		if ok && selector.Sel.Name == "Itoa" && len(typed.Args) == 1 {
			return staticString(typed.Args[0], values)
		}
		if !ok || selector.Sel.Name != "Sprintf" || len(typed.Args) == 0 {
			return "", false
		}
		format, ok := staticString(typed.Args[0], values)
		if !ok {
			return "", false
		}
		for _, argument := range typed.Args[1:] {
			value, resolved := staticString(argument, values)
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
	return "", false
}

func kebabCase(value string) string {
	var result []rune
	for index, char := range value {
		if unicode.IsUpper(char) {
			if index > 0 {
				result = append(result, '-')
			}
			result = append(result, unicode.ToLower(char))
			continue
		}
		result = append(result, char)
	}
	return string(result)
}

func dedupeConstructedSecrets(secrets []model.Secret) []model.Secret {
	seen := map[string]bool{}
	result := make([]model.Secret, 0, len(secrets))
	for _, secret := range secrets {
		key := secret.Name + "\x00" + secret.Source
		if !seen[key] {
			seen[key] = true
			result = append(result, secret)
		}
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].Name+result[i].Source < result[j].Name+result[j].Source
	})
	return result
}
