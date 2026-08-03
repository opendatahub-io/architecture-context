package extractor

import (
	"bufio"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

// extractDockerfileEntrypoints records literal ENTRYPOINT/CMD instructions.
// It deliberately does not interpret shell expansion or compose/build
// substitutions; those remain explicit unknowns for synthesis.
func extractDockerfileEntrypoints(root string) []model.Entrypoint {
	var result []model.Entrypoint
	_ = filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if entry.IsDir() {
			if path != root && ignoredDir(entry.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		name := strings.ToLower(entry.Name())
		if name != "dockerfile" && !strings.HasPrefix(name, "dockerfile.") {
			return nil
		}
		file, readErr := os.Open(path)
		if readErr != nil {
			return nil
		}
		defer file.Close()
		relative, relErr := filepath.Rel(root, path)
		if relErr != nil {
			return nil
		}
		scanner := bufio.NewScanner(file)
		line := 0
		for scanner.Scan() {
			line++
			fields := strings.Fields(scanner.Text())
			if len(fields) < 2 {
				continue
			}
			instruction := strings.ToUpper(fields[0])
			if instruction != "ENTRYPOINT" && instruction != "CMD" {
				continue
			}
			command := strings.TrimSpace(strings.TrimPrefix(scanner.Text(), fields[0]))
			result = append(result, model.Entrypoint{
				Name:    filepath.ToSlash(relative) + ":" + instruction,
				Type:    "Container entrypoint",
				Runtime: "Container",
				Command: command,
				Source:  filepath.ToSlash(relative) + ":" + strconv.Itoa(line),
			})
		}
		return nil
	})
	return result
}
