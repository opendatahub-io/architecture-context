// Command arch-doc assembles architecture Markdown using explicit section ownership.
package main

import (
	_ "embed"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

//go:embed section-manifest.json
var manifestBytes []byte

type manifest struct {
	RequiredSections         []string            `json:"required_sections"`
	KnownSections            []string            `json:"known_sections"`
	AnalyzerSections         []string            `json:"analyzer_sections"`
	SynthesisSections        []string            `json:"synthesis_sections"`
	ConditionalSynthesis     []string            `json:"conditional_synthesis_sections"`
	SharedSections           []string            `json:"shared_sections"`
	SynthesisSubsections     map[string][]string `json:"synthesis_subsections"`
	NonAuthoritativeSections []string            `json:"non_authoritative_sections"`
}

type section struct {
	Name  string `json:"name"`
	Owner string `json:"owner"`
	Text  string `json:"-"`
}

type document struct {
	Preamble  string
	Sections  []section
	Duplicate []string
}

var config manifest

func init() {
	if err := json.Unmarshal(manifestBytes, &config); err != nil {
		panic(fmt.Sprintf("invalid embedded section manifest: %v", err))
	}
}

func main() {
	if len(os.Args) < 2 {
		usage()
	}
	switch os.Args[1] {
	case "sections":
		exit(runSections(os.Args[2:]))
	case "validate":
		exit(runValidate(os.Args[2:]))
	case "update":
		exit(runUpdate(os.Args[2:]))
	case "assemble":
		exit(runAssemble(os.Args[2:]))
	case "help", "--help", "-h":
		usage()
	default:
		fmt.Fprintf(os.Stderr, "unknown command %q\n\n", os.Args[1])
		usage()
	}
}

func usage() {
	fmt.Fprintln(os.Stderr, "Usage:")
	fmt.Fprintln(os.Stderr, "  arch-doc sections FILE [--output text|json]")
	fmt.Fprintln(os.Stderr, "  arch-doc validate FILE")
	fmt.Fprintln(os.Stderr, "  arch-doc update FILE --section NAME --input CONTENT [--output FILE]")
	fmt.Fprintln(os.Stderr, "  arch-doc assemble --base FILE --candidate FILE --output FILE")
	os.Exit(2)
}

func exit(err error) {
	if err == nil {
		return
	}
	fmt.Fprintln(os.Stderr, "arch-doc:", err)
	os.Exit(1)
}

func runSections(args []string) error {
	flags := flag.NewFlagSet("sections", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	output := flags.String("output", "text", "output format: text or json")
	if err := flags.Parse(reorderPositionalFile(args)); err != nil {
		return err
	}
	if flags.NArg() != 1 {
		return errors.New("sections requires exactly one FILE")
	}
	doc, err := readDocument(flags.Arg(0))
	if err != nil {
		return err
	}
	if *output == "json" {
		payload := struct {
			Sections  []section `json:"sections"`
			Duplicate []string  `json:"duplicate_sections,omitempty"`
		}{doc.Sections, doc.Duplicate}
		encoded, encodeErr := json.MarshalIndent(payload, "", "  ")
		if encodeErr != nil {
			return encodeErr
		}
		fmt.Println(string(encoded))
		return nil
	}
	if *output != "text" {
		return fmt.Errorf("unsupported output format %q", *output)
	}
	for _, item := range doc.Sections {
		fmt.Printf("%-28s %s\n", item.Name, item.Owner)
	}
	return nil
}

func runValidate(args []string) error {
	flags := flag.NewFlagSet("validate", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	if err := flags.Parse(reorderPositionalFile(args)); err != nil {
		return err
	}
	if flags.NArg() != 1 {
		return errors.New("validate requires exactly one FILE")
	}
	doc, err := readDocument(flags.Arg(0))
	if err != nil {
		return err
	}
	errorsFound := validateDocument(doc)
	if len(errorsFound) != 0 {
		return errors.New(strings.Join(errorsFound, "; "))
	}
	fmt.Printf("Valid architecture document: %s (%d sections)\n", flags.Arg(0), len(doc.Sections))
	return nil
}

func runUpdate(args []string) error {
	flags := flag.NewFlagSet("update", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	sectionName := flags.String("section", "", "section to replace")
	inputPath := flags.String("input", "", "file containing section content")
	outputPath := flags.String("output", "", "output file; defaults to in-place")
	if err := flags.Parse(reorderPositionalFile(args)); err != nil {
		return err
	}
	if flags.NArg() != 1 || *sectionName == "" || *inputPath == "" {
		return errors.New("update requires FILE, --section, and --input")
	}
	owner := ownerFor(*sectionName)
	if owner != "synthesis" {
		return fmt.Errorf("section %q is owned by %s and cannot be updated by an agent", *sectionName, owner)
	}
	doc, err := readDocument(flags.Arg(0))
	if err != nil {
		return err
	}
	if validation := validateDocument(doc); len(validation) > 0 {
		return errors.New(strings.Join(validation, "; "))
	}
	content, err := os.ReadFile(*inputPath)
	if err != nil {
		return fmt.Errorf("read update content: %w", err)
	}
	replacement := normalizeSectionContent(*sectionName, string(content))
	updated, err := replaceSection(doc, *sectionName, replacement, true)
	if err != nil {
		return err
	}
	updatedText := renderDocument(updated)
	if validation := validateDocument(parseDocument(updatedText)); len(validation) > 0 {
		return errors.New(strings.Join(validation, "; "))
	}
	target := flags.Arg(0)
	if *outputPath != "" {
		target = *outputPath
	}
	return atomicWrite(target, updatedText)
}

func runAssemble(args []string) error {
	flags := flag.NewFlagSet("assemble", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	basePath := flags.String("base", "", "table-merged analyzer base")
	candidatePath := flags.String("candidate", "", "agent candidate")
	outputPath := flags.String("output", "", "assembled output")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if *basePath == "" || *candidatePath == "" || *outputPath == "" {
		return errors.New("assemble requires --base, --candidate, and --output")
	}
	base, err := readDocument(*basePath)
	if err != nil {
		return fmt.Errorf("read base: %w", err)
	}
	candidate, err := readDocument(*candidatePath)
	if err != nil {
		return fmt.Errorf("read candidate: %w", err)
	}
	if validation := validateDocument(base); len(validation) > 0 {
		return errors.New(strings.Join(validation, "; "))
	}
	if validation := validateSynthesisInput(candidate, "candidate"); len(validation) > 0 {
		return errors.New(strings.Join(validation, "; "))
	}
	assembled, err := assembleDocuments(base, candidate)
	if err != nil {
		return err
	}
	if validation := validateDocument(assembled); len(validation) > 0 {
		return errors.New(strings.Join(validation, "; "))
	}
	return atomicWrite(*outputPath, renderDocument(assembled))
}

func readDocument(path string) (document, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return document{}, fmt.Errorf("read %s: %w", path, err)
	}
	return parseDocument(string(data)), nil
}

func parseDocument(text string) document {
	lines := strings.SplitAfter(text, "\n")
	var current *section
	var preamble strings.Builder
	var sections []section
	seen := map[string]bool{}
	duplicates := []string{}
	for _, line := range lines {
		if strings.HasPrefix(line, "## ") {
			name := strings.TrimSpace(strings.TrimSuffix(strings.TrimSuffix(line[3:], "\n"), "\r"))
			if seen[name] {
				duplicates = appendUnique(duplicates, name)
			}
			seen[name] = true
			sections = append(sections, section{Name: name, Owner: ownerFor(name)})
			current = &sections[len(sections)-1]
			current.Text = line
			continue
		}
		if current == nil {
			preamble.WriteString(line)
		} else {
			current.Text += line
		}
	}
	return document{Preamble: preamble.String(), Sections: sections, Duplicate: duplicates}
}

func renderDocument(doc document) string {
	var output strings.Builder
	output.WriteString(doc.Preamble)
	for _, item := range doc.Sections {
		output.WriteString(item.Text)
	}
	return output.String()
}

func validateDocument(doc document) []string {
	issues := []string{}
	for _, duplicate := range doc.Duplicate {
		issues = append(issues, fmt.Sprintf("duplicate section: %s", duplicate))
	}
	present := map[string]bool{}
	for _, item := range doc.Sections {
		present[item.Name] = true
		if !contains(config.KnownSections, item.Name) {
			issues = append(issues, "unknown section: "+item.Name)
		}
	}
	for _, required := range config.RequiredSections {
		if !present[required] {
			issues = append(issues, "missing required section: "+required)
		}
	}
	return issues
}

func validateSynthesisInput(doc document, label string) []string {
	issues := []string{}
	for _, duplicate := range doc.Duplicate {
		issues = append(issues, fmt.Sprintf("%s duplicate section: %s", label, duplicate))
	}
	present := map[string]bool{}
	for _, item := range doc.Sections {
		present[item.Name] = true
		if !contains(config.KnownSections, item.Name) {
			issues = append(issues, fmt.Sprintf("%s unknown section: %s", label, item.Name))
		}
	}
	for _, required := range config.SynthesisSections {
		if !present[required] {
			issues = append(issues, fmt.Sprintf("%s missing synthesis section: %s", label, required))
		}
	}
	return issues
}

func assembleDocuments(base, candidate document) (document, error) {
	result := base
	candidateByName := sectionMap(candidate.Sections)
	for _, name := range config.SynthesisSections {
		candidateSection, ok := candidateByName[name]
		if !ok {
			return document{}, fmt.Errorf("candidate missing synthesis section: %s", name)
		}
		if _, ok := sectionMap(result.Sections)[name]; !ok {
			return document{}, fmt.Errorf("base missing synthesis section: %s", name)
		}
		result, _ = replaceSection(result, name, candidateSection.Text, false)
	}
	result = mergeSecuritySubsections(result, candidateByName)
	for _, name := range config.ConditionalSynthesis {
		candidateSection, ok := candidateByName[name]
		if !ok || hasSection(result, name) {
			continue
		}
		result.Sections = append(result.Sections, candidateSection)
	}
	if generated := generatedBy(candidate); generated != "" {
		result = replaceGeneratedBy(result, generated)
	}
	return result, nil
}

func mergeSecuritySubsections(base document, candidate map[string]section) document {
	baseSecurity, ok := findSection(base, "Security")
	if !ok {
		return base
	}
	securityText := baseSecurity.Text
	candidateSecurity, ok := candidate["Security"]
	if !ok {
		return base
	}
	for _, subsection := range config.SynthesisSubsections["Security"] {
		if block := extractSubsection(candidateSecurity.Text, subsection); block != "" && extractSubsection(securityText, subsection) == "" {
			securityText = strings.TrimRight(securityText, "\r\n") + "\n\n" + strings.TrimRight(block, "\r\n") + "\n"
		}
	}
	updated, _ := replaceSection(base, "Security", securityText, false)
	return updated
}

func extractSubsection(text, name string) string {
	lines := strings.SplitAfter(text, "\n")
	needle := "### " + name
	start, end := -1, len(lines)
	for index, line := range lines {
		trimmed := strings.TrimRight(strings.TrimSuffix(line, "\n"), "\r")
		if strings.HasPrefix(trimmed, "### ") {
			if start >= 0 {
				end = index
				break
			}
			if trimmed == needle {
				start = index
			}
		}
	}
	if start < 0 {
		return ""
	}
	return strings.Join(lines[start:end], "")
}

func replaceSection(doc document, name, replacement string, allowAppend bool) (document, error) {
	for index := range doc.Sections {
		if doc.Sections[index].Name == name {
			doc.Sections[index].Text = replacement
			return doc, nil
		}
	}
	if !allowAppend {
		return doc, fmt.Errorf("section not found: %s", name)
	}
	doc.Sections = append(doc.Sections, section{Name: name, Owner: ownerFor(name), Text: replacement})
	return doc, nil
}

func normalizeSectionContent(name, content string) string {
	content = strings.TrimSpace(content)
	prefix := "## " + name
	if strings.HasPrefix(content, prefix) {
		return content + "\n"
	}
	return prefix + "\n\n" + content + "\n"
}

func replaceGeneratedBy(doc document, line string) document {
	for index := range doc.Sections {
		lines := strings.SplitAfter(doc.Sections[index].Text, "\n")
		for lineIndex, current := range lines {
			if strings.HasPrefix(strings.TrimSpace(current), "- **Generated By**:") {
				lines[lineIndex] = line + "\n"
			}
		}
		doc.Sections[index].Text = strings.Join(lines, "")
	}
	return doc
}

func generatedBy(doc document) string {
	for _, item := range doc.Sections {
		for _, line := range strings.Split(item.Text, "\n") {
			if strings.HasPrefix(strings.TrimSpace(line), "- **Generated By**:") {
				return strings.TrimSpace(line)
			}
		}
	}
	return ""
}

func sectionMap(sections []section) map[string]section {
	result := make(map[string]section, len(sections))
	for _, item := range sections {
		result[item.Name] = item
	}
	return result
}

func findSection(doc document, name string) (section, bool) {
	for _, item := range doc.Sections {
		if item.Name == name {
			return item, true
		}
	}
	return section{}, false
}

func hasSection(doc document, name string) bool {
	_, ok := findSection(doc, name)
	return ok
}

func ownerFor(name string) string {
	for _, item := range config.SynthesisSections {
		if item == name {
			return "synthesis"
		}
	}
	for _, item := range config.ConditionalSynthesis {
		if item == name {
			return "synthesis-conditional"
		}
	}
	for _, item := range config.SharedSections {
		if item == name {
			return "shared"
		}
	}
	for _, item := range config.AnalyzerSections {
		if item == name {
			return "analyzer"
		}
	}
	for _, item := range config.NonAuthoritativeSections {
		if item == name {
			return "non-authoritative"
		}
	}
	for _, item := range config.RequiredSections {
		if item == name {
			return "analyzer"
		}
	}
	return "unmanaged"
}

func atomicWrite(path, content string) error {
	target := filepath.Clean(path)
	if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
		return fmt.Errorf("create output directory: %w", err)
	}
	temporary, err := os.CreateTemp(filepath.Dir(target), ".arch-doc-*")
	if err != nil {
		return fmt.Errorf("create temporary output: %w", err)
	}
	temporaryName := temporary.Name()
	defer os.Remove(temporaryName)
	if _, err := temporary.WriteString(content); err != nil {
		temporary.Close()
		return fmt.Errorf("write output: %w", err)
	}
	if err := temporary.Close(); err != nil {
		return fmt.Errorf("close output: %w", err)
	}
	if err := os.Rename(temporaryName, target); err != nil {
		return fmt.Errorf("replace output: %w", err)
	}
	return nil
}

func appendUnique(values []string, value string) []string {
	for _, current := range values {
		if current == value {
			return values
		}
	}
	return append(values, value)
}

func contains(values []string, value string) bool {
	for _, current := range values {
		if current == value {
			return true
		}
	}
	return false
}

func reorderPositionalFile(args []string) []string {
	if len(args) == 0 || strings.HasPrefix(args[0], "-") {
		return args
	}
	return append(append([]string{}, args[1:]...), args[0])
}
