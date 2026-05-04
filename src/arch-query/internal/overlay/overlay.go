package overlay

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/jctanner/arch-query/internal/types"
	"gopkg.in/yaml.v3"
)

func LoadOverlays(overlaysDir string) ([]*types.OverlayDoc, error) {
	entries, err := os.ReadDir(overlaysDir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}

	var overlays []*types.OverlayDoc
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".md") || e.Name() == "README.md" {
			continue
		}
		o, err := parseOverlayFile(filepath.Join(overlaysDir, e.Name()))
		if err != nil {
			continue
		}
		overlays = append(overlays, o)
	}
	return overlays, nil
}

func parseOverlayFile(path string) (*types.OverlayDoc, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	content := string(data)
	frontmatter, body := splitFrontmatter(content)
	if frontmatter == "" {
		return nil, nil
	}

	var doc types.OverlayDoc
	if err := yaml.Unmarshal([]byte(frontmatter), &doc); err != nil {
		return nil, err
	}

	sections := splitBodySections(body)
	doc.Fact = sections["Fact"]
	doc.Impact = sections["Impact on Strategies"]
	doc.Context = sections["Context"]

	return &doc, nil
}

func splitFrontmatter(content string) (string, string) {
	const delim = "---"
	if !strings.HasPrefix(strings.TrimSpace(content), delim) {
		return "", content
	}

	trimmed := strings.TrimSpace(content)
	rest := trimmed[len(delim):]
	end := strings.Index(rest, delim)
	if end < 0 {
		return "", content
	}

	fm := strings.TrimSpace(rest[:end])
	body := strings.TrimSpace(rest[end+len(delim):])
	return fm, body
}

func splitBodySections(body string) map[string]string {
	sections := make(map[string]string)
	lines := strings.Split(body, "\n")
	var currentHeading string
	var currentLines []string

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "## ") {
			if currentHeading != "" {
				sections[currentHeading] = strings.TrimSpace(strings.Join(currentLines, "\n"))
			}
			currentHeading = strings.TrimPrefix(trimmed, "## ")
			currentLines = nil
		} else if currentHeading != "" {
			currentLines = append(currentLines, line)
		}
	}
	if currentHeading != "" {
		sections[currentHeading] = strings.TrimSpace(strings.Join(currentLines, "\n"))
	}
	return sections
}
