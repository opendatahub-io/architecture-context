package cmd

import (
	"fmt"
	"os"
	"sort"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/output"
	"github.com/spf13/cobra"
)

var platformSummaryCmd = &cobra.Command{
	Use:   "platform-summary",
	Short: "Dump all structured data for a version as one JSON object",
	Long: `Aggregates all component data (CRDs, services, endpoints, deps,
RBAC, watches, network policies, dockerfiles) into a single JSON
document. Designed for machine consumption by the platform
architecture skill.

Examples:
  arch-query platform-summary
  arch-query platform-summary --version rhoai-3.4`,
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

		type componentEntry struct {
			Name       string `json:"name"`
			Type       string `json:"type"`
			Language   string `json:"language,omitempty"`
			Repository string `json:"repository,omitempty"`
			Version    string `json:"version,omitempty"`
			Purpose    string `json:"purpose"`
		}
		type crdEntry struct {
			Component string `json:"component"`
			Group     string `json:"group"`
			Version   string `json:"version"`
			Kind      string `json:"kind"`
			Scope     string `json:"scope"`
			Purpose   string `json:"purpose,omitempty"`
		}
		type serviceEntry struct {
			Component  string `json:"component"`
			Name       string `json:"name"`
			Type       string `json:"type,omitempty"`
			Port       string `json:"port"`
			TargetPort string `json:"target_port,omitempty"`
			Protocol   string `json:"protocol,omitempty"`
			Encryption string `json:"encryption,omitempty"`
			Auth       string `json:"auth,omitempty"`
			Exposure   string `json:"exposure,omitempty"`
		}
		type endpointEntry struct {
			Component  string `json:"component"`
			Path       string `json:"path"`
			Method     string `json:"method"`
			Port       string `json:"port,omitempty"`
			Protocol   string `json:"protocol,omitempty"`
			Encryption string `json:"encryption,omitempty"`
			Auth       string `json:"auth,omitempty"`
			Purpose    string `json:"purpose,omitempty"`
		}
		type grpcEntry struct {
			Component  string `json:"component"`
			Service    string `json:"service"`
			Port       string `json:"port"`
			Protocol   string `json:"protocol,omitempty"`
			Encryption string `json:"encryption,omitempty"`
			Auth       string `json:"auth,omitempty"`
			Purpose    string `json:"purpose,omitempty"`
		}
		type ingressEntry struct {
			Component  string `json:"component"`
			Type       string `json:"type"`
			Hosts      string `json:"hosts,omitempty"`
			Port       string `json:"port"`
			Protocol   string `json:"protocol,omitempty"`
			Encryption string `json:"encryption,omitempty"`
			TLSMode    string `json:"tls_mode,omitempty"`
			Exposure   string `json:"exposure,omitempty"`
		}
		type egressEntry struct {
			Component   string `json:"component"`
			Destination string `json:"destination"`
			Port        string `json:"port"`
			Protocol    string `json:"protocol,omitempty"`
			Encryption  string `json:"encryption,omitempty"`
			Auth        string `json:"auth,omitempty"`
			Purpose     string `json:"purpose,omitempty"`
		}
		type intDepEntry struct {
			From    string `json:"from"`
			To      string `json:"to"`
			Purpose string `json:"purpose,omitempty"`
		}
		type extDepEntry struct {
			Component  string `json:"component"`
			Dependency string `json:"dependency"`
			Version    string `json:"version,omitempty"`
			Required   string `json:"required,omitempty"`
			Purpose    string `json:"purpose,omitempty"`
		}
		type rbacEntry struct {
			Component string `json:"component"`
			RoleName  string `json:"role_name"`
			APIGroup  string `json:"api_group"`
			Resources string `json:"resources"`
			Verbs     string `json:"verbs"`
		}
		type watchEntry struct {
			Component  string `json:"component"`
			Type       string `json:"type"`
			GVK        string `json:"gvk"`
			Controller string `json:"controller"`
			Source     string `json:"source,omitempty"`
		}
		type netpolEntry struct {
			Component   string   `json:"component"`
			Name        string   `json:"name"`
			Source      string   `json:"source,omitempty"`
			PolicyTypes []string `json:"policy_types,omitempty"`
		}
		type dockerfileEntry struct {
			Component string   `json:"component"`
			Path      string   `json:"path"`
			BaseImage string   `json:"base_image"`
			Stages    int      `json:"stages"`
			User      string   `json:"user,omitempty"`
			Issues    []string `json:"issues,omitempty"`
		}
		type archComponentEntry struct {
			Component string `json:"component"`
			Name      string `json:"name"`
			Type      string `json:"type"`
			Purpose   string `json:"purpose,omitempty"`
		}

		var (
			components     []componentEntry
			crds           []crdEntry
			services       []serviceEntry
			endpoints      []endpointEntry
			grpcServices   []grpcEntry
			ingresses      []ingressEntry
			egresses       []egressEntry
			internalDeps   []intDepEntry
			externalDeps   []extDepEntry
			rbacRoles      []rbacEntry
			watches        []watchEntry
			netpols        []netpolEntry
			dockerfiles    []dockerfileEntry
			archComponents []archComponentEntry
		)

		for _, k := range keys {
			doc := data.Components[k]

			components = append(components, componentEntry{
				Name:       doc.Name,
				Type:       doc.DeployType,
				Language:   doc.Languages,
				Repository: doc.Repository,
				Version:    doc.Version,
				Purpose:    doc.Purpose,
			})

			for _, c := range doc.CRDs {
				crds = append(crds, crdEntry{k, c.Group, c.Version, c.Kind, c.Scope, c.Purpose})
			}
			for _, s := range doc.Services {
				services = append(services, serviceEntry{k, s.Name, s.Type, s.Port, s.TargetPort, s.Protocol, s.Encryption, s.Auth, s.Exposure})
			}
			for _, e := range doc.Endpoints {
				endpoints = append(endpoints, endpointEntry{k, e.Path, e.Method, e.Port, e.Protocol, e.Encryption, e.Auth, e.Purpose})
			}
			for _, g := range doc.GRPCServices {
				grpcServices = append(grpcServices, grpcEntry{k, g.Service, g.Port, g.Protocol, g.Encryption, g.Auth, g.Purpose})
			}
			for _, i := range doc.Ingresses {
				ingresses = append(ingresses, ingressEntry{k, i.Type, i.Hosts, i.Port, i.Protocol, i.Encryption, i.TLSMode, i.Exposure})
			}
			for _, e := range doc.Egresses {
				egresses = append(egresses, egressEntry{k, e.Destination, e.Port, e.Protocol, e.Encryption, e.Auth, e.Purpose})
			}
			for _, d := range doc.InternalDeps {
				internalDeps = append(internalDeps, intDepEntry{k, d.Component, d.Purpose})
			}
			for _, d := range doc.ExternalDeps {
				externalDeps = append(externalDeps, extDepEntry{k, d.Component, d.Version, d.Required, d.Purpose})
			}
			for _, r := range doc.RBACRoles {
				rbacRoles = append(rbacRoles, rbacEntry{k, r.RoleName, r.APIGroup, r.Resources, r.Verbs})
			}
			for _, w := range doc.ControllerWatches {
				watches = append(watches, watchEntry{k, w.Type, w.GVK, w.Controller, w.Source})
			}
			for _, np := range doc.NetworkPolicies {
				netpols = append(netpols, netpolEntry{k, np.Name, np.Source, np.PolicyTypes})
			}
			for _, df := range doc.Dockerfiles {
				dockerfiles = append(dockerfiles, dockerfileEntry{k, df.Path, df.BaseImage, df.Stages, df.User, df.Issues})
			}
			for _, ac := range doc.Components {
				archComponents = append(archComponents, archComponentEntry{k, ac.Name, ac.Type, ac.Purpose})
			}
		}

		summary := map[string]any{
			"version":            version,
			"component_count":    len(components),
			"components":         components,
			"crds":               crds,
			"services":           services,
			"endpoints":          endpoints,
			"grpc_services":      grpcServices,
			"ingresses":          ingresses,
			"egresses":           egresses,
			"internal_deps":      internalDeps,
			"external_deps":      externalDeps,
			"rbac_roles":         rbacRoles,
			"controller_watches": watches,
			"network_policies":   netpols,
			"dockerfiles":        dockerfiles,
			"arch_components":    archComponents,
		}

		return output.JSON(os.Stdout, summary)
	},
}

func init() {
	rootCmd.AddCommand(platformSummaryCmd)
}
