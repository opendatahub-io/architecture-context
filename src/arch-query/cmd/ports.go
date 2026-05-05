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

type portEntry struct {
	Port     string `json:"port"`
	Protocol string `json:"protocol"`
	Source   string `json:"source"`
}

var portsCmd = &cobra.Command{
	Use:   "ports [component]",
	Short: "List ports, optionally filtered by component",
	Args:  cobra.MaximumNArgs(1),
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
					if outputFormat == OutputJSON {
						return output.JSON(os.Stdout, collectPorts(doc))
					}
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

		if outputFormat == OutputJSON {
			result := make(map[string][]portEntry)
			for _, k := range keys {
				doc := data.Components[k]
				ports := collectPorts(doc)
				if len(ports) > 0 {
					result[k] = ports
				}
			}
			return output.JSON(os.Stdout, result)
		}

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

func collectPorts(doc *types.ComponentDoc) []portEntry {
	var ports []portEntry
	seen := make(map[string]bool)
	for _, svc := range doc.Services {
		key := svc.Port + "/" + svc.Protocol
		if seen[key] {
			continue
		}
		seen[key] = true
		ports = append(ports, portEntry{svc.Port, svc.Protocol, svc.Name})
	}
	for _, ep := range doc.Endpoints {
		key := ep.Port + "/HTTP"
		if seen[key] {
			continue
		}
		seen[key] = true
		ports = append(ports, portEntry{ep.Port, "HTTP", ep.Purpose})
	}
	for _, g := range doc.GRPCServices {
		key := g.Port + "/gRPC"
		if seen[key] {
			continue
		}
		seen[key] = true
		ports = append(ports, portEntry{g.Port, "gRPC", g.Service})
	}
	return ports
}

func printComponentPorts(name string, doc *types.ComponentDoc) {
	fmt.Printf("%s:\n", name)
	tw := output.NewTabWriter(os.Stdout)
	for _, p := range collectPorts(doc) {
		fmt.Fprintf(tw, "  %s\t%s\t%s\n", p.Port, p.Protocol, p.Source)
	}
	tw.Flush()
}

func init() {
	addOutputFlag(portsCmd, OutputText, OutputJSON)
	rootCmd.AddCommand(portsCmd)
}
