/**
 * lib/primitives.mjs — workflow-level primitives shared by workflow
 * modules (port plan §1.1 req 9): input validation, per-item fan-out,
 * completeness assertion, and result/artifact persistence.
 *
 * Extracted from org-scan.mjs's inline code. Rule of two: the copied
 * org-scan.mjs is refactored onto these as the first consumer and
 * arch-context.mjs is the second — proving the primitives are shaped
 * by the fan-out-analyze-aggregate pattern, not by one workflow.
 *
 * host.js keeps its exact agent/parallel/pipeline surface; these
 * compose it, never replace it. Every primitive fails loudly (throws
 * with workflow + item context) — a failed check is never a silently
 * dropped or hallucinated item.
 *
 * Portability seam: another project vendors the plugin tree, writes
 * workflows/<theirs>.mjs importing these primitives, and supplies its
 * own schema/prompt/renderer as data at the module boundary.
 */

import fs from "node:fs";
import path from "node:path";
import { Value } from "typebox/value";

/** Path confinement (CWE-22): join `name` into `dir` and reject any
 * result that escapes `dir`. Names here derive from model output
 * (component keys, repo names) — a prompt-injected result must not
 * write outside the run directory. Symlinks are not followed by
 * path.resolve; a pre-existing symlink target escaping `dir` is caught
 * by the prefix check only if the link itself is outside — symlink
 * contents are the writer's concern (files are created, not followed). */
export function safeJoin(dir, name) {
	if (typeof name !== "string" || name.includes("\0")) {
		throw new Error(`unsafe path name ${JSON.stringify(name)}`);
	}
	const resolved = path.resolve(dir, name);
	const root = path.resolve(dir);
	if (resolved !== root && !resolved.startsWith(root + path.sep)) {
		throw new Error(`path ${JSON.stringify(name)} escapes ${root}`);
	}
	return resolved;
}

/** Validate a workflow input object against a JSON Schema; loud on failure. */
export function validateInput(input, schema, workflow = "workflow") {
	if (!input || typeof input !== "object" || Array.isArray(input)) {
		throw new Error(
			`${workflow}: input must be an object, got ${JSON.stringify(input)?.slice(0, 80)}`,
		);
	}
	if (!Value.Check(schema, input)) {
		const errors = [...Value.Errors(schema, input)]
			.map((e) => `${e.path}: ${e.message}`)
			.join("; ");
		throw new Error(`${workflow}: input validation failed — ${errors}`);
	}
	return input;
}

/**
 * One schema-validated child agent per work item, bounded concurrency,
 * journaled by the host. Returns positional results aligned with items.
 *
 * opts: { promptOf(item, i), labelOf(item, i), schema, cwdOf?(item, i),
 *         model?, concurrency = 2, timeoutMs?, retries = 0,
 *         retryPromptOf?(item, i, error) }
 *
 * retries: on agent failure (invalid JSON, schema violation, nonzero
 * exit), the item is re-attempted with retryPromptOf(item, i, error) —
 * a fresh child session carrying the error context, so a model that
 * emitted malformed or non-conforming output gets one corrective shot.
 * Failed attempts' usage is still sunk (partial spend is real spend).
 */
export async function fanout(wf, items, opts) {
	const {
		promptOf, labelOf, schema, cwdOf, model, concurrency = 2, timeoutMs,
		retries = 0, retryPromptOf,
	} = opts;
	const attempt = async (item, index) => {
		const callOpts = {
			label: labelOf(item, index),
			schema,
			cwd: cwdOf ? cwdOf(item, index) : undefined,
			model,
			timeoutMs,
		};
		let lastErr;
		for (let attemptNo = 0; attemptNo <= retries; attemptNo++) {
			try {
				if (attemptNo === 0) {
					return await wf.agent(promptOf(item, index), callOpts);
				}
				return await wf.agent(retryPromptOf(item, index, lastErr, attemptNo), {
					...callOpts,
					label: `${labelOf(item, index)}:retry${attemptNo}`,
				});
			} catch (err) {
				lastErr = err;
			}
		}
		throw lastErr;
	};
	return wf.parallel(
		items.map((item, index) => () => attempt(item, index)),
		{ concurrency },
	);
}

/**
 * Cardinality + reality check: every item exactly one non-empty result,
 * and (when resultKey is given) each result is about the item it was
 * given. Returns results on success.
 */
export function assertComplete(items, results, opts = {}) {
	const { itemKey, resultKey, workflow = "workflow" } = opts;
	const expected = Array.isArray(items) ? items.length : -1;
	const got = Array.isArray(results) ? results.length : -1;
	if (got !== expected || expected < 0) {
		throw new Error(
			`${workflow}: expected ${expected} results, got ${got} — refusing to aggregate an incomplete set`,
		);
	}
	for (let i = 0; i < items.length; i++) {
		if (results[i] === null || results[i] === undefined) {
			throw new Error(`${workflow}: result ${i} is empty`);
		}
		if (itemKey && resultKey) {
			const want = itemKey(items[i], i);
			const have = resultKey(results[i], i);
			if (have !== want) {
				throw new Error(
					`${workflow}: result ${i} is about ${JSON.stringify(have)}, expected ${JSON.stringify(want)}`,
				);
			}
		}
	}
	return results;
}

/** Write one JSON file per result under <runDir>/results/. Returns paths. */
export function writeResults(wf, results, opts = {}) {
	const { fileOf, workflow = "workflow" } = opts;
	if (typeof fileOf !== "function") {
		throw new Error(`${workflow}: writeResults requires fileOf(result)`);
	}
	const dir = path.join(wf.runDir, "results");
	fs.mkdirSync(dir, { recursive: true });
	const files = [];
	for (const result of results) {
		const file = safeJoin(dir, fileOf(result));
		fs.writeFileSync(file, JSON.stringify(result) + "\n");
		files.push(file);
	}
	return files;
}

/** Write the run's artifact.json. Returns the artifact. */
export function writeArtifact(wf, artifact) {
	fs.writeFileSync(
		safeJoin(wf.runDir, "artifact.json"),
		JSON.stringify(artifact, null, "\t") + "\n",
	);
	return artifact;
}
