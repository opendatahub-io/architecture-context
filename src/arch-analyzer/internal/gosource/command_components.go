package gosource

import (
	"bufio"
	"encoding/json"
	"fmt"
	"go/ast"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

type dockerInstruction struct {
	operation string
	value     string
	line      int
}

type commandPackage struct {
	purpose string
}

type commandBuild struct {
	name       string
	packageDir string
	source     string
}

func extractShippedCommandComponents(root string, files []sourceFile) []model.SourceComponent {
	packages := executableCommandPackages(files)
	builds := shippedCommandBuilds(root)
	byName := map[string]model.SourceComponent{}
	for _, build := range builds {
		command, exists := packages[build.packageDir]
		if !exists {
			continue
		}
		component := model.SourceComponent{
			Name: build.name, Type: commandComponentType(command.purpose),
			Purpose: commandComponentPurpose(command.purpose), Source: build.source,
		}
		current, exists := byName[component.Name]
		if !exists || preferCommandComponentSource(component.Source, current.Source) {
			byName[component.Name] = component
		}
	}
	if len(byName) < 2 {
		return nil
	}
	result := make([]model.SourceComponent, 0, len(byName))
	for _, component := range byName {
		result = append(result, component)
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Name < result[j].Name })
	return result
}

func executableCommandPackages(files []sourceFile) map[string]commandPackage {
	result := map[string]commandPackage{}
	for _, file := range files {
		if file.file.Name.Name != "main" {
			continue
		}
		for _, declaration := range file.file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Recv != nil || function.Name.Name != "main" || function.Body == nil {
				continue
			}
			purpose := commandDocumentation(file)
			result[path.Clean(file.packageDir)] = commandPackage{purpose: purpose}
		}
	}
	return result
}

func commandDocumentation(file sourceFile) string {
	if file.file.Doc != nil {
		return strings.Join(strings.Fields(file.file.Doc.Text()), " ")
	}
	var selected *ast.CommentGroup
	for _, comment := range file.file.Comments {
		if comment.End() < file.file.Name.Pos() && (selected == nil || comment.End() > selected.End()) {
			selected = comment
		}
	}
	if selected == nil {
		return ""
	}
	text := strings.Join(strings.Fields(selected.Text()), " ")
	normalized := strings.ToLower(text)
	if strings.Contains(normalized, "copyright") || strings.Contains(normalized, "licensed under") {
		return ""
	}
	return text
}

func preferCommandComponentSource(candidate, current string) bool {
	candidateKonflux := strings.Contains(strings.ToLower(candidate), "konflux")
	currentKonflux := strings.Contains(strings.ToLower(current), "konflux")
	if candidateKonflux != currentKonflux {
		return !candidateKonflux
	}
	return candidate < current
}

func shippedCommandBuilds(root string) []commandBuild {
	var result []commandBuild
	_ = filepath.WalkDir(root, func(filePath string, entry fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if entry.IsDir() {
			if filePath != root && (ignoredDirectory(entry.Name()) || excludedCommandPath(entry.Name())) {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasPrefix(strings.ToLower(entry.Name()), "dockerfile") {
			return nil
		}
		instructions, err := readDockerInstructions(filePath)
		if err != nil {
			return nil
		}
		runnable := map[string]bool{}
		for _, instruction := range instructions {
			if instruction.operation == "ENTRYPOINT" || instruction.operation == "CMD" {
				if name := dockerRunnableName(instruction.value); name != "" {
					runnable[name] = true
				}
			}
		}
		relative, err := filepath.Rel(root, filePath)
		if err != nil {
			relative = filePath
		}
		for _, instruction := range instructions {
			if instruction.operation != "RUN" {
				continue
			}
			name, packageDir := parseGoBuild(instruction.value)
			if name == "" || packageDir == "" || excludedCommandPath(packageDir) || !runnable[name] {
				continue
			}
			result = append(result, commandBuild{
				name: name, packageDir: packageDir,
				source: fmt.Sprintf("%s:%d", filepath.ToSlash(relative), instruction.line),
			})
		}
		return nil
	})
	sort.Slice(result, func(i, j int) bool {
		return result[i].name+"\x00"+result[i].source < result[j].name+"\x00"+result[j].source
	})
	return result
}

func readDockerInstructions(filePath string) ([]dockerInstruction, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	var result []dockerInstruction
	scanner := bufio.NewScanner(file)
	lineNumber := 0
	startLine := 0
	logical := ""
	for scanner.Scan() {
		lineNumber++
		line := strings.TrimSpace(scanner.Text())
		if logical == "" && (line == "" || strings.HasPrefix(line, "#")) {
			continue
		}
		if logical == "" {
			startLine = lineNumber
		}
		continued := strings.HasSuffix(line, "\\")
		line = strings.TrimSpace(strings.TrimSuffix(line, "\\"))
		if logical != "" {
			logical += " "
		}
		logical += line
		if continued {
			continue
		}
		operation, value, found := strings.Cut(logical, " ")
		if found {
			result = append(result, dockerInstruction{
				operation: strings.ToUpper(strings.TrimSpace(operation)),
				value:     strings.TrimSpace(value), line: startLine,
			})
		}
		logical = ""
	}
	return result, scanner.Err()
}

func dockerRunnableName(value string) string {
	var arguments []string
	if strings.HasPrefix(strings.TrimSpace(value), "[") && json.Unmarshal([]byte(value), &arguments) == nil && len(arguments) > 0 {
		return path.Base(arguments[0])
	}
	fields := strings.Fields(value)
	if len(fields) == 0 {
		return ""
	}
	return path.Base(strings.Trim(fields[0], `"'`))
}

func parseGoBuild(value string) (string, string) {
	fields := strings.Fields(value)
	for index := 0; index+1 < len(fields); index++ {
		if path.Base(strings.Trim(fields[index], `"'`)) != "go" || fields[index+1] != "build" {
			continue
		}
		output := ""
		packageDir := ""
		for position := index + 2; position < len(fields); position++ {
			token := strings.Trim(fields[position], `"'`)
			switch {
			case token == "-o" && position+1 < len(fields):
				position++
				output = strings.Trim(fields[position], `"'`)
			case strings.HasPrefix(token, "-o="):
				output = strings.TrimPrefix(token, "-o=")
			case token == "." || token == "./":
				packageDir = "."
			case strings.HasSuffix(token, ".go") && !strings.Contains(token, "="):
				packageDir = path.Clean(path.Dir(strings.TrimPrefix(token, "./")))
			case strings.HasPrefix(token, "./"):
				packageDir = path.Clean(strings.TrimPrefix(token, "./"))
			}
		}
		if output != "" && packageDir != "" {
			return path.Base(output), packageDir
		}
	}
	return "", ""
}

func excludedCommandPath(value string) bool {
	for _, segment := range strings.Split(filepath.ToSlash(value), "/") {
		normalized := strings.ToLower(strings.TrimSpace(segment))
		switch normalized {
		case "demo", "demos", "example", "examples", "tool", "tools", "test", "tests", "testdata":
			return true
		}
		if strings.HasPrefix(normalized, "test-") || strings.HasSuffix(normalized, "-test") {
			return true
		}
	}
	return false
}

func commandComponentType(purpose string) string {
	normalized := strings.ToLower(purpose)
	switch {
	case strings.Contains(normalized, "api server") || strings.Contains(normalized, "http server"):
		return "Go HTTP Service"
	case strings.Contains(normalized, "processor"), strings.Contains(normalized, "garbage collector"), strings.Contains(normalized, "long-lived process"):
		return "Go Background Worker"
	default:
		return "Go executable"
	}
}

func extractCobraCLIComponents(files []sourceFile) []model.SourceComponent {
	var mainPackages []sourceFile
	hasCobra := false
	for _, file := range files {
		if file.file.Name.Name == "main" {
			mainPackages = append(mainPackages, file)
		}
		if importsPackage(file, "github.com/spf13/cobra") {
			hasCobra = true
		}
	}
	if !hasCobra || len(mainPackages) == 0 {
		return nil
	}
	var commands []string
	for _, file := range files {
		if !importsPackage(file, "github.com/spf13/cobra") {
			continue
		}
		ast.Inspect(file.file, func(node ast.Node) bool {
			literal, ok := node.(*ast.CompositeLit)
			if !ok || !isImportedType(file, literal.Type, "github.com/spf13/cobra", "Command") {
				return true
			}
			use := compositeResolvedStringField(literal, "Use", nil)
			if use != "" {
				name, _, _ := strings.Cut(use, " ")
				if name != "" && !stringInSlice(commands, name) {
					commands = append(commands, name)
				}
			}
			return true
		})
	}
	if len(commands) == 0 {
		return nil
	}
	name := commands[0]
	if len(mainPackages) > 0 {
		parts := strings.Split(mainPackages[0].modulePath, "/")
		if len(parts) > 0 {
			name = parts[len(parts)-1]
		}
	}
	return []model.SourceComponent{{
		Name: name, Type: "CLI Tool",
		Purpose: "Cobra CLI application",
		Source:  mainPackages[0].path,
	}}
}

func stringInSlice(slice []string, value string) bool {
	for _, s := range slice {
		if s == value {
			return true
		}
	}
	return false
}

func commandComponentPurpose(purpose string) string {
	if purpose != "" {
		return purpose
	}
	return "Executable Go command selected by the runtime image build"
}
