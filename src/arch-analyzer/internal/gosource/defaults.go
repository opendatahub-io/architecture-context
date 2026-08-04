package gosource

import (
	"go/ast"
	"go/token"
	"sort"
	"strconv"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

type structField struct {
	name         string
	typeRef      goType
	defaultValue string
	source       string
}

type structDefinition struct {
	fields []structField
}

type defaultCandidate struct {
	value    string
	sources  map[string]bool
	conflict bool
}

func extractKubebuilderDefaults(files []sourceFile) map[string]model.SourceDefault {
	definitions := collectStructDefinitions(files)
	candidates := map[string]*defaultCandidate{}
	keys := make([]string, 0, len(definitions))
	for key := range definitions {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		walkDefaultFields(definitions, key, "", map[string]bool{}, candidates, 0)
	}

	result := make(map[string]model.SourceDefault, len(candidates))
	for path, candidate := range candidates {
		if candidate.conflict || candidate.value == "" {
			continue
		}
		sources := mapKeys(candidate.sources)
		result[path] = model.SourceDefault{Path: path, Value: candidate.value, Sources: sources}
	}
	return result
}

func collectStructDefinitions(files []sourceFile) map[string]structDefinition {
	definitions := map[string]structDefinition{}
	for _, file := range files {
		for _, declaration := range file.file.Decls {
			general, ok := declaration.(*ast.GenDecl)
			if !ok || general.Tok.String() != "type" {
				continue
			}
			for _, rawSpec := range general.Specs {
				typeSpec, ok := rawSpec.(*ast.TypeSpec)
				if !ok {
					continue
				}
				structType, ok := typeSpec.Type.(*ast.StructType)
				if !ok {
					continue
				}
				definition := structDefinition{}
				previousFieldEnd := structType.Fields.Opening
				for _, field := range structType.Fields.List {
					defaultValue, defaultPosition := kubebuilderDefault(file, field, previousFieldEnd)
					fieldType := expressionType(field.Type, nil, file)
					for _, name := range field.Names {
						evidencePosition := name.Pos()
						if defaultPosition.IsValid() {
							evidencePosition = defaultPosition
						}
						definition.fields = append(definition.fields, structField{
							name:         name.Name,
							typeRef:      fieldType,
							defaultValue: defaultValue,
							source:       sourceAt(file, evidencePosition),
						})
					}
					previousFieldEnd = field.End()
				}
				definitions[typeKey(goType{
					packagePath: packagePath(file),
					name:        typeSpec.Name.Name,
				})] = definition
			}
		}
	}
	return definitions
}

func walkDefaultFields(
	definitions map[string]structDefinition,
	typeName string,
	prefix string,
	visiting map[string]bool,
	candidates map[string]*defaultCandidate,
	depth int,
) {
	if depth > 10 || visiting[typeName] {
		return
	}
	definition, ok := definitions[typeName]
	if !ok {
		return
	}
	visiting[typeName] = true
	defer delete(visiting, typeName)
	for _, field := range definition.fields {
		path := field.name
		if prefix != "" {
			path = prefix + "." + field.name
		}
		if field.defaultValue != "" {
			addDefaultCandidate(candidates, path, field.defaultValue, field.source)
		}
		if field.typeRef.name != "" {
			walkDefaultFields(definitions, typeKey(field.typeRef), path, visiting, candidates, depth+1)
		}
	}
}

func addDefaultCandidate(candidates map[string]*defaultCandidate, path, value, source string) {
	candidate := candidates[path]
	if candidate == nil {
		candidate = &defaultCandidate{value: value, sources: map[string]bool{}}
		candidates[path] = candidate
	} else if candidate.value != value {
		candidate.conflict = true
	}
	if source != "" {
		candidate.sources[source] = true
	}
}

func kubebuilderDefault(file sourceFile, field *ast.Field, previousFieldEnd token.Pos) (string, token.Pos) {
	for _, group := range []*ast.CommentGroup{field.Doc, field.Comment} {
		if value, position := defaultInCommentGroup(group); value != "" {
			return value, position
		}
	}
	for _, group := range file.file.Comments {
		if group.Pos() <= previousFieldEnd || group.End() >= field.Pos() {
			continue
		}
		if value, position := defaultInCommentGroup(group); value != "" {
			return value, position
		}
	}
	return "", token.NoPos
}

func defaultInCommentGroup(group *ast.CommentGroup) (string, token.Pos) {
	if group == nil {
		return "", token.NoPos
	}
	for _, comment := range group.List {
		text := comment.Text
		marker := strings.Index(text, "+kubebuilder:default")
		if marker < 0 {
			continue
		}
		value := strings.TrimSpace(text[marker+len("+kubebuilder:default"):])
		value = strings.TrimPrefix(value, ":=")
		value = strings.TrimPrefix(value, "=")
		value = strings.TrimPrefix(value, ":")
		value = strings.TrimSpace(strings.TrimSuffix(value, "*/"))
		if strings.HasPrefix(value, "{") || strings.HasPrefix(value, "[") {
			return "", token.NoPos
		}
		if unquoted, err := strconv.Unquote(value); err == nil {
			return unquoted, comment.Pos()
		}
		return value, comment.Pos()
	}
	return "", token.NoPos
}

func packagePath(file sourceFile) string {
	path := file.modulePath
	if file.packageDir != "" {
		path += "/" + file.packageDir
	}
	return path
}

func typeKey(value goType) string {
	return value.packagePath + "\x00" + value.name
}
