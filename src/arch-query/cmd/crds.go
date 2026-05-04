package cmd

import (
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/output"
	"github.com/spf13/cobra"
)

var crdsCmd = &cobra.Command{
	Use:   "crds [component]",
	Short: "List CRDs, optionally filtered by component",
	Args:  cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		version := versionArg
		if version == "" {
			versions, err := loader.DiscoverVersions(baseDir)
			if err != nil {
				return err
			}
			version = loader.DefaultVersion(versions)
		}

		data, err := loader.LoadVersion(baseDir, version)
		if err != nil {
			return fmt.Errorf("loading version %s: %w", version, err)
		}

		if len(args) == 1 {
			name := strings.ToLower(args[0])
			for k, doc := range data.Components {
				if strings.EqualFold(k, name) {
					if len(doc.CRDs) == 0 {
						fmt.Printf("%s has no CRDs.\n", k)
						return nil
					}
					fmt.Printf("%s CRDs:\n", k)
					tw := output.NewTabWriter(os.Stdout)
					for _, crd := range doc.CRDs {
						fmt.Fprintf(tw, "  %s/%s\t%s\t%s\n", crd.Group, crd.Version, crd.Kind, crd.Scope)
					}
					tw.Flush()
					return nil
				}
			}
			fmt.Fprintf(os.Stderr, "Component %q not found in %s.\n", name, version)
			os.Exit(1)
		}

		// All CRDs across all components
		type crdEntry struct {
			group, version, kind, scope, source string
		}
		var all []crdEntry
		for k, doc := range data.Components {
			for _, crd := range doc.CRDs {
				all = append(all, crdEntry{crd.Group, crd.Version, crd.Kind, crd.Scope, k})
			}
		}
		sort.Slice(all, func(i, j int) bool {
			if all[i].group != all[j].group {
				return all[i].group < all[j].group
			}
			return all[i].kind < all[j].kind
		})

		fmt.Printf("%d CRDs across %s:\n", len(all), version)
		tw := output.NewTabWriter(os.Stdout)
		for _, c := range all {
			fmt.Fprintf(tw, "  %s/%s\t%s\t%s\t%s\n", c.group, c.version, c.kind, c.source, c.scope)
		}
		tw.Flush()
		return nil
	},
}

func init() {
	rootCmd.AddCommand(crdsCmd)
}
