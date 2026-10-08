export const meta = {
  name: 'roadmap-draft',
  description: "The product roadmap in the roadmap skill's format: River prioritizes the PRD's requirements into three tiers with a why-now and a success signal each, plus the OKR table; Quinn sequences them with dependencies and writes ROADMAP.md with a dated revision-history entry; a checker validates it. With ROADMAP.md present it runs in update mode: Section 1 rewritten, a new revision entry prepended. Normally launched by /ck:roadmap, which mints the run directory and owns the review, with an object: runId, runDir, projectRoot, pluginRoot, timestamp, inputs (absolute paths of docs/PRD.md and, when they exist, docs/opportunity.md, docs/market-research.md, docs/TEAM.md), outputPath (optional; default <projectRoot>/ROADMAP.md), startAt (optional: prioritize | sequence | validate). A direct /ck:roadmap-draft works too, with everything defaulted to the current project and no run record.",
  phases: [
    { title: 'Prioritize', detail: 'ck:river writes the current-state snapshot, the three tiers with a success signal each, and the OKR table' },
    { title: 'Sequence', detail: 'ck:quinn orders the work with dependencies and writes ROADMAP.md with a dated revision-history entry' },
    { title: 'Validate', detail: 'one neutral Haiku agent checks the roadmap contract; ck:quinn revises at most once' },
  ],
  personas: ['river', 'quinn'],
}

// Direct invocation (/ck:roadmap-draft) needs no arguments; a skill may pass an object. Paths default to
// the project the session is in, and without a plugin root the contract is loaded by skill name.
const a = (args && typeof args === 'object') ? args : {}
const projectRoot = a.projectRoot || '.'
const runDir = a.runDir || (projectRoot + '/.ck/runs/roadmap-latest')
const runId = a.runId || 'roadmap-direct'
const stamp = a.timestamp || 'today (write the date from `date -u`)'
const outPath = a.outputPath || (projectRoot + '/ROADMAP.md')
const inputs = Array.isArray(a.inputs) && a.inputs.length
  ? a.inputs
  : [projectRoot + '/docs/PRD.md (required)', 'and whichever of ' + projectRoot + '/docs/opportunity.md, ' + projectRoot + '/docs/market-research.md, and ' + projectRoot + '/docs/TEAM.md exist']
const contractStep = a.pluginRoot
  ? 'Read ' + a.pluginRoot + '/skills/roadmap-artifact/SKILL.md (the roadmap contract).'
  : 'Load the skill ck:roadmap-artifact with the Skill tool (the roadmap contract).'
const housekeeping = a.runDir ? '' : 'If ' + projectRoot + '/.git exists, run this with the Bash tool so the run cache stays out of git status: grep -qxF ".ck/" ' + projectRoot + '/.git/info/exclude 2>/dev/null || echo ".ck/" >> ' + projectRoot + '/.git/info/exclude . If it is refused, skip it and never mention it in a document. '
const ONE_WRITE = 'Write the whole file with one Write call; do not build it with piecemeal edits, and do not re-read, edit, count, or check it after writing: return as soon as it is written, because a checker runs next and names anything unmet. '
const SMALLEST_EDITS = 'Make the smallest edits that satisfy each listed item, with the Edit tool on the passages concerned, in at most ten Edit calls; where the item is length, cut whole paragraphs of repetition until the document is at least five percent under the cap, so one revision settles it. Do not rewrite the document, do not re-read files you were not asked to read, do not run web searches, and do not count, grep, or check the result: the checker runs again next. If an item needs a source you do not have, mark the claim unverified instead of inventing one. '
const VALIDATOR_MODEL = 'claude-haiku-4-5-20251001'

const ORDER = ['prioritize', 'sequence', 'validate']
const startAt = ORDER.includes(a.startAt) ? a.startAt : 'prioritize'
const runs = stage => ORDER.indexOf(stage) >= ORDER.indexOf(startAt)
if (startAt !== 'prioritize') log(`roadmap: starting at ${startAt}; ${runDir} holds the earlier stages' files`)

const ROW = (props, req) => ({ type: 'object', properties: props, required: req })
const PRIORITIES_SCHEMA = {
  type: 'object',
  properties: {
    product: { type: 'string' },
    stopReason: { type: 'string' },
    existingRoadmap: { type: 'boolean' },
    snapshot: { type: 'string' },
    tier1: { type: 'array', items: ROW({ opportunity: { type: 'string' }, whyNow: { type: 'string' }, successSignal: { type: 'string' }, requirement: { type: 'string' } }, ['opportunity', 'whyNow', 'successSignal', 'requirement']) },
    tier2: { type: 'array', items: ROW({ opportunity: { type: 'string' }, userNeed: { type: 'string' }, assumptions: { type: 'string' } }, ['opportunity', 'userNeed', 'assumptions']) },
    tier3: { type: 'array', items: ROW({ opportunity: { type: 'string' }, strategicValue: { type: 'string' }, whyNotNow: { type: 'string' } }, ['opportunity', 'strategicValue', 'whyNotNow']) },
    okrs: { type: 'array', items: ROW({ keyResult: { type: 'string' }, target: { type: 'string' }, current: { type: 'string' } }, ['keyResult', 'target', 'current']) },
    openQuestions: { type: 'array', items: { type: 'string' } },
  },
  // stopReason is optional on purpose: a required string gets filled, and a filled one would stop good priorities.
  required: ['product', 'existingRoadmap', 'snapshot', 'tier1', 'tier2', 'tier3', 'okrs', 'openQuestions'],
}

const DOC_SCHEMA = {
  type: 'object',
  properties: {
    path: { type: 'string' },
    mode: { type: 'string', enum: ['create', 'update'] },
    tier1: { type: 'number' },
    tier2: { type: 'number' },
    tier3: { type: 'number' },
    okrs: { type: 'number' },
    revisionTitle: { type: 'string' },
  },
  required: ['path', 'mode', 'tier1', 'tier2', 'tier3', 'okrs', 'revisionTitle'],
}

const VALIDATION_SCHEMA = {
  type: 'object',
  properties: {
    valid: { type: 'boolean' },
    missing: { type: 'array', items: { type: 'string' } },
    notes: { type: 'string' },
  },
  required: ['valid', 'missing', 'notes'],
}

// ---- Prioritize ----
let priorities = null
if (runs('prioritize')) {
  phase('Prioritize')
  priorities = await agent(
    `The project repository is ${projectRoot}. ` + housekeeping +
    `Read the product documents: ${inputs.join(', ')}. If docs/PRD.md does not exist, do not prioritize: return ` +
    `empty lists and set stopReason to "Run /ck:prd first. It writes docs/PRD.md, the requirements the roadmap ` +
    `orders." That is the only case with a stopReason; when you prioritize, leave the field out, and put no ` +
    `summary or note in it. Say whether ${outPath} already exists (existingRoadmap) and, if it does, read it so the ` +
    `snapshot reflects what shipped since its last entry.\n` +
    `Length first: the roadmap is capped at 2,500 words in all, so be brief everywhere; the snapshot is one short paragraph of five sentences at most, and openQuestions points to the PRD's open questions by number ("PRD open question 3") instead of restating them, writing out only the questions the roadmap itself raises.\n` +
    `Write the current-state snapshot (one paragraph: what exists today, what is in flight, what is blocked). ` +
    `Then the opportunities, from the PRD's numbered requirements and the other documents, in three tiers: ` +
    `Tier 1, ship next, each with why now, a measurable success signal, and the PRD requirement number it ` +
    `traces to; Tier 2, high value for the next sprint, each with the user need and the assumptions to ` +
    `validate; Tier 3, strategic or longer horizon, each with the strategic value and why not now. Then the ` +
    `OKR table: at least one key result with a target and its current value. Apply your Required Behaviors ` +
    `in subagent form: the smaller first version is Tier 1, and anything you would have asked goes under ` +
    `openQuestions with your assumption. Write the object as JSON to ${runDir}/priorities.json (create the ` +
    `directory if needed) and return it.`,
    { label: 'river:prioritize', phase: 'Prioritize', agentType: 'ck:river', effort: 'medium', schema: PRIORITIES_SCHEMA },
  )
  if (!priorities) throw new Error('roadmap: River returned no priorities')
  // The tiers decide whether to stop; stopReason only words the stop. Text beside a filled tier is a note.
  const note = (priorities.stopReason || '').trim()
  if (!(priorities.tier1.length + priorities.tier2.length + priorities.tier3.length)) throw new Error('roadmap: ' + (note || 'River found nothing to prioritize. If docs/PRD.md does not exist, run /ck:prd first; it writes the requirements the roadmap orders.'))
  if (note) log(`prioritize: River left a note beside the tiers, which does not stop the run: ${note}`)
  log(`prioritize: ${priorities.product}; tiers ${priorities.tier1.length}/${priorities.tier2.length}/${priorities.tier3.length}, ${priorities.okrs.length} key result(s); ${priorities.existingRoadmap ? 'update' : 'create'} mode`)
}

// ---- Sequence ----
let doc = null
if (runs('sequence')) {
  phase('Sequence')
  doc = await agent(
    `The project repository is ${projectRoot}. Read ${runDir}/priorities.json and the product documents: ` +
    `${inputs.join(', ')}. ${contractStep} It carries the exact skeleton of ROADMAP.md, including the dashes ` +
    `in its headings, which are not prose.\n` +
    `Length first: under 2,500 words in all; carry the priorities' wording, do not expand it, and keep Open Questions to pointers at the PRD's numbered questions plus the roadmap's own.\n` +
    `Write ${outPath} to that skeleton. ` + ONE_WRITE +
    `Section 1 (everything above Revision History): the snapshot and the three tier tables from the ` +
    `priorities, each tier with the skeleton's columns; Recommended Sequencing as an ordered list that places ` +
    `every Tier 1 item, names its dependencies, and says what each step unblocks; Open Questions; the OKR ` +
    `table. Section 2 (Revision History): one new entry dated ${stamp} with every subsection (What Changed, ` +
    `Why, Open Questions Resolved / Added, Change Types with the boxes that apply ticked, Triggered By). If ` +
    `${outPath} already exists, keep its existing revision-history entries below the new one, unchanged, and ` +
    `set mode to update; otherwise mode is create. Apply your Required Behaviors in subagent form.\n` +
    `Return only the object: path must be '${outPath}'; tier1, tier2, tier3, and okrs are row counts; ` +
    `revisionTitle is the new entry's title. Do not repeat the document in the return value.`,
    { label: 'quinn:sequence', phase: 'Sequence', agentType: 'ck:quinn', effort: 'medium', schema: DOC_SCHEMA },
  )
  if (!doc) throw new Error('roadmap: Quinn returned nothing for the roadmap; the priorities are at ' + runDir + '/priorities.json')
  log(`sequence: ${doc.mode}; tiers ${doc.tier1}/${doc.tier2}/${doc.tier3}; "${doc.revisionTitle}"`)
}

// ---- Validate ----
let validation = null
if (runs('validate')) {
  phase('Validate')
  validation = await agent(
    `${contractStep} With the Bash tool, count the words of ${outPath} (wc -w < ${outPath}) and put the number in notes; never judge ` +
    `length by impression. The contract caps it at 2,500; a count at or over the cap is an unmet item that quotes the count. ` +
    `Then read ${outPath} and ${projectRoot}/docs/PRD.md. Check the roadmap against every numbered ` +
    `item in the contract's checklist and against the skeleton's heading order, including that every Tier 1 ` +
    `row traces to a numbered PRD requirement and that the newest revision-history entry is dated ${stamp}. ` +
    `Return valid=true only if every item holds. For each unmet item, one line in missing that quotes the ` +
    `checklist item and says what is absent or wrong. House-style item: the document never states the total size of the persona roster (a count of a subset, such as the seats on one tier, is fine); an occurrence is an unmet item that quotes it. Judge the shape, not the priorities.`,
    { label: 'validate', phase: 'Validate', model: VALIDATOR_MODEL, effort: 'low', schema: VALIDATION_SCHEMA },
  )
  if (validation && !validation.valid) {
    log(`validate: ${validation.missing.length} unmet item(s); Quinn revises once`)
    const revised = await agent(
      `${contractStep} Read ${outPath} and ${runDir}/priorities.json. A checker found these unmet checklist ` +
      `items:\n` + validation.missing.map(m => '- ' + m).join('\n') + '\n' +
      `Revise ${outPath} so each item holds, keeping the existing revision-history entries. ` + SMALLEST_EDITS +
      `Return only the updated object; path must be '${outPath}'.`,
      { label: 'quinn:revise', phase: 'Validate', agentType: 'ck:quinn', effort: 'medium', schema: DOC_SCHEMA },
    )
    if (revised) doc = revised
    else log('validate: revision returned nothing; keeping the first roadmap')
  } else if (!validation) {
    log('validate: validator returned nothing; proceeding unvalidated')
  } else {
    log('validate: roadmap passes the contract checklist')
  }
}

return {
  runId,
  startedAt: startAt,
  path: doc ? doc.path : outPath,
  mode: doc ? doc.mode : null,
  tiers: doc ? [doc.tier1, doc.tier2, doc.tier3] : null,
  openQuestions: priorities ? priorities.openQuestions : [],
  validation,
  generated: stamp,
}
