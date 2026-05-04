package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/output"
	"github.com/spf13/cobra"
)

var versionsCmd = &cobra.Command{
	Use:   "versions",
	Short: "List available architecture-context versions",
	RunE: func(cmd *cobra.Command, args []string) error {
		versions, err := loader.DiscoverVersions(archFS, archSymlinks)
		if err != nil {
			return fmt.Errorf("discovering versions: %w", err)
		}

		defaultVer := loader.DefaultVersion(versions)
		fmt.Printf("%d versions available:\n\n", len(versions))

		tw := output.NewTabWriter(os.Stdout)
		for _, v := range versions {
			aliases := ""
			if len(v.Aliases) > 0 {
				aliases = "[" + strings.Join(v.Aliases, ", ") + "]"
			}
			def := ""
			if v.Name == defaultVer {
				def = " (default)"
			}
			fmt.Fprintf(tw, "  %s\t%s\t(%d components)%s\n", v.Name, aliases, v.ComponentCount, def)
		}
		tw.Flush()
		return nil
	},
}

func init() {
	rootCmd.AddCommand(versionsCmd)
}
