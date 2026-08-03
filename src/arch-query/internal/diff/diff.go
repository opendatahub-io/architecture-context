package diff

import (
	"sort"
	"strings"

	"github.com/jctanner/arch-query/internal/types"
)

const FormatVersion = "1"

type Outcome string

const (
	OutcomeAdded        Outcome = "added"
	OutcomeRemoved      Outcome = "removed"
	OutcomeChanged      Outcome = "changed"
	OutcomeUnchanged    Outcome = "unchanged"
	OutcomeUnknown      Outcome = "unknown"
	OutcomeNotExtracted Outcome = "not-extracted"
)

type DiffResult struct {
	FormatVersion string          `json:"format_version"`
	FromVersion   string          `json:"from_version"`
	ToVersion     string          `json:"to_version"`
	Status        string          `json:"status"`
	Added         []string        `json:"added"`
	Removed       []string        `json:"removed"`
	Changed       []ComponentDiff `json:"changed"`
	UnchangedCount int            `json:"unchanged_count"`
}

type ComponentDiff struct {
	Name       string         `json:"name"`
	Categories []CategoryDiff `json:"categories"`
}

type CategoryDiff struct {
	Category string   `json:"category"`
	Outcome  Outcome  `json:"outcome"`
	Added    []string `json:"added,omitempty"`
	Removed  []string `json:"removed,omitempty"`
}

func Compute(fromVersion, toVersion string, from, to *types.VersionData) *DiffResult {
	if from == nil && to == nil {
		return &DiffResult{
			FormatVersion: FormatVersion,
			FromVersion:   fromVersion,
			ToVersion:     toVersion,
			Status:        "incompatible",
			Added:         []string{},
			Removed:       []string{},
			Changed:       []ComponentDiff{},
		}
	}
	if from == nil {
		return notExtractedResult(fromVersion, toVersion, "from")
	}
	if to == nil {
		return notExtractedResult(fromVersion, toVersion, "to")
	}

	setA := make(map[string]bool, len(from.Components))
	for k := range from.Components {
		setA[k] = true
	}
	setB := make(map[string]bool, len(to.Components))
	for k := range to.Components {
		setB[k] = true
	}

	var added, removed, common []string
	for k := range to.Components {
		if !setA[k] {
			added = append(added, k)
		}
	}
	sort.Strings(added)

	for k := range from.Components {
		if !setB[k] {
			removed = append(removed, k)
		}
	}
	sort.Strings(removed)

	for k := range from.Components {
		if setB[k] {
			common = append(common, k)
		}
	}
	sort.Strings(common)

	var changed []ComponentDiff
	unchangedCount := 0

	for _, k := range common {
		cd := diffComponent(k, from.Components[k], to.Components[k])
		if cd != nil {
			changed = append(changed, *cd)
		} else {
			unchangedCount++
		}
	}

	return &DiffResult{
		FormatVersion:  FormatVersion,
		FromVersion:    fromVersion,
		ToVersion:      toVersion,
		Status:         "ok",
		Added:          added,
		Removed:        removed,
		Changed:        changed,
		UnchangedCount: unchangedCount,
	}
}

func ComputeSingle(name, fromVersion, toVersion string, from, to *types.VersionData) *DiffResult {
	if from == nil && to == nil {
		return &DiffResult{
			FormatVersion: FormatVersion,
			FromVersion:   fromVersion,
			ToVersion:     toVersion,
			Status:        "incompatible",
			Added:         []string{},
			Removed:       []string{},
			Changed:       []ComponentDiff{},
		}
	}
	if from == nil {
		return notExtractedResult(fromVersion, toVersion, "from")
	}
	if to == nil {
		return notExtractedResult(fromVersion, toVersion, "to")
	}

	docA := findComponent(from, name)
	docB := findComponent(to, name)

	if docA == nil && docB == nil {
		return &DiffResult{
			FormatVersion: FormatVersion,
			FromVersion:   fromVersion,
			ToVersion:     toVersion,
			Status:        "unknown",
			Added:         []string{},
			Removed:       []string{},
			Changed:       []ComponentDiff{},
		}
	}
	if docA == nil {
		return &DiffResult{
			FormatVersion:  FormatVersion,
			FromVersion:    fromVersion,
			ToVersion:      toVersion,
			Status:         "ok",
			Added:          []string{name},
			Removed:        []string{},
			Changed:        []ComponentDiff{},
			UnchangedCount: 0,
		}
	}
	if docB == nil {
		return &DiffResult{
			FormatVersion:  FormatVersion,
			FromVersion:    fromVersion,
			ToVersion:      toVersion,
			Status:         "ok",
			Added:          []string{},
			Removed:        []string{name},
			Changed:        []ComponentDiff{},
			UnchangedCount: 0,
		}
	}

	cd := diffComponent(name, docA, docB)
	result := &DiffResult{
		FormatVersion: FormatVersion,
		FromVersion:   fromVersion,
		ToVersion:     toVersion,
		Status:        "ok",
		Added:         []string{},
		Removed:       []string{},
		Changed:       []ComponentDiff{},
	}
	if cd != nil {
		result.Changed = []ComponentDiff{*cd}
	} else {
		result.UnchangedCount = 1
	}
	return result
}

func notExtractedResult(fromVersion, toVersion, missing string) *DiffResult {
	return &DiffResult{
		FormatVersion: FormatVersion,
		FromVersion:   fromVersion,
		ToVersion:     toVersion,
		Status:        "not-extracted:" + missing,
		Added:         []string{},
		Removed:       []string{},
		Changed:       []ComponentDiff{},
	}
}

func diffComponent(name string, a, b *types.ComponentDoc) *ComponentDiff {
	type catSpec struct {
		category string
		setA     map[string]bool
		setB     map[string]bool
	}

	specs := []catSpec{
		{"crds", crdSet(a.CRDs), crdSet(b.CRDs)},
		{"endpoints", endpointSet(a.Endpoints), endpointSet(b.Endpoints)},
		{"grpc_services", grpcSet(a.GRPCServices), grpcSet(b.GRPCServices)},
		{"external_deps", depSet(a.ExternalDeps), depSet(b.ExternalDeps)},
		{"internal_deps", depSet(a.InternalDeps), depSet(b.InternalDeps)},
		{"services", serviceSet(a.Services), serviceSet(b.Services)},
		{"ingresses", ingressSet(a.Ingresses), ingressSet(b.Ingresses)},
		{"egresses", egressSet(a.Egresses), egressSet(b.Egresses)},
		{"rbac_roles", rbacSet(a.RBACRoles), rbacSet(b.RBACRoles)},
	}

	var diffs []CategoryDiff
	for _, s := range specs {
		added, removed := setDiff(s.setA, s.setB)
		if len(added) > 0 || len(removed) > 0 {
			diffs = append(diffs, CategoryDiff{
				Category: s.category,
				Outcome:  OutcomeChanged,
				Added:    added,
				Removed:  removed,
			})
		}
	}

	if len(diffs) == 0 {
		return nil
	}
	return &ComponentDiff{
		Name:       name,
		Categories: diffs,
	}
}

func findComponent(data *types.VersionData, name string) *types.ComponentDoc {
	for k, v := range data.Components {
		if strings.EqualFold(k, name) {
			return v
		}
	}
	return nil
}

func setDiff(a, b map[string]bool) (added, removed []string) {
	for k := range b {
		if !a[k] {
			added = append(added, k)
		}
	}
	for k := range a {
		if !b[k] {
			removed = append(removed, k)
		}
	}
	sort.Strings(added)
	sort.Strings(removed)
	return
}

func crdSet(crds []types.CRD) map[string]bool {
	s := make(map[string]bool)
	for _, c := range crds {
		s[c.Group+"/"+c.Version+" "+c.Kind] = true
	}
	return s
}

func depSet(deps []types.Dependency) map[string]bool {
	s := make(map[string]bool)
	for _, d := range deps {
		s[d.Component] = true
	}
	return s
}

func serviceSet(services []types.Service) map[string]bool {
	s := make(map[string]bool)
	for _, svc := range services {
		s[svc.Name+" "+svc.Port] = true
	}
	return s
}

func endpointSet(endpoints []types.Endpoint) map[string]bool {
	s := make(map[string]bool)
	for _, ep := range endpoints {
		s[ep.Method+" "+ep.Path+" "+ep.Port] = true
	}
	return s
}

func grpcSet(services []types.GRPCService) map[string]bool {
	s := make(map[string]bool)
	for _, g := range services {
		s[g.Service+" "+g.Port] = true
	}
	return s
}

func ingressSet(ingresses []types.Ingress) map[string]bool {
	s := make(map[string]bool)
	for _, ing := range ingresses {
		s[ing.Component+" "+ing.Type+" "+ing.Port] = true
	}
	return s
}

func egressSet(egresses []types.Egress) map[string]bool {
	s := make(map[string]bool)
	for _, eg := range egresses {
		s[eg.Destination+" "+eg.Port+" "+eg.Protocol] = true
	}
	return s
}

func rbacSet(roles []types.RBACRole) map[string]bool {
	s := make(map[string]bool)
	for _, r := range roles {
		s[r.RoleName+" "+r.APIGroup+" "+r.Resources] = true
	}
	return s
}
