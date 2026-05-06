package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/output"
	"github.com/jctanner/arch-query/internal/types"
	"github.com/spf13/cobra"
)

var depsCmd = &cobra.Command{
	Use:   "deps <component>",
	Short: "Show dependency graph for a component",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := strings.ToLower(args[0])

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

		var doc *types.ComponentDoc
		var docKey string
		for k, v := range data.Components {
			if strings.EqualFold(k, name) {
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
	},
}

func containsIgnoreCase(s, substr string) bool {
	return strings.Contains(strings.ToLower(s), strings.ToLower(substr))
}

func init() {
	addOutputFlag(depsCmd, OutputText, OutputJSON)
	rootCmd.AddCommand(depsCmd)
}
