export const meta = {
  name: 'brief-draft',
  description: 'Toni runs a basic market pass (three to five comparable products, sourced), River writes docs/brief.md from one line of idea text to the brief contract, and a checker validates the shape, with River revising at most twice. Normally launched by /ck:brief, which mints the run directory and owns the review, with an object: runId, runDir (absolute cache directory), projectRoot (absolute path of the project repository), pluginRoot, timestamp, idea, opportunityPath (optional; absolute), marketResearchPath (optional; absolute), briefPath (optional; default <projectRoot>/docs/brief.md). A direct /ck:brief-draft <idea> works too, with everything defaulted to the current project and no run record.',
  phases: [
    { title: 'Market pass', detail: 'ck:toni finds three to five comparable products with a source each, reading market research and the opportunity first when they exist' },
    { title: 'Draft', detail: 'ck:river writes the brief: problem and root-cause chain, user, success metric, comparable products, scope with a smaller first version, non-goals, open questions' },
    { title: 'Validate', detail: 'one neutral Haiku agent checks the brief contract, word count first; ck:river revises at most twice, and the checker runs again after each revision' },
  ],
  personas: ['toni', 'river'],
}

// Direct invocation (/ck:brief-draft <idea>) hands the typed text to the script as a string; a skill
// launch passes an object. Both are accepted. Paths default to the project the session is in,
// and without a plugin root the contract is loaded by skill name instead of by path.
const a = (args && typeof args === 'object') ? args : { idea: typeof args === 'string' ? args.trim() : '' }
if (!a.idea && !a.opportunityPath) {
  throw new Error('brief: type the idea after the command, for example /ck:brief An app that reminds you to water each plant on its own schedule. Or run /ck:opportunity first so the brief can start from docs/opportunity.md.')
}
const projectRoot = a.projectRoot || '.'
const runDir = a.runDir || (projectRoot + '/.ck/runs/brief-latest')
const runId = a.runId || 'brief-direct'
const stamp = a.timestamp || 'today (write the date from `date -u`)'
const briefPath = a.briefPath || (projectRoot + '/docs/brief.md')
const contractStep = a.pluginRoot
  ? 'Read ' + a.pluginRoot + '/skills/brief-artifact/SKILL.md (the brief contract).'
  : 'Load the skill ck:brief-artifact with the Skill tool (the brief contract).'
const housekeeping = a.runDir ? '' : 'If ' + projectRoot + '/.git exists, run this with the Bash tool so the run cache stays out of git status: grep -qxF ".ck/" ' + projectRoot + '/.git/info/exclude 2>/dev/null || echo ".ck/" >> ' + projectRoot + '/.git/info/exclude . If it is refused, skip it and never mention it in a document. '
// A direct launch (/ck:brief-draft <idea>) cannot check the disk, so it names the documents a project may already have
// and lets the agents read the ones that exist; a skill launch passes the paths that exist.
const existing = a.runDir
  ? [a.opportunityPath, a.marketResearchPath].filter(Boolean)
  : [projectRoot + '/docs/opportunity.md (if it exists)', projectRoot + '/docs/market-research.md (if it exists)']
const ideaText = a.idea || 'Take the idea from the concept statement in ' + a.opportunityPath
const VALIDATOR_MODEL = 'claude-haiku-4-5-20251001'
const MAX_REVISIONS = 2
const WORD_CAP = 1200
const WORD_TARGET = 1000
const SECTIONS = ['Idea', 'Problem and root-cause chain', 'User', 'Success metric and leading indicator', 'Comparable products', 'Scope', 'Non-goals', 'Open questions for the author']

const MARKET_SCHEMA = {
  type: 'object',
  properties: {
    comparables: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          name: { type: 'string' }, what: { type: 'string' }, who: { type: 'string' },
          price: { type: 'string' }, gap: { type: 'string' }, source: { type: 'string' },
        },
        required: ['name', 'what', 'who', 'price', 'gap', 'source'],
      },
    },
    crowding: { type: 'string' },
    readFirst: { type: 'array', items: { type: 'string' } },
    searchesRun: { type: 'number' },
  },
  required: ['comparables', 'crowding', 'readFirst', 'searchesRun'],
}

// The brief is on disk; the return value carries only what the closing message needs, so the
// author is not paid twice for the same words.
const BRIEF_SCHEMA = {
  type: 'object',
  properties: {
    briefPath: { type: 'string' },
    title: { type: 'string' },
    chainSteps: { type: 'number' },
    comparables: { type: 'number' },
    nonGoals: { type: 'number' },
    openQuestions: { type: 'array', items: { type: 'string' } },
  },
  required: ['briefPath', 'title', 'chainSteps', 'comparables', 'nonGoals', 'openQuestions'],
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

// ---- Market pass ----
phase('Market pass')
const market = await agent(
  `The idea, in the author's words: ${ideaText}\n` +
  housekeeping +
  (existing.length
    ? `Read these first and search only for what they lack: ${existing.join(', ')}. List what you read in readFirst.\n`
    : `There is no market research or opportunity analysis yet; readFirst is empty.\n`) +
  `Find three to five comparable products: for each, in one paragraph of at most sixty words, what it does, ` +
  `who it is for, its price or business model, the gap this idea would fill, and one source URL. Add one ` +
  `paragraph on how crowded the space is. ` +
  `Use web search; record how many searches you ran. Write the object as JSON to ${runDir}/market.json (create the directory if needed) and return it.`,
  { label: 'toni:market', phase: 'Market pass', agentType: 'ck:toni', schema: MARKET_SCHEMA },
)
if (!market) log('market pass: Toni returned nothing; the brief will say the comparable-products section is pending')
else log(`market pass: ${market.comparables.length} comparable(s), ${market.searchesRun} search(es)`)

// ---- Draft ----
phase('Draft')
let brief = await agent(
  `The author's idea, in their own words: ${ideaText}\n` +
  `Length first: write about ${WORD_TARGET} words in all and never more than ${WORD_CAP}, which is the contract's cap; this is the short document that governs the long one, and a draft over the cap is sent back for a trim.\n` +
  (existing.length ? `Also read: ${existing.join(', ')}.\n` : '') +
  `${contractStep} It gives the section order, required fields, and the checklist your brief ` +
  `will be validated against. The sections, in order: ` + SECTIONS.map(s => '"' + s + '"').join(', ') + `.\n` +
  (market
    ? `Comparable products, from Toni's market pass (attribute the section to it and cite its sources):\n` +
      JSON.stringify(market, null, 1) + '\n'
    : `The market pass returned nothing; write the Comparable products section as "pending" and say why.\n`) +
  `Write ${briefPath} to that contract (create the directory if needed). Write the whole file with one Write call; do not build it with piecemeal edits, and do not re-read, edit, count, or check it after writing: return as soon as it is written, because a checker runs next and names anything unmet. Apply your Required Behaviors in ` +
  `subagent form. Three Whys: do not accept the idea as the problem; write the chain (idea, why, why, why), ` +
  `each step more specific, until the user pain is exposed or the idea is shown to address a symptom, and say ` +
  `which. V0 Challenge: propose a first version that cuts at least half the scope, say what it cuts, and give ` +
  `your recommendation with the decision marked open for the author. Premortem: not yet; it belongs to the PRD.\n` +
  `One primary user. One success number with a target and a date, plus one leading indicator. At least two ` +
  `non-goals. Anything you would have asked the author goes under Open questions for the author, each with ` +
  `the assumption you proceeded on; the list is present even when empty. Date the document ${stamp}.\n` +
  `Plain words. ` +
  `Return only the brief object: briefPath must be '${briefPath}'; chainSteps, comparables, and nonGoals are ` +
  `counts of what you wrote; openQuestions is the list of open questions, one line each. Do not repeat the ` +
  `document in the return value.`,
  { label: 'river:draft', phase: 'Draft', agentType: 'ck:river', effort: 'medium', schema: BRIEF_SCHEMA },
)
if (!brief) throw new Error('brief: River returned nothing')
log(`brief: ${brief.chainSteps} step(s) in the root-cause chain, ${brief.comparables} comparable(s), ${brief.openQuestions.length} open question(s)`)

// ---- Validate ----
phase('Validate')
let validation = null
for (let round = 1; round <= MAX_REVISIONS + 1; round++) {
  validation = await agent(
    `${contractStep} First count the words with the Bash tool: wc -w < ${briefPath} ; the contract caps the brief at ${WORD_CAP} words, and a count over the cap is an unmet item that quotes the count. Then read ${briefPath} and check it against every numbered item in the contract's ` +
    `checklist and against the section order. Return valid=true only if every item holds. For each unmet item, ` +
    `one line in missing that quotes the checklist item and says what is absent or wrong. Judge the shape, not ` +
    `the idea. ` +
      `House-style item: the document never states the total size of the persona roster (a count of a subset, such as the seats on one tier, is fine); an occurrence is an unmet item that quotes it. `,
    { label: `validate:${round}`, phase: 'Validate', model: VALIDATOR_MODEL, effort: 'low', schema: VALIDATION_SCHEMA },
  )
  if (!validation) { log('validate: validator returned nothing; proceeding unvalidated'); break }
  if (validation.valid) { log(`validate: brief passes the contract checklist (round ${round})`); break }
  if (round > MAX_REVISIONS) { log(`validate: still unmet after ${MAX_REVISIONS} revision(s): ${validation.missing.join(' | ')}`); break }
  log(`validate: ${validation.missing.length} unmet item(s); River revises (revision ${round} of ${MAX_REVISIONS})`)
  const revised = await agent(
    `${contractStep} Read ${briefPath}. A checker found these unmet checklist items:\n` +
    validation.missing.map(m => '- ' + m).join('\n') + '\n' +
    `Revise ${briefPath} so each item holds. Make the smallest edits that satisfy each listed item, with the Edit tool on the passages concerned, in at most ten Edit calls; where the item is length, cut whole paragraphs of repetition until the document is at least five percent under the cap, so one revision settles it. Do not rewrite the document, do not re-read files you were not asked to read, do not run web searches, and do not count, grep, or check the result: the checker runs again next. If an item needs a source you do not have, mark the claim unverified instead of inventing one. Return only the updated brief object (counts and open questions); briefPath must be '${briefPath}'.`,
    { label: `river:revise:${round}`, phase: 'Validate', agentType: 'ck:river', effort: 'medium', schema: BRIEF_SCHEMA },
  )
  if (!revised) { log('validate: revision returned nothing; keeping the previous document'); break }
  brief = revised
}

return {
  runId,
  briefPath: brief.briefPath,
  title: brief.title,
  comparables: brief.comparables,
  openQuestions: brief.openQuestions,
  validation,
  generated: stamp,
}
