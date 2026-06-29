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

var provenanceUpstreamOnly bool

var provenanceCmd = &cobra.Command{
	Use:   "provenance [component-or-repo]",
	Short: "Show upstream/downstream/fork relationships for repos",
	Long: `Show repository provenance data: which repos are forks, what their
upstream source is, downstream mirrors, and how they sync.

Without arguments, lists all repos with provenance info.
With a component name, shows provenance for that component's repo.
With an org/repo string, shows provenance for that specific repo.

Examples:
  arch-query provenance
  arch-query provenance kserve
  arch-query provenance opendatahub-io/kserve
  arch-query provenance --upstream-only`,
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

		if data.Provenance == nil || len(data.Provenance.Repos) == 0 {
			fmt.Fprintf(os.Stderr, "No provenance data in %s. Run discovery with provenance enabled.\n", version)
			os.Exit(1)
		}

		compToRepo := loader.LoadComponentRepoMapping(archFS, version)

		repoToComps := make(map[string][]string)
		for comp, repo := range compToRepo {
			repoToComps[repo] = append(repoToComps[repo], comp)
		}

		if len(args) == 1 {
			return runSingleProvenance(args[0], data.Provenance, compToRepo)
		}

		return runAllProvenance(data.Provenance, repoToComps)
	},
}

func repoRole(r types.ProvenanceRepo) string {
	if r.Upstream != "" && len(r.Downstream) > 0 {
		return "midstream"
	}
	if r.Upstream != "" {
		return "midstream"
	}
	if len(r.Downstream) > 0 {
		return "origin"
	}
	return "standalone"
}

func runSingleProvenance(query string, prov *types.Provenance, compToRepo map[string]string) error {
	var repoKey string

	if strings.Contains(query, "/") {
		repoKey = query
	} else {
		if mapped, ok := compToRepo[query]; ok {
			repoKey = mapped
		} else {
			for key, r := range prov.Repos {
				if strings.EqualFold(r.Repo, query) {
					repoKey = key
					break
				}
			}
		}
	}

	repo, ok := prov.Repos[repoKey]
	if !ok {
		fmt.Fprintf(os.Stderr, "No provenance data for %q.\n", query)
		os.Exit(1)
	}

	if outputFormat == OutputJSON {
		return output.JSON(os.Stdout, repo)
	}

	role := repoRole(repo)

	if repo.Upstream != "" || len(repo.Downstream) > 0 {
		fmt.Println()
		if repo.Upstream != "" {
			fmt.Printf("  %s  (upstream)\n", repo.Upstream)
			syncLabel := repo.SyncMechanism
			if syncLabel == "" {
				syncLabel = "unknown"
			}
			fmt.Printf("    |\n")
			fmt.Printf("    | %s", syncLabel)
			if len(repo.SyncWorkflows) > 0 {
				fmt.Printf(" (%s)", strings.Join(repo.SyncWorkflows, ", "))
			}
			fmt.Println()
			fmt.Printf("    v\n")
		}
		fmt.Printf("  %s  (%s)\n", repoKey, role)
		for _, ds := range repo.Downstream {
			fmt.Printf("    |\n")
			fmt.Printf("    v\n")
			fmt.Printf("  %s  (downstream)\n", ds)
		}
		fmt.Println()
	} else {
		fmt.Printf("\n  %s  (%s)\n\n", repoKey, role)
	}

	return nil
}

func runAllProvenance(prov *types.Provenance, repoToComps map[string][]string) error {
	keys := make([]string, 0, len(prov.Repos))
	for k := range prov.Repos {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	if provenanceUpstreamOnly {
		filtered := keys[:0]
		for _, k := range keys {
			if prov.Repos[k].Upstream != "" {
				filtered = append(filtered, k)
			}
		}
		keys = filtered
	}

	if outputFormat == OutputJSON {
		result := make(map[string]types.ProvenanceRepo, len(keys))
		for _, k := range keys {
			result[k] = prov.Repos[k]
		}
		return output.JSON(os.Stdout, result)
	}

	tw := output.NewTabWriter(os.Stdout)
	fmt.Fprintf(tw, "REPO\tROLE\tUPSTREAM\tSYNC\tDOWNSTREAM\n")
	for _, k := range keys {
		r := prov.Repos[k]
		role := repoRole(r)
		upstream := "-"
		if r.Upstream != "" {
			upstream = r.Upstream
		}
		sync := "-"
		if r.SyncMechanism != "" {
			sync = r.SyncMechanism
		}
		downstream := "-"
		if len(r.Downstream) > 0 {
			downstream = strings.Join(r.Downstream, ", ")
		}

		label := k
		if comps, ok := repoToComps[k]; ok && len(comps) > 0 {
			sort.Strings(comps)
			label = k + " (" + comps[0] + ")"
		}

		fmt.Fprintf(tw, "%s\t%s\t%s\t%s\t%s\n", label, role, upstream, sync, downstream)
	}
	tw.Flush()

	fmt.Fprintf(os.Stderr, "\n%d repos (%d with upstream, %d with downstream)\n",
		prov.Metadata.TotalRepos, prov.Metadata.ReposWithUpstream, prov.Metadata.ReposWithDownstream)
	return nil
}

func init() {
	provenanceCmd.Flags().BoolVar(&provenanceUpstreamOnly, "upstream-only", false,
		"Only show repos that have an upstream")
	addOutputFlag(provenanceCmd, OutputText, OutputJSON)
	rootCmd.AddCommand(provenanceCmd)
}
