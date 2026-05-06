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

var overlaysCmd = &cobra.Command{
	Use:   "overlays",
	Short: "List active overlays and what they affect",
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

		if len(data.Overlays) == 0 {
			if outputFormat == OutputJSON {
				return output.JSON(os.Stdout, []*types.OverlayDoc{})
			}
			fmt.Println("No overlays found.")
			return nil
		}

		var active []*types.OverlayDoc
		for _, o := range data.Overlays {
			if o.Status == "active" {
				active = append(active, o)
			}
		}

		if outputFormat == OutputJSON {
			return output.JSON(os.Stdout, active)
		}

		fmt.Printf("%d active overlays:\n\n", len(active))
		tw := output.NewTabWriter(os.Stdout)
		for _, o := range active {
			affects := strings.Join(o.Affects, ", ")
			releases := strings.Join(o.Release, ", ")
			fmt.Fprintf(tw, "  %s\t%s\treleases: %s\taffects: %s\n", o.ID, o.Title, releases, affects)
		}
		tw.Flush()

		fmt.Println()
		for _, o := range active {
			fmt.Printf("[%s] %s\n", o.ID, o.Title)
			if o.Fact != "" {
				fmt.Printf("  %s\n", firstLine(o.Fact))
			}
			fmt.Println()
		}

		return nil
	},
}

func firstLine(s string) string {
	lines := strings.SplitN(s, "\n", 2)
	if len(lines) > 0 {
		return strings.TrimSpace(lines[0])
	}
	return s
}

func init() {
	addOutputFlag(overlaysCmd, OutputText, OutputJSON)
	rootCmd.AddCommand(overlaysCmd)
}
