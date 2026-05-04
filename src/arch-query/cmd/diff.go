package cmd

import (
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/types"
	"github.com/spf13/cobra"
)

var diffAll bool

var diffCmd = &cobra.Command{
	Use:   "diff <component> <version-a> <version-b>",
	Short: "Compare a component between two versions",
	Long: `Compare a component (or all components with --all) between two versions.

Examples:
  arch-query diff kserve rhoai-3.3 rhoai-3.4
  arch-query diff --all rhoai-3.3 rhoai-3.4`,
	Args: cobra.RangeArgs(2, 3),
	RunE: func(cmd *cobra.Command, args []string) error {
		var component, verA, verB string
		if diffAll {
			if len(args) != 2 {
				return fmt.Errorf("--all requires exactly 2 version arguments")
			}
			verA, verB = args[0], args[1]
		} else {
			if len(args) != 3 {
				return fmt.Errorf("requires component name and two versions")
			}
			component = strings.ToLower(args[0])
			verA, verB = args[1], args[2]
		}

		dataA, err := loader.LoadVersion(archFS, verA)
		if err != nil {
			return fmt.Errorf("loading %s: %w", verA, err)
		}
		dataB, err := loader.LoadVersion(archFS, verB)
		if err != nil {
			return fmt.Errorf("loading %s: %w", verB, err)
		}

		if diffAll || component == "platform" {
			return diffAllComponents(verA, verB, dataA, dataB)
		}
		return diffSingleComponent(component, verA, verB, dataA, dataB)
	},
}

func diffAllComponents(verA, verB string, dataA, dataB *types.VersionData) error {
	fmt.Printf("%s -> %s\n\n", verA, verB)

	setA := make(map[string]bool)
	for k := range dataA.Components {
		setA[k] = true
	}
	setB := make(map[string]bool)
	for k := range dataB.Components {
		setB[k] = true
	}

	var added, removed, common []string
	for k := range dataB.Components {
		if !setA[k] {
			added = append(added, k)
		}
	}
	sort.Strings(added)
	for k := range dataA.Components {
		if !setB[k] {
			removed = append(removed, k)
		}
	}
	sort.Strings(removed)
	for k := range dataA.Components {
		if setB[k] {
			common = append(common, k)
		}
	}
	sort.Strings(common)

	if len(added) > 0 {
		fmt.Printf("  Added components (%d):\n", len(added))
		for _, k := range added {
			fmt.Printf("    %s\n", k)
		}
		fmt.Println()
	}

	if len(removed) > 0 {
		fmt.Printf("  Removed components (%d):\n", len(removed))
		for _, k := range removed {
			fmt.Printf("    %s\n", k)
		}
		fmt.Println()
	}

	var changed []string
	for _, k := range common {
		a := dataA.Components[k]
		b := dataB.Components[k]
		diffs := componentChanges(a, b)
		if len(diffs) > 0 {
			changed = append(changed, fmt.Sprintf("    %s: %s", k, strings.Join(diffs, ", ")))
		}
	}

	if len(changed) > 0 {
		fmt.Printf("  Changed (%d components):\n", len(changed))
		for _, c := range changed {
			fmt.Println(c)
		}
		fmt.Println()
	}

	fmt.Printf("  Unchanged: %d components\n", len(common)-len(changed))

	// Cross-cutting summary: aggregate the most common changes across all components
	addedDepsAgg := make(map[string]int)
	removedDepsAgg := make(map[string]int)
	addedCRDGroupsAgg := make(map[string]int)
	removedCRDGroupsAgg := make(map[string]int)
	addedRBACGroupsAgg := make(map[string]int)
	removedRBACGroupsAgg := make(map[string]int)

	for _, k := range common {
		a := dataA.Components[k]
		b := dataB.Components[k]

		dA := depSet(a.ExternalDeps, a.InternalDeps)
		dB := depSet(b.ExternalDeps, b.InternalDeps)
		for dep := range dB {
			if !dA[dep] {
				addedDepsAgg[dep]++
			}
		}
		for dep := range dA {
			if !dB[dep] {
				removedDepsAgg[dep]++
			}
		}

		cA := crdSet(a.CRDs)
		cB := crdSet(b.CRDs)
		for crd := range cB {
			if !cA[crd] {
				group := strings.SplitN(crd, "/", 2)[0]
				addedCRDGroupsAgg[group]++
			}
		}
		for crd := range cA {
			if !cB[crd] {
				group := strings.SplitN(crd, "/", 2)[0]
				removedCRDGroupsAgg[group]++
			}
		}

		rA := rbacGroupSet(a.RBACRoles)
		rB := rbacGroupSet(b.RBACRoles)
		for g := range rB {
			if !rA[g] {
				addedRBACGroupsAgg[g]++
			}
		}
		for g := range rA {
			if !rB[g] {
				removedRBACGroupsAgg[g]++
			}
		}
	}

	fmt.Println("\n  Key changes across platform:")

	if len(addedDepsAgg) > 0 {
		fmt.Println("    Dependencies added:")
		for _, entry := range topN(addedDepsAgg, 10) {
			fmt.Printf("      %s (in %d components)\n", entry.name, entry.count)
		}
	}
	if len(removedDepsAgg) > 0 {
		fmt.Println("    Dependencies removed:")
		for _, entry := range topN(removedDepsAgg, 10) {
			fmt.Printf("      %s (from %d components)\n", entry.name, entry.count)
		}
	}
	if len(addedCRDGroupsAgg) > 0 {
		fmt.Println("    CRD API groups added:")
		for _, entry := range topN(addedCRDGroupsAgg, 10) {
			fmt.Printf("      %s (%d CRDs)\n", entry.name, entry.count)
		}
	}
	if len(removedCRDGroupsAgg) > 0 {
		fmt.Println("    CRD API groups removed:")
		for _, entry := range topN(removedCRDGroupsAgg, 10) {
			fmt.Printf("      %s (%d CRDs)\n", entry.name, entry.count)
		}
	}
	if len(addedRBACGroupsAgg) > 0 {
		fmt.Println("    RBAC API groups added:")
		for _, entry := range topN(addedRBACGroupsAgg, 10) {
			fmt.Printf("      %s (in %d components)\n", entry.name, entry.count)
		}
	}
	if len(removedRBACGroupsAgg) > 0 {
		fmt.Println("    RBAC API groups removed:")
		for _, entry := range topN(removedRBACGroupsAgg, 10) {
			fmt.Printf("      %s (from %d components)\n", entry.name, entry.count)
		}
	}

	return nil
}

type ranked struct {
	name  string
	count int
}

func topN(m map[string]int, n int) []ranked {
	var entries []ranked
	for k, v := range m {
		entries = append(entries, ranked{k, v})
	}
	sort.Slice(entries, func(i, j int) bool {
		if entries[i].count != entries[j].count {
			return entries[i].count > entries[j].count
		}
		return entries[i].name < entries[j].name
	})
	if len(entries) > n {
		entries = entries[:n]
	}
	return entries
}

func rbacGroupSet(roles []types.RBACRole) map[string]bool {
	s := make(map[string]bool)
	for _, r := range roles {
		s[r.APIGroup] = true
	}
	return s
}

func diffSingleComponent(name, verA, verB string, dataA, dataB *types.VersionData) error {
	docA := findComponent(dataA, name)
	docB := findComponent(dataB, name)

	if docA == nil && docB == nil {
		fmt.Fprintf(os.Stderr, "Component %q not found in either %s or %s.\n", name, verA, verB)
		os.Exit(1)
	}
	if docA == nil {
		fmt.Printf("%s: not present in %s, added in %s\n", name, verA, verB)
		return nil
	}
	if docB == nil {
		fmt.Printf("%s: present in %s, removed in %s\n", name, verA, verB)
		return nil
	}

	fmt.Printf("%s: %s -> %s\n\n", name, verA, verB)

	crdsA := crdSet(docA.CRDs)
	crdsB := crdSet(docB.CRDs)
	addedCRDs, removedCRDs := setDiff(crdsA, crdsB)
	if len(addedCRDs) > 0 {
		fmt.Println("  Added CRDs:")
		for _, c := range addedCRDs {
			fmt.Printf("    %s\n", c)
		}
	}
	if len(removedCRDs) > 0 {
		fmt.Println("  Removed CRDs:")
		for _, c := range removedCRDs {
			fmt.Printf("    %s\n", c)
		}
	}

	depsA := depSet(docA.ExternalDeps, docA.InternalDeps)
	depsB := depSet(docB.ExternalDeps, docB.InternalDeps)
	addedDeps, removedDeps := setDiff(depsA, depsB)
	if len(addedDeps) > 0 {
		fmt.Println("  Added dependencies:")
		for _, d := range addedDeps {
			fmt.Printf("    %s\n", d)
		}
	}
	if len(removedDeps) > 0 {
		fmt.Println("  Removed dependencies:")
		for _, d := range removedDeps {
			fmt.Printf("    %s\n", d)
		}
	}

	svcA := serviceSet(docA.Services)
	svcB := serviceSet(docB.Services)
	addedSvc, removedSvc := setDiff(svcA, svcB)
	if len(addedSvc) > 0 {
		fmt.Println("  Added services:")
		for _, s := range addedSvc {
			fmt.Printf("    %s\n", s)
		}
	}
	if len(removedSvc) > 0 {
		fmt.Println("  Removed services:")
		for _, s := range removedSvc {
			fmt.Printf("    %s\n", s)
		}
	}

	epA := endpointSet(docA.Endpoints)
	epB := endpointSet(docB.Endpoints)
	addedEP, removedEP := setDiff(epA, epB)
	if len(addedEP) > 0 {
		fmt.Println("  Added HTTP endpoints:")
		for _, e := range addedEP {
			fmt.Printf("    %s\n", e)
		}
	}
	if len(removedEP) > 0 {
		fmt.Println("  Removed HTTP endpoints:")
		for _, e := range removedEP {
			fmt.Printf("    %s\n", e)
		}
	}

	grpcA := grpcSet(docA.GRPCServices)
	grpcB := grpcSet(docB.GRPCServices)
	addedGRPC, removedGRPC := setDiff(grpcA, grpcB)
	if len(addedGRPC) > 0 {
		fmt.Println("  Added gRPC services:")
		for _, g := range addedGRPC {
			fmt.Printf("    %s\n", g)
		}
	}
	if len(removedGRPC) > 0 {
		fmt.Println("  Removed gRPC services:")
		for _, g := range removedGRPC {
			fmt.Printf("    %s\n", g)
		}
	}

	rbacA := rbacSet(docA.RBACRoles)
	rbacB := rbacSet(docB.RBACRoles)
	addedRBAC, removedRBAC := setDiff(rbacA, rbacB)
	if len(addedRBAC) > 0 {
		fmt.Println("  Added RBAC roles:")
		for _, r := range addedRBAC {
			fmt.Printf("    %s\n", r)
		}
	}
	if len(removedRBAC) > 0 {
		fmt.Println("  Removed RBAC roles:")
		for _, r := range removedRBAC {
			fmt.Printf("    %s\n", r)
		}
	}

	ingA := ingressSet(docA.Ingresses)
	ingB := ingressSet(docB.Ingresses)
	addedIng, removedIng := setDiff(ingA, ingB)
	if len(addedIng) > 0 {
		fmt.Println("  Added ingress:")
		for _, i := range addedIng {
			fmt.Printf("    %s\n", i)
		}
	}
	if len(removedIng) > 0 {
		fmt.Println("  Removed ingress:")
		for _, i := range removedIng {
			fmt.Printf("    %s\n", i)
		}
	}

	egA := egressSet(docA.Egresses)
	egB := egressSet(docB.Egresses)
	addedEg, removedEg := setDiff(egA, egB)
	if len(addedEg) > 0 {
		fmt.Println("  Added egress:")
		for _, e := range addedEg {
			fmt.Printf("    %s\n", e)
		}
	}
	if len(removedEg) > 0 {
		fmt.Println("  Removed egress:")
		for _, e := range removedEg {
			fmt.Printf("    %s\n", e)
		}
	}

	hasChanges := len(addedCRDs) > 0 || len(removedCRDs) > 0 ||
		len(addedDeps) > 0 || len(removedDeps) > 0 ||
		len(addedSvc) > 0 || len(removedSvc) > 0 ||
		len(addedEP) > 0 || len(removedEP) > 0 ||
		len(addedGRPC) > 0 || len(removedGRPC) > 0 ||
		len(addedRBAC) > 0 || len(removedRBAC) > 0 ||
		len(addedIng) > 0 || len(removedIng) > 0 ||
		len(addedEg) > 0 || len(removedEg) > 0
	if !hasChanges {
		fmt.Println("  No structural changes detected.")
	}

	return nil
}

func findComponent(data *types.VersionData, name string) *types.ComponentDoc {
	for k, v := range data.Components {
		if strings.EqualFold(k, name) {
			return v
		}
	}
	return nil
}

func componentChanges(a, b *types.ComponentDoc) []string {
	var changes []string
	if d := countSetDiff(crdSet(a.CRDs), crdSet(b.CRDs)); d != "" {
		changes = append(changes, d+" CRDs")
	}
	if d := countSetDiff(depSet(a.ExternalDeps, a.InternalDeps), depSet(b.ExternalDeps, b.InternalDeps)); d != "" {
		changes = append(changes, d+" deps")
	}
	if d := countSetDiff(serviceSet(a.Services), serviceSet(b.Services)); d != "" {
		changes = append(changes, d+" services")
	}
	if d := countSetDiff(endpointSet(a.Endpoints), endpointSet(b.Endpoints)); d != "" {
		changes = append(changes, d+" endpoints")
	}
	if d := countSetDiff(grpcSet(a.GRPCServices), grpcSet(b.GRPCServices)); d != "" {
		changes = append(changes, d+" gRPC")
	}
	if d := countSetDiff(rbacSet(a.RBACRoles), rbacSet(b.RBACRoles)); d != "" {
		changes = append(changes, d+" RBAC roles")
	}
	if d := countSetDiff(ingressSet(a.Ingresses), ingressSet(b.Ingresses)); d != "" {
		changes = append(changes, d+" ingress")
	}
	if d := countSetDiff(egressSet(a.Egresses), egressSet(b.Egresses)); d != "" {
		changes = append(changes, d+" egress")
	}
	return changes
}

func countSetDiff(a, b map[string]bool) string {
	added, removed := 0, 0
	for k := range b {
		if !a[k] {
			added++
		}
	}
	for k := range a {
		if !b[k] {
			removed++
		}
	}
	if added == 0 && removed == 0 {
		return ""
	}
	var parts []string
	if added > 0 {
		parts = append(parts, fmt.Sprintf("+%d", added))
	}
	if removed > 0 {
		parts = append(parts, fmt.Sprintf("-%d", removed))
	}
	return strings.Join(parts, "/")
}

func crdSet(crds []types.CRD) map[string]bool {
	s := make(map[string]bool)
	for _, c := range crds {
		s[c.Group+"/"+c.Version+" "+c.Kind] = true
	}
	return s
}

func depSet(external, internal []types.Dependency) map[string]bool {
	s := make(map[string]bool)
	for _, d := range external {
		s[d.Component] = true
	}
	for _, d := range internal {
		s[d.Component] = true
	}
	return s
}

func serviceSet(services []types.Service) map[string]bool {
	s := make(map[string]bool)
	for _, svc := range services {
		s[svc.Name+" "+svc.Port] = true
	}
	return s
}

func endpointSet(endpoints []types.Endpoint) map[string]bool {
	s := make(map[string]bool)
	for _, ep := range endpoints {
		s[ep.Method+" "+ep.Path+" "+ep.Port] = true
	}
	return s
}

func grpcSet(services []types.GRPCService) map[string]bool {
	s := make(map[string]bool)
	for _, g := range services {
		s[g.Service+" "+g.Port] = true
	}
	return s
}

func rbacSet(roles []types.RBACRole) map[string]bool {
	s := make(map[string]bool)
	for _, r := range roles {
		s[r.RoleName+" "+r.APIGroup+" "+r.Resources] = true
	}
	return s
}

func ingressSet(ingresses []types.Ingress) map[string]bool {
	s := make(map[string]bool)
	for _, ing := range ingresses {
		s[ing.Component+" "+ing.Type+" "+ing.Port] = true
	}
	return s
}

func egressSet(egresses []types.Egress) map[string]bool {
	s := make(map[string]bool)
	for _, eg := range egresses {
		s[eg.Destination+" "+eg.Port+" "+eg.Protocol] = true
	}
	return s
}

func setDiff(a, b map[string]bool) (added, removed []string) {
	for k := range b {
		if !a[k] {
			added = append(added, k)
		}
	}
	for k := range a {
		if !b[k] {
			removed = append(removed, k)
		}
	}
	sort.Strings(added)
	sort.Strings(removed)
	return
}

func init() {
	diffCmd.Flags().BoolVar(&diffAll, "all", false, "Compare all components between versions")
	rootCmd.AddCommand(diffCmd)
}
