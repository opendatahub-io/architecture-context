/**
 * test-child — scripted child provider for the workflow-engine POC.
 *
 * Registers provider "test-child" with model "echo": a fully deterministic,
 * zero-inference classifier. Given a prompt "CLASSIFY <item>" it replies
 * with JSON {"item": "...", "bucket": "..."} where the bucket is a stable
 * hash of the item text. Used as the Layer 1-3 child so the whole stack
 * runs offline and byte-deterministically.
 */

import { createAssistantMessageEventStream } from "@earendil-works/pi-ai/compat";

const BUCKETS = ["alpha", "beta", "gamma"];

function classify(item) {
	let h = 0;
	for (const ch of item) h = (h * 31 + ch.charCodeAt(0)) >>> 0;
	return BUCKETS[h % BUCKETS.length];
}

function lastUserText(messages) {
	for (let i = messages.length - 1; i >= 0; i--) {
		const m = messages[i];
		if (m.role !== "user") continue;
		if (typeof m.content === "string") return m.content;
		if (Array.isArray(m.content)) {
			return m.content.filter((b) => b && b.type === "text").map((b) => b.text).join("\n");
		}
		return "";
	}
	return "";
}


// ANALYZE fixture: a SummarySchema-conforming deterministic summary.
function fixtureSummary(key) {
	return JSON.stringify({
		component: key,
		purpose: {
			short: `fixture summary of ${key}`,
			detailed: `fixture architecture summary of ${key}`,
		},
		architecturalAnalysis: `fixture architectural analysis of ${key}`,
		architectureComponents: [{ name: key, type: "fixture", purpose: `fixture component ${key}` }],
		subComponents: [],
		apisExposed: {
			httpEndpoints: [{ path: "/", methods: ["GET"], description: `fixture endpoint of ${key}` }],
			grpcServices: [],
			customResourceDefinitions: [],
		},
		dependencies: { external: [{ name: "fixture-dep", purpose: `fixture dependency of ${key}` }], internalPlatform: [] },
		deployment: { summary: `fixture deployment of ${key}`, variants: [{ name: "fixture", description: `fixture variant of ${key}` }] },
		network: {
			services: [{ name: `${key}-service`, description: `fixture service of ${key}` }],
			ingress: [],
			egress: [],
		},
		security: { authentication: "fixture", authorization: "fixture", secrets: [{ name: "FIXTURE_SECRET", description: `fixture secret of ${key}` }], fipsCompliance: "fixture" },
		multiTenancy: { model: "none", isolationMechanisms: [], sharedServices: [] },
		dataFlows: [],
		integrationPoints: [],
		concerns: [],
	});
}

function zeroUsage() {
	return {
		input: 0,
		output: 0,
		cacheRead: 0,
		cacheWrite: 0,
		totalTokens: 0,
		cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
	};
}

function assistant(content, stopReason, extra) {
	return {
		role: "assistant",
		content,
		api: "test-child-stream",
		provider: "test-child",
		model: "echo",
		usage: zeroUsage(),
		stopReason,
		timestamp: Date.now(),
		...extra,
	};
}

export default function (pi) {
	pi.registerProvider("test-child", {
		// baseUrl is required by the registration form but never contacted.
		baseUrl: "http://127.0.0.1:9",
		api: "test-child-stream",
		// Placeholder credential: streamSimple performs no HTTP, so no real key exists.
		apiKey: "local-no-inference",
		models: [
			{
				id: "echo",
				name: "Echo (scripted, no inference)",
				reasoning: false,
				input: ["text"],
				cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
				contextWindow: 100000,
				maxTokens: 4096,
			},
		],
		streamSimple(model, context) {
			const stream = createAssistantMessageEventStream();
			// slow- fixtures: delayed emit (~2.5s) so the check suite can kill
			// a run mid-fan-out and exercise durable resume offline.
			const emit = (out, delayMs = 0) => {
				if (delayMs > 0) {
					setTimeout(() => emit(out), delayMs);
					return stream;
				}
				const final = assistant([{ type: "text", text: out }], "stop");
				stream.push({ type: "start", partial: assistant([], "pending") });
				stream.push({ type: "text_start", contentIndex: 0, partial: assistant([{ type: "text", text: "" }], "pending") });
				stream.push({ type: "text_delta", contentIndex: 0, delta: out, partial: assistant([{ type: "text", text: out }], "pending") });
				stream.push({ type: "text_end", contentIndex: 0, content: out, partial: final });
				stream.push({ type: "done", reason: "stop", message: final });
				stream.end();
				return stream;
			};
			const text = lastUserText(context.messages);
			// Verb dispatch: CLASSIFY (demo), CLONE (org-scan discovery),
			// SCAN (org-scan per-repo), ANALYZE (arch-context per-component).
			// All outputs are deterministic.
			const trimmed = text.trim();
			if (trimmed.startsWith("ECHO") || trimmed.startsWith("<skill ")) {
				return emit(JSON.stringify({ echo: trimmed.slice(0, 400) }));
			}
			const clone = /^CLONE\s+([^\n]+)/.exec(trimmed);
			const scan = /^SCAN\s+([^\n]+)\s+at\s+([^\n]+)/.exec(trimmed);
			const retryAggregate = /^RETRY\s+AGGREGATE\s+PLATFORM\s+(\S+)/.exec(trimmed);
			const aggregate = /^AGGREGATE\s+PLATFORM\s+(\S+)/.exec(trimmed);
			const retryAnalyze = /^RETRY\s+ANALYZE\s+(\S+)/.exec(trimmed);
			const analyze = /^ANALYZE\s+(\S+)/.exec(trimmed);
			const match = /^CLASSIFY\s+([^\n]+)/.exec(trimmed);
			if (retryAggregate || aggregate) {
				const name = (aggregate || retryAggregate)[1];
				return emit(JSON.stringify({
					platform: name,
					overview: `fixture platform overview of ${name}`,
					componentRelationships: {
						centralComponents: ["fixture-central"],
						integrationPatterns: [{ name: "fixture pattern", description: `fixture integration pattern of ${name}` }],
					},
					networkArchitecture: `fixture network architecture of ${name}`,
					securitySummary: `fixture security summary of ${name}`,
					dataFlows: [{ name: "fixture flow", description: `fixture data flow of ${name}` }],
					deploymentTopology: `fixture deployment topology of ${name}`,
					crossCuttingConcerns: [],
				}));
			}
			if (retryAnalyze) {
				// Corrective retry: __malformed__ stays broken (the check
				// script's persistent-failure negative); everything else —
				// including the flaky fixture's second attempt — succeeds,
				// proving the fanout retry path end-to-end offline.
				const key = retryAnalyze[1];
				if (key === "__malformed__") {
					return emit("this is still not json");
				}
				return emit(fixtureSummary(key));
			}
			if (analyze) {
				const key = analyze[1];
				// Deliberately-bad fixtures for the check script's negative
				// suite: __malformed__ emits non-JSON (host must fail on
				// parse), __wrongkey__ emits valid JSON about the wrong
				// component (assertComplete reality check must catch it),
				// __flaky__ emits the real-world failure shape (unescaped
				// quotes inside a string) and recovers on retry.
				if (key === "__malformed__") {
					return emit("this is not json");
				}
				if (key === "__flaky__") {
					// Mimics the GLM failure: /{"tenant"}/ breaks the JSON.
					return emit('{"component":"__flaky__","purpose":{"short":"quotes " inside" break JSON"}}');
				}
				if (key === "__wrongkey__") {
					return emit(JSON.stringify({
						component: "someone-else",
						purpose: { short: "fixture", detailed: "fixture" },
						architecturalAnalysis: "fixture",
						architectureComponents: [],
						subComponents: [],
						apisExposed: { httpEndpoints: [], grpcServices: [], customResourceDefinitions: [] },
						dependencies: { external: [], internalPlatform: [] },
						deployment: { summary: "fixture", variants: [] },
						network: { services: [], ingress: [], egress: [] },
						security: { authentication: "fixture", authorization: "fixture", secrets: [], fipsCompliance: "fixture" },
						multiTenancy: { model: "none", isolationMechanisms: [], sharedServices: [] },
						dataFlows: [],
						integrationPoints: [],
						concerns: [],
					}));
				}
				return emit(fixtureSummary(key), key.startsWith("slow-") ? 2500 : 0);
			}
			if (clone) {
				const out = JSON.stringify({
					root: ".context/org",
					repo_count: 3,
					repos: [
						{ name: "odh-dashboard", path: ".context/org/odh-dashboard" },
						{ name: "model-registry", path: ".context/org/model-registry" },
						{ name: "llama-stack-distribution", path: ".context/org/llama-stack-distribution" },
					],
				});
				return emit(out);
			}
			if (scan) {
				const out = JSON.stringify({ repo: scan[1].trim(), summary: `fixture architecture summary of ${scan[1].trim()}`, concerns: [] });
				return emit(out);
			}
			if (!match) {
				const error = assistant([], "error", { errorMessage: `test-child: prompt must be CLASSIFY/CLONE/SCAN/ANALYZE, got: ${JSON.stringify(text.slice(0, 80))}` });
				stream.push({ type: "error", reason: "error", error });
				stream.end();
				return stream;
			}
			const item = match[1].trim();
			return emit(JSON.stringify({ item, bucket: classify(item) }));
		},
	});
}
