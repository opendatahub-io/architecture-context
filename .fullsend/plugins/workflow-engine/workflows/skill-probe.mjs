/**
 * skill-probe.mjs — demonstrates "/skill:name args" agent prompts: pi
 * expands the skill into the child's user message before the child model
 * runs, so wf.agent("/skill:...") composes skills into fan-out work.
 */
const Echo = {
	type: "object",
	properties: { echo: { type: "string" } },
	required: ["echo"],
	additionalProperties: false,
};

export default async function run(wf) {
	const result = await wf.agent("/skill:classifier classify alpha", { label: "skill-echo", schema: Echo });
	return { echo: result.echo, summary: "skill expansion captured" };
}
