package cmd

import (
	"fmt"
	"io/fs"
	"os"
	"strings"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/output"
	"github.com/spf13/cobra"
)

var componentRaw bool

var componentCmd = &cobra.Command{
	Use:   "component <name>",
	Short: "Show component fact sheet",
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

		if componentRaw {
			path := version + "/" + name + ".md"
			data, err := fs.ReadFile(archFS, path)
			if err != nil {
				return fmt.Errorf("reading %s: %w", path, err)
			}
			fmt.Print(string(data))
			return nil
		}

		data, err := loader.LoadVersion(archFS, overlayFS, version)
		if err != nil {
			return fmt.Errorf("loading version %s: %w", version, err)
		}

		doc, ok := data.Components[name]
		if !ok {
			// Try case-insensitive lookup
			for k, v := range data.Components {
				if strings.EqualFold(k, name) {
					doc = v
					ok = true
					break
				}
			}
		}
		if !ok {
			fmt.Fprintf(os.Stderr, "Component %q not found in %s.\n", name, version)
			fmt.Fprintf(os.Stderr, "Use 'arch-query search %s' to find similar components.\n", name)
			os.Exit(1)
		}

		fmt.Printf("# %s\n", doc.Name)
		output.KeyValue(os.Stdout, "Purpose", doc.Purpose)
		output.KeyValue(os.Stdout, "Type", doc.DeployType)
		output.KeyValue(os.Stdout, "Repository", doc.Repository)
		output.KeyValue(os.Stdout, "Branch", doc.Branch)
		output.KeyValue(os.Stdout, "Languages", doc.Languages)
		output.KeyValue(os.Stdout, "Version", doc.Version)

		if len(doc.Components) > 0 {
			output.SectionHeader(os.Stdout, "Architecture Components")
			tw := output.NewTabWriter(os.Stdout)
			for _, ac := range doc.Components {
				fmt.Fprintf(tw, "  %s\t%s\t%s\n", ac.Name, ac.Type, ac.Purpose)
			}
			tw.Flush()
		}

		if len(doc.CRDs) > 0 {
			output.SectionHeader(os.Stdout, "CRDs")
			tw := output.NewTabWriter(os.Stdout)
			for _, crd := range doc.CRDs {
				fmt.Fprintf(tw, "  %s/%s\t%s\t%s\n", crd.Group, crd.Version, crd.Kind, crd.Scope)
			}
			tw.Flush()
		}

		if len(doc.Services) > 0 {
			output.SectionHeader(os.Stdout, "Services")
			tw := output.NewTabWriter(os.Stdout)
			for _, svc := range doc.Services {
				fmt.Fprintf(tw, "  %s\t%s\t%s\t%s\n", svc.Port, svc.Protocol, svc.Name, svc.Exposure)
			}
			tw.Flush()
		}

		if len(doc.Endpoints) > 0 {
			output.SectionHeader(os.Stdout, "HTTP Endpoints")
			tw := output.NewTabWriter(os.Stdout)
			for _, ep := range doc.Endpoints {
				fmt.Fprintf(tw, "  %s\t%s\t%s\t%s\n", ep.Port, ep.Method, ep.Path, ep.Purpose)
			}
			tw.Flush()
		}

		if len(doc.Ingresses) > 0 {
			output.SectionHeader(os.Stdout, "Ingress")
			tw := output.NewTabWriter(os.Stdout)
			for _, ing := range doc.Ingresses {
				fmt.Fprintf(tw, "  %s\t%s\t%s\t%s\t%s\n", ing.Component, ing.Type, ing.Port, ing.Protocol, ing.Exposure)
			}
			tw.Flush()
		}

		if len(doc.Egresses) > 0 {
			output.SectionHeader(os.Stdout, "Egress")
			tw := output.NewTabWriter(os.Stdout)
			for _, eg := range doc.Egresses {
				fmt.Fprintf(tw, "  %s\t%s\t%s\t%s\n", eg.Destination, eg.Port, eg.Protocol, eg.Purpose)
			}
			tw.Flush()
		}

		if len(doc.ExternalDeps) > 0 || len(doc.InternalDeps) > 0 {
			output.SectionHeader(os.Stdout, "Dependencies")
			if len(doc.ExternalDeps) > 0 {
				fmt.Println("  External:")
				for _, d := range doc.ExternalDeps {
					req := ""
					if d.Required != "" && d.Required != "Yes" {
						req = " (optional)"
					}
					fmt.Printf("    %s%s - %s\n", d.Component, req, d.Purpose)
				}
			}
			if len(doc.InternalDeps) > 0 {
				fmt.Println("  Internal platform:")
				for _, d := range doc.InternalDeps {
					fmt.Printf("    %s - %s\n", d.Component, d.Purpose)
				}
			}
		}

		fmt.Printf("\nFull doc: %s/%s\n", version, doc.FileName)
		return nil
	},
}

func init() {
	componentCmd.Flags().BoolVar(&componentRaw, "raw", false, "Print the full raw markdown instead of the parsed fact sheet")
	rootCmd.AddCommand(componentCmd)
}
