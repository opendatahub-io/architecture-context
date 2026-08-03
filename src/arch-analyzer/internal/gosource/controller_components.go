package gosource

import (
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func extractControllerComponents(watches []model.ControllerWatch) []model.SourceComponent {
	type controllerInfo struct {
		kind   string
		source string
	}
	var controllers []controllerInfo
	seen := map[string]bool{}
	for _, watch := range watches {
		if watch.Type != "For" {
			continue
		}
		parts := strings.Split(watch.GVK, "/")
		kind := parts[len(parts)-1]
		if kind == "" || seen[kind] {
			continue
		}
		seen[kind] = true
		controllers = append(controllers, controllerInfo{kind: kind, source: watch.Source})
	}
	if len(controllers) < 2 {
		return nil
	}
	result := make([]model.SourceComponent, 0, len(controllers))
	for _, ctrl := range controllers {
		result = append(result, model.SourceComponent{
			Name:    ctrl.kind + " controller",
			Type:    "Controller",
			Purpose: "Reconciles " + ctrl.kind + " resources",
			Source:  ctrl.source,
		})
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Name < result[j].Name })
	return result
}
