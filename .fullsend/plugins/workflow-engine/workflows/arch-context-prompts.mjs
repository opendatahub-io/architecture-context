/**
 * arch-context-prompts.mjs — the swappable prompt block (plan §P1 data
 * block 2), extracted from arch-context.mjs so it carries ZERO imports:
 * plain `node` can import it (see test-prompts.mjs — golden prompt
 * tests), while the parent module's typebox dependency requires pi's
 * loader. Prompt text is code for LLM children; it gets the same
 * regression-testing discipline as the engine.
 */

export function promptFor(item) {
	const ctx = item.promptContext || {};
	const lines = [
		`ANALYZE ${item.key}`,
		``,
		`You are generating the architecture summary for the repository checked out at the current working directory (${item.repoDir}).`,
	];
	// promptContext is optional enrichment (build metadata, overlay context
	// in the original pipeline; repo identity here) — never required.
	if (ctx.repo_url) lines.push(`Repository: ${ctx.repo_url}`);
	if (ctx.ref) lines.push(`Pinned ref: ${ctx.ref}`);
	if (ctx.checkout_branch) lines.push(`Branch: ${ctx.checkout_branch}`);
	if (ctx.type) lines.push(`Component type: ${ctx.type}`);
	if (item.analyzerDir) {
		lines.push(
			``,
			`BASELINE FACTS (ground truth — never contradict these):`,
			`- ${item.analyzerDir}/analyzer_synthesis_context.md — bounded, source-linked projection; read this FIRST`,
			`- ${item.analyzerDir}/analyzer_architecture.md — rendered analyzer baseline (its "Architectural Analysis" section is pending; writing that narrative is YOUR job)`,
			`- ${item.analyzerDir}/component-architecture.json — authoritative analyzer JSON`,
			``,
			`Use the analyzer facts as your baseline: they save you time and tokens. Read`,
			`repository source in the working directory as needed to write the narrative`,
			`and fill gaps. Do not invent facts that are in neither the baseline nor the`,
			`source.`,
		);
	} else {
		lines.push(``, `No analyzer baseline is provided; analyze the source directly.`);
	}
	lines.push(...contractLines(item));
	return lines.join("\n");
}

/** The output contract, shared by the first attempt and every retry —
 * a retry is a FRESH session that has never seen the original prompt,
 * so it must carry the full field list, not a reference to it. */
/** Output discipline shared by every agent prompt in this workflow. */

export function disciplineLines() {
	return [
		``,
		`Respond with ONLY the raw JSON object — no markdown code fences, no prose before or after.`,
		`The first character of the response must be '{' and the last must be '}'.`,
		`Every value must match the exact JSON type listed: narrative fields are strings`,
		`(write "none" or "not applicable" — never booleans, null, or empty strings);`,
		`arrays may be empty.`,
		`The JSON must be strictly valid: escape every double quote inside string values`,
		`(write \\" for each \") and avoid literal double quotes in URL paths (write`,
		`/{tenant}/ rather than /{\"tenant\"}/). Keep string values concise (under ~25 words).`,
		``,
		`Before responding, self-check: every narrative field is a non-empty string;`,
		`no null or boolean values anywhere; all required fields present.`,
	];
}

export function contractLines(item) {
	return [
		...disciplineLines(),
		``,
		`JSON fields (the architecture template's sections; empty arrays where a`,
		`section does not apply):`,
		`- component: exactly ${JSON.stringify(item.key)}`,
		`- purpose: {short: one sentence, detailed: one paragraph}`,
		`- architecturalAnalysis: concise architecture narrative synthesized from analyzer facts and bounded source evidence`,
		`- architectureComponents: [{name, type, purpose}] — every field a non-empty string`,
		`- subComponents: [{name, apiRoutes: [{path, methods}], upstreamDependencies: [], configuration: []}]`,
		`- apisExposed: {httpEndpoints: [{path, methods, description}], grpcServices: [{name, description}], customResourceDefinitions: [{group, version, kind, purpose}]}`,
		`- dependencies: {external: [{name, purpose}], internalPlatform: [names]}`,
		`- deployment: {summary, variants: [{name, description}]}`,
		`- network: {services: [{name, description}], ingress: [{name, description}], egress: [{name, description}]}`,
		`- security: {authentication, authorization, secrets: [{name, description}], fipsCompliance: string such as "not applicable" or a compliance summary}`,
		`- multiTenancy: {model, isolationMechanisms: [], sharedServices: []}`,
		`- dataFlows: [{name, description}]`,
		`- integrationPoints: [{name, description}]`,
		`- concerns: [] (architectural concerns or risks)`,
		`no null or boolean values anywhere; all 14 top-level fields present.`,
	];
}

/** Corrective retry prompt: a fresh child session carrying the exact
 * failure (invalid JSON, schema violation) and the FULL output contract.
 * Used via the fanout primitive's retries option. */

export function retryPromptFor(item, _index, err) {
	return [
		`RETRY ANALYZE ${item.key}`,
		``,
		`A previous response for this component was rejected:`,
		`${err && err.message ? err.message : String(err)}`,
		``,
		`Regenerate the complete architecture summary JSON for the repository at the`,
		`current working directory (${item.repoDir}), fixing the reported problem.`,
		...(item.analyzerDir
			? [`The analyzer baseline facts are at ${item.analyzerDir}/ (read the synthesis context first).`]
			: []),
		...contractLines(item),
	].join("\n");
}

/** Deterministic cross-component inventory — the arch-query
 * platform-summary analog: merges the prebuilt analyzer baselines so
 * the synthesis agent (and the published doc) get machine-extracted
 * facts, including cross-repo service wiring that no single-repo read
 * can produce. */

export function platformContractLines(platform) {
	return [
		``,
		`JSON fields:`,
		`- platform: exactly ${JSON.stringify(platform)}`,
		`- overview: one to two paragraphs synthesizing what this platform is and does`,
		`- componentRelationships: {centralComponents: [component names], integrationPatterns: [{name, description}]}`,
		`- networkArchitecture: the platform network story (string)`,
		`- securitySummary: shared authentication/authorization/secrets posture (string)`,
		`- dataFlows: [{name, description}] — key end-to-end workflows across components`,
		`- deploymentTopology: how the platform deploys and runs (string)`,
		`- crossCuttingConcerns: [] (strings)`,
	];
}

/** The platform-synthesis prompt (the aggregate-platform-architecture
 * skill's port): validated component results + deterministic analyzer
 * inventory in, one cross-cutting synthesis out. */

export function platformPromptFor(platform, items, summaries, inventory) {
	const trimmed = summaries.map((r) => ({
		component: r.component,
		purpose: r.purpose,
		architecturalAnalysis: r.architecturalAnalysis,
		dependencies: r.dependencies,
		network: r.network,
		integrationPoints: r.integrationPoints,
		dataFlows: r.dataFlows,
		concerns: r.concerns,
	}));
	return [
		`AGGREGATE PLATFORM ${platform}`,
		``,
		`You are synthesizing the platform-level architecture document for the`,
		`${JSON.stringify(platform)} platform from ${summaries.length} component summaries.`,
		``,
		`COMPONENT SUMMARIES (validated structured results):`,
		JSON.stringify(trimmed, null, 1),
		``,
		`ANALYZER INVENTORY (deterministic, machine-extracted — ground truth for`,
		`wiring and counts; do not contradict it):`,
		JSON.stringify(inventory, null, 1),
		``,
		`Synthesize the cross-cutting view: how the components relate and integrate,`,
		`the platform network story, the shared security posture, the key end-to-end`,
		`data flows, the deployment topology, and cross-cutting concerns. Where the`,
		`inventory shows service wiring (hosts, backends), use it verbatim.`,
		...disciplineLines(),
		...platformContractLines(platform),
	].join("\n");
}

// ---------------------------------------------------------------------------
// Swappable data block 3: aggregation renderers
// (markdown shaped like the architecture template)
// ---------------------------------------------------------------------------
