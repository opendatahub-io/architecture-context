package extractor

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"gopkg.in/yaml.v3"
)

type object struct {
	data       map[string]any
	source     string
	line       int
	node       *yaml.Node
	transforms []*nameTransform
}

type nameTransform struct {
	prefix    string
	suffix    string
	namespace string
}

type kustomization struct {
	Resources             []string `yaml:"resources"`
	Bases                 []string `yaml:"bases"`
	Components            []string `yaml:"components"`
	PatchesStrategicMerge []string `yaml:"patchesStrategicMerge"`
	PatchesJSON6902       []struct {
		Path   string         `yaml:"path"`
		Target map[string]any `yaml:"target"`
	} `yaml:"patchesJson6902"`
	Patches            []any  `yaml:"patches"`
	NamePrefix         string `yaml:"namePrefix"`
	NameSuffix         string `yaml:"nameSuffix"`
	Namespace          string `yaml:"namespace"`
	ConfigMapGenerator []any  `yaml:"configMapGenerator"`
	SecretGenerator    []any  `yaml:"secretGenerator"`
	Replacements       []any  `yaml:"replacements"`
	Vars               []any  `yaml:"vars"`
	Images             []any  `yaml:"images"`
}

type loader struct {
	root       string
	visiting   map[string]bool
	transforms []*nameTransform
	warnings   []string
}

func (l *loader) load(path string) ([]object, error) {
	objects, err := l.loadRaw(path)
	if err != nil {
		return nil, err
	}
	for _, transform := range l.transforms {
		var scoped []object
		for index := range objects {
			if hasTransform(objects[index], transform) {
				scoped = append(scoped, objects[index])
			}
		}
		applyTransforms(scoped, transform.prefix, transform.suffix, transform.namespace)
	}
	return objects, nil
}

func hasTransform(item object, wanted *nameTransform) bool {
	for _, transform := range item.transforms {
		if transform == wanted {
			return true
		}
	}
	return false
}

func (l *loader) loadRaw(path string) ([]object, error) {
	path = filepath.Clean(path)
	info, err := os.Stat(path)
	if err != nil {
		return nil, fmt.Errorf("inspect manifest path %s: %w", path, err)
	}
	if !info.IsDir() {
		return l.loadYAML(path)
	}

	kustomizationPath := ""
	for _, name := range []string{"kustomization.yaml", "kustomization.yml", "kustomization.yaml.in", "Kustomization"} {
		candidate := filepath.Join(path, name)
		if _, err := os.Stat(candidate); err == nil {
			kustomizationPath = candidate
			break
		}
	}
	if kustomizationPath == "" {
		return nil, fmt.Errorf("no kustomization file in %s", path)
	}
	if l.visiting[kustomizationPath] {
		return nil, fmt.Errorf("kustomization cycle at %s", kustomizationPath)
	}
	l.visiting[kustomizationPath] = true
	defer delete(l.visiting, kustomizationPath)

	content, err := os.ReadFile(kustomizationPath)
	if err != nil {
		return nil, fmt.Errorf("read kustomization %s: %w", kustomizationPath, err)
	}
	var config kustomization
	if err := yaml.Unmarshal(content, &config); err != nil {
		return nil, fmt.Errorf("parse kustomization %s: %w", kustomizationPath, err)
	}
	l.recordUnsupported(config)

	entries := append(append(append([]string{}, config.Resources...), config.Bases...), config.Components...)
	var objects []object
	for _, entry := range entries {
		if isRemote(entry) {
			l.warn("remote resources skipped")
			continue
		}
		loaded, err := l.loadRaw(filepath.Join(path, entry))
		if err != nil {
			if errors.Is(err, os.ErrNotExist) {
				l.warn("missing optional kustomize resources skipped")
				continue
			}
			return nil, err
		}
		objects = append(objects, loaded...)
	}

	patchPaths := append([]string{}, config.PatchesStrategicMerge...)
	for _, raw := range config.Patches {
		switch patch := raw.(type) {
		case string:
			patchPaths = append(patchPaths, patch)
		case map[string]any:
			if patchPath, ok := patch["path"].(string); ok {
				if target, targeted := patch["target"].(map[string]any); targeted {
					objects, err = l.applyTargetedPatchFile(objects, filepath.Join(path, patchPath), target)
					if err != nil {
						if errors.Is(err, os.ErrNotExist) {
							l.warn("missing optional kustomize patches skipped")
							continue
						}
						return nil, err
					}
				} else {
					patchPaths = append(patchPaths, patchPath)
				}
			} else {
				l.warn("inline patches skipped")
			}
		}
	}
	for _, patch := range config.PatchesJSON6902 {
		if isRemote(patch.Path) {
			l.warn("remote patches skipped")
			continue
		}
		objects, err = l.applyJSONPatchFile(objects, filepath.Join(path, patch.Path), patch.Target)
		if err != nil {
			if errors.Is(err, os.ErrNotExist) {
				l.warn("missing optional kustomize patches skipped")
				continue
			}
			return nil, err
		}
	}
	for _, patchPath := range patchPaths {
		if isRemote(patchPath) {
			l.warn("remote patches skipped")
			continue
		}
		patches, err := l.loadYAML(filepath.Join(path, patchPath))
		if err != nil {
			if errors.Is(err, os.ErrNotExist) {
				l.warn("missing optional kustomize patches skipped")
				continue
			}
			return nil, err
		}
		objects = mergePatches(objects, patches)
	}

	if config.NamePrefix != "" || config.NameSuffix != "" || config.Namespace != "" {
		transform := &nameTransform{prefix: config.NamePrefix, suffix: config.NameSuffix, namespace: config.Namespace}
		l.transforms = append(l.transforms, transform)
		for index := range objects {
			objects[index].transforms = append(objects[index].transforms, transform)
		}
	}
	return objects, nil
}

func (l *loader) applyTargetedPatchFile(objects []object, path string, target map[string]any) ([]object, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read targeted patch %s: %w", path, err)
	}
	var document any
	if err := yaml.Unmarshal(content, &document); err != nil {
		return nil, fmt.Errorf("parse targeted patch %s: %w", path, err)
	}
	if _, isOperations := document.([]any); isOperations {
		return l.applyJSONPatchFile(objects, path, target)
	}
	patches, err := l.loadYAML(path)
	if err != nil {
		return nil, err
	}
	return mergePatches(objects, patches), nil
}

func (l *loader) recordUnsupported(config kustomization) {
	if len(config.ConfigMapGenerator) > 0 {
		l.warn("configMapGenerator not resolved")
	}
	if len(config.SecretGenerator) > 0 {
		l.warn("secretGenerator not resolved")
	}
	if len(config.Replacements) > 0 {
		l.warn("replacements not resolved")
	}
	if len(config.Vars) > 0 {
		l.warn("vars not resolved")
	}
	if len(config.Images) > 0 {
		l.warn("image transforms not resolved")
	}
}

func (l *loader) warn(message string) {
	l.warnings = appendUnique(l.warnings, message)
}

func (l *loader) applyJSONPatchFile(objects []object, path string, target map[string]any) ([]object, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read JSON patch %s: %w", path, err)
	}
	var operations []map[string]any
	if err := yaml.Unmarshal(content, &operations); err != nil {
		return nil, fmt.Errorf("parse JSON patch %s: %w", path, err)
	}
	relative, err := filepath.Rel(l.root, path)
	if err != nil {
		relative = path
	}
	for index := range objects {
		if kind := stringValue(target, "kind"); kind != "" && stringValue(objects[index].data, "kind") != kind {
			continue
		}
		if name := stringValue(target, "name"); name != "" && nestedString(objects[index].data, "metadata", "name") != name {
			continue
		}
		for _, operation := range operations {
			if err := applyJSONOperation(objects[index].data, operation); err != nil {
				l.warn("inapplicable JSON patch operations skipped")
				continue
			}
		}
		objects[index].source = filepath.ToSlash(relative)
		objects[index].line = 1
	}
	return objects, nil
}

func (l *loader) loadYAML(path string) ([]object, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("open manifest %s: %w", path, err)
	}
	defer file.Close()

	decoder := yaml.NewDecoder(file)
	var result []object
	for {
		var node yaml.Node
		err := decoder.Decode(&node)
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return nil, fmt.Errorf("parse manifest %s: %w", path, err)
		}
		if len(node.Content) == 0 {
			continue
		}
		var data map[string]any
		if err := node.Decode(&data); err != nil {
			return nil, fmt.Errorf("decode manifest %s: %w", path, err)
		}
		if stringValue(data, "kind") == "" {
			continue
		}
		relative, err := filepath.Rel(l.root, path)
		if err != nil {
			relative = path
		}
		result = append(result, object{
			data: data, source: filepath.ToSlash(relative), line: node.Content[0].Line,
			node: node.Content[0],
		})
	}
	return result, nil
}

func selectManifestRoot(root, overlay, distribution string) (string, error) {
	if overlay != "" {
		if !filepath.IsAbs(overlay) {
			overlay = filepath.Join(root, overlay)
		}
		return overlay, nil
	}

	var candidates []string
	foundKustomization := false
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() && path != root && ignoredDir(entry.Name()) {
			return filepath.SkipDir
		}
		if entry.IsDir() || !isKustomization(entry.Name()) {
			return nil
		}
		foundKustomization = true
		dir := filepath.Dir(path)
		if distribution == "" || pathMatchesDistribution(dir, distribution) {
			candidates = append(candidates, dir)
		}
		return nil
	})
	if err != nil {
		return "", fmt.Errorf("scan repository: %w", err)
	}
	if len(candidates) == 0 {
		if distribution != "" && foundKustomization {
			return "", fmt.Errorf("no kustomization matches distribution %q; use --overlay to select one", distribution)
		}
		return "", nil
	}
	sort.Slice(candidates, func(i, j int) bool {
		leftDefault := filepath.Base(candidates[i]) == "default"
		rightDefault := filepath.Base(candidates[j]) == "default"
		if leftDefault != rightDefault {
			return leftDefault
		}
		left := strings.Count(filepath.Clean(candidates[i]), string(filepath.Separator))
		right := strings.Count(filepath.Clean(candidates[j]), string(filepath.Separator))
		if left == right {
			return candidates[i] < candidates[j]
		}
		return left < right
	})
	return candidates[0], nil
}

func loadAllYAML(root string) ([]object, []string, error) {
	l := loader{root: root, visiting: map[string]bool{}}
	var objects []object
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() && path != root && ignoredDir(entry.Name()) {
			return filepath.SkipDir
		}
		if entry.IsDir() || isKustomization(entry.Name()) || !isYAML(entry.Name()) {
			return nil
		}
		loaded, err := l.loadYAML(path)
		if err != nil {
			relative, relativeErr := filepath.Rel(root, path)
			if relativeErr != nil {
				relative = path
			}
			l.warn("unparseable or templated YAML skipped during repository-wide discovery: " + filepath.ToSlash(relative))
			return nil
		}
		objects = append(objects, loaded...)
		return nil
	})
	return objects, l.warnings, err
}

func isRemote(path string) bool {
	return strings.Contains(path, "://") || strings.HasPrefix(path, "git@")
}

func isYAML(name string) bool {
	extension := strings.ToLower(filepath.Ext(name))
	return extension == ".yaml" || extension == ".yml"
}

func isKustomization(name string) bool {
	return name == "Kustomization" || strings.EqualFold(name, "kustomization.yaml") ||
		strings.EqualFold(name, "kustomization.yml") || strings.EqualFold(name, "kustomization.yaml.in")
}

func ignoredDir(name string) bool {
	switch name {
	case ".git", ".hg", ".svn", "node_modules", "vendor":
		return true
	default:
		return false
	}
}

func pathMatchesDistribution(path, distribution string) bool {
	wanted := strings.ToLower(distribution)
	for _, part := range strings.Split(filepath.ToSlash(path), "/") {
		if strings.ToLower(part) == wanted {
			return true
		}
	}
	return strings.Contains(strings.ToLower(filepath.ToSlash(path)), wanted)
}
