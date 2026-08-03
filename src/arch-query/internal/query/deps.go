package query

import (
	"strings"

	"github.com/jctanner/arch-query/internal/types"
)

type DependencyEntry struct {
	Component       string `json:"component"`
	Version         string `json:"version,omitempty"`
	Required        string `json:"required,omitempty"`
	Purpose         string `json:"purpose"`
	InteractionType string `json:"interaction_type,omitempty"`
	Kind            string `json:"kind"`
	LifecycleStatus string `json:"lifecycle_status"`
}

type ReverseDependencyEntry struct {
	Component string `json:"component"`
	Purpose   string `json:"purpose"`
}

type DependencyStatusResult struct {
	Component    string                   `json:"component"`
	Release      string                   `json:"release,omitempty"`
	Dependencies []DependencyEntry        `json:"dependencies"`
	ReverseDeps  []ReverseDependencyEntry  `json:"reverse_deps"`
}

func QueryDependencyStatus(component, release, version string, data *types.VersionData) *Response {
	args := map[string]any{"component": component}
	if release != "" {
		args["release"] = release
	}

	doc := findComponent(data, component)
	if doc == nil {
		return UnknownResponse("dependency-status", args, version,
			"component not found in version "+version)
	}

	var deps []DependencyEntry
	for _, d := range doc.ExternalDeps {
		deps = append(deps, DependencyEntry{
			Component:       d.Component,
			Version:         d.Version,
			Required:        d.Required,
			Purpose:         d.Purpose,
			InteractionType: d.InteractionType,
			Kind:            "external",
			LifecycleStatus: "unknown",
		})
	}
	for _, d := range doc.InternalDeps {
		deps = append(deps, DependencyEntry{
			Component:       d.Component,
			Version:         d.Version,
			Required:        d.Required,
			Purpose:         d.Purpose,
			InteractionType: d.InteractionType,
			Kind:            "internal",
			LifecycleStatus: "unknown",
		})
	}
	if deps == nil {
		deps = []DependencyEntry{}
	}

	compKey := resolveComponentKey(data, component)
	var reverse []ReverseDependencyEntry
	for k, other := range data.Components {
		if strings.EqualFold(k, compKey) {
			continue
		}
		for _, d := range other.ExternalDeps {
			if strings.EqualFold(d.Component, compKey) {
				reverse = append(reverse, ReverseDependencyEntry{
					Component: k,
					Purpose:   d.Purpose,
				})
				break
			}
		}
		for _, d := range other.InternalDeps {
			if strings.EqualFold(d.Component, compKey) {
				reverse = append(reverse, ReverseDependencyEntry{
					Component: k,
					Purpose:   d.Purpose,
				})
				break
			}
		}
	}
	if reverse == nil {
		reverse = []ReverseDependencyEntry{}
	}

	var evidence []Evidence
	evidence = append(evidence, Evidence{
		Source:   version + "/" + doc.FileName,
		Category: "dependencies",
	})

	return &Response{
		ContractVersion: ContractVersion,
		Query:           "dependency-status",
		Args:            args,
		Version:         version,
		Status:          StatusOK,
		Evidence:        evidence,
		Result: DependencyStatusResult{
			Component:    component,
			Release:      release,
			Dependencies: deps,
			ReverseDeps:  reverse,
		},
	}
}
