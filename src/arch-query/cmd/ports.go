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

var portsCmd = &cobra.Command{
	Use:   "ports [component]",
	Short: "List ports, optionally filtered by component",
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
					printComponentPorts(k, doc)
					return nil
				}
			}
			fmt.Fprintf(os.Stderr, "Component %q not found in %s.\n", name, version)
			os.Exit(1)
		}

		keys := make([]string, 0, len(data.Components))
		for k := range data.Components {
			keys = append(keys, k)
		}
		sort.Strings(keys)

		for _, k := range keys {
			doc := data.Components[k]
			if len(doc.Services) == 0 && len(doc.Endpoints) == 0 && len(doc.GRPCServices) == 0 {
				continue
			}
			printComponentPorts(k, doc)
			fmt.Println()
		}
		return nil
	},
}

func printComponentPorts(name string, doc *types.ComponentDoc) {
	fmt.Printf("%s:\n", name)
	tw := output.NewTabWriter(os.Stdout)
	seen := make(map[string]bool)

	for _, svc := range doc.Services {
		key := svc.Port + "/" + svc.Protocol
		if seen[key] {
			continue
		}
		seen[key] = true
		fmt.Fprintf(tw, "  %s\t%s\t%s\n", svc.Port, svc.Protocol, svc.Name)
	}
	for _, ep := range doc.Endpoints {
		key := ep.Port + "/HTTP"
		if seen[key] {
			continue
		}
		seen[key] = true
		fmt.Fprintf(tw, "  %s\tHTTP\t%s\n", ep.Port, ep.Purpose)
	}
	for _, g := range doc.GRPCServices {
		key := g.Port + "/gRPC"
		if seen[key] {
			continue
		}
		seen[key] = true
		fmt.Fprintf(tw, "  %s\tgRPC\t%s\n", g.Port, g.Service)
	}
	tw.Flush()
}

func init() {
	rootCmd.AddCommand(portsCmd)
}
