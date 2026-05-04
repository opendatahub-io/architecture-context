package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/spf13/cobra"
)

var existsCmd = &cobra.Command{
	Use:   "exists <component>",
	Short: "Check if a component exists in the inventory",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := strings.ToLower(args[0])

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

		for k, doc := range data.Components {
			if strings.EqualFold(k, name) {
				fmt.Printf("%s exists in %s inventory.\n", k, version)
				fmt.Printf("Type: %s | Doc: %s/%s/%s\n", doc.DeployType, baseDir, version, doc.FileName)
				return nil
			}
		}

		fmt.Fprintf(os.Stderr, "Not found in %s component inventory.\n", version)

		var closest []string
		for k := range data.Components {
			if strings.Contains(strings.ToLower(k), name) || strings.Contains(name, strings.ToLower(k)) {
				closest = append(closest, k)
			}
		}
		if len(closest) > 0 {
			fmt.Fprintf(os.Stderr, "Closest matches: %s\n", strings.Join(closest, ", "))
		} else {
			fmt.Fprintln(os.Stderr, "Closest matches: none.")
		}
		fmt.Fprintln(os.Stderr, "Note: RHOAI architecture context covers only the OpenShift AI platform.")
		fmt.Fprintln(os.Stderr, "Components from RHEL AI, RHAIIS, or upstream-only projects are not included.")
		os.Exit(1)
		return nil
	},
}

func init() {
	rootCmd.AddCommand(existsCmd)
}
