/**
 * arch-context.mjs — the architecture-context port workflow: analyzer-baseline
 * validation, one child agent per component (analyzing the pre-cloned checkout
 * in its cwd against the analyzer baseline), then platform-level aggregation.
 * Port of the original pipeline's phases 2c (static-analysis validation),
 * 3 (generate) and 4/6 (collect/platform); P0's components.json is the
 * work-item source and P0's host-side arch-analyzer run is the baseline.
 *
 * Composition (port plan §1.1 req 9): everything structural is imported
 * primitives (validateInput / fanout / assertComplete / writeResults /
 * writeArtifact). The arch-specific surface is exactly three swappable
 * data blocks — another project ports this module by swapping them:
 *
 *   1. Input + SummarySchema   (input contract; summary sections = the
 *                               repo-to-architecture-summary template)
 *   2. promptFor()             (per-component prompt = the skill contract:
 *                               analyzer baseline as ground truth)
 *   3. renderComponentDoc() / renderPlatformDoc()  (template-shaped output)
 *
 * Stage gating (CLI parity, §5.5): `stages` selects which phases run —
 * fetch/parse are host-side by design (P0), analyze validates the prebuilt
 * analyzer baseline in-workflow, generate is the fan-out, collect/platform
 * publish. Diagrams are a non-goal. collect/platform without generate
 * requires durable journal replay (planned P5) and fails loudly for now.
 */

import fs from "node:fs";
import path from "node:path";

import {
	assertComplete,
	fanout,
	safeJoin,
	validateInput,
	writeArtifact,
	writeResults,
} from "../lib/primitives.mjs";
// The swappable prompt block lives in its own dependency-free module so
// plain `node` can import it (test-prompts.mjs golden tests); this
// module's typebox dependency requires pi's loader.
import { promptFor, retryPromptFor, platformPromptFor } from "./arch-context-prompts.mjs";

export const meta = {
	name: "arch-context",
	description:
		"Analyze a component set (work items from components.json, with analyzer baselines) and aggregate a platform architecture document",
};

// ---------------------------------------------------------------------------
// Swappable data block 1: input contract + per-component summary schema
// ---------------------------------------------------------------------------

const Input = {
	type: "object",
	properties: {
		platform: { type: "string", minLength: 1 },
		stages: { type: "array", items: { type: "string", minLength: 1 } },
		concurrency: { type: "integer", minimum: 1 },
		timeoutMs: { type: "integer", minimum: 1000 },
		components: { type: "array", items: { type: "string", minLength: 1 } },
		items: { type: "array", items: { type: "object" } },
		architectureDir: { type: "string", minLength: 1 },
	},
	additionalProperties: false,
};

const WorkItem = {
	type: "object",
	properties: {
		key: { type: "string", minLength: 1 },
		repoDir: { type: "string", minLength: 1 },
		analyzerDir: { type: "string", minLength: 1 },
		promptContext: { type: "object" },
	},
	required: ["key", "repoDir"],
	additionalProperties: false,
};

// SummarySchema mirrors the section structure of
// .claude/skills/repo-to-architecture-summary/templates/architecture-template.md
// (the RHOAI-specific sections — AIPCC ecosystems, serving runtimes,
// kustomize parameterization detail, RBAC tables — are collapsed or
// dropped; empty arrays are valid where a section does not apply).
const SummarySchema = {
	type: "object",
	properties: {
		component: { type: "string", minLength: 1 },
		purpose: {
			type: "object",
			properties: {
				short: { type: "string", minLength: 1 },
				detailed: { type: "string", minLength: 1 },
			},
			required: ["short", "detailed"],
			additionalProperties: false,
		},
		architecturalAnalysis: { type: "string", minLength: 1 },
		architectureComponents: {
			type: "array",
			items: {
				type: "object",
				properties: {
					name: { type: "string", minLength: 1 },
					type: { type: "string", minLength: 1 },
					purpose: { type: "string", minLength: 1 },
				},
				required: ["name", "type", "purpose"],
				additionalProperties: false,
			},
		},
		subComponents: {
			type: "array",
			items: {
				type: "object",
				properties: {
					name: { type: "string", minLength: 1 },
					apiRoutes: {
						type: "array",
						items: {
							type: "object",
							properties: {
								path: { type: "string", minLength: 1 },
								methods: { type: "array", items: { type: "string" } },
							},
							required: ["path", "methods"],
							additionalProperties: false,
						},
					},
					upstreamDependencies: { type: "array", items: { type: "string" } },
					configuration: { type: "array", items: { type: "string" } },
				},
				required: ["name", "apiRoutes", "upstreamDependencies", "configuration"],
				additionalProperties: false,
			},
		},
		apisExposed: {
			type: "object",
			properties: {
				httpEndpoints: {
					type: "array",
					items: {
						type: "object",
						properties: {
							path: { type: "string", minLength: 1 },
							methods: { type: "array", items: { type: "string" } },
							description: { type: "string", minLength: 1 },
						},
						required: ["path", "methods", "description"],
						additionalProperties: false,
					},
				},
				grpcServices: {
					type: "array",
					items: {
						type: "object",
						properties: {
							name: { type: "string", minLength: 1 },
							description: { type: "string", minLength: 1 },
						},
						required: ["name", "description"],
						additionalProperties: false,
					},
				},
				customResourceDefinitions: {
					type: "array",
					items: {
						type: "object",
						properties: {
							group: { type: "string", minLength: 1 },
							version: { type: "string", minLength: 1 },
							kind: { type: "string", minLength: 1 },
							purpose: { type: "string", minLength: 1 },
						},
						required: ["group", "version", "kind", "purpose"],
						additionalProperties: false,
					},
				},
			},
			required: ["httpEndpoints", "grpcServices", "customResourceDefinitions"],
			additionalProperties: false,
		},
		dependencies: {
			type: "object",
			properties: {
				external: {
					type: "array",
					items: {
						type: "object",
						properties: {
							name: { type: "string", minLength: 1 },
							purpose: { type: "string", minLength: 1 },
							version: { type: "string", minLength: 1 },
							role: { type: "string", minLength: 1 },
						},
						required: ["name"],
						additionalProperties: false,
					},
				},
				internalPlatform: { type: "array", items: { type: "string" } },
			},
			required: ["external", "internalPlatform"],
			additionalProperties: false,
		},
		deployment: {
			type: "object",
			properties: {
				summary: { type: "string", minLength: 1 },
				variants: {
					type: "array",
					items: {
						type: "object",
						properties: {
							name: { type: "string", minLength: 1 },
							description: { type: "string", minLength: 1 },
						},
						required: ["name", "description"],
						additionalProperties: false,
					},
				},
			},
			required: ["summary", "variants"],
			additionalProperties: false,
		},
		network: {
			type: "object",
			properties: {
				services: {
					type: "array",
					items: {
						type: "object",
						properties: {
							name: { type: "string", minLength: 1 },
							description: { type: "string", minLength: 1 },
						},
						required: ["name", "description"],
						additionalProperties: false,
					},
				},
				ingress: {
					type: "array",
					items: {
						type: "object",
						properties: {
							name: { type: "string", minLength: 1 },
							description: { type: "string", minLength: 1 },
						},
						required: ["name", "description"],
						additionalProperties: false,
					},
				},
				egress: {
					type: "array",
					items: {
						type: "object",
						properties: {
							name: { type: "string", minLength: 1 },
							description: { type: "string", minLength: 1 },
						},
						required: ["name", "description"],
						additionalProperties: false,
					},
				},
			},
			required: ["services", "ingress", "egress"],
			additionalProperties: false,
		},
		security: {
			type: "object",
			properties: {
				authentication: { type: "string", minLength: 1 },
				authorization: { type: "string", minLength: 1 },
				secrets: {
					type: "array",
					items: {
						type: "object",
						properties: {
							name: { type: "string", minLength: 1 },
							description: { type: "string", minLength: 1 },
						},
						required: ["name", "description"],
						additionalProperties: false,
					},
				},
				fipsCompliance: { type: "string", minLength: 1 },
			},
			required: ["authentication", "authorization", "secrets", "fipsCompliance"],
			additionalProperties: false,
		},
		multiTenancy: {
			type: "object",
			properties: {
				model: { type: "string", minLength: 1 },
				isolationMechanisms: { type: "array", items: { type: "string" } },
				sharedServices: { type: "array", items: { type: "string" } },
			},
			required: ["model", "isolationMechanisms", "sharedServices"],
			additionalProperties: false,
		},
		dataFlows: {
			type: "array",
			items: {
				type: "object",
				properties: {
					name: { type: "string", minLength: 1 },
					description: { type: "string", minLength: 1 },
				},
				required: ["name", "description"],
				additionalProperties: false,
			},
		},
		integrationPoints: {
			type: "array",
			items: {
				type: "object",
				properties: {
					name: { type: "string", minLength: 1 },
					description: { type: "string", minLength: 1 },
				},
				required: ["name", "description"],
				additionalProperties: false,
			},
		},
		concerns: { type: "array", items: { type: "string" } },
	},
	required: [
		"component",
		"purpose",
		"architecturalAnalysis",
		"architectureComponents",
		"subComponents",
		"apisExposed",
		"dependencies",
		"deployment",
		"network",
		"security",
		"multiTenancy",
		"dataFlows",
		"integrationPoints",
		"concerns",
	],
	additionalProperties: false,
};
// ---------------------------------------------------------------------------
// Swappable data block 1b: platform synthesis schema
// (mirrors aggregate-platform-architecture's template; RHOAI-specific
// sections — webhooks, kustomize patterns, overlay deployment, maturity
// scoring — are collapsed)
// ---------------------------------------------------------------------------

const PlatformSchema = {
	type: "object",
	properties: {
		platform: { type: "string", minLength: 1 },
		overview: { type: "string", minLength: 1 },
		componentRelationships: {
			type: "object",
			properties: {
				centralComponents: { type: "array", items: { type: "string", minLength: 1 } },
				integrationPatterns: {
					type: "array",
					items: {
						type: "object",
						properties: {
							name: { type: "string", minLength: 1 },
							description: { type: "string", minLength: 1 },
						},
						required: ["name", "description"],
						additionalProperties: false,
					},
				},
			},
			required: ["centralComponents", "integrationPatterns"],
			additionalProperties: false,
		},
		networkArchitecture: { type: "string", minLength: 1 },
		securitySummary: { type: "string", minLength: 1 },
		dataFlows: {
			type: "array",
			items: {
				type: "object",
				properties: {
					name: { type: "string", minLength: 1 },
					description: { type: "string", minLength: 1 },
				},
				required: ["name", "description"],
				additionalProperties: false,
			},
		},
		deploymentTopology: { type: "string", minLength: 1 },
		crossCuttingConcerns: { type: "array", items: { type: "string" } },
	},
	required: [
		"platform",
		"overview",
		"componentRelationships",
		"networkArchitecture",
		"securitySummary",
		"dataFlows",
		"deploymentTopology",
		"crossCuttingConcerns",
	],
	additionalProperties: false,
};


// ---------------------------------------------------------------------------
// Swappable data block 2: per-component analysis prompt
// (port of the repo-to-architecture-summary skill contract)
// ---------------------------------------------------------------------------

function platformInventory(items) {
	const components = [];
	const crossRepoIngress = [];
	for (const item of items) {
		const entry = {
			component: item.key,
			httpEndpoints: 0,
			services: 0,
			deployments: 0,
			entrypoints: 0,
		};
		if (item.analyzerDir) {
			try {
				const facts = JSON.parse(
					fs.readFileSync(path.join(path.resolve(item.analyzerDir), "component-architecture.json"), "utf8"),
				);
				entry.httpEndpoints = Array.isArray(facts.http_endpoints) ? facts.http_endpoints.length : 0;
				entry.services = Array.isArray(facts.services) ? facts.services.length : 0;
				entry.deployments = Array.isArray(facts.deployments) ? facts.deployments.length : 0;
				entry.entrypoints = Array.isArray(facts.entrypoints) ? facts.entrypoints.length : 0;
				for (const rule of facts.ingress_routing || []) {
					if (rule.host && rule.backend) {
						crossRepoIngress.push({
							name: String(rule.name || rule.host),
							host: String(rule.host),
							paths: (rule.paths || []).join(", "),
							backend: String(rule.backend),
							tls: Boolean(rule.tls),
						});
					}
				}
			} catch {
				/* missing/invalid baseline is reported loudly by the analyze stage */
			}
		}
		components.push(entry);
	}
	return { components, crossRepoIngress };
}

/** Platform synthesis field contract (shared by attempt and retries). */
function renderComponentDoc(result, item, platform) {
	// The Metadata section is load-bearing for arch-query (the consumer
	// CLI): its fact sheets parse Repository/Branch/Version/Languages/
	// Deployment Type from `- **Key**: value` bullets here.
	const ctx = (item && item.promptContext) || {};
	const lines = [
		`# Component: ${result.component}`,
		``,
		`## Metadata`,
		``,
		...(ctx.repo_url ? [`- **Repository**: ${ctx.repo_url}`] : []),
		...(ctx.ref ? [`- **Version**: ${ctx.ref}`] : []),
		...(ctx.checkout_branch ? [`- **Branch**: ${ctx.checkout_branch}`] : []),
		`- **Distribution**: ${platform}`,
		...(ctx.type ? [`- **Deployment Type**: ${ctx.type}`] : []),
		`- **Generated By**: workflow-engine (arch-context)`,
		``,
		`## Purpose`,
		``,
		result.purpose.detailed,
		``,
		`## Architectural Analysis`,
		``,
		result.architecturalAnalysis,
		``,
		`## Architecture Components`,
		``,
		`| Component | Type | Purpose |`,
		`|----|----|-------|`,
	];
	for (const c of result.architectureComponents) {
		lines.push(`| ${c.name} | ${c.type} | ${c.purpose} |`);
	}
	lines.push(``);
	for (const sub of result.subComponents) {
		lines.push(`## Sub-Component: ${sub.name}`, ``);
		if (sub.apiRoutes.length > 0) {
			lines.push(`**API Routes:**`, ``, `| Path | Methods |`, `|----|--------|`);
			for (const route of sub.apiRoutes) {
				lines.push(`| ${route.path} | ${route.methods.join(", ")} |`);
			}
			lines.push(``);
		}
		if (sub.upstreamDependencies.length > 0) {
			lines.push(`**Upstream Dependencies:** ${sub.upstreamDependencies.join(", ")}`, ``);
		}
		if (sub.configuration.length > 0) {
			lines.push(`**Configuration:**`, ``, ...sub.configuration.map((c) => `- ${c}`), ``);
		}
	}
	const { apisExposed } = result;
	lines.push(`## APIs Exposed`, ``);
	if (apisExposed.httpEndpoints.length > 0) {
		lines.push(`### HTTP Endpoints`, ``, `| Path | Methods | Description |`, `|----|---------|-------------|`);
		for (const ep of apisExposed.httpEndpoints) {
			lines.push(`| ${ep.path} | ${ep.methods.join(", ")} | ${ep.description} |`);
		}
		lines.push(``);
	}
	if (apisExposed.grpcServices.length > 0) {
		lines.push(`### gRPC Services`, ``);
		for (const svc of apisExposed.grpcServices) lines.push(`- **${svc.name}**: ${svc.description}`);
		lines.push(``);
	}
	if (apisExposed.customResourceDefinitions.length > 0) {
		lines.push(`### Custom Resource Definitions (CRDs)`, ``, `| Group | Version | Kind | Purpose |`, `|-----|-------|-----|-------|`);
		for (const crd of apisExposed.customResourceDefinitions) {
			lines.push(`| ${crd.group} | ${crd.version} | ${crd.kind} | ${crd.purpose} |`);
		}
		lines.push(``);
	}
	if (result.dependencies.external.length > 0 || result.dependencies.internalPlatform.length > 0) {
		lines.push(`## Dependencies`, ``);
		if (result.dependencies.external.length > 0) {
			lines.push(`**External:**`, ``);
			for (const dep of result.dependencies.external) {
				const note = dep.purpose || dep.role || dep.version || "";
				lines.push(note ? `- **${dep.name}** — ${note}` : `- **${dep.name}**`);
			}
			lines.push(``);
		}
		if (result.dependencies.internalPlatform.length > 0) {
			lines.push(`**Internal Platform:** ${result.dependencies.internalPlatform.join(", ")}`, ``);
		}
	}
	lines.push(`## Deployment`, ``, result.deployment.summary, ``);
	if (result.deployment.variants.length > 0) {
		lines.push(`**Variants:**`, ``, ...result.deployment.variants.map((v) => `- **${v.name}**: ${v.description}`), ``);
	}
	const { network } = result;
	lines.push(`## Network Architecture`, ``);
	for (const [label, entries] of [
		["Services", network.services],
		["Ingress", network.ingress],
		["Egress", network.egress],
	]) {
		if (entries.length > 0) {
			lines.push(`**${label}:**`, ``, ...entries.map((e) => `- **${e.name}**: ${e.description}`), ``);
		}
	}
	const { security } = result;
	lines.push(
		`## Security`,
		``,
		`- **Authentication:** ${security.authentication}`,
		`- **Authorization:** ${security.authorization}`,
		`- **FIPS Compliance:** ${security.fipsCompliance}`,
		``,
	);
	if (security.secrets.length > 0) {
		lines.push(`**Secrets:**`, ``);
		for (const secret of security.secrets) {
			lines.push(`- **${secret.name}** — ${secret.description}`);
		}
		lines.push(``);
	}
	const { multiTenancy } = result;
	if (multiTenancy.model.toLowerCase() !== "none" || multiTenancy.isolationMechanisms.length > 0) {
		lines.push(`## Multi-Tenancy`, ``, `**Model:** ${multiTenancy.model}`, ``);
		if (multiTenancy.isolationMechanisms.length > 0) {
			lines.push(`**Isolation Mechanisms:**`, ``, ...multiTenancy.isolationMechanisms.map((m) => `- ${m}`), ``);
		}
		if (multiTenancy.sharedServices.length > 0) {
			lines.push(`**Shared Services:** ${multiTenancy.sharedServices.join(", ")}`, ``);
		}
	}
	if (result.dataFlows.length > 0) {
		lines.push(`## Data Flows`, ``);
		for (const flow of result.dataFlows) lines.push(`- **${flow.name}**: ${flow.description}`);
		lines.push(``);
	}
	if (result.integrationPoints.length > 0) {
		lines.push(`## Integration Points`, ``);
		for (const ip of result.integrationPoints) lines.push(`- **${ip.name}**: ${ip.description}`);
		lines.push(``);
	}
	if (result.concerns.length > 0) {
		lines.push(`## Concerns`, ``, ...result.concerns.map((c) => `- ${c}`), ``);
	}
	// Required by the repo's doc linter; deterministic from the pinned
	// ref's git history (captured at P0 into promptContext).
	const recent = (item && item.promptContext && item.promptContext.recent_changes) || [];
	if (recent.length > 0) {
		lines.push(`## Recent Changes`, ``, ...recent.map((c) => `- ${c}`), ``);
	}
	return lines.join("\n") + "\n";
}

function renderPlatformDoc(summary, artifact) {
	const lines = [
		`# Platform Architecture — ${summary.platform}`,
		``,
		`## Metadata`,
		``,
		`- Components analyzed: ${artifact.analyzed}/${artifact.expected}`,
		`- Complete: ${artifact.complete}`,
		`- Components: ${artifact.components.join(", ")}`,
		``,
		`## Platform Overview`,
		``,
		summary.overview,
		``,
		`## Component Relationships`,
		``,
		`### Internal Dependencies`,
		``,
	];
	const edges = [];
	for (const result of artifact.results) {
		for (const dep of result.dependencies.internalPlatform) {
			edges.push(`${result.component} -> ${dep}`);
		}
	}
	lines.push(...(edges.length > 0 ? edges.map((e) => `- ${e}`) : ["_(none declared)_"]), ``);
	const cr = summary.componentRelationships;
	if (cr.centralComponents.length > 0) {
		lines.push(`### Central Components`, ``, ...cr.centralComponents.map((c) => `- **${c}**`), ``);
	}
	if (cr.integrationPatterns.length > 0) {
		lines.push(`### Integration Patterns`, ``);
		for (const ip of cr.integrationPatterns) lines.push(`- **${ip.name}**: ${ip.description}`);
		lines.push(``);
	}
	lines.push(`## Network Architecture`, ``, summary.networkArchitecture, ``);
	if (artifact.inventory && artifact.inventory.crossRepoIngress.length > 0) {
		lines.push(`### Analyzer-Detected Service Wiring`, ``, `| Ingress | Host | Paths | Backend | TLS |`, `|----|----|----|----|----|`);
		for (const w of artifact.inventory.crossRepoIngress) {
			lines.push(`| ${w.name} | ${w.host} | ${w.paths} | ${w.backend} | ${w.tls} |`);
		}
		lines.push(``);
	}
	lines.push(`## Platform Security`, ``, summary.securitySummary, ``);
	if (summary.dataFlows.length > 0) {
		lines.push(`## Data Flows`, ``);
		for (const f of summary.dataFlows) lines.push(`- **${f.name}**: ${f.description}`);
		lines.push(``);
	}
	lines.push(`## Deployment Topology`, ``, summary.deploymentTopology, ``);
	if (summary.crossCuttingConcerns.length > 0) {
		lines.push(`## Cross-Cutting Concerns`, ``, ...summary.crossCuttingConcerns.map((c) => `- ${c}`), ``);
	}
	if (artifact.inventory && artifact.inventory.components.length > 0) {
		lines.push(`## Analyzer Inventory`, ``, `| Component | Endpoints | Services | Deployments | Entrypoints |`, `|----|----|----|----|----|`);
		for (const inv of artifact.inventory.components) {
			lines.push(`| ${inv.component} | ${inv.httpEndpoints} | ${inv.services} | ${inv.deployments} | ${inv.entrypoints} |`);
		}
		lines.push(``);
	}
	return lines.join("\n") + "\n";
}

// ---------------------------------------------------------------------------
// Workflow body — primitive composition, no bespoke inline logic
// ---------------------------------------------------------------------------

const ALL_STAGES = ["fetch", "parse", "analyze", "generate", "collect", "diagrams", "platform"];
const HOST_SIDE_STAGES = new Set(["fetch", "parse"]);
const DEFAULT_STAGES = ["analyze", "generate", "collect", "platform"];

function resolveStages(cfg) {
	const notes = [];
	let stages = cfg.stages || DEFAULT_STAGES;
	for (const stage of stages) {
		if (!ALL_STAGES.includes(stage)) {
			throw new Error(
				`arch-context: unknown stage ${JSON.stringify(stage)} (known: ${ALL_STAGES.join(", ")})`,
			);
		}
	}
	stages = stages.filter((stage) => {
		if (HOST_SIDE_STAGES.has(stage)) {
			notes.push(`stage '${stage}' is host-side by design (P0 pre-clone/prebuilt manifest); skipped in-workflow`);
			return false;
		}
		if (stage === "diagrams") {
			notes.push("stage 'diagrams' is a non-goal for this experiment; skipped");
			return false;
		}
		return true;
	});
	return { stages, notes };
}

function loadWorkItems(cfg) {
	let items = cfg.items;
	if (!items) {
		const file = process.env.WORKFLOW_INPUT_FILE;
		if (!file || !file.trim()) {
			throw new Error(
				"arch-context: no work items — set input.items or WORKFLOW_INPUT_FILE (path to components.json)",
			);
		}
		let raw;
		try {
			raw = JSON.parse(fs.readFileSync(file, "utf8"));
		} catch (err) {
			throw new Error(`arch-context: cannot read work items from ${file}: ${err.message}`);
		}
		if (!Array.isArray(raw)) {
			throw new Error(`arch-context: ${file} must be a JSON array of work items`);
		}
		items = raw;
	}
	items = items.map((item) => validateInput(item, WorkItem, `arch-context item ${JSON.stringify(item?.key)}`));
	if (cfg.components) {
		const wanted = new Set(cfg.components);
		const selected = items.filter((item) => wanted.has(item.key));
		const missing = cfg.components.filter((key) => !items.some((item) => item.key === key));
		if (missing.length > 0) {
			throw new Error(`arch-context: unknown component(s) requested: ${missing.join(", ")}`);
		}
		items = selected;
	}
	if (items.length === 0) {
		throw new Error("arch-context: no work items to process");
	}
	return items;
}

/** In-workflow analyze stage: validate the prebuilt analyzer baseline.
 * The arch-analyzer run itself is deterministic and host-side (P0);
 * generate depends on its outputs, so missing/invalid baselines must
 * fail loudly here, before any inference is spent. */
function validateAnalyzerBaselines(items, notes) {
	for (const item of items) {
		if (!item.analyzerDir) {
			notes.push(`${item.key}: no analyzer baseline; generate will analyze source without baseline facts`);
			continue;
		}
		const dir = path.resolve(item.analyzerDir);
		const jsonFile = path.join(dir, "component-architecture.json");
		const mdFile = path.join(dir, "analyzer_architecture.md");
		let facts;
		try {
			facts = JSON.parse(fs.readFileSync(jsonFile, "utf8"));
		} catch (err) {
			throw new Error(
				`arch-context analyze: ${item.key}: cannot read analyzer JSON (${jsonFile}): ${err.message}`,
			);
		}
		if (!fs.existsSync(mdFile) || fs.statSync(mdFile).size === 0) {
			throw new Error(
				`arch-context analyze: ${item.key}: missing or empty analyzer baseline ${mdFile}`,
			);
		}
		const factCount = Object.values(facts)
			.filter((v) => Array.isArray(v))
			.reduce((n, v) => n + v.length, 0);
		notes.push(`${item.key}: analyzer baseline validated (${factCount} facts)`);
	}
}

export default async function run(wf, input) {
	const cfg = validateInput(input, Input, "arch-context");
	const { stages, notes } = resolveStages(cfg);
	const items = loadWorkItems(cfg);
	const platform = cfg.platform || "unknown";

	const runAnalyze = stages.includes("analyze");
	const runGenerate = stages.includes("generate");
	const runCollect = stages.includes("collect");
	const runPlatform = stages.includes("platform");
	if ((runCollect || runPlatform) && !runGenerate) {
		throw new Error(
			"arch-context: 'collect'/'platform' without 'generate' needs the validated results in memory; durable journal replay (WORKFLOW_KEEP_RUNS) only resumes interrupted generate runs — include 'generate' in stages",
		);
	}

	// Phase 2c (in-workflow): validate the analyzer baseline generate depends on.
	if (runAnalyze) {
		validateAnalyzerBaselines(items, notes);
	}

	let summaries = [];
	if (runGenerate) {
		// Phase 3 — fan-out: one analysis child per component, in its
		// checkout, against the analyzer baseline. Real analysis runs
		// minutes, not seconds: default timeout 5 min, overridable via
		// input.timeoutMs (host default of 120s is for scripted children).
		summaries = await fanout(wf, items, {
			promptOf: promptFor,
			labelOf: (item) => `analyze:${item.key}`,
			schema: SummarySchema,
			cwdOf: (item) => item.repoDir,
			concurrency: cfg.concurrency ?? 2,
			timeoutMs: cfg.timeoutMs ?? 300000,
			// Corrective retries: models occasionally emit invalid JSON
			// (unescaped quotes in long outputs), null/boolean leaves, or
			// (pre-contract-fix) drift from the field structure. Each
			// retry is a fresh session carrying the exact failure AND the
			// full output contract.
			retries: 2,
			retryPromptOf: retryPromptFor,
		});
		assertComplete(items, summaries, {
			itemKey: (item) => item.key,
			resultKey: (summary) => summary.component,
			workflow: "arch-context",
		});
	}

	// Phases 4+6 — per-component results and platform aggregate. Validated
	// results are published as markdown into <architectureDir>/<platform>/
	// (the repo's conventional output tree) in addition to the run dir's
	// machine-readable copies. Publishing renders from validated JSON —
	// children never write markdown, so published files are deterministic
	// functions of validated results.
	const archDir = path.resolve(cfg.architectureDir || "architecture", platform);
	if (runCollect && summaries.length > 0) {
		writeResults(wf, summaries, {
			fileOf: (summary) => `${summary.component}.json`,
			workflow: "arch-context",
		});
		fs.mkdirSync(archDir, { recursive: true });
		summaries.forEach((summary, index) => {
			fs.writeFileSync(
				safeJoin(archDir, `${summary.component}.md`),
				renderComponentDoc(summary, items[index], platform),
			);
		});
	}

	// Phase 6 — platform synthesis: one agent over the validated component
	// results + the deterministic analyzer inventory (the
	// aggregate-platform-architecture skill's port). Single-item fanout
	// gives it the same retry semantics as the component children.
	let platformSummary = null;
	const inventory = platformInventory(items);
	if (runPlatform && summaries.length > 0) {
		[platformSummary] = await fanout(wf, [platform], {
			promptOf: () => platformPromptFor(platform, items, summaries, inventory),
			labelOf: () => "aggregate-platform",
			schema: PlatformSchema,
			concurrency: 1,
			timeoutMs: cfg.timeoutMs ?? 300000,
			retries: 2,
			retryPromptOf: (name, _i, err) => [
				`RETRY AGGREGATE PLATFORM ${name}`,
				``,
				`A previous platform synthesis was rejected:`,
				`${err.message}`,
				``,
				`Regenerate the complete platform synthesis JSON from the same component`,
				`summaries and analyzer inventory (platform must be exactly ${JSON.stringify(name)}).`,
				...disciplineLines(),
				...platformContractLines(name),
			].join("\n"),
		});
	}

	const artifact = {
		platform,
		stages,
		analyzed: summaries.length,
		expected: items.length,
		complete: runGenerate ? summaries.length === items.length : true,
		components: items.map((item) => item.key),
		notes,
		results: summaries,
		platformSummary,
		inventory,
		summary: runGenerate
			? `${summaries.length}/${items.length} components analyzed (${platform})`
			: `analyze-only: ${items.length} component(s) validated (${platform})`,
	};
	writeArtifact(wf, artifact);
	if (platformSummary) {
		fs.writeFileSync(safeJoin(wf.runDir, "PLATFORM.md"), renderPlatformDoc(platformSummary, artifact));
		fs.mkdirSync(archDir, { recursive: true });
		fs.writeFileSync(safeJoin(archDir, "PLATFORM.md"), renderPlatformDoc(platformSummary, artifact));
	}
	if (runGenerate && !artifact.complete) {
		throw new Error(`arch-context: incomplete — ${summaries.length}/${items.length} components analyzed`);
	}
	return artifact;
}
