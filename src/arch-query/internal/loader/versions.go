package loader

import (
	"encoding/json"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jctanner/arch-query/internal/types"
)

func DiscoverVersions(fsys fs.FS, symlinks map[string]string) ([]types.VersionInfo, error) {
	entries, err := fs.ReadDir(fsys, ".")
	if err != nil {
		return nil, err
	}

	targetToAliases := make(map[string][]string)
	for alias, target := range symlinks {
		targetToAliases[target] = append(targetToAliases[target], alias)
	}

	var realDirs []string
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		name := entry.Name()
		if _, isAlias := symlinks[name]; isAlias {
			continue
		}
		realDirs = append(realDirs, name)
	}

	var versions []types.VersionInfo
	for _, name := range realDirs {
		if name == "diagrams" || name == "overlays" {
			continue
		}
		count := countComponentFiles(fsys, name)
		v := types.VersionInfo{
			Name:           name,
			Path:           name,
			IsSymlink:      false,
			Aliases:        targetToAliases[name],
			ComponentCount: count,
		}
		versions = append(versions, v)
	}

	sort.Slice(versions, func(i, j int) bool {
		return versionSortKey(versions[i].Name) < versionSortKey(versions[j].Name)
	})

	return versions, nil
}

func DefaultVersion(versions []types.VersionInfo) string {
	for _, v := range versions {
		if v.Name == "rhoai.next" {
			return v.Name
		}
	}
	if len(versions) > 0 {
		return versions[len(versions)-1].Name
	}
	return ""
}

func ResolveVersion(fsys fs.FS, version string) (string, error) {
	info, err := fs.Stat(fsys, version)
	if err != nil {
		return "", err
	}
	if !info.IsDir() {
		return "", fs.ErrNotExist
	}
	return version, nil
}

func countComponentFiles(fsys fs.FS, dir string) int {
	entries, err := fs.ReadDir(fsys, dir)
	if err != nil {
		return 0
	}
	count := 0
	for _, e := range entries {
		if !e.IsDir() && strings.HasSuffix(e.Name(), ".md") && !isExcludedFile(e.Name()) {
			count++
		}
	}
	return count
}

// LoadSymlinksFromDisk discovers symlinks by reading the real filesystem.
func LoadSymlinksFromDisk(baseDir string) map[string]string {
	symlinks := make(map[string]string)
	entries, err := os.ReadDir(baseDir)
	if err != nil {
		return symlinks
	}
	for _, entry := range entries {
		fullPath := filepath.Join(baseDir, entry.Name())
		info, err := entry.Info()
		if err != nil {
			continue
		}
		if info.Mode()&os.ModeSymlink != 0 {
			target, err := os.Readlink(fullPath)
			if err != nil {
				continue
			}
			symlinks[entry.Name()] = target
		}
	}
	return symlinks
}

// LoadSymlinksFromFS reads a symlinks.json manifest from the filesystem.
func LoadSymlinksFromFS(fsys fs.FS) map[string]string {
	data, err := fs.ReadFile(fsys, "symlinks.json")
	if err != nil {
		return make(map[string]string)
	}
	var symlinks map[string]string
	if err := json.Unmarshal(data, &symlinks); err != nil {
		return make(map[string]string)
	}
	return symlinks
}

var excludedFiles = map[string]bool{
	"PLATFORM.md":           true,
	"README.md":             true,
	"RHOAI-Build-Config.md": true,
	"build-info.json":       true,
	"component-map.json":    true,
}

func isExcludedFile(name string) bool {
	return excludedFiles[name]
}

func versionSortKey(name string) string {
	if name == "rhoai.next" {
		return "zzzz"
	}
	parts := strings.SplitN(name, "-", 2)
	if len(parts) < 2 {
		return name
	}
	ver := parts[1]
	segments := strings.Split(ver, ".")
	var padded []string
	for _, s := range segments {
		sub := strings.Split(s, "-")
		for _, part := range sub {
			padded = append(padded, padVersion(part))
		}
	}
	return strings.Join(padded, ".")
}

func padVersion(s string) string {
	for len(s) < 10 {
		s = "0" + s
	}
	return s
}
