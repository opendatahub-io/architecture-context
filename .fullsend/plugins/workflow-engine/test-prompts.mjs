#!/usr/bin/env node
/**
 * test-prompts.mjs — golden prompt tests for the arch-context workflow.
 *
 * Prompt text is code for LLM children; this gives it the same
 * regression discipline as the engine's event-stream determinism
 * checks. Born from PR #91 review findings M-3 and m-2, both of which
 * every contract-level test was blind to:
 *
 *   - M-3: the retry prompt's error parameter received the item INDEX
 *     (rendered "undefined") — caught here by asserting the rejection
 *     reason appears in the rendered retry prompt.
 *   - m-2: the JSON-escape instruction rendered `write \\"` (which,
 *     followed, produces invalid JSON) — caught here by a
 *     self-consistency check: every escape example the prompt teaches
 *     must, applied inside a JSON string, parse.
 *
 * Golden files (test-golden/) lock the full rendered prompts; any
 * unintended change — escaping churn, signature drift, accidental
 * edits — fails the byte comparison.
 *
 * Usage:
 *   node test-prompts.mjs            # compare against goldens
 *   node test-prompts.mjs --update   # regenerate goldens (review the diff!)
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
	promptFor,
	retryPromptFor,
	platformPromptFor,
} from "./workflows/arch-context-prompts.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const GOLDEN_DIR = path.join(HERE, "test-golden");
const UPDATE = process.argv.includes("--update");

// ── Fixtures (deterministic; mirrors the check suite's inline items) ─────
const fixtureItem = {
	key: "fixture-component",
	repoDir: "checkouts/example.head/fixture-component",
	analyzerDir: "architecture/fixture/fixture-component/.analyzer",
	promptContext: {
		repo_url: "https://github.com/example/fixture-component",
		ref: "0123456789abcdef0123456789abcdef01234567",
		checkout_branch: "main",
		type: "service",
		recent_changes: ["0123456 fix: example recent change"],
	},
};
const fixtureItemNoBaseline = {
	key: "no-baseline",
	repoDir: "checkouts/example.head/no-baseline",
	promptContext: {},
};
const fixtureError = new Error(
	'agent(analyze:fixture-component): output not valid JSON (Unexpected token in JSON at position 42)',
);
const fixturePlatform = "fixture";
const fixtureSummaries = [
	{
		component: "fixture-component",
		purpose: { short: "fixture summary", detailed: "fixture detailed summary" },
		architecturalAnalysis: "fixture analysis",
		dependencies: { external: [], internalPlatform: [] },
		network: { services: [], ingress: [], egress: [] },
		integrationPoints: [],
		dataFlows: [],
		concerns: [],
	},
];
const fixtureInventory = {
	components: [{ component: "fixture-component", httpEndpoints: 12, services: 1, deployments: 1, entrypoints: 1 }],
	crossRepoIngress: [{ name: "fixture", host: "fixture.svc.cluster.local", paths: "/", backend: "fixture", tls: true }],
};

const renders = {
	"component-prompt.txt": promptFor(fixtureItem),
	"component-prompt-no-baseline.txt": promptFor(fixtureItemNoBaseline),
	"retry-prompt.txt": retryPromptFor(fixtureItem, 0, fixtureError),
	"platform-prompt.txt": platformPromptFor(fixturePlatform, [fixtureItem], fixtureSummaries, fixtureInventory),
};

let failures = 0;

// ── 1. Golden comparison ─────────────────────────────────────────────────
fs.mkdirSync(GOLDEN_DIR, { recursive: true });
for (const [name, text] of Object.entries(renders)) {
	const file = path.join(GOLDEN_DIR, name);
	if (UPDATE) {
		fs.writeFileSync(file, text);
		console.log(`updated golden: ${name} (${text.length} bytes)`);
		continue;
	}
	if (!fs.existsSync(file)) {
		console.error(`FAIL: golden ${name} missing (run with --update to create)`);
		failures++;
		continue;
	}
	const golden = fs.readFileSync(file, "utf8");
	if (golden !== text) {
		console.error(`FAIL: golden ${name} drifted (${golden.length} -> ${text.length} bytes)`);
		failures++;
	}
}
if (UPDATE) process.exit(0);

// ── 2. M-3: the retry prompt must carry the actual rejection reason ─────
const retryText = renders["retry-prompt.txt"];
if (!retryText.includes(fixtureError.message)) {
	console.error("FAIL: retry prompt does not contain the rejection reason (M-3 class: parameter binding renders 'undefined')");
	failures++;
} else {
	console.log("retry prompt carries the rejection reason: OK");
}

// ── 3. m-2: self-consistency — every escape example the prompt teaches,
//    applied inside a JSON string, must parse. ────────────────────────────
for (const text of Object.values(renders)) {
	const examples = [...text.matchAll(/\(write (\\"|\\\\") for each "\)/g)].map((m) => m[1]);
	for (const example of examples) {
		// the model, following the instruction, writes the example inside a
		// JSON string value: {"x":"a<example>b"}
		const applied = `{"x":"a${example}b"}`;
		try {
			JSON.parse(applied);
		} catch {
			console.error(`FAIL: escape example ${JSON.stringify(example)} (from the prompt) produces invalid JSON when followed: ${applied}`);
			failures++;
		}
	}
}
console.log("escape examples self-consistent: OK");

// ── 4. Structural invariants every prompt must keep ─────────────────────
for (const [name, text] of Object.entries(renders)) {
	if (!text.includes("Respond with ONLY the raw JSON object")) {
		console.error(`FAIL: ${name} lost the raw-JSON discipline line`);
		failures++;
	}
	if (text.includes("undefined")) {
		console.error(`FAIL: ${name} renders the literal string 'undefined' (unbound variable class)`);
		failures++;
	}
}
console.log("structural invariants: OK");

if (failures > 0) {
	console.error(`PROMPT-TESTS: FAIL (${failures})`);
	process.exit(1);
}
console.log("PROMPT-TESTS: PASS");
