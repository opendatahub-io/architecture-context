package loader

import (
	"io/fs"
	"strings"

	"github.com/jctanner/arch-query/internal/jsondata"
	"github.com/jctanner/arch-query/internal/markdown"
	"github.com/jctanner/arch-query/internal/overlay"
	"github.com/jctanner/arch-query/internal/types"
)

func LoadVersion(fsys fs.FS, overlayFS fs.FS, version string) (*types.VersionData, error) {
	resolved, err := ResolveVersion(fsys, version)
	if err != nil {
		return nil, err
	}

	entries, err := fs.ReadDir(fsys, resolved)
	if err != nil {
		return nil, err
	}

	components := make(map[string]*types.ComponentDoc)
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if !strings.HasSuffix(name, ".md") || isExcludedFile(name) {
			continue
		}
		key := strings.TrimSuffix(name, ".md")
		path := resolved + "/" + name
		doc, err := markdown.ParseComponentDoc(fsys, path)
		if err != nil {
			continue
		}
		components[key] = doc
	}

	// Enrich with arch-analyzer JSON data
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if !strings.HasSuffix(name, ".json") || isExcludedFile(name) {
			continue
		}
		key := strings.TrimSuffix(name, ".json")
		jsonPath := resolved + "/" + name
		jsonDoc, err := jsondata.ParseComponentJSON(fsys, jsonPath)
		if err != nil {
			continue
		}
		if existing, ok := components[key]; ok {
			mergeJSON(existing, jsonDoc)
		} else {
			jsonDoc.Name = key
			jsonDoc.FileName = name
			components[key] = jsonDoc
		}
	}

	platformPath := resolved + "/PLATFORM.md"
	platform, _ := markdown.ParsePlatformDoc(fsys, platformPath)

	var overlays []*types.OverlayDoc
	if overlayFS != nil {
		overlays, _ = overlay.LoadOverlays(overlayFS)
	}

	data := &types.VersionData{
		Version: types.VersionInfo{
			Name:           version,
			Path:           resolved,
			ComponentCount: len(components),
		},
		Components: components,
		Platform:   platform,
		Overlays:   overlays,
	}

	return data, nil
}

// mergeJSON supplements a markdown-parsed doc with arch-analyzer JSON data.
// JSON-only fields are always set. For shared fields (services, RBAC, endpoints,
// internal deps), JSON data is appended only when the markdown doc has none.
func mergeJSON(dst, src *types.ComponentDoc) {
	// Always set JSON-only fields
	dst.ControllerWatches = src.ControllerWatches
	dst.NetworkPolicies = src.NetworkPolicies
	dst.Dockerfiles = src.Dockerfiles
	dst.CommitSHA = src.CommitSHA
	dst.AnalyzerVersion = src.AnalyzerVersion

	// Supplement shared fields if markdown didn't populate them
	if len(dst.Services) == 0 {
		dst.Services = src.Services
	}
	if len(dst.RBACRoles) == 0 {
		dst.RBACRoles = src.RBACRoles
	}
	if len(dst.Endpoints) == 0 {
		dst.Endpoints = src.Endpoints
	}
	if len(dst.InternalDeps) == 0 {
		dst.InternalDeps = src.InternalDeps
	}
}
