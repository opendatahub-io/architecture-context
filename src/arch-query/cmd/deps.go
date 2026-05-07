package cmd

import (
	"fmt"
	"os"
	"regexp"
	"sort"
	"strings"
	"unicode"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/output"
	"github.com/jctanner/arch-query/internal/types"
	"github.com/spf13/cobra"
)

var depsTree bool

var depsCmd = &cobra.Command{
	Use:   "deps [component]",
	Short: "Show dependency graph (single component or full platform tree)",
	Long: `Show dependency relationships between components.

Without arguments, renders the full platform dependency tree showing
how the operator deploys and connects all components.

With a component argument, shows that component's direct dependencies
and reverse dependencies (who depends on it).

Examples:
  arch-query deps                          # full platform tree
  arch-query deps --tree                   # same (explicit)
  arch-query deps kserve                   # single component
  arch-query deps --version rhoai-3.4      # specific version
  arch-query deps -o json                  # all edges as JSON`,
	Args: cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		version := versionArg
		if version == "" {
			versions, err := loader.DiscoverVersions(archFS, archSymlinks)
			if err != nil {
				return err
			}
			version = loader.DefaultVersion(versions)
		}

		data, err := loader.LoadVersion(archFS, overlayFS, version)
		if err != nil {
			return fmt.Errorf("loading version %s: %w", version, err)
		}

		if len(args) == 1 {
			return runSingleComponentDeps(data, args[0], version)
		}
		return runTreeDeps(data, version)
	},
}

func runSingleComponentDeps(data *types.VersionData, name, version string) error {
	lower := strings.ToLower(name)
	var doc *types.ComponentDoc
	var docKey string
	for k, v := range data.Components {
		if strings.EqualFold(k, lower) {
			doc = v
			docKey = k
			break
		}
	}
	if doc == nil {
		fmt.Fprintf(os.Stderr, "Component %q not found in %s.\n", name, version)
		os.Exit(1)
	}

	type reverseDep struct {
		Component string `json:"component"`
		Purpose   string `json:"purpose"`
	}
	var reverse []reverseDep
	for k, other := range data.Components {
		if strings.EqualFold(k, docKey) {
			continue
		}
		found := false
		for _, d := range other.ExternalDeps {
			if strings.EqualFold(d.Component, docKey) {
				reverse = append(reverse, reverseDep{k, d.Purpose})
				found = true
				break
			}
		}
		if found {
			continue
		}
		for _, d := range other.InternalDeps {
			if strings.EqualFold(d.Component, docKey) {
				reverse = append(reverse, reverseDep{k, d.Purpose})
				break
			}
		}
	}

	if outputFormat == OutputJSON {
		result := struct {
			Component    string            `json:"component"`
			ExternalDeps []types.Dependency `json:"external_deps,omitempty"`
			InternalDeps []types.Dependency `json:"internal_deps,omitempty"`
			Reverse      []reverseDep       `json:"reverse_deps,omitempty"`
		}{
			Component:    docKey,
			ExternalDeps: doc.ExternalDeps,
			InternalDeps: doc.InternalDeps,
			Reverse:      reverse,
		}
		return output.JSON(os.Stdout, result)
	}

	fmt.Printf("%s depends on:\n", docKey)
	if len(doc.ExternalDeps) > 0 {
		for _, d := range doc.ExternalDeps {
			req := ""
			if strings.Contains(strings.ToLower(d.Required), "no") || strings.Contains(strings.ToLower(d.Required), "optional") {
				req = " (optional)"
			}
			fmt.Printf("  %s%s - %s\n", d.Component, req, d.Purpose)
		}
	}
	if len(doc.InternalDeps) > 0 {
		for _, d := range doc.InternalDeps {
			fmt.Printf("  %s - %s\n", d.Component, d.Purpose)
		}
	}
	if len(doc.ExternalDeps) == 0 && len(doc.InternalDeps) == 0 {
		fmt.Println("  (none documented)")
	}

	fmt.Printf("\n%s is used by:\n", docKey)
	if len(reverse) > 0 {
		for _, r := range reverse {
			fmt.Printf("  %s - %s\n", r.Component, r.Purpose)
		}
	} else {
		fmt.Println("  (no reverse dependencies found in docs)")
	}

	return nil
}

type depEdge struct {
	From       string `json:"from"`
	To         string `json:"to"`
	ToKey      string `json:"to_key,omitempty"`
	Purpose    string `json:"purpose,omitempty"`
	Annotation string `json:"annotation"`
}

func runTreeDeps(data *types.VersionData, version string) error {
	nameToKey := buildNameLookup(data.Components)

	var edges []depEdge
	adjacency := map[string][]depEdge{}
	hasIncoming := map[string]bool{}
	seenEdges := map[[2]string]bool{}

	for key, doc := range data.Components {
		for _, dep := range doc.InternalDeps {
			toKey := resolveToKey(dep.Component, nameToKey)
			if toKey == "" {
				continue
			}
			if toKey == key {
				continue
			}
			pair := [2]string{key, toKey}
			if seenEdges[pair] {
				continue
			}
			seenEdges[pair] = true

			ann := deriveAnnotation(dep.Purpose)
			e := depEdge{
				From:       key,
				To:         displayName(data.Components, toKey),
				ToKey:      toKey,
				Purpose:    dep.Purpose,
				Annotation: ann,
			}
			edges = append(edges, e)
			adjacency[key] = append(adjacency[key], e)
			hasIncoming[toKey] = true
		}
	}

	if outputFormat == OutputJSON {
		sort.Slice(edges, func(i, j int) bool {
			if edges[i].From != edges[j].From {
				return edges[i].From < edges[j].From
			}
			return edges[i].ToKey < edges[j].ToKey
		})
		return output.JSON(os.Stdout, edges)
	}

	if len(edges) == 0 {
		fmt.Fprintf(os.Stderr, "No resolvable internal dependencies found in %s.\n", version)
		return nil
	}

	roots := findRoots(adjacency, hasIncoming, data.Components)

	fmt.Printf("Dependency tree for %s (%d edges, %d roots):\n\n",
		version, len(edges), len(roots))

	visited := map[string]bool{}
	for _, root := range roots {
		printTree(data.Components, adjacency, root, visited)
	}

	orphans := findOrphans(data.Components, adjacency, hasIncoming, visited)
	if len(orphans) > 0 {
		fmt.Printf("\nLeaf components (no internal deps to/from other components):\n")
		for _, k := range orphans {
			name := displayName(data.Components, k)
			fmt.Printf("  %s\n", name)
		}
	}

	return nil
}

// Semantic aliases for display names that can't be derived from component keys.
var semanticAliases = map[string]string{
	"workbenches":        "notebooks",
	"workbench":          "notebooks",
	"notebook":           "notebooks",
	"ray":                "kuberay",
	"kuberay operator":   "kuberay",
	"trustyai":           "trustyai-service-operator",
	"llamastack":         "ogx-k8s-operator",
	"llamastackoperator": "ogx-k8s-operator",
}

func buildNameLookup(components map[string]*types.ComponentDoc) map[string]string {
	lookup := map[string]string{}

	for key, doc := range components {
		lookup[strings.ToLower(key)] = key
		if doc.Name != "" {
			lookup[strings.ToLower(doc.Name)] = key
		}
		normalized := normalizeName(key)
		if normalized != "" {
			lookup[normalized] = key
		}
		if doc.Name != "" {
			normalized = normalizeName(doc.Name)
			if normalized != "" {
				lookup[normalized] = key
			}
		}

		// Strip common prefixes to create shorter aliases
		for _, prefix := range []string{"odh-", "rhoai-"} {
			if strings.HasPrefix(key, prefix) {
				short := key[len(prefix):]
				lookup[strings.ToLower(short)] = key
				lookup[normalizeName(short)] = key
			}
		}

		// Strip "-operator" suffix for matching "X Operator" → x-operator
		if strings.HasSuffix(key, "-operator") {
			base := key[:len(key)-len("-operator")]
			lookup[strings.ToLower(base)] = key
			lookup[normalizeName(base)] = key
		}
	}

	// Add semantic aliases (only if the target component exists)
	for alias, target := range semanticAliases {
		if _, ok := components[target]; ok {
			lookup[alias] = target
		}
	}

	return lookup
}

var nonAlphaNum = regexp.MustCompile(`[^a-z0-9]+`)

func normalizeName(s string) string {
	lower := strings.ToLower(s)
	return strings.TrimRight(nonAlphaNum.ReplaceAllString(lower, ""), "")
}

func resolveToKey(displayTarget string, lookup map[string]string) string {
	lower := strings.ToLower(strings.TrimSpace(displayTarget))

	if key, ok := lookup[lower]; ok {
		return key
	}

	normalized := normalizeName(displayTarget)
	if key, ok := lookup[normalized]; ok {
		return key
	}

	// Check semantic aliases directly
	if target, ok := semanticAliases[lower]; ok {
		if key, ok := lookup[strings.ToLower(target)]; ok {
			return key
		}
	}
	if target, ok := semanticAliases[normalized]; ok {
		if key, ok := lookup[strings.ToLower(target)]; ok {
			return key
		}
	}

	// Handle "X / Y" patterns — try each part
	if strings.Contains(displayTarget, "/") {
		for _, part := range strings.Split(displayTarget, "/") {
			part = strings.TrimSpace(part)
			if key, ok := lookup[strings.ToLower(part)]; ok {
				return key
			}
			if key, ok := lookup[normalizeName(part)]; ok {
				return key
			}
		}
	}

	// Handle "X (Y)" — try the part before the paren
	if idx := strings.Index(displayTarget, "("); idx > 0 {
		before := strings.TrimSpace(displayTarget[:idx])
		if key, ok := lookup[strings.ToLower(before)]; ok {
			return key
		}
		if key, ok := lookup[normalizeName(before)]; ok {
			return key
		}
	}

	// Try with common prefixes added: "Dashboard" → "odh-dashboard"
	for _, prefix := range []string{"odh-", "rhoai-"} {
		candidate := prefix + strings.ToLower(strings.ReplaceAll(displayTarget, " ", "-"))
		if key, ok := lookup[candidate]; ok {
			return key
		}
	}

	// Try hyphenated form: "Model Controller" → "model-controller"
	hyphenated := strings.ToLower(strings.ReplaceAll(strings.TrimSpace(displayTarget), " ", "-"))
	if key, ok := lookup[hyphenated]; ok {
		return key
	}
	// With -operator suffix: "Model Controller" → "model-controller-operator" (unlikely but try)
	if key, ok := lookup[hyphenated+"-operator"]; ok {
		return key
	}

	// Prefix match: prefer keys that start with the target (or target starts with key)
	if len(normalized) >= 3 {
		var bestKey string
		bestLen := 0
		for norm, key := range lookup {
			if len(norm) < 3 {
				continue
			}
			if strings.HasPrefix(norm, normalized) || strings.HasPrefix(normalized, norm) {
				matchLen := len(norm)
				if matchLen > bestLen {
					bestLen = matchLen
					bestKey = key
				}
			}
		}
		if bestKey != "" {
			return bestKey
		}
	}

	// Substring match: find keys containing the target, prefer shortest (most specific)
	if len(normalized) >= 4 {
		var bestKey string
		bestLen := 999
		for norm, key := range lookup {
			if len(norm) < 4 {
				continue
			}
			if strings.Contains(norm, normalized) {
				if len(norm) < bestLen {
					bestLen = len(norm)
					bestKey = key
				}
			}
		}
		if bestKey != "" {
			return bestKey
		}
	}

	return ""
}

func deriveAnnotation(purpose string) string {
	lower := strings.ToLower(purpose)

	switch {
	case strings.Contains(lower, "deploys") || strings.Contains(lower, "manifest"):
		return "deploys"
	case strings.Contains(lower, "crd") && strings.Contains(lower, "watch"):
		return "CRD watch"
	case strings.Contains(lower, "crd"):
		return "CRD"
	case strings.Contains(lower, "sidecar"):
		return "sidecar"
	case containsAny(lower, "rest api", "http api", "rest/http"):
		return "API"
	case strings.Contains(lower, "grpc"):
		return "gRPC"
	case strings.Contains(lower, "manages") || strings.Contains(lower, "lifecycle"):
		return "manages"
	case strings.Contains(lower, "routing") || strings.Contains(lower, "routes"):
		return "routing"
	case strings.Contains(lower, "auth"):
		return "auth"
	case strings.Contains(lower, "monitor") || strings.Contains(lower, "metrics"):
		return "metrics"
	case strings.Contains(lower, "serving"):
		return "serving"
	}

	// Truncate the purpose to a short annotation
	words := strings.Fields(purpose)
	if len(words) > 4 {
		words = words[:4]
	}
	result := strings.Join(words, " ")
	result = strings.TrimRightFunc(result, func(r rune) bool {
		return unicode.IsPunct(r) || unicode.IsSpace(r)
	})
	return result
}

func containsAny(s string, substrs ...string) bool {
	for _, sub := range substrs {
		if strings.Contains(s, sub) {
			return true
		}
	}
	return false
}

func findRoots(adjacency map[string][]depEdge, hasIncoming map[string]bool, components map[string]*types.ComponentDoc) []string {
	// Known operator roots
	knownRoots := []string{"rhods-operator", "opendatahub-operator"}
	var roots []string
	for _, r := range knownRoots {
		if _, ok := components[r]; ok {
			if _, hasEdges := adjacency[r]; hasEdges {
				roots = append(roots, r)
			}
		}
	}
	if len(roots) > 0 {
		return roots
	}

	// Fall back: nodes with outgoing edges but no incoming
	for key := range adjacency {
		if !hasIncoming[key] {
			roots = append(roots, key)
		}
	}
	sort.Strings(roots)
	if len(roots) > 0 {
		return roots
	}

	// Last resort: node with most outgoing edges
	maxEdges := 0
	maxKey := ""
	for key, edges := range adjacency {
		if len(edges) > maxEdges {
			maxEdges = len(edges)
			maxKey = key
		}
	}
	if maxKey != "" {
		return []string{maxKey}
	}
	return nil
}

func printTree(components map[string]*types.ComponentDoc, adjacency map[string][]depEdge,
	root string, visited map[string]bool) {
	fmt.Println(displayName(components, root))
	visited[root] = true
	children := sortedChildren(adjacency[root])
	for i, child := range children {
		printSubtree(components, adjacency, child.ToKey, child.Annotation, "", i == len(children)-1, visited)
	}
}

func printSubtree(components map[string]*types.ComponentDoc, adjacency map[string][]depEdge,
	key string, annotation string, prefix string, isLast bool, visited map[string]bool) {

	connector := "|-- "
	if isLast {
		connector = "`-- "
	}

	label := displayName(components, key)
	if annotation != "" {
		label = fmt.Sprintf("%s (%s)", label, annotation)
	}

	if visited[key] && len(adjacency[key]) > 0 {
		fmt.Printf("%s%s%s (*)\n", prefix, connector, label)
		return
	}

	fmt.Printf("%s%s%s\n", prefix, connector, label)
	visited[key] = true

	children := sortedChildren(adjacency[key])
	if len(children) == 0 {
		return
	}

	var nextPrefix string
	if isLast {
		nextPrefix = prefix + "    "
	} else {
		nextPrefix = prefix + "|   "
	}

	for i, child := range children {
		printSubtree(components, adjacency, child.ToKey, child.Annotation, nextPrefix, i == len(children)-1, visited)
	}
}

func sortedChildren(edges []depEdge) []depEdge {
	if len(edges) == 0 {
		return nil
	}
	sorted := make([]depEdge, len(edges))
	copy(sorted, edges)
	sort.Slice(sorted, func(i, j int) bool {
		return sorted[i].ToKey < sorted[j].ToKey
	})
	return sorted
}

func displayName(components map[string]*types.ComponentDoc, key string) string {
	if doc, ok := components[key]; ok && doc.Name != "" {
		return doc.Name
	}
	return key
}

func findOrphans(components map[string]*types.ComponentDoc, adjacency map[string][]depEdge,
	hasIncoming map[string]bool, visited map[string]bool) []string {
	var orphans []string
	for key := range components {
		if visited[key] {
			continue
		}
		if _, hasOut := adjacency[key]; hasOut {
			continue
		}
		if hasIncoming[key] {
			continue
		}
		orphans = append(orphans, key)
	}
	sort.Strings(orphans)
	return orphans
}

func init() {
	depsCmd.Flags().BoolVar(&depsTree, "tree", false, "Render as tree (default for text output without component arg)")
	addOutputFlag(depsCmd, OutputText, OutputJSON)
	rootCmd.AddCommand(depsCmd)
}
