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

var webhookTypeFilter string
var webhookTargetFilter string

const OutputWide = "wide"

var webhooksCmd = &cobra.Command{
	Use:   "webhooks [component]",
	Short: "List webhooks, optionally filtered by component",
	Long: `Show validating and mutating admission webhooks with their rules
and source references.

Output modes:
  text (default)  compact table
  wide            includes purpose, data_read, sources
  json            full structured data

Examples:
  arch-query webhooks
  arch-query webhooks rhods-operator
  arch-query webhooks rhods-operator --output wide
  arch-query webhooks --type mutating
  arch-query webhooks --target inferenceservices
  arch-query webhooks --target inferenceservices.serving.kserve.io
  arch-query webhooks kserve --output json`,
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

		if len(args) == 1 {
			name := strings.ToLower(args[0])
			for k, doc := range data.Components {
				if strings.EqualFold(k, name) {
					filtered := filterWebhooks(doc.Webhooks)
					if outputFormat == OutputJSON {
						result := struct {
							Webhooks         []types.Webhook    `json:"webhooks"`
							PlatformWebhooks []types.WebhookRef `json:"platform_webhooks,omitempty"`
							ExternalWebhooks []types.WebhookRef `json:"external_webhooks,omitempty"`
						}{
							Webhooks:         filtered,
							PlatformWebhooks: doc.PlatformWebhooks,
							ExternalWebhooks: doc.ExternalWebhooks,
						}
						return output.JSON(os.Stdout, result)
					}
					if len(filtered) == 0 {
						fmt.Printf("%s has no webhooks.\n", k)
						return nil
					}
					if outputFormat == OutputWide {
						printWideComponent(k, filtered)
					} else {
						printCompact(k, "", filtered)
					}
					return nil
				}
			}
			return fmt.Errorf("component %q not found in %s", name, version)
		}

		type taggedWebhook struct {
			Component string
			types.Webhook
		}
		var all []taggedWebhook
		for k, doc := range data.Components {
			for _, w := range doc.Webhooks {
				if webhookTypeFilter != "" && !strings.EqualFold(w.Type, webhookTypeFilter) {
					continue
				}
				if webhookTargetFilter != "" && !matchesTarget(w, webhookTargetFilter) {
					continue
				}
				all = append(all, taggedWebhook{Component: k, Webhook: w})
			}
		}
		sort.Slice(all, func(i, j int) bool {
			if all[i].Component != all[j].Component {
				return all[i].Component < all[j].Component
			}
			return all[i].Name < all[j].Name
		})

		if outputFormat == OutputJSON {
			type jsonEntry struct {
				Component string `json:"component"`
				types.Webhook
			}
			var entries []jsonEntry
			for _, tw := range all {
				entries = append(entries, jsonEntry(tw))
			}
			return output.JSON(os.Stdout, entries)
		}

		if len(all) == 0 {
			fmt.Fprintf(os.Stderr, "No webhooks found in %s.\n", version)
			return nil
		}

		if outputFormat == OutputWide {
			fmt.Printf("%d webhooks across %s:\n", len(all), version)
			tabw := output.NewTabWriter(os.Stdout)
			for _, w := range all {
				fmt.Fprintf(tabw, "  %s\t%s\t%s\t%s\t%s\t%s\n",
					w.Component, w.Name, w.Type, w.FailurePolicy, rulesSum(w.Webhook), w.Purpose)
			}
			tabw.Flush()
		} else {
			fmt.Printf("%d webhooks across %s:\n", len(all), version)
			tw := output.NewTabWriter(os.Stdout)
			for _, w := range all {
				fmt.Fprintf(tw, "  %s\t%s\t%s\t%s\t%s\n",
					w.Component, w.Name, w.Type, w.FailurePolicy, rulesSum(w.Webhook))
			}
			tw.Flush()
		}
		return nil
	},
}

func printCompact(component string, prefix string, webhooks []types.Webhook) {
	fmt.Printf("%s%s: %d webhooks\n", prefix, component, len(webhooks))
	tw := output.NewTabWriter(os.Stdout)
	for _, w := range webhooks {
		fmt.Fprintf(tw, "  %s\t%s\t%s\t%s\n",
			w.Name, w.Type, w.FailurePolicy, rulesSum(w))
	}
	tw.Flush()
}

func printWideComponent(component string, webhooks []types.Webhook) {
	fmt.Printf("%s: %d webhooks\n", component, len(webhooks))
	tw := output.NewTabWriter(os.Stdout)
	for _, w := range webhooks {
		fmt.Fprintf(tw, "  %s\t%s\t%s\t%s\t%s\n",
			w.Name, w.Type, w.FailurePolicy, rulesSum(w), w.Purpose)
	}
	tw.Flush()
}



func filterWebhooks(webhooks []types.Webhook) []types.Webhook {
	var out []types.Webhook
	for _, w := range webhooks {
		if webhookTypeFilter != "" && !strings.EqualFold(w.Type, webhookTypeFilter) {
			continue
		}
		if webhookTargetFilter != "" && !matchesTarget(w, webhookTargetFilter) {
			continue
		}
		out = append(out, w)
	}
	if webhookTypeFilter == "" && webhookTargetFilter == "" {
		return webhooks
	}
	return out
}

func matchesTarget(w types.Webhook, target string) bool {
	targetResource := target
	targetGroup := ""
	if idx := strings.Index(target, "."); idx >= 0 {
		targetResource = target[:idx]
		targetGroup = target[idx+1:]
	}
	for _, r := range w.Rules {
		for _, res := range r.Resources {
			if !resourceMatches(res, targetResource) {
				continue
			}
			if targetGroup == "" {
				return true
			}
			for _, g := range r.APIGroups {
				if strings.EqualFold(g, targetGroup) {
					return true
				}
			}
		}
	}
	return false
}

func resourceMatches(resource string, target string) bool {
	if strings.EqualFold(resource, target) {
		return true
	}
	if strings.EqualFold(resource, target+"s") || strings.EqualFold(resource+"s", target) {
		return true
	}
	if strings.EqualFold(resource, target+"es") || strings.EqualFold(resource+"es", target) {
		return true
	}
	return false
}

func rulesSum(w types.Webhook) string {
	var parts []string
	for _, r := range w.Rules {
		parts = append(parts, strings.Join(r.Resources, ","))
	}
	return strings.Join(parts, ";")
}

func init() {
	webhooksCmd.Flags().StringVar(&webhookTypeFilter, "type", "", "Filter by webhook type (mutating, validating, conversion)")
	webhooksCmd.Flags().StringVar(&webhookTargetFilter, "target", "", "Filter by target resource (e.g., inferenceservices, inferenceservices.serving.kserve.io)")
	addOutputFlag(webhooksCmd, OutputText, OutputJSON, OutputWide)
	rootCmd.AddCommand(webhooksCmd)
}
