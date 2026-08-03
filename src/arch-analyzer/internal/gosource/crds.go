package gosource

import (
	"go/ast"
	"go/token"
	"sort"
	"strconv"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func extractKubebuilderReferenceContracts(files []sourceFile) []model.APIReferenceContract {
	definitions := collectStructDefinitions(files)
	enums := collectTypedStringValues(files)
	var result []model.APIReferenceContract
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			general, ok := declaration.(*ast.GenDecl)
			if !ok || general.Tok.String() != "type" {
				continue
			}
			for _, raw := range general.Specs {
				typeSpec, ok := raw.(*ast.TypeSpec)
				if !ok || !markerPresent("+kubebuilder:object:root=true", leadingCommentGroups(file, typeSpec.Pos())...) ||
					strings.HasSuffix(typeSpec.Name.Name, "List") {
					continue
				}
				root := typeKey(goType{packagePath: packagePath(file), name: typeSpec.Name.Name})
				walkReferenceContracts(definitions, enums, root, typeSpec.Name.Name, "", map[string]bool{}, &result, 0)
			}
		}
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].OwnerKind+result[i].Field < result[j].OwnerKind+result[j].Field
	})
	return result
}

func walkReferenceContracts(
	definitions map[string]structDefinition,
	enums map[string][]string,
	typeName, ownerKind, path string,
	visiting map[string]bool,
	result *[]model.APIReferenceContract,
	depth int,
) {
	if depth > 8 || visiting[typeName] {
		return
	}
	definition, ok := definitions[typeName]
	if !ok {
		return
	}
	visiting[typeName] = true
	defer delete(visiting, typeName)

	var kindDefault, failureDefault, source string
	var failureType goType
	for _, field := range definition.fields {
		switch field.name {
		case "Kind":
			kindDefault = field.defaultValue
			if source == "" {
				source = field.source
			}
		case "FailureMode":
			failureDefault = field.defaultValue
			failureType = field.typeRef
			if source == "" {
				source = field.source
			}
		}
	}
	if kindDefault != "" && failureDefault != "" && path != "" {
		*result = append(*result, model.APIReferenceContract{
			OwnerKind: ownerKind, Field: path, DefaultKind: kindDefault,
			FailureModeDefault: failureDefault,
			FailureModes:       append([]string{}, enums[typeKey(failureType)]...), Source: source,
		})
	}
	for _, field := range definition.fields {
		if field.typeRef.name == "" {
			continue
		}
		fieldPath := field.name
		if path != "" {
			fieldPath = path + "." + field.name
		}
		walkReferenceContracts(definitions, enums, typeKey(field.typeRef), ownerKind, fieldPath, visiting, result, depth+1)
	}
}

func collectTypedStringValues(files []sourceFile) map[string][]string {
	result := map[string][]string{}
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			general, ok := declaration.(*ast.GenDecl)
			if !ok || general.Tok.String() != "const" {
				continue
			}
			for _, raw := range general.Specs {
				value, ok := raw.(*ast.ValueSpec)
				if !ok || value.Type == nil {
					continue
				}
				key := typeKey(expressionType(value.Type, nil, file))
				for _, expression := range value.Values {
					literal, ok := quotedStringLiteral(expression)
					if ok {
						seen := false
						for _, existing := range result[key] {
							seen = seen || existing == literal
						}
						if !seen {
							result[key] = append(result[key], literal)
						}
					}
				}
			}
		}
	}
	return result
}

type apiPackage struct {
	group   string
	version string
}

func extractKubebuilderCRDs(files []sourceFile) ([]model.CRD, string) {
	packages := map[string]apiPackage{}
	for _, file := range files {
		key := sourcePackageKey(file)
		metadata := packages[key]
		if group := groupNameMarker(file.file); group != "" {
			metadata.group = group
		}
		group, version := groupVersionLiteral(file.file)
		if metadata.group == "" {
			metadata.group = group
		}
		if metadata.version == "" {
			metadata.version = version
		}
		if metadata.version == "" {
			candidate := file.packageDir
			if index := strings.LastIndex(candidate, "/"); index >= 0 {
				candidate = candidate[index+1:]
			}
			if isKubernetesVersion(candidate) {
				metadata.version = candidate
			}
		}
		packages[key] = metadata
	}

	var crds []model.CRD
	rootTypes := 0
	unresolved := 0
	for _, file := range files {
		metadata := packages[sourcePackageKey(file)]
		for _, declaration := range file.file.Decls {
			general, ok := declaration.(*ast.GenDecl)
			if !ok || general.Tok.String() != "type" {
				continue
			}
			for _, raw := range general.Specs {
				typeSpec, ok := raw.(*ast.TypeSpec)
				if !ok {
					continue
				}
				comments := leadingCommentGroups(file, typeSpec.Pos())
				if !markerPresent("+kubebuilder:object:root=true", comments...) {
					continue
				}
				if strings.HasSuffix(typeSpec.Name.Name, "List") {
					continue
				}
				if _, ok := typeSpec.Type.(*ast.StructType); !ok {
					continue
				}
				rootTypes++
				if metadata.group == "" || metadata.version == "" {
					unresolved++
					continue
				}
				crds = append(crds, model.CRD{
					Group:   metadata.group,
					Version: metadata.version,
					Kind:    typeSpec.Name.Name,
					Scope:   resourceScope(comments...),
					Source:  sourceAt(file, typeSpec.Pos()),
				})
			}
		}
	}

	crds = dedupeCRDs(crds)
	switch {
	case rootTypes == 0:
		return nil, "not_found"
	case unresolved > 0:
		return crds, "partial: extracted " + strconv.Itoa(len(crds)) +
			" Kubebuilder CRD identities; " + strconv.Itoa(unresolved) +
			" root API types lacked group or version metadata"
	default:
		return crds, "complete: extracted " + strconv.Itoa(len(crds)) +
			" Kubebuilder CRD identities"
	}
}

func leadingCommentGroups(file sourceFile, position token.Pos) []*ast.CommentGroup {
	previousDeclaration := token.NoPos
	for _, declaration := range file.file.Decls {
		if declaration.End() < position && declaration.End() > previousDeclaration {
			previousDeclaration = declaration.End()
		}
	}
	ast.Inspect(file.file, func(node ast.Node) bool {
		typeSpec, ok := node.(*ast.TypeSpec)
		if ok && typeSpec.End() < position && typeSpec.End() > previousDeclaration {
			previousDeclaration = typeSpec.End()
		}
		return true
	})
	var result []*ast.CommentGroup
	for _, group := range file.file.Comments {
		if group.Pos() > previousDeclaration && group.End() < position {
			result = append(result, group)
		}
	}
	return result
}

func sourcePackageKey(file sourceFile) string {
	return file.modulePath + "\x00" + file.packageDir + "\x00" + file.file.Name.Name
}

func groupNameMarker(file *ast.File) string {
	for _, group := range file.Comments {
		for _, line := range markerLines(group) {
			if value, ok := strings.CutPrefix(line, "+groupName="); ok {
				return strings.TrimSpace(value)
			}
		}
	}
	return ""
}

func groupVersionLiteral(file *ast.File) (string, string) {
	group := ""
	version := ""
	ast.Inspect(file, func(node ast.Node) bool {
		literal, ok := node.(*ast.CompositeLit)
		if !ok || !isGroupVersionType(literal.Type) {
			return true
		}
		for _, raw := range literal.Elts {
			entry, ok := raw.(*ast.KeyValueExpr)
			if !ok {
				continue
			}
			key, ok := entry.Key.(*ast.Ident)
			if !ok {
				continue
			}
			value, ok := quotedStringLiteral(entry.Value)
			if !ok {
				continue
			}
			switch key.Name {
			case "Group":
				group = value
			case "Version":
				version = value
			}
		}
		return group == "" || version == ""
	})
	return group, version
}

func isGroupVersionType(expression ast.Expr) bool {
	switch value := expression.(type) {
	case *ast.Ident:
		return value.Name == "GroupVersion"
	case *ast.SelectorExpr:
		return value.Sel.Name == "GroupVersion"
	default:
		return false
	}
}

func quotedStringLiteral(expression ast.Expr) (string, bool) {
	literal, ok := expression.(*ast.BasicLit)
	if !ok || literal.Kind.String() != "STRING" {
		return "", false
	}
	value, err := strconv.Unquote(literal.Value)
	return value, err == nil
}

func markerPresent(marker string, groups ...*ast.CommentGroup) bool {
	for _, group := range groups {
		for _, line := range markerLines(group) {
			if line == marker {
				return true
			}
		}
	}
	return false
}

func resourceScope(groups ...*ast.CommentGroup) string {
	for _, group := range groups {
		for _, line := range markerLines(group) {
			value, ok := strings.CutPrefix(line, "+kubebuilder:resource:")
			if !ok {
				continue
			}
			for _, option := range strings.Split(value, ",") {
				if scope, ok := strings.CutPrefix(strings.TrimSpace(option), "scope="); ok {
					if strings.EqualFold(scope, "cluster") {
						return "Cluster"
					}
					return "Namespaced"
				}
			}
		}
	}
	return "Namespaced"
}

func markerLines(group *ast.CommentGroup) []string {
	if group == nil {
		return nil
	}
	result := make([]string, 0, len(group.List))
	for _, comment := range group.List {
		text := strings.TrimSpace(comment.Text)
		text = strings.TrimPrefix(text, "//")
		text = strings.TrimPrefix(text, "/*")
		text = strings.TrimSuffix(text, "*/")
		for _, line := range strings.Split(text, "\n") {
			result = append(result, strings.TrimSpace(line))
		}
	}
	return result
}

func isKubernetesVersion(value string) bool {
	if len(value) < 2 || value[0] != 'v' || value[1] < '0' || value[1] > '9' {
		return false
	}
	for _, character := range value[2:] {
		if (character < '0' || character > '9') &&
			(character < 'a' || character > 'z') {
			return false
		}
	}
	return true
}

func dedupeCRDs(values []model.CRD) []model.CRD {
	seen := map[string]bool{}
	result := make([]model.CRD, 0, len(values))
	for _, value := range values {
		key := value.Group + "\x00" + value.Version + "\x00" + value.Kind
		if seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, value)
	}
	return result
}
