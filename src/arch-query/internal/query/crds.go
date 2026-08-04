package query

import (
	"strings"

	"github.com/jctanner/arch-query/internal/types"
)

type CRDEntry struct {
	Group   string `json:"group"`
	Version string `json:"version"`
	Kind    string `json:"kind"`
	Scope   string `json:"scope"`
	Purpose string `json:"purpose,omitempty"`
	Source  string `json:"source,omitempty"`
}

type ControllerWatchEntry struct {
	Type       string `json:"type"`
	GVK        string `json:"gvk"`
	Controller string `json:"controller"`
	Source     string `json:"source,omitempty"`
}

type CRDResult struct {
	Component  string                 `json:"component"`
	CRDs       []CRDEntry             `json:"crds"`
	Watches    []ControllerWatchEntry  `json:"watches"`
}

func QueryCRDs(component string, version string, data *types.VersionData) *Response {
	args := map[string]any{"component": component}

	doc := findComponent(data, component)
	if doc == nil {
		return UnknownResponse("crds", args, version,
			"component not found in version "+version)
	}

	var crds []CRDEntry
	for _, c := range doc.CRDs {
		crds = append(crds, CRDEntry{
			Group:   c.Group,
			Version: c.Version,
			Kind:    c.Kind,
			Scope:   c.Scope,
			Purpose: c.Purpose,
			Source:  c.Source,
		})
	}
	if crds == nil {
		crds = []CRDEntry{}
	}

	var watches []ControllerWatchEntry
	for _, w := range doc.ControllerWatches {
		watches = append(watches, ControllerWatchEntry{
			Type:       w.Type,
			GVK:        w.GVK,
			Controller: w.Controller,
			Source:     w.Source,
		})
	}
	if watches == nil {
		watches = []ControllerWatchEntry{}
	}

	var evidence []Evidence
	if len(crds) > 0 || len(watches) > 0 {
		evidence = append(evidence, Evidence{
			Source:   version + "/" + doc.FileName,
			Category: "crds",
		})
	}
	if doc.AnalyzerVersion != "" {
		evidence = append(evidence, Evidence{
			Source:   "arch-analyzer " + doc.AnalyzerVersion,
			Category: "extraction",
		})
	}

	return &Response{
		ContractVersion: ContractVersion,
		Query:           "crds",
		Args:            args,
		Version:         version,
		Status:          StatusOK,
		Evidence:        evidence,
		Result: CRDResult{
			Component: component,
			CRDs:      crds,
			Watches:   watches,
		},
	}
}

func findComponent(data *types.VersionData, name string) *types.ComponentDoc {
	lower := strings.ToLower(name)
	for k, v := range data.Components {
		if strings.EqualFold(k, lower) {
			return v
		}
	}
	return nil
}

func resolveComponentKey(data *types.VersionData, name string) string {
	lower := strings.ToLower(name)
	for k := range data.Components {
		if strings.EqualFold(k, lower) {
			return k
		}
	}
	return ""
}
