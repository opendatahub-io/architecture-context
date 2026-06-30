package loader

import (
	"encoding/json"
	"fmt"
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

	buildInfo := loadBuildInfo(fsys, resolved)
	provenance, _ := loadProvenance(fsys, resolved)

	data := &types.VersionData{
		Version: types.VersionInfo{
			Name:           version,
			Path:           resolved,
			ComponentCount: len(components),
		},
		Components: components,
		Platform:   platform,
		Overlays:   overlays,
		BuildInfo:  buildInfo,
		Provenance: provenance,
	}

	return data, nil
}

func loadBuildInfo(fsys fs.FS, versionDir string) *types.BuildInfo {
	path := versionDir + "/build-info.json"
	raw, err := fs.ReadFile(fsys, path)
	if err != nil {
		return nil
	}
	var bi types.BuildInfo
	if err := json.Unmarshal(raw, &bi); err != nil {
		return nil
	}
	return &bi
}

func loadProvenance(fsys fs.FS, versionDir string) (*types.Provenance, error) {
	path := versionDir + "/component-map.json"
	raw, err := fs.ReadFile(fsys, path)
	if err != nil {
		return nil, fmt.Errorf("reading %s: %w", path, err)
	}
	var wrapper struct {
		Provenance *types.Provenance `json:"provenance"`
	}
	if err := json.Unmarshal(raw, &wrapper); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	return wrapper.Provenance, nil
}

// LoadComponentRepoMapping reads component-map.json and builds a map from
// component key to "org/repo" string for cross-referencing with provenance data.
func LoadComponentRepoMapping(fsys fs.FS, version string) map[string]string {
	resolved, err := ResolveVersion(fsys, version)
	if err != nil {
		return nil
	}
	path := resolved + "/component-map.json"
	raw, err := fs.ReadFile(fsys, path)
	if err != nil {
		return nil
	}
	var wrapper struct {
		Components map[string]struct {
			RepoOrg  string `json:"repo_org"`
			RepoName string `json:"repo_name"`
		} `json:"components"`
	}
	if err := json.Unmarshal(raw, &wrapper); err != nil {
		return nil
	}
	result := make(map[string]string, len(wrapper.Components))
	for key, comp := range wrapper.Components {
		if comp.RepoOrg != "" && comp.RepoName != "" {
			result[key] = comp.RepoOrg + "/" + comp.RepoName
		}
	}
	return result
}

// mergeJSON supplements a markdown-parsed doc with arch-analyzer JSON data.
// JSON-only fields are always set. For shared fields (services, RBAC, endpoints,
// internal deps), JSON data is appended only when the markdown doc has none.
func mergeJSON(dst, src *types.ComponentDoc) {
	// Always set JSON-only fields
	dst.ControllerWatches = src.ControllerWatches
	dst.Webhooks = src.Webhooks
	dst.PlatformWebhooks = src.PlatformWebhooks
	dst.ExternalWebhooks = src.ExternalWebhooks
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
