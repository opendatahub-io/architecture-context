package markdown

import (
	"errors"
	"io/fs"
	"strings"

	"github.com/jctanner/arch-query/internal/types"
)

func ParsePlatformDoc(fsys fs.FS, path string) (*types.PlatformDoc, error) {
	data, err := fs.ReadFile(fsys, path)
	if err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return nil, nil
		}
		return nil, err
	}

	lines := strings.Split(string(data), "\n")
	sections := splitSections(lines)

	doc := &types.PlatformDoc{}

	if sec, ok := findSection(sections, "Metadata"); ok {
		doc.Metadata = ParseMetadata(sec.lines)
	}

	if sec, ok := findSection(sections, "Platform Overview"); ok {
		var paras []string
		for _, l := range sec.lines {
			t := strings.TrimSpace(l)
			if t != "" {
				paras = append(paras, t)
			}
		}
		doc.Overview = strings.Join(paras, "\n\n")
	}

	if sec, ok := findSection(sections, "Component Inventory"); ok {
		doc.Components = parsePlatformComponents(sec.lines)
	}

	return doc, nil
}

func parsePlatformComponents(lines []string) []types.PlatformComponent {
	rows := ParseTableSkipHeader(lines)
	var result []types.PlatformComponent
	for _, row := range rows {
		if len(row) >= 6 {
			result = append(result, types.PlatformComponent{
				Name:       row[0],
				Type:       row[1],
				Language:   row[2],
				Repository: row[3],
				Version:    row[4],
				Purpose:    row[5],
			})
		}
	}
	return result
}
