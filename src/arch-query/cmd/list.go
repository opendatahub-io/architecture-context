package cmd

import (
	"fmt"
	"os"
	"sort"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/output"
	"github.com/spf13/cobra"
)

var namesOnly bool

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all components in a version",
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

		keys := make([]string, 0, len(data.Components))
		for k := range data.Components {
			keys = append(keys, k)
		}
		sort.Strings(keys)

		if namesOnly {
			for _, k := range keys {
				fmt.Println(k)
			}
			return nil
		}

		fmt.Printf("%d components in %s:\n\n", len(keys), version)
		tw := output.NewTabWriter(os.Stdout)
		for _, k := range keys {
			doc := data.Components[k]
			deployType := doc.DeployType
			if deployType == "" {
				deployType = doc.Metadata["Deployment Type"]
			}
			purpose := doc.Purpose
			if len(purpose) > 80 {
				purpose = purpose[:77] + "..."
			}
			fmt.Fprintf(tw, "  %s\t%s\t%s\n", k, deployType, purpose)
		}
		tw.Flush()
		return nil
	},
}

func init() {
	listCmd.Flags().BoolVar(&namesOnly, "names-only", false, "Print component names only, one per line")
	rootCmd.AddCommand(listCmd)
}
