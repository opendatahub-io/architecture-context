package loader

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/jctanner/arch-query/internal/markdown"
	"github.com/jctanner/arch-query/internal/overlay"
	"github.com/jctanner/arch-query/internal/types"
)

func LoadVersion(baseDir, version string) (*types.VersionData, error) {
	versionDir, err := ResolveVersion(baseDir, version)
	if err != nil {
		return nil, err
	}

	entries, err := os.ReadDir(versionDir)
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
		path := filepath.Join(versionDir, name)
		doc, err := markdown.ParseComponentDoc(path)
		if err != nil {
			continue
		}
		components[key] = doc
	}

	platformPath := filepath.Join(versionDir, "PLATFORM.md")
	platform, _ := markdown.ParsePlatformDoc(platformPath)

	overlaysDir := filepath.Join(filepath.Dir(baseDir), "overlays")
	overlays, _ := overlay.LoadOverlays(overlaysDir)

	data := &types.VersionData{
		Version: types.VersionInfo{
			Name:           version,
			Path:           versionDir,
			ComponentCount: len(components),
		},
		Components: components,
		Platform:   platform,
		Overlays:   overlays,
	}

	return data, nil
}

func OverlaysDir(baseDir string) string {
	return filepath.Join(filepath.Dir(baseDir), "overlays")
}
