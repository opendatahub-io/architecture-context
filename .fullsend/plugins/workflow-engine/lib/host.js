/**
 * WorkflowHost — the agent()/parallel()/pipeline() surface for workflow
 * modules, in the shape of Claude Code's Workflow API but with the
 * contracts the binary-analysis campaign showed matter:
 *
 *  - agent() results are schema-validated (TypeBox) and journaled to disk
 *    before use — a failed validation is a loud error, never a silently
 *    dropped or hallucinated item;
 *  - the journal is a plain JSONL file with content-addressed keys, so
 *    replay/resume is inspectable rather than engine magic;
 *  - parallel()/pipeline() are bounded-concurrency code, not LLM decisions;
 *  - the host runs in Node with the full stdlib — cardinality checks,
 *    file reads and hashing are ordinary code, no sandbox constraints.
 */

import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { Value } from "typebox/value";
import { Type } from "typebox";

const CHILD_TIMEOUT_MS = 120000;

export function createHost(options) {
	const { runDir, childModel, childArgs, childEnv, childSessionDir, usageSink, onUpdate } = options;
	const journalPath = path.join(runDir, "journal.jsonl");

	function journalKey(prompt, opts) {
		return createHash("sha256")
			.update([childModel(opts?.model), opts?.label ?? "", prompt].join("\0"))
			.digest("hex")
			.slice(0, 16);
	}

	function journalRead() {
		try {
			return new Map(
				fs
					.readFileSync(journalPath, "utf8")
					.split("\n")
					.filter(Boolean)
					.map((line) => {
						const entry = JSON.parse(line);
						return [entry.key, entry.result];
					}),
			);
		} catch {
			return new Map();
		}
	}

	function journalWrite(key, prompt, result) {
		fs.mkdirSync(path.dirname(journalPath), { recursive: true });
		fs.appendFileSync(journalPath, JSON.stringify({ key, prompt, result }) + "\n");
	}

	/** One child agent call: dispatch, parse, validate, journal, record usage. */
	async function agent(prompt, opts = {}) {
		const model = opts.model || (typeof childModel === "function" ? childModel() : childModel);
		// Per-agent cwd: the child is a real process, so its working
		// directory is a spawn option. Falls back to the run dir when the
		// requested directory does not exist (e.g. a scripted clone that
		// reports paths without materializing checkouts).
		const cwd = opts.cwd && fs.existsSync(opts.cwd) ? opts.cwd : runDir;
		const key = journalKey(prompt, opts);
		const journal = journalRead();
		if (opts.replay !== false && journal.has(key)) {
			return journal.get(key);
		}
		const sessionDir = childSessionDir(opts.label || key);
		fs.mkdirSync(sessionDir, { recursive: true });
		const child = spawn("pi", [...childArgs(model, sessionDir), prompt], {
			env: childEnv(),
			cwd,
			stdio: ["ignore", "pipe", "pipe"],
		});
		let stdout = "";
		let stderr = "";
		child.stderr.on("data", (d) => (stderr += d));
		// Incremental line parse: forward child text deltas to the parent's
		// tool_execution_update events (pi's native partial-result channel)
		// as they stream, while still buffering everything for the final
		// authoritative parse.
		let lineBuf = "";
		child.stdout.on("data", (d) => {
			stdout += d;
			lineBuf += d;
			const lines = lineBuf.split("\n");
			lineBuf = lines.pop();
			for (const line of lines) {
				const trimmed = line.trim();
				if (!trimmed.startsWith("{")) continue;
				let evt;
				try {
					evt = JSON.parse(trimmed);
				} catch {
					continue;
				}
				const upd = evt.type === "message_update" && evt.assistantMessageEvent?.type === "text_delta" ? evt.assistantMessageEvent.delta : null;
				if (upd !== null && onUpdate) {
					onUpdate({
						content: [{ type: "text", text: `[${opts.label || key}] ${String(upd).slice(0, 200)}` }],
						details: { agent: opts.label || key, delta: String(upd).slice(0, 200) },
					});
				}
			}
		});
		const timer = setTimeout(() => child.kill("SIGKILL"), opts.timeoutMs || CHILD_TIMEOUT_MS);
		const code = await new Promise((resolve) => child.on("close", (c) => { clearTimeout(timer); resolve(c); }));
		const usage = usageFrom(stdout);
		usageSink(usage);
		if (code !== 0) {
			throw new Error(`agent(${opts.label || prompt.slice(0, 40)}): child exit ${code}: ${stderr.slice(0, 200)}`);
		}
		const { text, settled } = parseChild(stdout);
		if (!settled) throw new Error(`agent(${opts.label}): child stream did not settle`);
		if (!text) throw new Error(`agent(${opts.label}): child produced no assistant text`);
		let parsed;
		try {
			parsed = JSON.parse(text);
		} catch (err) {
			throw new Error(`agent(${opts.label}): output not valid JSON (${err.message}): ${text.slice(0, 200)}`);
		}
		if (opts.schema && !Value.Check(opts.schema, parsed)) {
			const errors = [...Value.Errors(opts.schema, parsed)].map((e) => `${e.path}: ${e.message}`).join("; ");
			throw new Error(`agent(${opts.label}): schema validation failed — ${errors}`);
		}
		journalWrite(key, prompt, parsed);
		return parsed;
	}

	/** Bounded-concurrency fan-out over thunks; positional results.
	 * Fail-stop: once a thunk rejects, workers claim no NEW items (an
	 * in-flight call completes and its usage is recorded), so the usage
	 * written at rejection time is not silently under-counted by later
	 * spawns. The first rejection still propagates via Promise.all. */
	async function parallel(thunks, opts = {}) {
		const limit = Math.max(1, opts.concurrency || 2);
		const results = new Array(thunks.length);
		let next = 0;
		let failed = false;
		await Promise.all(
			Array.from({ length: Math.min(limit, thunks.length) }, async () => {
				while (!failed && next < thunks.length) {
					const i = next++;
					try {
						results[i] = await thunks[i]();
					} catch (err) {
						failed = true;
						throw err;
					}
				}
			}),
		);
		return results;
	}

	/** Per-item stage chains: stage(value, item, index); null skips the rest. */
	async function pipeline(items, stages, opts = {}) {
		return parallel(
			items.map((item) => async () => {
				let value = item;
				for (const stage of stages) {
					if (value === null || value === undefined) return null;
					value = await stage(value, item);
				}
				return value;
			}),
			opts,
		);
	}

	return { agent, parallel, pipeline, runDir, Type };
}

function usageFrom(out) {
	let input = 0;
	let output = 0;
	let cacheRead = 0;
	let cacheWrite = 0;
	let cost = 0;
	for (const line of out.split("\n")) {
		const trimmed = line.trim();
		if (!trimmed.startsWith("{")) continue;
		let evt;
		try {
			evt = JSON.parse(trimmed);
		} catch {
			continue;
		}
		if (evt.type === "message_end" && evt.message?.role === "assistant" && evt.message.usage) {
			const u = evt.message.usage;
			input += u.input || 0;
			output += u.output || 0;
			cacheRead += u.cacheRead || 0;
			cacheWrite += u.cacheWrite || 0;
			cost += u.cost?.total ?? 0;
		}
	}
	return { input, output, cacheRead, cacheWrite, cost };
}

function parseChild(out) {
	let text = null;
	let settled = false;
	for (const line of out.split("\n")) {
		const trimmed = line.trim();
		if (!trimmed.startsWith("{")) continue;
		let evt;
		try {
			evt = JSON.parse(trimmed);
		} catch {
			continue;
		}
		if (evt.type === "message_end" && evt.message?.role === "assistant") {
			const t = (evt.message.content || [])
				.map((b) => (b?.type === "text" ? b.text : ""))
				.filter(Boolean)
				.join("\n");
			if (t) text = t;
		}
		if (evt.type === "agent_settled") settled = true;
	}
	return { text, settled };
}
