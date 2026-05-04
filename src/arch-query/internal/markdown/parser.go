package markdown

import (
	"io/fs"
	"path/filepath"
	"strings"

	"github.com/jctanner/arch-query/internal/types"
)

func ParseComponentDoc(fsys fs.FS, path string) (*types.ComponentDoc, error) {
	data, err := fs.ReadFile(fsys, path)
	if err != nil {
		return nil, err
	}

	lines := strings.Split(string(data), "\n")
	sections := splitSections(lines)

	doc := &types.ComponentDoc{
		FileName:    filepath.Base(path),
		RawSections: make(map[string]string),
	}

	for _, s := range sections {
		doc.RawSections[s.name] = strings.Join(s.lines, "\n")
	}

	// Extract component name from H1
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "# ") && !strings.HasPrefix(line, "## ") {
			name := strings.TrimPrefix(line, "# ")
			name = strings.TrimPrefix(name, "Component: ")
			doc.Name = strings.TrimSpace(name)
			break
		}
	}

	if sec, ok := findSection(sections, "Metadata"); ok {
		doc.Metadata = ParseMetadata(sec.lines)
		doc.Repository = doc.Metadata["Repository"]
		doc.Version = doc.Metadata["Version"]
		doc.Languages = doc.Metadata["Languages"]
		doc.DeployType = doc.Metadata["Deployment Type"]
	}

	if sec, ok := findSection(sections, "Purpose"); ok {
		doc.Purpose, doc.PurposeFull = parsePurpose(sec.lines)
	}

	if sec, ok := findSection(sections, "Architecture Components"); ok {
		doc.Components = parseArchComponents(sec.lines)
	}

	if sec, ok := findSection(sections, "APIs Exposed"); ok {
		doc.CRDs = parseCRDs(sec.lines)
		doc.Endpoints = parseEndpoints(sec.lines)
		doc.GRPCServices = parseGRPCServices(sec.lines)
	}

	if sec, ok := findSection(sections, "Dependencies"); ok {
		doc.ExternalDeps, doc.InternalDeps = parseDependencies(sec.lines)
	}

	if sec, ok := findSection(sections, "Network Architecture"); ok {
		doc.Services = parseServices(sec.lines)
		doc.Ingresses = parseIngresses(sec.lines)
		doc.Egresses = parseEgresses(sec.lines)
	}

	if sec, ok := findSection(sections, "Security"); ok {
		doc.RBACRoles = parseRBACRoles(sec.lines)
	}

	return doc, nil
}

type section struct {
	name  string
	lines []string
}

func splitSections(lines []string) []section {
	var sections []section
	var current *section

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "## ") && !strings.HasPrefix(trimmed, "### ") {
			if current != nil {
				sections = append(sections, *current)
			}
			name := strings.TrimPrefix(trimmed, "## ")
			current = &section{name: name}
		} else if current != nil {
			current.lines = append(current.lines, line)
		}
	}
	if current != nil {
		sections = append(sections, *current)
	}
	return sections
}

func findSection(sections []section, name string) (section, bool) {
	for _, s := range sections {
		if s.name == name {
			return s, true
		}
	}
	return section{}, false
}

func parsePurpose(lines []string) (short, full string) {
	var inShort, inDetailed bool
	var shortLines, detailedLines []string

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "**Short**:") {
			inShort = true
			inDetailed = false
			text := strings.TrimPrefix(trimmed, "**Short**:")
			text = strings.TrimSpace(text)
			if text != "" {
				shortLines = append(shortLines, text)
			}
			continue
		}
		if strings.HasPrefix(trimmed, "**Detailed**:") {
			inShort = false
			inDetailed = true
			text := strings.TrimPrefix(trimmed, "**Detailed**:")
			text = strings.TrimSpace(text)
			if text != "" {
				detailedLines = append(detailedLines, text)
			}
			continue
		}
		if inShort && trimmed != "" {
			shortLines = append(shortLines, trimmed)
		}
		if inDetailed && trimmed != "" {
			detailedLines = append(detailedLines, trimmed)
		}
	}

	short = strings.Join(shortLines, " ")
	full = strings.Join(detailedLines, " ")
	if short == "" && len(lines) > 0 {
		// Fallback: take first non-empty line
		for _, l := range lines {
			l = strings.TrimSpace(l)
			if l != "" {
				short = l
				break
			}
		}
	}
	return
}

func parseArchComponents(lines []string) []types.ArchComponent {
	rows := ParseTableSkipHeader(lines)
	var result []types.ArchComponent
	for _, row := range rows {
		if len(row) >= 3 {
			result = append(result, types.ArchComponent{
				Name:    row[0],
				Type:    row[1],
				Purpose: row[2],
			})
		}
	}
	return result
}

func parseCRDs(lines []string) []types.CRD {
	subsection := extractSubsection(lines, "Custom Resource Definitions")
	if subsection == nil {
		return nil
	}
	rows := ParseTableSkipHeader(subsection)
	var result []types.CRD
	for _, row := range rows {
		if len(row) >= 4 {
			crd := types.CRD{
				Group:   row[0],
				Version: row[1],
				Kind:    row[2],
				Scope:   row[3],
			}
			if len(row) >= 5 {
				crd.Purpose = row[4]
			}
			result = append(result, crd)
		}
	}
	return result
}

func parseEndpoints(lines []string) []types.Endpoint {
	subsection := extractSubsection(lines, "HTTP Endpoints")
	if subsection == nil {
		return nil
	}
	rows := ParseTableSkipHeader(subsection)
	var result []types.Endpoint
	for _, row := range rows {
		if len(row) >= 7 {
			result = append(result, types.Endpoint{
				Path:       row[0],
				Method:     row[1],
				Port:       row[2],
				Protocol:   row[3],
				Encryption: row[4],
				Auth:       row[5],
				Purpose:    row[6],
			})
		}
	}
	return result
}

func parseGRPCServices(lines []string) []types.GRPCService {
	subsection := extractSubsection(lines, "gRPC Services")
	if subsection == nil {
		return nil
	}
	rows := ParseTableSkipHeader(subsection)
	var result []types.GRPCService
	for _, row := range rows {
		if len(row) >= 6 {
			result = append(result, types.GRPCService{
				Service:    row[0],
				Port:       row[1],
				Protocol:   row[2],
				Encryption: row[3],
				Auth:       row[4],
				Purpose:    row[5],
			})
		}
	}
	return result
}

func parseDependencies(lines []string) (external []types.Dependency, internal []types.Dependency) {
	extSub := extractSubsection(lines, "External Dependencies")
	if extSub != nil {
		rows := ParseTableSkipHeader(extSub)
		for _, row := range rows {
			if len(row) >= 4 {
				external = append(external, types.Dependency{
					Component: row[0],
					Version:   row[1],
					Required:  row[2],
					Purpose:   row[3],
				})
			}
		}
	}

	intSub := extractSubsection(lines, "Internal Platform Dependencies")
	if intSub != nil {
		rows := ParseTableSkipHeader(intSub)
		for _, row := range rows {
			if len(row) >= 3 {
				internal = append(internal, types.Dependency{
					Component:       row[0],
					InteractionType: row[1],
					Purpose:         row[2],
				})
			}
		}
	}
	return
}

func parseServices(lines []string) []types.Service {
	subsection := extractSubsection(lines, "Services")
	if subsection == nil {
		subsection = lines
	}
	rows := ParseTableSkipHeader(subsection)
	var result []types.Service
	for _, row := range rows {
		if len(row) >= 8 {
			result = append(result, types.Service{
				Name:       row[0],
				Type:       row[1],
				Port:       row[2],
				TargetPort: row[3],
				Protocol:   row[4],
				Encryption: row[5],
				Auth:       row[6],
				Exposure:   row[7],
			})
		}
	}
	return result
}

func parseRBACRoles(lines []string) []types.RBACRole {
	subsection := extractSubsection(lines, "RBAC")
	if subsection == nil {
		return nil
	}
	rows := ParseTableSkipHeader(subsection)
	var result []types.RBACRole
	for _, row := range rows {
		if len(row) >= 4 {
			result = append(result, types.RBACRole{
				RoleName:  row[0],
				APIGroup:  row[1],
				Resources: row[2],
				Verbs:     row[3],
			})
		}
	}
	return result
}

func parseIngresses(lines []string) []types.Ingress {
	subsection := extractSubsection(lines, "Ingress")
	if subsection == nil {
		return nil
	}
	rows := ParseTableSkipHeader(subsection)
	var result []types.Ingress
	for _, row := range rows {
		if len(row) >= 8 {
			result = append(result, types.Ingress{
				Component:  row[0],
				Type:       row[1],
				Hosts:      row[2],
				Port:       row[3],
				Protocol:   row[4],
				Encryption: row[5],
				TLSMode:    row[6],
				Exposure:   row[7],
			})
		}
	}
	return result
}

func parseEgresses(lines []string) []types.Egress {
	subsection := extractSubsection(lines, "Egress")
	if subsection == nil {
		return nil
	}
	rows := ParseTableSkipHeader(subsection)
	var result []types.Egress
	for _, row := range rows {
		if len(row) >= 6 {
			result = append(result, types.Egress{
				Destination: row[0],
				Port:        row[1],
				Protocol:    row[2],
				Encryption:  row[3],
				Auth:        row[4],
				Purpose:     row[5],
			})
		}
	}
	return result
}

func extractSubsection(lines []string, heading string) []string {
	var result []string
	found := false
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "### ") || strings.HasPrefix(trimmed, "## ") {
			if found {
				break
			}
			h := strings.TrimPrefix(trimmed, "### ")
			if strings.Contains(h, heading) {
				found = true
			}
			continue
		}
		if found {
			result = append(result, line)
		}
	}
	if found {
		return result
	}
	return nil
}
