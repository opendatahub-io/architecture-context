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

var watchTypeFilter string

var watchesCmd = &cobra.Command{
	Use:   "watches [component]",
	Short: "List controller watches, optionally filtered by component",
	Long: `Show which CRDs and resources each controller watches, with source
file references. Data comes from arch-analyzer JSON (controller_watches).

Examples:
  arch-query watches
  arch-query watches models-as-a-service
  arch-query watches --type For`,
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
			name := strings.ToLower(args[0])
			for k, doc := range data.Components {
				if strings.EqualFold(k, name) {
					filtered := doc.ControllerWatches
					if watchTypeFilter != "" {
						var f []interface{}
						for _, w := range filtered {
							if strings.EqualFold(w.Type, watchTypeFilter) {
								f = append(f, w)
							}
						}
						if outputFormat == OutputJSON {
							return output.JSON(os.Stdout, f)
						}
						filtered = nil
						for _, w := range doc.ControllerWatches {
							if strings.EqualFold(w.Type, watchTypeFilter) {
								filtered = append(filtered, w)
							}
						}
					}
					if len(filtered) == 0 {
						if outputFormat == OutputJSON {
							return output.JSON(os.Stdout, []any{})
						}
						fmt.Printf("%s has no controller watches.\n", k)
						return nil
					}
					if outputFormat == OutputJSON {
						return output.JSON(os.Stdout, filtered)
					}
					fmt.Printf("%s controller watches:\n", k)
					tw := output.NewTabWriter(os.Stdout)
					for _, w := range filtered {
						fmt.Fprintf(tw, "  %s\t%s\t%s\t%s\n", w.Type, w.GVK, w.Controller, w.Source)
					}
					tw.Flush()
					return nil
				}
			}
			fmt.Fprintf(os.Stderr, "Component %q not found in %s.\n", name, version)
			os.Exit(1)
		}

		type watchEntry struct {
			Type       string `json:"type"`
			GVK        string `json:"gvk"`
			Controller string `json:"controller"`
			Source     string `json:"source"`
			Component  string `json:"component"`
		}
		var all []watchEntry
		for k, doc := range data.Components {
			for _, w := range doc.ControllerWatches {
				if watchTypeFilter != "" && !strings.EqualFold(w.Type, watchTypeFilter) {
					continue
				}
				all = append(all, watchEntry{w.Type, w.GVK, w.Controller, w.Source, k})
			}
		}
		sort.Slice(all, func(i, j int) bool {
			if all[i].Component != all[j].Component {
				return all[i].Component < all[j].Component
			}
			return all[i].GVK < all[j].GVK
		})

		if outputFormat == OutputJSON {
			return output.JSON(os.Stdout, all)
		}

		if len(all) == 0 {
			fmt.Fprintf(os.Stderr, "No controller watches found in %s.\n", version)
			return nil
		}

		fmt.Printf("%d controller watches across %s:\n", len(all), version)
		tw := output.NewTabWriter(os.Stdout)
		for _, w := range all {
			fmt.Fprintf(tw, "  %s\t%s\t%s\t%s\t%s\n", w.Component, w.Type, w.GVK, w.Controller, w.Source)
		}
		tw.Flush()
		return nil
	},
}

func init() {
	watchesCmd.Flags().StringVar(&watchTypeFilter, "type", "", "Filter by watch type (For, Owns, Watches)")
	addOutputFlag(watchesCmd, OutputText, OutputJSON)
	rootCmd.AddCommand(watchesCmd)
}
