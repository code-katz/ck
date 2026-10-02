export const meta = {
  name: 'market-research',
  description: 'Market research as a fan-out: Toni plans four to six questions across market size and trends, competitors, customers and channels, pricing, and constraints; neutral researchers answer them in parallel from the web with a source per claim; a cross-check marks unsourced claims and contradictions; Toni writes docs/market-research.md to the market research contract; a checker validates it. Type /ck:market-research, optionally followed by a focus in a sentence; with no focus the questions come from docs/opportunity.md or docs/brief.md. A skill may instead pass an object: runId, runDir, projectRoot, pluginRoot, timestamp, focus, inputs (absolute paths of docs/opportunity.md and docs/brief.md when they exist), outputPath (optional; default <projectRoot>/docs/market-research.md), startAt (optional: plan | research | crosscheck | write | validate).',
  phases: [
    { title: 'Plan', detail: 'ck:toni writes four to six research questions, each with what a good answer contains' },
    { title: 'Research', detail: 'one neutral Sonnet 5 researcher per question, in parallel, with web search; a source per claim' },
    { title: 'Cross-check', detail: 'one neutral agent: every claim sourced or marked unverified; contradictions listed with both sources; stale sources flagged' },
    { title: 'Write', detail: 'ck:toni writes docs/market-research.md to the contract' },
    { title: 'Validate', detail: 'one neutral Haiku agent checks the contract; ck:toni revises at most once' },
  ],
  personas: ['toni'],
}

// Direct invocation (/ck:market-research [focus]) hands the typed text to the script as a string;
// a skill launch passes an object. Both are accepted. Paths default to the project the session is
// in, and without a plugin root the contract is loaded by skill name instead of by path.
const a = (args && typeof args === 'object') ? args : { focus: typeof args === 'string' ? args.trim() : '' }
const projectRoot = a.projectRoot || '.'
const runDir = a.runDir || (projectRoot + '/.ck/runs/market-research-latest')
const runId = a.runId || 'market-research-direct'
const stamp = a.timestamp || 'today (write the date from `date -u`)'
const outPath = a.outputPath || (projectRoot + '/docs/market-research.md')
const focus = a.focus || ''
const inputs = Array.isArray(a.inputs) && a.inputs.length
  ? a.inputs
  : ['whichever of ' + projectRoot + '/docs/opportunity.md and ' + projectRoot + '/docs/brief.md exist']
const contractStep = a.pluginRoot
  ? 'Read ' + a.pluginRoot + '/skills/market-research-artifact/SKILL.md (the market research contract).'
  : 'Load the skill ck:market-research-artifact with the Skill tool (the market research contract).'
const housekeeping = a.runDir ? '' : 'If ' + projectRoot + '/.git exists, run this with the Bash tool so the run cache stays out of git status: grep -qxF ".ck/" ' + projectRoot + '/.git/info/exclude 2>/dev/null || echo ".ck/" >> ' + projectRoot + '/.git/info/exclude . If it is refused, skip it and never mention it in a document. '
const ONE_WRITE = 'Write the whole file with one Write call; do not build it with piecemeal edits, and do not re-read it after writing. '
const SMALLEST_EDITS = 'Make the smallest edits that satisfy each listed item, with the Edit tool on the passages concerned; do not rewrite the document, do not re-read files you were not asked to read, and do not run web searches. If an item needs a source you do not have, mark the claim unverified instead of inventing one. '
const RESEARCH_MODEL = 'claude-sonnet-5'
const VALIDATOR_MODEL = 'claude-haiku-4-5-20251001'
const MIN_QUESTIONS = 4
const MAX_QUESTIONS = 6
const SECTIONS = ['Summary', 'Market size and trends', 'Competitors and substitutes', 'Customers, segments, and channels', 'Pricing and business models', 'Constraints', 'Contradictions and unknowns', 'Implications for positioning', 'Sources']

const ORDER = ['plan', 'research', 'crosscheck', 'write', 'validate']
const startAt = ORDER.includes(a.startAt) ? a.startAt : 'plan'
const runs = stage => ORDER.indexOf(stage) >= ORDER.indexOf(startAt)
if (startAt !== 'plan') log(`market-research: starting at ${startAt}; ${runDir} holds the earlier stages' files`)

const PLAN_SCHEMA = {
  type: 'object',
  properties: {
    product: { type: 'string' },
    inputsRead: { type: 'array', items: { type: 'string' } },
    stopReason: { type: 'string' },
    questions: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'number' },
          area: { type: 'string', enum: ['market-size-and-trends', 'competitors-and-substitutes', 'customers-and-channels', 'pricing-and-business-models', 'constraints'] },
          question: { type: 'string' },
          goodAnswer: { type: 'string' },
        },
        required: ['id', 'area', 'question', 'goodAnswer'],
      },
    },
  },
  required: ['product', 'inputsRead', 'stopReason', 'questions'],
}

const FINDINGS_SCHEMA = {
  type: 'object',
  properties: {
    questionId: { type: 'number' },
    path: { type: 'string' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          claim: { type: 'string' },
          source: { type: 'string' },
          sourceDate: { type: 'string' },
          confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
        },
        required: ['claim', 'source', 'sourceDate', 'confidence'],
      },
    },
    contradictions: { type: 'array', items: { type: 'string' } },
    couldNotFind: { type: 'array', items: { type: 'string' } },
    searchesRun: { type: 'number' },
  },
  required: ['questionId', 'path', 'findings', 'contradictions', 'couldNotFind', 'searchesRun'],
}

const CROSSCHECK_SCHEMA = {
  type: 'object',
  properties: {
    path: { type: 'string' },
    claimsChecked: { type: 'number' },
    unverified: { type: 'array', items: { type: 'string' } },
    contradictions: {
      type: 'array',
      items: {
        type: 'object',
        properties: { topic: { type: 'string' }, claimA: { type: 'string' }, sourceA: { type: 'string' }, claimB: { type: 'string' }, sourceB: { type: 'string' } },
        required: ['topic', 'claimA', 'sourceA', 'claimB', 'sourceB'],
      },
    },
    stale: { type: 'array', items: { type: 'string' } },
  },
  required: ['path', 'claimsChecked', 'unverified', 'contradictions', 'stale'],
}

const DOC_SCHEMA = {
  type: 'object',
  properties: {
    path: { type: 'string' },
    findings: { type: 'number' },
    competitors: { type: 'number' },
    sources: { type: 'number' },
    unknowns: { type: 'number' },
  },
  required: ['path', 'findings', 'competitors', 'sources', 'unknowns'],
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

// ---- Plan ----
let plan = null
if (runs('plan')) {
  phase('Plan')
  plan = await agent(
    `The project repository is ${projectRoot}. ` + housekeeping +
    (focus ? `The author's focus for this research: ${focus}\n` : 'The author gave no focus.\n') +
    `Read the product documents: ${inputs.join(', ')}. List what you read in inputsRead. If there is no focus ` +
    `and neither docs/opportunity.md nor docs/brief.md exists, do not plan: set stopReason to one sentence ` +
    `naming what to run first (/ck:opportunity or /ck:brief) and return an empty questions list.\n` +
    `Otherwise say what the product is in one line (product) and write ${MIN_QUESTIONS} to ${MAX_QUESTIONS} ` +
    `research questions covering at least four of the five areas: market size and trends; competitors and ` +
    `substitutes; customers, segments, and channels; pricing and business models; platform, legal, or ` +
    `regulatory constraints. For each: a numbered id, the area, the question, and what a good answer contains ` +
    `(the numbers, names, or facts it must have). Write the object as JSON to ${runDir}/plan.json (create the ` +
    `directory if needed) and return it.`,
    { label: 'toni:plan', phase: 'Plan', agentType: 'ck:toni', effort: 'medium', schema: PLAN_SCHEMA },
  )
  if (!plan) throw new Error('market-research: Toni returned no plan')
  if (plan.stopReason) throw new Error('market-research: ' + plan.stopReason)
  plan.questions = plan.questions.slice(0, MAX_QUESTIONS)
  if (plan.questions.length < MIN_QUESTIONS) log(`plan: only ${plan.questions.length} question(s); the contract asks for ${MIN_QUESTIONS} to ${MAX_QUESTIONS}`)
  log(`plan: ${plan.product}; ${plan.questions.length} question(s) across ${new Set(plan.questions.map(q => q.area)).size} area(s)`)
}

// ---- Research ----
let research = []
if (runs('research')) {
  phase('Research')
  if (!plan) throw new Error('market-research: cannot start at research without the plan; start at plan')
  research = (await parallel(plan.questions.map(q => () => agent(
    `Research question ${q.id} (${q.area}) about ${plan.product}: ${q.question}\n` +
    `A good answer contains: ${q.goodAnswer}\n` +
    `Use web search. Return findings, each one claim with its source URL, the source's date, and your ` +
    `confidence; contradictions you noticed between sources; what you could not find; and how many searches ` +
    `you ran. Prefer primary sources and sources under 18 months old; say when you had to use older ones. ` +
    `Write the object as JSON to ${runDir}/research/${q.id}.json (create the directory if needed) and return ` +
    `it with questionId ${q.id} and path '${runDir}/research/${q.id}.json'.`,
    { label: `research:${q.id}:${q.area}`, phase: 'Research', model: RESEARCH_MODEL, effort: 'medium', schema: FINDINGS_SCHEMA },
  )))).filter(Boolean)
  const missing = plan.questions.filter(q => !research.some(r => r.questionId === q.id)).map(q => q.id)
  if (!research.length) throw new Error('market-research: every researcher was stopped or failed')
  if (missing.length) log(`research: question(s) ${missing.join(', ')} returned nothing; the document says so`)
  log(`research: ${research.reduce((n, r) => n + r.findings.length, 0)} finding(s) from ${research.reduce((n, r) => n + r.searchesRun, 0)} search(es)`)
}

// ---- Cross-check ----
let crosscheck = null
if (runs('crosscheck')) {
  phase('Cross-check')
  crosscheck = await agent(
    `Read ${runDir}/plan.json and every file under ${runDir}/research/. Check the findings: every claim must ` +
    `carry a source URL, else list it under unverified; where two researchers' claims conflict, list the ` +
    `topic with both claims and both sources; flag sources older than 18 months as stale (list the claim and ` +
    `the date). Count the claims you checked. Write the object as JSON to ${runDir}/crosscheck.json and return ` +
    `it with path '${runDir}/crosscheck.json'.`,
    { label: 'crosscheck', phase: 'Cross-check', model: RESEARCH_MODEL, effort: 'medium', schema: CROSSCHECK_SCHEMA },
  )
  if (!crosscheck) log('crosscheck: returned nothing; Toni writes from the research files alone')
  else log(`crosscheck: ${crosscheck.claimsChecked} claim(s) checked, ${crosscheck.unverified.length} unverified, ${crosscheck.contradictions.length} contradiction(s), ${crosscheck.stale.length} stale`)
}

// ---- Write ----
let doc = null
if (runs('write')) {
  phase('Write')
  doc = await agent(
    `The project repository is ${projectRoot}. Read ${runDir}/plan.json, every file under ${runDir}/research/, ` +
    `and ${runDir}/crosscheck.json if it exists: read each of those once, in that order, and nothing else; do not ` +
    `re-read any of them and do not search the web, the research is done. ${contractStep} It gives the section order, required fields, ` +
    `and the checklist your document will be validated against. The sections, in order: ` +
    SECTIONS.map(s => '"' + s + '"').join(', ') + `.\n` +
    `Write ${outPath} to that contract (create the directory if needed). ` + ONE_WRITE +
    `Summary has exactly five findings that change a decision, one sentence each. Every claim in the body ` +
    `carries a source number [n] that appears in Sources (URL, title, date accessed), or is marked unverified. ` +
    `The competitors table has at least three rows. Contradictions and unknowns lists the cross-check's ` +
    `contradictions with both sources, the unverified claims, and what could not be found; it is present even ` +
    `when empty. Mark any source older than 18 months as historical. Date the document ${stamp}. Under 2,500 ` +
    `words before Sources.\n` +
    `Return only the object: path must be '${outPath}'; findings, competitors, sources, and unknowns are counts ` +
    `of what you wrote. Do not repeat the document in the return value.`,
    { label: 'toni:write', phase: 'Write', agentType: 'ck:toni', effort: 'medium', schema: DOC_SCHEMA },
  )
  if (!doc) throw new Error('market-research: Toni returned nothing for the document; the research is under ' + runDir)
  log(`write: ${doc.findings} finding(s), ${doc.competitors} competitor(s), ${doc.sources} source(s), ${doc.unknowns} unknown(s)`)
}

// ---- Validate ----
let validation = null
if (runs('validate')) {
  phase('Validate')
  validation = await agent(
    `${contractStep} Read ${outPath}. Check the document against every numbered item in the contract's ` +
    `checklist and against the section order. Return valid=true only if every item holds. For each unmet ` +
    `item, one line in missing that quotes the checklist item and says what is absent or wrong. Judge the ` +
    `shape, not the market.`,
    { label: 'validate', phase: 'Validate', model: VALIDATOR_MODEL, effort: 'low', schema: VALIDATION_SCHEMA },
  )
  if (validation && !validation.valid) {
    log(`validate: ${validation.missing.length} unmet item(s); Toni revises once`)
    const revised = await agent(
      `${contractStep} Read ${outPath}. A checker found these unmet ` +
      `checklist items:\n` + validation.missing.map(m => '- ' + m).join('\n') + '\n' +
      `Revise ${outPath} so each item holds. ` + SMALLEST_EDITS + `Return only the updated object; path must be '${outPath}'.`,
      { label: 'toni:revise', phase: 'Validate', agentType: 'ck:toni', effort: 'medium', schema: DOC_SCHEMA },
    )
    if (revised) doc = revised
    else log('validate: revision returned nothing; keeping the first document')
  } else if (!validation) {
    log('validate: validator returned nothing; proceeding unvalidated')
  } else {
    log('validate: document passes the contract checklist')
  }
}

return {
  runId,
  startedAt: startAt,
  path: doc ? doc.path : outPath,
  questions: plan ? plan.questions.length : null,
  findings: doc ? doc.findings : null,
  sources: doc ? doc.sources : null,
  contradictions: crosscheck ? crosscheck.contradictions.length : null,
  validation,
  generated: stamp,
}
