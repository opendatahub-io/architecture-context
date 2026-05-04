package cmd

import (
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/output"
	"github.com/jctanner/arch-query/internal/types"
	"github.com/spf13/cobra"
)

var grepCmd = &cobra.Command{
	Use:   "grep <term>",
	Short: "Search all fields across all components for a term",
	Long: `Deep search across CRDs, dependencies, services, endpoints, RBAC,
and purpose text for a term. Shows every component that references
the term and in what context.

Examples:
  arch-query grep gateway
  arch-query grep httproute
  arch-query grep envoy`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		term := strings.ToLower(args[0])

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

		keys := make([]string, 0, len(data.Components))
		for k := range data.Components {
			keys = append(keys, k)
		}
		sort.Strings(keys)

		found := false
		for _, k := range keys {
			doc := data.Components[k]
			hits := grepComponent(term, doc)
			if len(hits) == 0 {
				continue
			}
			found = true
			fmt.Printf("%s:\n", k)
			tw := output.NewTabWriter(os.Stdout)
			for _, h := range hits {
				fmt.Fprintf(tw, "  [%s]\t%s\n", h.field, h.value)
			}
			tw.Flush()
			fmt.Println()
		}

		if !found {
			fmt.Fprintf(os.Stderr, "No references to %q found in %s.\n", term, version)
		}

		return nil
	},
}

type grepHit struct {
	field string
	value string
}

func grepComponent(term string, doc *types.ComponentDoc) []grepHit {
	var hits []grepHit

	if matchAny(term, doc.Purpose, doc.PurposeFull) {
		hits = append(hits, grepHit{"purpose", doc.Purpose})
	}

	for _, c := range doc.CRDs {
		if matchAny(term, c.Group, c.Version, c.Kind, c.Purpose) {
			hits = append(hits, grepHit{"crd", fmt.Sprintf("%s/%s %s (%s)", c.Group, c.Version, c.Kind, c.Scope)})
		}
	}

	for _, d := range doc.ExternalDeps {
		if matchAny(term, d.Component, d.Purpose) {
			hits = append(hits, grepHit{"ext-dep", fmt.Sprintf("%s - %s", d.Component, d.Purpose)})
		}
	}
	for _, d := range doc.InternalDeps {
		if matchAny(term, d.Component, d.Purpose) {
			hits = append(hits, grepHit{"int-dep", fmt.Sprintf("%s - %s", d.Component, d.Purpose)})
		}
	}

	for _, s := range doc.Services {
		if matchAny(term, s.Name, s.Type, s.Exposure) {
			hits = append(hits, grepHit{"service", fmt.Sprintf("%s %s/%s", s.Name, s.Port, s.Protocol)})
		}
	}

	for _, ep := range doc.Endpoints {
		if matchAny(term, ep.Path, ep.Purpose) {
			hits = append(hits, grepHit{"endpoint", fmt.Sprintf("%s %s %s", ep.Method, ep.Path, ep.Port)})
		}
	}

	for _, g := range doc.GRPCServices {
		if matchAny(term, g.Service, g.Purpose) {
			hits = append(hits, grepHit{"grpc", fmt.Sprintf("%s %s", g.Service, g.Port)})
		}
	}

	for _, r := range doc.RBACRoles {
		if matchAny(term, r.RoleName, r.APIGroup, r.Resources, r.Verbs) {
			hits = append(hits, grepHit{"rbac", fmt.Sprintf("%s %s %s [%s]", r.RoleName, r.APIGroup, r.Resources, r.Verbs)})
		}
	}

	for _, ing := range doc.Ingresses {
		if matchAny(term, ing.Component, ing.Type, ing.Hosts, ing.Exposure) {
			hits = append(hits, grepHit{"ingress", fmt.Sprintf("%s %s %s/%s %s", ing.Component, ing.Type, ing.Port, ing.Protocol, ing.Exposure)})
		}
	}

	for _, eg := range doc.Egresses {
		if matchAny(term, eg.Destination, eg.Purpose) {
			hits = append(hits, grepHit{"egress", fmt.Sprintf("%s %s/%s - %s", eg.Destination, eg.Port, eg.Protocol, eg.Purpose)})
		}
	}

	for _, ac := range doc.Components {
		if matchAny(term, ac.Name, ac.Type, ac.Purpose) {
			hits = append(hits, grepHit{"arch", fmt.Sprintf("%s (%s) - %s", ac.Name, ac.Type, ac.Purpose)})
		}
	}

	// Search raw sections for anything the structured parse missed
	for section, content := range doc.RawSections {
		if len(hits) > 0 {
			break
		}
		if strings.Contains(strings.ToLower(content), term) {
			lines := strings.Split(content, "\n")
			for _, line := range lines {
				if strings.Contains(strings.ToLower(line), term) {
					line = strings.TrimSpace(line)
					if line != "" && !strings.HasPrefix(line, "|") {
						hits = append(hits, grepHit{section, truncate(line, 100)})
						break
					}
				}
			}
		}
	}

	return hits
}

func matchAny(term string, fields ...string) bool {
	for _, f := range fields {
		if strings.Contains(strings.ToLower(f), term) {
			return true
		}
	}
	return false
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n-3] + "..."
}

func init() {
	rootCmd.AddCommand(grepCmd)
}
