/**
 * workflow-engine — deterministic workflow engine as a pi provider (POC).
 *
 * Registers provider "workflow-engine" with chat model "v1" (zero cost, no
 * inference) and the "workflow" tool. The provider's streamSimple() emits a
 * fixed two-turn conversation:
 *
 *   turn 1 (last message is the user prompt): parse the work items from the
 *     prompt and emit an assistant message containing one deterministic
 *     `workflow` tool call;
 *   turn 2 (last message is the tool result): emit the final assistant
 *     message summarizing the artifact.
 *
 * The tool's execute() runs the demo pipeline in real code:
 *   Phase A — ingest: validate items, write run state (deterministic run id
 *     from the item hash, directory cleaned per run for idempotency);
 *   Phase B — fan-out: one child `pi --print` session per item, concurrency
 *     2, each on the scripted test-child provider (or a real model when
 *     WORKFLOW_CHILD_MODEL is set); results validated as JSON and written
 *     to disk; one usage-file record per child (fullsend contract shape);
 *   Phase C — aggregate: completeness assertion (every item exactly one
 *     validated result), final artifact, tool result summary.
 *
 * Parent usage is honestly zero: this provider performs no inference.
 */

import { createAssistantMessageEventStream } from "@earendil-works/pi-ai/compat";
import { Type } from "typebox";
import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { createHost } from "./lib/host.js";

const PROVIDER = "workflow-engine";
const MODEL_ID = "v1";
const API = "workflow-engine-stream";
const TOOL_NAME = "workflow";
const TOOL_CALL_ID = "workflow-call-1"; // deterministic across runs
const MAX_CONCURRENT = 2;
const CHILD_TIMEOUT_MS = 120000;

const HERE = path.dirname(fileURLToPath(import.meta.url));
// The scripted child provider ships inside this plugin tree (bundle, not a
// second plugin entry) so the sandbox upload carries it and the relative
// path resolves in both the Phase 1 container and the fullsend sandbox.
const TEST_CHILD_DIR = path.resolve(HERE, "test-child");
// Optional override for Layer 4: "relay/rits/zai-org/glm-5-3" plus
// WORKFLOW_CHILD_MODELS_JSON pointing at a models.json to install for
// children (and WORKFLOW_CHILD_ENV for extra child env, e.g. the relay key).
const CHILD_MODEL = process.env.WORKFLOW_CHILD_MODEL || "test-child/echo";

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

function assistant(content, stopReason, extra = {}) {
	return {
		role: "assistant",
		content,
		api: API,
		provider: PROVIDER,
		model: MODEL_ID,
		usage: zeroUsage(),
		stopReason,
		timestamp: Date.now(),
		...extra,
	};
}

function lastMessage(messages) {
	return messages[messages.length - 1];
}

function toolResultText(message) {
	if (!message || message.role !== "toolResult") return "";
	const parts = Array.isArray(message.content) ? message.content : [message.content];
	return parts
		.map((b) => (b && b.type === "text" ? b.text : ""))
		.filter(Boolean)
		.join("\n");
}

/** Parse the workflow input object: WORKFLOW_INPUT (JSON) first, then
 * WORKFLOW_ITEMS ("a,b,c" -> {items:[...]}), then the Phase 1 prompt form
 * "Run the demo pipeline on: a, b, c". The command comes from
 * WORKFLOW_COMMAND (default "run-demo"). */
function parseInput(messages) {
	const json = process.env.WORKFLOW_INPUT;
	if (json && json.trim()) {
		try {
			const value = JSON.parse(json);
			if (value && typeof value === "object" && !Array.isArray(value)) return value;
		} catch {
			return null;
		}
	}
	const envItems = process.env.WORKFLOW_ITEMS;
	if (envItems && envItems.trim()) {
		const items = envItems.split(",").map((s) => s.trim()).filter(Boolean);
		if (items.length > 0) return { items };
	}
	for (let i = messages.length - 1; i >= 0; i--) {
		const m = messages[i];
		if (m.role !== "user") continue;
		const text = typeof m.content === "string" ? m.content : Array.isArray(m.content) ? m.content.map((b) => (b && b.type === "text" ? b.text : "")).join("\n") : "";
		const match = /on:\s*(.+)$/s.exec(text);
		if (!match) return null;
		const items = match[1].split(",").map((s) => s.trim()).filter(Boolean);
		return items.length > 0 ? { items } : null;
	}
	return null;
}

// ---------------------------------------------------------------------------
// Provider stream
// ---------------------------------------------------------------------------

function streamWorkflowEngine(model, context) {
	const stream = createAssistantMessageEventStream();
	const last = lastMessage(context.messages);

	try {
		if (!last || last.role === "user") {
			// Turn 1: emit the workflow tool call.
			const input = parseInput(context.messages);
			if (!input) {
				const error = assistant([], "error", { errorMessage: 'workflow-engine: no workflow input found (set WORKFLOW_INPUT/WORKFLOW_ITEMS or prompt "Run the demo pipeline on: item1, item2, ...")' });
				stream.push({ type: "error", reason: "error", error });
				stream.end();
				return stream;
			}
			const command = process.env.WORKFLOW_COMMAND || "run-demo";
			const toolCall = {
				type: "toolCall",
				id: TOOL_CALL_ID,
				name: TOOL_NAME,
				arguments: { command, input },
			};
			const final = assistant([toolCall], "toolUse");
			const emptyCall = { type: "toolCall", id: TOOL_CALL_ID, name: TOOL_NAME, arguments: {} };
			stream.push({ type: "start", partial: assistant([], "pending") });
			stream.push({ type: "toolcall_start", contentIndex: 0, partial: assistant([emptyCall], "pending") });
			stream.push({ type: "toolcall_end", contentIndex: 0, toolCall, partial: assistant([toolCall], "pending") });
			stream.push({ type: "done", reason: "toolUse", message: final });
			stream.end();
			return stream;
		}

		if (last.role === "toolResult") {
			// Turn 2: final message derived deterministically from the tool result.
			const result = toolResultText(last);
			const text = `Demo pipeline finished. ${result}`;
			const final = assistant([{ type: "text", text }], "stop");
			stream.push({ type: "start", partial: assistant([], "pending") });
			stream.push({ type: "text_start", contentIndex: 0, partial: assistant([{ type: "text", text: "" }], "pending") });
			stream.push({ type: "text_delta", contentIndex: 0, delta: text, partial: assistant([{ type: "text", text }], "pending") });
			stream.push({ type: "text_end", contentIndex: 0, content: text, partial: final });
			stream.push({ type: "done", reason: "stop", message: final });
			stream.end();
			return stream;
		}

		const error = assistant([], "error", { errorMessage: `workflow-engine: unexpected last message role ${last ? last.role : "none"}` });
		stream.push({ type: "error", reason: "error", error });
		stream.end();
		return stream;
	} catch (err) {
		const error = assistant([], "error", { errorMessage: `workflow-engine: ${err && err.message ? err.message : String(err)}` });
		stream.push({ type: "error", reason: "error", error });
		stream.end();
		return stream;
	}
}

// ---------------------------------------------------------------------------
// Demo pipeline (runs inside the workflow tool)
// ---------------------------------------------------------------------------

function runIdFor(spec) {
	return createHash("sha256").update(spec).digest("hex").slice(0, 8);
}

function childArgs(model, sessionDir) {
	const args = [
		"--print",
		"--mode",
		"json",
		"--no-approve",
		"--no-extensions",
		"--no-prompt-templates",
		"--no-themes",
		"--session-dir",
		sessionDir,
		"--thinking",
		"off",
	];
	if (model.startsWith("test-child/")) {
		args.push("-e", TEST_CHILD_DIR);
	}
	args.push("--model", model);
	return args;
}

function childEnvFor() {
	// stdin is ignored by the host's spawn; PI_* vars are stripped so a child
	// cannot reach this parent's session server; HOME points at a per-run
	// child home so no host pi state is touched.
	const childHome = path.join(process.cwd(), "workflow-runs", ".child-home");
	const env = { ...process.env, HOME: childHome };
	for (const key of Object.keys(env)) {
		if (key.startsWith("PI_")) delete env[key];
	}
	if (process.env.WORKFLOW_CHILD_MODELS_JSON) {
		const agentDir = path.join(childHome, ".pi", "agent");
		fs.mkdirSync(agentDir, { recursive: true });
		fs.copyFileSync(process.env.WORKFLOW_CHILD_MODELS_JSON, path.join(agentDir, "models.json"));
	}
	// Skills for children: copied into the child agent dir (user-level
	// skills load without project trust), so "/skill:name args" prompts
	// expand in each child. Project .pi/skills would require trust.
	if (process.env.WORKFLOW_CHILD_SKILLS) {
		const skillsDir = path.join(childHome, ".pi", "agent", "skills");
		fs.mkdirSync(skillsDir, { recursive: true });
		fs.cpSync(process.env.WORKFLOW_CHILD_SKILLS, skillsDir, { recursive: true });
	}
	if (process.env.WORKFLOW_CHILD_ENV) {
		for (const pair of process.env.WORKFLOW_CHILD_ENV.split("\n")) {
			const eq = pair.indexOf("=");
			if (eq > 0) env[pair.slice(0, eq)] = pair.slice(eq + 1);
		}
	}
	return env;
}




function recordUsage(runDir, seq, usage) {
	const line = JSON.stringify({
		seq,
		model: CHILD_MODEL,
		usage: {
			input: usage.input || 0,
			output: usage.output || 0,
			cacheRead: usage.cacheRead || 0,
			cacheWrite: usage.cacheWrite || 0,
			cost: usage.cost && typeof usage.cost.total === "number" ? usage.cost.total : 0,
		},
	});
	// Run-dir copy (Phase 1 check script) plus, when running under fullsend,
	// the runner's usage file so foldPiSubagentUsage folds the children into
	// metrics.json (the usage-file contract from pi_subagents.go).
	const targets = [path.join(runDir, "usage.jsonl")];
	const agentDir = process.env.PI_CODING_AGENT_DIR;
	if (agentDir) targets.push(path.join(agentDir, "subagents", "usage.jsonl"));
	for (const target of targets) {
		fs.mkdirSync(path.dirname(target), { recursive: true });
		fs.appendFileSync(target, line + "\n");
	}
}


async function runPipeline(params, onUpdate) {
	const command = params.command;
	// Trust boundary: the command selects a workflow module that is
	// imported into this process. Anything the model can name must not
	// escape the workflows/ directory (path traversal -> arbitrary
	// module import, CWE-22 -> CWE-94).
	if (typeof command !== "string" || !/^[a-z0-9-]+$/.test(command)) {
		return {
			content: [{ type: "text", text: `workflow failed: invalid command ${JSON.stringify(command)} (allowed: lowercase alphanumeric and hyphens)` }],
			isError: true,
			details: { phase: "dispatch" },
		};
	}
	const workflowPath = path.resolve(HERE, "workflows", `${command.replace(/^run-/, "")}.mjs`);
	const workflowsRoot = path.resolve(HERE, "workflows");
	if (!workflowPath.startsWith(workflowsRoot + path.sep)) {
		return {
			content: [{ type: "text", text: `workflow failed: command ${JSON.stringify(command)} escapes the workflows directory` }],
			isError: true,
			details: { phase: "dispatch" },
		};
	}
	if (!fs.existsSync(workflowPath)) {
		return {
			content: [{ type: "text", text: `workflow failed: no workflow module for command ${JSON.stringify(command)}` }],
			isError: true,
			details: { phase: "dispatch" },
		};
	}
	const input = params.input && typeof params.input === "object" ? params.input : {};
	const runId = runIdFor(command + "\n" + JSON.stringify(input));
	const runDir = path.join(process.cwd(), "workflow-runs", runId);
	// P5 durable resume: with WORKFLOW_KEEP_RUNS set, an existing runDir
	// for the same command+input hash is NOT wiped — the host's journal
	// (content-addressed, per-runDir) then replays completed children
	// instead of re-spawning them. Killed mid-fan-out, a re-run pays only
	// for the uncompleted children.
	if (!process.env.WORKFLOW_KEEP_RUNS) {
		fs.rmSync(runDir, { recursive: true, force: true });
	}
	fs.mkdirSync(runDir, { recursive: true });

	// Usage records are written in item order after the run so the file is
	// byte-deterministic regardless of child completion order.
	const usageRecords = [];
	const host = createHost({
		runDir,
		childModel: (m) => m || CHILD_MODEL,
		childArgs: (model, sessionDir) => childArgs(model, sessionDir),
		childEnv: childEnvFor,
		childSessionDir: (label) => path.join(runDir, "child-sessions", `agent-${String(label).replace(/[^a-zA-Z0-9_-]/g, "_")}`),
		usageSink: (usage) => usageRecords.push(usage),
		onUpdate,
	});

	const { default: workflow } = await import(pathToFileURL(workflowPath).href);
	let artifact;
	try {
		artifact = await workflow(host, input);
	} catch (err) {
		// Record usage even on failure: partial spend is real spend.
		for (let i = 0; i < usageRecords.length; i++) recordUsage(runDir, i + 1, usageRecords[i]);
		return {
			content: [{ type: "text", text: `workflow failed: ${err.message}; see ${runDir}` }],
			isError: true,
			details: { runDir, runId, error: err.message },
		};
	}
	for (let i = 0; i < usageRecords.length; i++) recordUsage(runDir, i + 1, usageRecords[i]);
	return {
		content: [{ type: "text", text: `workflow complete: ${artifact.summary || command}; artifact at ${path.join(runDir, "artifact.json")}` }],
		details: { runDir, runId, ...artifact },
	};
}

// ---------------------------------------------------------------------------
// Extension entry
// ---------------------------------------------------------------------------

export default function (pi) {
	pi.registerProvider(PROVIDER, {
		// baseUrl is required by the registration form but never contacted:
		// streamSimple below is fully local and performs no HTTP.
		baseUrl: "http://127.0.0.1:9",
		api: API,
		// Placeholder credential: streamSimple performs no HTTP, so no real key exists.
		apiKey: "local-no-inference",
		models: [
			{
				id: MODEL_ID,
				name: "Workflow Engine v1 (deterministic, no inference)",
				reasoning: false,
				input: ["text"],
				cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
				contextWindow: 1000000,
				maxTokens: 8192,
			},
		],
		streamSimple: streamWorkflowEngine,
	});

	pi.registerTool({
		name: TOOL_NAME,
		label: "Workflow",
		description: "Run the deterministic demo workflow pipeline (ingest, fan-out child agents, aggregate)",
		promptSnippet: "Runs the demo workflow pipeline when the user asks to run it on a list of items.",
		promptGuidelines: ["Use the workflow tool when the user asks to run the demo pipeline on items."],
		parameters: Type.Object({
			command: Type.String({ description: "Workflow command to run (selects workflows/<name>.mjs)" }),
			input: Type.Any({ description: "Workflow input object" }),
		}),
		async execute(_toolCallId, params, _signal, onUpdate) {
			return runPipeline(params, onUpdate);
		},
	});
}
