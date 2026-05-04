package loader

import (
	"io/fs"
	"strings"

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

	platformPath := resolved + "/PLATFORM.md"
	platform, _ := markdown.ParsePlatformDoc(fsys, platformPath)

	var overlays []*types.OverlayDoc
	if overlayFS != nil {
		overlays, _ = overlay.LoadOverlays(overlayFS)
	}

	data := &types.VersionData{
		Version: types.VersionInfo{
			Name:           version,
			Path:           resolved,
			ComponentCount: len(components),
		},
		Components: components,
		Platform:   platform,
		Overlays:   overlays,
	}

	return data, nil
}
