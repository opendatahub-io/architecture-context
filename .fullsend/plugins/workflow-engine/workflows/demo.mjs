/**
 * demo.mjs — the demo pipeline as a workflow module.
 *
 * Authoring surface mirrors Claude Code's Workflow API:
 *
 *   export const meta = {...}
 *   export default async function (wf, input) { ... wf.agent() ... wf.parallel() ... }
 *
 * Differences that matter (by design): results are schema-validated before
 * use, persisted to the journal and to per-item files, and the completeness
 * assertion is ordinary code running with the full Node stdlib.
 */

import fs from "node:fs";
import path from "node:path";

export const meta = {
	name: "demo",
	description: "Classify work items into buckets via child agents",
};

const BUCKETS = ["alpha", "beta", "gamma"];

const Result = {
	type: "object",
	properties: {
		item: { type: "string" },
		bucket: { type: "string", enum: BUCKETS },
	},
	required: ["item", "bucket"],
	additionalProperties: false,
};

export default async function run(wf, input) {
	const items = input.items;
	if (!Array.isArray(items) || items.length === 0 || items.some((s) => typeof s !== "string" || !s.trim())) {
		throw new Error("demo: items must be a non-empty list of non-empty strings");
	}

	// Phase A — ingest (plain code: state file, results dir).
	fs.mkdirSync(path.join(wf.runDir, "results"), { recursive: true });
	fs.writeFileSync(path.join(wf.runDir, "state.json"), JSON.stringify({ phase: "ingest", items }, null, "\t") + "\n");

	// Phase B — fan-out: one child per item, schema-validated, journaled.
	const classify = (item) => () =>
		wf.agent(
			`CLASSIFY ${item}\nClassify the item named on the first line into exactly one bucket: alpha, beta, or gamma.\nReply with only minified JSON {"item":"<item>","bucket":"<bucket>"} and nothing else.`,
			{ label: item, schema: Result },
		);
	const results = await wf.parallel(items.map(classify), { concurrency: 2 });

	// Per-item contract: the result must be about the item it was asked about.
	for (let i = 0; i < items.length; i++) {
		if (results[i].item !== items[i]) {
			throw new Error(`demo: result ${i} is about ${JSON.stringify(results[i].item)}, expected ${JSON.stringify(items[i])}`);
		}
		fs.writeFileSync(path.join(wf.runDir, "results", `${items[i]}.json`), JSON.stringify(results[i]) + "\n");
	}
	fs.writeFileSync(path.join(wf.runDir, "state.json"), JSON.stringify({ phase: "aggregate", items }, null, "\t") + "\n");

	// Phase C — completeness assertion + artifact.
	const artifact = {
		items,
		complete: results.length === items.length,
		classified: results.length,
		failed: 0,
		failures: [],
		results,
		summary: `${results.length}/${items.length} items classified`,
	};
	fs.writeFileSync(path.join(wf.runDir, "artifact.json"), JSON.stringify(artifact, null, "\t") + "\n");
	if (!artifact.complete) {
		throw new Error(`demo: incomplete — ${results.length}/${items.length} items classified`);
	}
	return artifact;
}
