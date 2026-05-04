package loader

import (
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jctanner/arch-query/internal/types"
)

func DiscoverVersions(baseDir string) ([]types.VersionInfo, error) {
	entries, err := os.ReadDir(baseDir)
	if err != nil {
		return nil, err
	}

	targetToAliases := make(map[string][]string)
	var realDirs []string

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
			targetToAliases[target] = append(targetToAliases[target], entry.Name())
		} else if entry.IsDir() {
			realDirs = append(realDirs, entry.Name())
		}
	}

	var versions []types.VersionInfo
	for _, name := range realDirs {
		if name == "diagrams" {
			continue
		}
		fullPath := filepath.Join(baseDir, name)
		count := countComponentFiles(fullPath)
		v := types.VersionInfo{
			Name:           name,
			Path:           fullPath,
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

func ResolveVersion(baseDir, version string) (string, error) {
	fullPath := filepath.Join(baseDir, version)
	resolved, err := filepath.EvalSymlinks(fullPath)
	if err != nil {
		return "", err
	}
	info, err := os.Stat(resolved)
	if err != nil {
		return "", err
	}
	if !info.IsDir() {
		return "", os.ErrNotExist
	}
	return resolved, nil
}

func countComponentFiles(dir string) int {
	entries, err := os.ReadDir(dir)
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

var excludedFiles = map[string]bool{
	"PLATFORM.md":          true,
	"README.md":            true,
	"RHOAI-Build-Config.md": true,
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
