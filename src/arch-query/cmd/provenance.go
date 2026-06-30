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

var (
	provenanceUpstreamOnly bool
	provenanceAll          bool
	provenanceFilter       string
)

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

		// Build set of org/repo strings that are included components
		componentRepos := make(map[string]bool, len(compToRepo))
		for _, repo := range compToRepo {
			componentRepos[repo] = true
		}

		if len(args) == 1 {
			return runSingleProvenance(args[0], data.Provenance, compToRepo, componentRepos)
		}

		return runAllProvenance(data.Provenance, repoToComps, componentRepos)
	},
}

var midstreamOrgs = map[string]bool{
	"opendatahub-io": true,
}

var downstreamOrgs = map[string]bool{
	"red-hat-data-services": true,
}

func repoRole(r types.ProvenanceRepo) string {
	if downstreamOrgs[r.Org] {
		return "downstream"
	}
	if strVal(r.Upstream) != "" && len(r.Downstream) > 0 {
		return "midstream"
	}
	if strVal(r.Upstream) != "" {
		if midstreamOrgs[r.Org] {
			return "midstream"
		}
		return "downstream"
	}
	if midstreamOrgs[r.Org] {
		return "midstream"
	}
	return "upstream"
}

func runSingleProvenance(query string, prov *types.Provenance, compToRepo map[string]string, componentRepos map[string]bool) error {
	var repoKey string

	if strings.Contains(query, "/") {
		repoKey = query
		if _, ok := prov.Repos[repoKey]; !ok {
			for key := range prov.Repos {
				if strings.EqualFold(key, query) {
					repoKey = key
					break
				}
			}
		}
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

	if !provenanceAll && !componentRepos[repoKey] {
		fmt.Fprintf(os.Stderr, "Repo %q was excluded from components. Use --all to include excluded repos.\n", repoKey)
		os.Exit(1)
	}

	if outputFormat == OutputJSON {
		return output.JSON(os.Stdout, repo)
	}

	role := repoRole(repo)

	upVal := strVal(repo.Upstream)
	syncVal := strVal(repo.SyncMechanism)
	if upVal != "" || len(repo.Downstream) > 0 {
		fmt.Println()
		if upVal != "" {
			fmt.Printf("  %s  (upstream)\n", upVal)
			syncLabel := syncVal
			if syncLabel == "" {
				syncLabel = "unknown"
			}
			fmt.Printf("    |\n")
			fmt.Printf("    | %s", syncLabel)
			if repo.SyncBranch != "" {
				fmt.Printf(" [%s]", repo.SyncBranch)
			}
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

func runAllProvenance(prov *types.Provenance, repoToComps map[string][]string, componentRepos map[string]bool) error {
	keys := make([]string, 0, len(prov.Repos))
	for k := range prov.Repos {
		if !provenanceAll && !componentRepos[k] {
			continue
		}
		keys = append(keys, k)
	}
	sort.Strings(keys)

	if provenanceFilter != "" {
		needle := strings.ToLower(provenanceFilter)
		filtered := keys[:0]
		for _, k := range keys {
			r := prov.Repos[k]
			if strings.Contains(strings.ToLower(k), needle) ||
				strings.Contains(strings.ToLower(strVal(r.Upstream)), needle) ||
				containsAnyLower(r.Downstream, needle) {
				filtered = append(filtered, k)
				continue
			}
			// Walk upstream chain so downstream repos match on
			// their ultimate upstream (e.g. llm-d via ODH midstream)
			if strVal(r.Upstream) != "" {
				if upRepo, ok := prov.Repos[strVal(r.Upstream)]; ok {
					if strings.Contains(strings.ToLower(strVal(upRepo.Upstream)), needle) {
						filtered = append(filtered, k)
					}
				}
			}
		}
		keys = filtered
	}

	if provenanceUpstreamOnly {
		filtered := keys[:0]
		for _, k := range keys {
			if strVal(prov.Repos[k].Upstream) != "" {
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
	fmt.Fprintf(tw, "UPSTREAM\tSYNC-U-M\tMIDSTREAM\tSYNC-M-D\tDOWNSTREAM\n")
	for _, k := range keys {
		r := prov.Repos[k]

		upStr := strVal(r.Upstream)
		syncStr := strVal(r.SyncMechanism)

		upstream := "-"
		if upStr != "" {
			upstream = upStr
		}

		syncUM := "-"
		if upStr != "" && syncStr != "" {
			syncUM = syncStr
		}

		downstream := "-"
		syncMD := "-"
		if len(r.Downstream) > 0 {
			downstream = strings.Join(r.Downstream, ", ")
			for _, ds := range r.Downstream {
				if dsRepo, ok := prov.Repos[ds]; ok && strVal(dsRepo.SyncMechanism) != "" {
					syncMD = strVal(dsRepo.SyncMechanism)
					break
				}
			}
		}

		role := repoRole(r)
		if role == "downstream" {
			ulUpstream := "-"
			mid := "-"
			syncUMDs := "-"
			syncMDDs := "-"
			if upStr != "" {
				upOrg := strings.SplitN(upStr, "/", 2)[0]
				if midstreamOrgs[upOrg] {
					mid = upStr
					if syncStr != "" {
						syncMDDs = syncStr
					}
					if mRepo, ok := prov.Repos[upStr]; ok && strVal(mRepo.Upstream) != "" {
						ulUpstream = strVal(mRepo.Upstream)
						if strVal(mRepo.SyncMechanism) != "" {
							syncUMDs = strVal(mRepo.SyncMechanism)
						}
					}
				} else {
					ulUpstream = upStr
					if syncStr != "" {
						syncUMDs = syncStr
					}
				}
			}
			fmt.Fprintf(tw, "%s\t%s\t%s\t%s\t%s\n", ulUpstream, syncUMDs, mid, syncMDDs, k)
		} else if role == "midstream" {
			fmt.Fprintf(tw, "%s\t%s\t%s\t%s\t%s\n", upstream, syncUM, k, syncMD, downstream)
		} else {
			// Upstream repo: split downstream list into midstream and downstream
			// based on org hierarchy
			mid := "-"
			ds := "-"
			syncUMUp := "-"
			syncMDUp := "-"
			if len(r.Downstream) > 0 {
				var midList, dsList []string
				for _, d := range r.Downstream {
					dOrg := strings.SplitN(d, "/", 2)[0]
					if midstreamOrgs[dOrg] {
						midList = append(midList, d)
					} else {
						dsList = append(dsList, d)
					}
				}
				if len(midList) > 0 {
					mid = strings.Join(midList, ", ")
					for _, m := range midList {
						if mRepo, ok := prov.Repos[m]; ok && strVal(mRepo.SyncMechanism) != "" {
							syncUMUp = strVal(mRepo.SyncMechanism)
							break
						}
					}
					for _, m := range midList {
						if mRepo, ok := prov.Repos[m]; ok {
							for _, mds := range mRepo.Downstream {
								if mdsRepo, ok := prov.Repos[mds]; ok && strVal(mdsRepo.SyncMechanism) != "" {
									syncMDUp = strVal(mdsRepo.SyncMechanism)
									break
								}
							}
							if syncMDUp != "-" {
								break
							}
						}
					}
				}
				if len(dsList) > 0 {
					ds = strings.Join(dsList, ", ")
					if syncMDUp == "-" {
						for _, d := range dsList {
							if dRepo, ok := prov.Repos[d]; ok && strVal(dRepo.SyncMechanism) != "" {
								syncMDUp = strVal(dRepo.SyncMechanism)
								break
							}
						}
					}
				}
			}
			fmt.Fprintf(tw, "%s\t%s\t%s\t%s\t%s\n", k, syncUMUp, mid, syncMDUp, ds)
		}
	}
	tw.Flush()

	shown := len(keys)
	total := len(prov.Repos)
	if shown < total {
		fmt.Fprintf(os.Stderr, "\n%d component repos shown (%d total, use --all to include excluded)\n", shown, total)
	} else {
		fmt.Fprintf(os.Stderr, "\n%d repos (%d with upstream, %d with downstream)\n",
			prov.Metadata.TotalRepos, prov.Metadata.ReposWithUpstream, prov.Metadata.ReposWithDownstream)
	}
	return nil
}

func strVal(p *string) string {
	if p == nil {
		return ""
	}
	return *p
}

func containsAnyLower(items []string, needle string) bool {
	for _, item := range items {
		if strings.Contains(strings.ToLower(item), needle) {
			return true
		}
	}
	return false
}

func init() {
	provenanceCmd.Flags().StringVar(&provenanceFilter, "filter", "",
		"Filter repos by substring match against repo key, upstream, or downstream")
	provenanceCmd.Flags().BoolVar(&provenanceUpstreamOnly, "upstream-only", false,
		"Only show repos that have an upstream")
	provenanceCmd.Flags().BoolVar(&provenanceAll, "all", false,
		"Include repos excluded from the component map")
	addOutputFlag(provenanceCmd, OutputText, OutputJSON)
	rootCmd.AddCommand(provenanceCmd)
}
