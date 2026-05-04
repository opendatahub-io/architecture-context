package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/output"
	"github.com/spf13/cobra"
)

var overlaysCmd = &cobra.Command{
	Use:   "overlays",
	Short: "List active overlays and what they affect",
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

		if len(data.Overlays) == 0 {
			fmt.Println("No overlays found.")
			return nil
		}

		active := 0
		for _, o := range data.Overlays {
			if o.Status == "active" {
				active++
			}
		}

		fmt.Printf("%d active overlays:\n\n", active)
		tw := output.NewTabWriter(os.Stdout)
		for _, o := range data.Overlays {
			if o.Status != "active" {
				continue
			}
			affects := strings.Join(o.Affects, ", ")
			releases := strings.Join(o.Release, ", ")
			fmt.Fprintf(tw, "  %s\t%s\treleases: %s\taffects: %s\n", o.ID, o.Title, releases, affects)
		}
		tw.Flush()

		fmt.Println()
		for _, o := range data.Overlays {
			if o.Status != "active" {
				continue
			}
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
	rootCmd.AddCommand(overlaysCmd)
}
