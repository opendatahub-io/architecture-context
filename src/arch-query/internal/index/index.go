package index

import (
	"sort"

	"github.com/jctanner/arch-query/internal/types"
)

const FormatVersion = "2"

var CategorySectionMap = map[string][]string{
	"api-surface":      {"endpoints", "grpc_services", "crds"},
	"deployment-model": {"architecture_components", "dockerfiles", "services"},
	"dependencies":     {"external_deps", "internal_deps"},
	"security":         {"rbac_roles", "network_policies", "ingresses", "egresses"},
	"purpose":          {},
}

type ContextIndex struct {
	FormatVersion    string              `json:"format_version"`
	Version          string              `json:"version"`
	CategoryMappings map[string][]string `json:"category_mappings"`
	Components       []IndexEntry        `json:"components"`
}

type IndexEntry struct {
	Name       string            `json:"name"`
	SourcePath string            `json:"source_path,omitempty"`
	Purpose    string            `json:"purpose,omitempty"`
	DeployType string            `json:"deploy_type,omitempty"`
	Repository string            `json:"repository,omitempty"`
	Sections   map[string]int    `json:"sections"`
	Metadata   map[string]string `json:"metadata,omitempty"`
}

func Generate(version string, data *types.VersionData) *ContextIndex {
	mappings := buildCategoryMappings()

	if data == nil {
		return &ContextIndex{
			FormatVersion:    FormatVersion,
			Version:          version,
			CategoryMappings: mappings,
			Components:       []IndexEntry{},
		}
	}

	keys := make([]string, 0, len(data.Components))
	for k := range data.Components {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	versionPath := data.Version.Path

	entries := make([]IndexEntry, 0, len(keys))
	for _, k := range keys {
		doc := data.Components[k]
		entries = append(entries, buildEntry(k, doc, versionPath))
	}

	return &ContextIndex{
		FormatVersion:    FormatVersion,
		Version:          version,
		CategoryMappings: mappings,
		Components:       entries,
	}
}

func buildCategoryMappings() map[string][]string {
	mappings := make(map[string][]string, len(CategorySectionMap))
	for k, v := range CategorySectionMap {
		cp := make([]string, len(v))
		copy(cp, v)
		sort.Strings(cp)
		mappings[k] = cp
	}
	return mappings
}

func buildEntry(name string, doc *types.ComponentDoc, versionPath string) IndexEntry {
	sections := make(map[string]int)

	if len(doc.Components) > 0 {
		sections["architecture_components"] = len(doc.Components)
	}
	if len(doc.CRDs) > 0 {
		sections["crds"] = len(doc.CRDs)
	}
	if len(doc.Endpoints) > 0 {
		sections["endpoints"] = len(doc.Endpoints)
	}
	if len(doc.GRPCServices) > 0 {
		sections["grpc_services"] = len(doc.GRPCServices)
	}
	if len(doc.ExternalDeps) > 0 {
		sections["external_deps"] = len(doc.ExternalDeps)
	}
	if len(doc.InternalDeps) > 0 {
		sections["internal_deps"] = len(doc.InternalDeps)
	}
	if len(doc.Services) > 0 {
		sections["services"] = len(doc.Services)
	}
	if len(doc.Ingresses) > 0 {
		sections["ingresses"] = len(doc.Ingresses)
	}
	if len(doc.Egresses) > 0 {
		sections["egresses"] = len(doc.Egresses)
	}
	if len(doc.RBACRoles) > 0 {
		sections["rbac_roles"] = len(doc.RBACRoles)
	}
	if len(doc.ControllerWatches) > 0 {
		sections["controller_watches"] = len(doc.ControllerWatches)
	}
	if len(doc.Webhooks) > 0 {
		sections["webhooks"] = len(doc.Webhooks)
	}
	if len(doc.NetworkPolicies) > 0 {
		sections["network_policies"] = len(doc.NetworkPolicies)
	}
	if len(doc.Dockerfiles) > 0 {
		sections["dockerfiles"] = len(doc.Dockerfiles)
	}

	var sourcePath string
	if doc.FileName != "" && versionPath != "" {
		sourcePath = versionPath + "/" + doc.FileName
	}

	entry := IndexEntry{
		Name:       name,
		SourcePath: sourcePath,
		Purpose:    doc.Purpose,
		DeployType: doc.DeployType,
		Repository: doc.Repository,
		Sections:   sections,
	}

	if doc.CommitSHA != "" || doc.AnalyzerVersion != "" {
		entry.Metadata = make(map[string]string)
		if doc.CommitSHA != "" {
			entry.Metadata["commit_sha"] = doc.CommitSHA
		}
		if doc.AnalyzerVersion != "" {
			entry.Metadata["analyzer_version"] = doc.AnalyzerVersion
		}
	}

	return entry
}
