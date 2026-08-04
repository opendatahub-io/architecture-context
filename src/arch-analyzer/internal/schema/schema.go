package schema

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"gopkg.in/yaml.v3"
)

type extractedSchema struct {
	filename string
	schema   map[string]any
}

func Extract(root, outputDirectory string) (int, error) {
	absoluteRoot, err := filepath.Abs(root)
	if err != nil {
		return 0, fmt.Errorf("resolve repository path: %w", err)
	}
	var schemas []extractedSchema
	err = filepath.WalkDir(absoluteRoot, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			if path != absoluteRoot && ignoredDirectory(entry.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		if !isYAML(entry.Name()) {
			return nil
		}
		extracted, extractErr := extractFile(path)
		if extractErr != nil {
			return extractErr
		}
		schemas = append(schemas, extracted...)
		return nil
	})
	if err != nil {
		return 0, fmt.Errorf("scan CRD schemas: %w", err)
	}
	if len(schemas) == 0 {
		return 0, nil
	}
	sort.Slice(schemas, func(i, j int) bool { return schemas[i].filename < schemas[j].filename })
	if err := os.MkdirAll(outputDirectory, 0o755); err != nil {
		return 0, fmt.Errorf("create schema output directory: %w", err)
	}
	written := map[string]bool{}
	for _, extracted := range schemas {
		if written[extracted.filename] {
			continue
		}
		content, err := json.MarshalIndent(extracted.schema, "", "  ")
		if err != nil {
			return 0, fmt.Errorf("encode schema %s: %w", extracted.filename, err)
		}
		content = append(content, '\n')
		if err := os.WriteFile(filepath.Join(outputDirectory, extracted.filename), content, 0o644); err != nil {
			return 0, fmt.Errorf("write schema %s: %w", extracted.filename, err)
		}
		written[extracted.filename] = true
	}
	return len(written), nil
}

func extractFile(path string) ([]extractedSchema, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read CRD candidate %s: %w", path, err)
	}
	if !bytes.Contains(content, []byte("kind: CustomResourceDefinition")) {
		return nil, nil
	}
	if bytes.Contains(content, []byte("{{")) {
		return nil, nil
	}
	decoder := yaml.NewDecoder(bytes.NewReader(content))
	var result []extractedSchema
	for {
		var document map[string]any
		err := decoder.Decode(&document)
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, fmt.Errorf("parse CRD candidate %s: %w", path, err)
		}
		if stringValue(document, "kind") != "CustomResourceDefinition" {
			continue
		}
		spec := mapValue(document, "spec")
		kind := stringValue(mapValue(spec, "names"), "kind")
		if kind == "" {
			continue
		}
		versions, _ := spec["versions"].([]any)
		for _, rawVersion := range versions {
			version, _ := rawVersion.(map[string]any)
			name := stringValue(version, "name")
			schema := mapValue(mapValue(version, "schema"), "openAPIV3Schema")
			if name != "" && len(schema) > 0 {
				result = append(result, extractedSchema{filename: schemaFilename(kind, name), schema: schema})
			}
		}
		if len(versions) == 0 {
			name := stringValue(spec, "version")
			schema := mapValue(mapValue(spec, "validation"), "openAPIV3Schema")
			if name != "" && len(schema) > 0 {
				result = append(result, extractedSchema{filename: schemaFilename(kind, name), schema: schema})
			}
		}
	}
	return result, nil
}

func schemaFilename(kind, version string) string {
	name := strings.ToLower(kind + "." + version)
	name = strings.Map(func(r rune) rune {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '.' || r == '-' {
			return r
		}
		return '-'
	}, name)
	return name + ".json"
}

func mapValue(value map[string]any, key string) map[string]any {
	result, _ := value[key].(map[string]any)
	return result
}

func stringValue(value map[string]any, key string) string {
	result, _ := value[key].(string)
	return result
}

func isYAML(name string) bool {
	extension := strings.ToLower(filepath.Ext(name))
	return extension == ".yaml" || extension == ".yml"
}

func ignoredDirectory(name string) bool {
	switch name {
	case ".git", ".hg", ".svn", "node_modules", "vendor", "test", "tests", "testdata", "mock", "mocks", "k8mocks":
		return true
	default:
		return false
	}
}
