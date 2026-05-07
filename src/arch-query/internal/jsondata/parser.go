package jsondata

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"strings"

	"github.com/jctanner/arch-query/internal/types"
)

type rawJSON struct {
	Component       string `json:"component"`
	Repo            string `json:"repo"`
	CommitSHA       string `json:"commit_sha"`
	AnalyzerVersion string `json:"analyzer_version"`
	Summary         string `json:"summary"`

	RBAC struct {
		KubebuilderMarkers []struct {
			File   string `json:"file"`
			Line   int    `json:"line"`
			Marker string `json:"marker"`
			Parsed struct {
				Groups    []string `json:"groups"`
				Resources []string `json:"resources"`
				Verbs     []string `json:"verbs"`
			} `json:"parsed"`
		} `json:"kubebuilder_markers"`
	} `json:"rbac"`

	Services []struct {
		Name     string `json:"name"`
		Source   string `json:"source"`
		Type     string `json:"type"`
		Ports    []struct {
			Name       string `json:"name"`
			Port       int    `json:"port"`
			TargetPort any    `json:"targetPort"`
			Protocol   string `json:"protocol"`
		} `json:"ports"`
		Selector         map[string]string `json:"selector"`
		TargetDeployment string            `json:"target_deployment"`
	} `json:"services"`

	ControllerWatches []struct {
		Type       string `json:"type"`
		GVK        string `json:"gvk"`
		Controller string `json:"controller"`
		Source     string `json:"source"`
	} `json:"controller_watches"`

	NetworkPolicies []struct {
		Name        string            `json:"name"`
		Source      string            `json:"source"`
		PodSelector map[string]string `json:"pod_selector"`
		PolicyTypes []string          `json:"policy_types"`
	} `json:"network_policies"`

	HTTPEndpoints []struct {
		Method string `json:"method"`
		Path   string `json:"path"`
		Source string `json:"source"`
	} `json:"http_endpoints"`

	Dockerfiles []struct {
		Path         string   `json:"path"`
		BaseImage    string   `json:"base_image"`
		Stages       int      `json:"stages"`
		User         string   `json:"user"`
		ExposedPorts []int    `json:"exposed_ports"`
		Issues       []string `json:"issues"`
	} `json:"dockerfiles"`

	Dependencies struct {
		GoVersion   string `json:"go_version"`
		InternalODH []struct {
			Component   string `json:"component"`
			Interaction string `json:"interaction"`
		} `json:"internal_odh"`
	} `json:"dependencies"`
}

// ParseComponentJSON reads a component-architecture.json file and returns
// a ComponentDoc populated with the structured data. The caller should
// merge this with the markdown-parsed ComponentDoc.
func ParseComponentJSON(fsys fs.FS, path string) (*types.ComponentDoc, error) {
	data, err := fs.ReadFile(fsys, path)
	if err != nil {
		return nil, err
	}

	var raw rawJSON
	if err := json.Unmarshal(data, &raw); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}

	doc := &types.ComponentDoc{
		CommitSHA:       raw.CommitSHA,
		AnalyzerVersion: raw.AnalyzerVersion,
	}

	// RBAC from kubebuilder markers
	for _, m := range raw.RBAC.KubebuilderMarkers {
		groups := strings.Join(m.Parsed.Groups, ",")
		groups = strings.ReplaceAll(groups, `""`, "")
		doc.RBACRoles = append(doc.RBACRoles, types.RBACRole{
			RoleName:  m.File,
			APIGroup:  groups,
			Resources: strings.Join(m.Parsed.Resources, ","),
			Verbs:     strings.Join(m.Parsed.Verbs, ","),
		})
	}

	// Services — one entry per port
	for _, svc := range raw.Services {
		for _, p := range svc.Ports {
			if p.Port == 0 {
				continue
			}
			tp := fmt.Sprintf("%v", p.TargetPort)
			doc.Services = append(doc.Services, types.Service{
				Name:       svc.Name,
				Type:       svc.Type,
				Port:       fmt.Sprintf("%d", p.Port),
				TargetPort: tp,
				Protocol:   p.Protocol,
			})
		}
	}

	// Controller watches
	for _, w := range raw.ControllerWatches {
		doc.ControllerWatches = append(doc.ControllerWatches, types.ControllerWatch{
			Type:       w.Type,
			GVK:        w.GVK,
			Controller: w.Controller,
			Source:     w.Source,
		})
	}

	// Network policies
	for _, np := range raw.NetworkPolicies {
		doc.NetworkPolicies = append(doc.NetworkPolicies, types.NetworkPolicy{
			Name:        np.Name,
			Source:      np.Source,
			PodSelector: np.PodSelector,
			PolicyTypes: np.PolicyTypes,
		})
	}

	// HTTP endpoints
	for _, ep := range raw.HTTPEndpoints {
		doc.Endpoints = append(doc.Endpoints, types.Endpoint{
			Method: ep.Method,
			Path:   ep.Path,
		})
	}

	// Dockerfiles
	for _, df := range raw.Dockerfiles {
		doc.Dockerfiles = append(doc.Dockerfiles, types.Dockerfile{
			Path:         df.Path,
			BaseImage:    df.BaseImage,
			Stages:       df.Stages,
			User:         df.User,
			ExposedPorts: df.ExposedPorts,
			Issues:       df.Issues,
		})
	}

	// Internal ODH dependencies
	for _, dep := range raw.Dependencies.InternalODH {
		doc.InternalDeps = append(doc.InternalDeps, types.Dependency{
			Component: dep.Component,
			Purpose:   dep.Interaction,
		})
	}

	return doc, nil
}
