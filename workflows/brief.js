export const meta = {
  name: 'brief',
  description: 'Toni runs a basic market pass (three to five comparable products, sourced), River writes docs/brief.md from one line of idea text to the brief contract, and a checker validates the shape. Args: runId, runDir (absolute cache directory), projectRoot (absolute path of the project repository), pluginRoot, timestamp, idea (text; may be empty when opportunityPath is given), opportunityPath (optional; absolute), marketResearchPath (optional; absolute), briefPath (optional; default <projectRoot>/docs/brief.md).',
  phases: [
    { title: 'Market pass', detail: 'ck:toni finds three to five comparable products with a source each, reading market research and the opportunity first when they exist' },
    { title: 'Draft', detail: 'ck:river writes the brief: problem and root-cause chain, user, success metric, comparable products, scope with a smaller first version, non-goals, open questions' },
    { title: 'Validate', detail: 'one neutral Haiku agent checks the brief contract; ck:river revises at most once' },
  ],
  personas: ['toni', 'river'],
}

if (!args || !args.runId || !args.runDir || !args.projectRoot || !args.pluginRoot || !args.timestamp) {
  throw new Error('brief: args.runId, args.runDir, args.projectRoot, args.pluginRoot, and args.timestamp are required')
}
if (!args.idea && !args.opportunityPath) {
  throw new Error('brief: give an idea in a sentence, or run /ck:opportunity first so the brief can start from docs/opportunity.md')
}
const projectRoot = args.projectRoot
const briefPath = args.briefPath || (projectRoot + '/docs/brief.md')
const contract = args.pluginRoot + '/skills/brief-artifact/SKILL.md'
const stamp = args.timestamp
const runDir = args.runDir
const existing = [args.opportunityPath, args.marketResearchPath].filter(Boolean)
const ideaText = args.idea || 'Take the idea from the concept statement in ' + args.opportunityPath
const VALIDATOR_MODEL = 'claude-haiku-4-5-20251001'
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

const BRIEF_SCHEMA = {
  type: 'object',
  properties: {
    briefPath: { type: 'string' },
    title: { type: 'string' },
    rootCauseChain: { type: 'array', items: { type: 'string' } },
    user: { type: 'string' },
    successMetric: { type: 'string' },
    leadingIndicator: { type: 'string' },
    comparables: { type: 'number' },
    v0: {
      type: 'object',
      properties: {
        scope: { type: 'string' },
        cuts: { type: 'array', items: { type: 'string' } },
        recommendation: { type: 'string' },
      },
      required: ['scope', 'cuts', 'recommendation'],
    },
    nonGoals: { type: 'array', items: { type: 'string' } },
    openQuestions: { type: 'array', items: { type: 'string' } },
  },
  required: ['briefPath', 'title', 'rootCauseChain', 'user', 'successMetric', 'leadingIndicator', 'comparables', 'v0', 'nonGoals', 'openQuestions'],
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
  (existing.length
    ? `Read these first and search only for what they lack: ${existing.join(', ')}. List what you read in readFirst.\n`
    : `There is no market research or opportunity analysis yet; readFirst is empty.\n`) +
  `Find three to five comparable products: for each, in one paragraph of at most sixty words, what it does, ` +
  `who it is for, its price or business model, the gap this idea would fill, and one source URL. Add one ` +
  `paragraph on how crowded the space is. ` +
  `Use web search; record how many searches you ran. Write the object as JSON to ${runDir}/market.json and return it.`,
  { label: 'toni:market', phase: 'Market pass', agentType: 'ck:toni', schema: MARKET_SCHEMA },
)
if (!market) log('market pass: Toni returned nothing; the brief will say the comparable-products section is pending')
else log(`market pass: ${market.comparables.length} comparable(s), ${market.searchesRun} search(es)`)

// ---- Draft ----
phase('Draft')
let brief = await agent(
  `The author's idea, in their own words: ${ideaText}\n` +
  (existing.length ? `Also read: ${existing.join(', ')}.\n` : '') +
  `Read ${contract}. It is the brief contract: section order, required fields, and the checklist your brief ` +
  `will be validated against. The sections, in order: ` + SECTIONS.map(s => '"' + s + '"').join(', ') + `.\n` +
  (market
    ? `Comparable products, from Toni's market pass (attribute the section to it and cite its sources):\n` +
      JSON.stringify(market, null, 1) + '\n'
    : `The market pass returned nothing; write the Comparable products section as "pending" and say why.\n`) +
  `Write ${briefPath} to that contract (create the directory if needed). Apply your Required Behaviors in ` +
  `subagent form. Three Whys: do not accept the idea as the problem; write the chain (idea, why, why, why), ` +
  `each step more specific, until the user pain is exposed or the idea is shown to address a symptom, and say ` +
  `which. V0 Challenge: propose a first version that cuts at least half the scope, say what it cuts, and give ` +
  `your recommendation with the decision marked open for the author. Premortem: not yet; it belongs to the PRD.\n` +
  `One primary user. One success number with a target and a date, plus one leading indicator. At least two ` +
  `non-goals. Anything you would have asked the author goes under Open questions for the author, each with ` +
  `the assumption you proceeded on; the list is present even when empty.\n` +
  `Plain words, under 1,200 words in all: this is the short document that governs the long one. ` +
  `Return the brief object; briefPath must be '${briefPath}'; comparables is the count you wrote.`,
  { label: 'river:draft', phase: 'Draft', agentType: 'ck:river', schema: BRIEF_SCHEMA },
)
if (!brief) throw new Error('brief: River returned nothing')
log(`brief: ${brief.rootCauseChain.length} step(s) in the root-cause chain, ${brief.comparables} comparable(s), ${brief.openQuestions.length} open question(s)`)

// ---- Validate ----
phase('Validate')
const validation = await agent(
  `Read ${contract} and ${briefPath}. Check the brief against every numbered item in the contract's ` +
  `checklist and against the section order. Return valid=true only if every item holds. For each unmet item, ` +
  `one line in missing that quotes the checklist item and says what is absent or wrong. Judge the shape, not ` +
  `the idea.`,
  { label: 'validate', phase: 'Validate', model: VALIDATOR_MODEL, effort: 'low', schema: VALIDATION_SCHEMA },
)
if (validation && !validation.valid) {
  log(`validate: ${validation.missing.length} unmet item(s); River revises once`)
  const revised = await agent(
    `Read ${contract} and ${briefPath}. A checker found these unmet checklist items:\n` +
    validation.missing.map(m => '- ' + m).join('\n') + '\n' +
    `Revise ${briefPath} in place so each item holds. Return the updated brief object; briefPath must be '${briefPath}'.`,
    { label: 'river:revise', phase: 'Validate', agentType: 'ck:river', schema: BRIEF_SCHEMA },
  )
  if (revised) brief = revised
  else log('validate: revision returned nothing; keeping the first draft')
} else if (!validation) {
  log('validate: validator returned nothing; proceeding unvalidated')
} else {
  log('validate: brief passes the contract checklist')
}

return {
  runId: args.runId,
  briefPath: brief.briefPath,
  title: brief.title,
  comparables: brief.comparables,
  openQuestions: brief.openQuestions,
  validation,
  generated: stamp,
}
