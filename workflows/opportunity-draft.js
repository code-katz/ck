export const meta = {
  name: 'opportunity-draft',
  description: 'Opportunity analysis: River frames the idea and chooses up to four contributing lenses from the roster (Toni and Akira always, a domain seat such as Reiner for a game or Jordan for a data product, Sage optionally); each contributor writes its own sourced section in parallel; River assembles docs/opportunity.md to the opportunity contract; a checker validates it. Type /ck:opportunity followed by the idea in a sentence. A skill may instead pass an object: runId, runDir (absolute cache directory), projectRoot (absolute path of the project repository), pluginRoot, timestamp, idea, inputs (absolute paths of docs/TEAM.md and docs/market-research.md when they exist), outputPath (optional; default <projectRoot>/docs/opportunity.md), startAt (optional: frame | sections | assemble | validate).',
  phases: [
    { title: 'Frame', detail: 'ck:river writes the concept and hypothesis, chooses the contributors with a reason each, and briefs each one' },
    { title: 'Sections', detail: 'up to four contributors in parallel, each on its own tier, each writing its sourced section' },
    { title: 'Assemble', detail: 'ck:river writes docs/opportunity.md: summary, concept, market context, the lens sections, stage gates, monetization, risks, open questions, sources' },
    { title: 'Validate', detail: 'one neutral Haiku agent checks the opportunity contract; ck:river revises at most twice' },
  ],
  personas: ['river', 'toni', 'akira', 'sage', 'reiner', 'jordan', 'kai', 'morgan', 'cornelius', 'casey'],
}

// Direct invocation (/ck:opportunity <idea>) hands the typed text to the script as a string; a skill
// launch passes an object. Both are accepted. Paths default to the project the session is in, and
// without a plugin root the contract and the roster are loaded by skill name instead of by path.
const a = (args && typeof args === 'object') ? args : { idea: typeof args === 'string' ? args.trim() : '' }
if (!a.idea) {
  throw new Error('opportunity: type the idea after the command, for example /ck:opportunity A two-player card game set in the 1944 Ardennes that plays in under an hour.')
}
const projectRoot = a.projectRoot || '.'
const runDir = a.runDir || (projectRoot + '/.ck/runs/opportunity-latest')
const runId = a.runId || 'opportunity-direct'
const stamp = a.timestamp || 'today (write the date from `date -u`)'
const outPath = a.outputPath || (projectRoot + '/docs/opportunity.md')
const inputs = Array.isArray(a.inputs) ? a.inputs : []
const contractStep = a.pluginRoot
  ? 'Read ' + a.pluginRoot + '/skills/opportunity-artifact/SKILL.md (the opportunity contract).'
  : 'Load the skill ck:opportunity-artifact with the Skill tool (the opportunity contract).'
const rosterStep = a.pluginRoot
  ? 'Read the roster: ' + a.pluginRoot + '/profiles/ROSTER.md (one line per persona: name, role, tier, domain).'
  : 'Load the skill ck:roster with the Skill tool (the roster: one line per persona with name, role, tier, domain).'
const housekeeping = a.runDir ? '' : 'If ' + projectRoot + '/.git exists, run this with the Bash tool so the run cache stays out of git status: grep -qxF ".ck/" ' + projectRoot + '/.git/info/exclude 2>/dev/null || echo ".ck/" >> ' + projectRoot + '/.git/info/exclude . If it is refused, skip it and never mention it in a document. '
const ONE_WRITE = 'Write the whole file with one Write call; do not build it with piecemeal edits, and do not re-read, edit, count, or check it after writing: return as soon as it is written, because a checker runs next and names anything unmet. '
const SMALLEST_EDITS = 'Make the smallest edits that satisfy each listed item, with the Edit tool on the passages concerned, in at most ten Edit calls; where the item is length, cut whole sentences and paragraphs of repetition rather than trimming words. Do not rewrite the document, do not re-read files you were not asked to read, do not run web searches, and do not count, grep, or check the result: the checker runs again next. If an item needs a source you do not have, mark the claim unverified instead of inventing one. '
const MAX_CONTRIBUTORS = 4
const MAX_REVISIONS = 2
const VALIDATOR_MODEL = 'claude-haiku-4-5-20251001'
// The fixed sections of the contract. The lens sections go between Market context and Stage gates.
const SECTIONS = ['Executive summary', 'Concept statement', 'Problem and root-cause chain', 'Market context', 'Stage gates', 'Monetization and business model', 'Risks', 'Open questions', 'Sources']

const ORDER = ['frame', 'sections', 'assemble', 'validate']
const startAt = ORDER.includes(a.startAt) ? a.startAt : 'frame'
const runs = stage => ORDER.indexOf(stage) >= ORDER.indexOf(startAt)
if (startAt !== 'frame') log(`opportunity: starting at ${startAt}; ${runDir} holds the earlier stages' files`)

const FRAME_SCHEMA = {
  type: 'object',
  properties: {
    productKind: { type: 'string' },
    concept: { type: 'string' },
    hypothesis: { type: 'string' },
    contributors: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          persona: { type: 'string' },
          lens: { type: 'string' },
          title: { type: 'string' },
          why: { type: 'string' },
          questions: { type: 'array', items: { type: 'string' } },
        },
        required: ['persona', 'lens', 'title', 'why', 'questions'],
      },
    },
  },
  required: ['productKind', 'concept', 'hypothesis', 'contributors'],
}

const SECTION_SCHEMA = {
  type: 'object',
  properties: {
    persona: { type: 'string' },
    path: { type: 'string' },
    heading: { type: 'string' },
    sources: { type: 'number' },
    questions: { type: 'array', items: { type: 'string' } },
  },
  required: ['persona', 'path', 'heading', 'sources', 'questions'],
}

const DOC_SCHEMA = {
  type: 'object',
  properties: {
    path: { type: 'string' },
    verdict: { type: 'string', enum: ['worth-doing', 'worth-doing-smaller', 'not-now'] },
    decidingNumber: { type: 'string' },
    stageGates: { type: 'number' },
    risks: { type: 'number' },
    sources: { type: 'number' },
    openQuestions: { type: 'array', items: { type: 'string' } },
  },
  required: ['path', 'verdict', 'decidingNumber', 'stageGates', 'risks', 'sources', 'openQuestions'],
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

// ---- Frame ----
let frame = null
if (runs('frame')) {
  phase('Frame')
  frame = await agent(
    `The author's idea, in their own words: ${a.idea}\n` +
    `The project repository is ${projectRoot}. ` + housekeeping +
    (inputs.length ? `Read these first: ${inputs.join(', ')}. ` : '') +
    `${rosterStep}\n` +
    `Say what kind of product this is in one line (productKind). Write the concept statement (what it is and ` +
    `for whom, two sentences) and the hypothesis (what would have to be true for it to be worth doing).\n` +
    `Choose the contributing lenses, at most ${MAX_CONTRIBUTORS}, from the roster: toni (marketing: market ` +
    `context, positioning, and a go-to-market sketch) and akira (architecture: technical shape) always; one ` +
    `domain seat for the product's kind (reiner for a game, jordan for a data product, cornelius for a ` +
    `historical setting, kai for a design-led product, and so on); sage (business: model and stage economics) ` +
    `when the domain seat is not sage and a fourth seat earns its place. If docs/TEAM.md is among the inputs, ` +
    `prefer its cast. For each contributor: lens (one word), a section title, why this persona, and the three ` +
    `to five questions its section must answer.\n` +
    `Write the object as JSON to ${runDir}/frame.json (create the directory if needed) and return it.`,
    { label: 'river:frame', phase: 'Frame', agentType: 'ck:river', schema: FRAME_SCHEMA },
  )
  if (!frame) throw new Error('opportunity: River returned no frame')
  frame.contributors = frame.contributors.slice(0, MAX_CONTRIBUTORS)
  log(`frame: ${frame.productKind}; contributors ${frame.contributors.map(c => c.persona + ' (' + c.lens + ')').join(', ')}`)
}

// ---- Sections ----
let sections = []
if (runs('sections')) {
  phase('Sections')
  const contributors = frame ? frame.contributors : null
  if (!contributors) throw new Error('opportunity: cannot start at sections without the frame; start at frame')
  sections = (await parallel(contributors.map(c => () => agent(
    `You are ${c.persona}, the ${c.lens} lens on the opportunity analysis for: ${frame.concept}\n` +
    `Hypothesis: ${frame.hypothesis}\n` +
    `The project repository is ${projectRoot}. ` + (inputs.length ? `Read these first: ${inputs.join(', ')}. ` : '') +
    `Read ${runDir}/frame.json for the full frame.\n` +
    `Write your section to ${runDir}/sections/${c.persona}.md (create the directory if needed). ` + ONE_WRITE +
    `It starts with the heading "## ${c.lens.charAt(0).toUpperCase() + c.lens.slice(1)}: ${c.title}" and answers ` +
    `these questions in order: ${c.questions.map((q, i) => (i + 1) + '. ' + q).join(' ')}\n` +
    `Every claim about the world (market size, competitors, prices, platform rules, history) carries a source: ` +
    `use web search, cite the URL inline as [n] with a Sources list at the end of your section, and record the ` +
    `count. Apply your Required Behaviors in subagent form. End with your Handoff Brief. At most 600 words ` +
    `before your Sources list. Return the object; path must be '${runDir}/sections/${c.persona}.md'.`,
    { label: `${c.lens}:${c.persona}`, phase: 'Sections', agentType: 'ck:' + c.persona, effort: 'high', schema: SECTION_SCHEMA },
  )))).filter(Boolean)
  const missing = contributors.filter(c => !sections.some(s => s.persona === c.persona)).map(c => c.persona)
  if (!sections.length) throw new Error('opportunity: every contributor was stopped or failed')
  if (missing.length) log(`sections: ${missing.join(', ')} returned nothing; the document says so`)
  log(`sections: ${sections.length} written, ${sections.reduce((n, s) => n + s.sources, 0)} source(s)`)
}

// ---- Assemble ----
let doc = null
if (runs('assemble')) {
  phase('Assemble')
  const sectionList = sections.length
    ? sections.map(s => s.path + ' (' + s.heading + ')').join(', ')
    : `every file under ${runDir}/sections/ (written by the earlier run of this workflow)`
  doc = await agent(
    `The author's idea: ${a.idea}\n` +
    `The project repository is ${projectRoot}. Read ${runDir}/frame.json and the contributors' sections: ${sectionList}. ` +
    (inputs.length ? `Also read: ${inputs.join(', ')}. ` : '') +
    `${contractStep} It gives the section order, required fields, and the checklist your document will be ` +
    `validated against.\n` +
    `Write ${outPath} to that contract (create the directory if needed). ` + ONE_WRITE +
    `The fixed sections, in order: ` + SECTIONS.map(s => '"' + s + '"').join(', ') + `. The contributors' ` +
    `sections go between Market context and Stage gates, each included verbatim under its own heading with ` +
    `its Handoff Brief; renumber their inline source markers so every source appears once in the final ` +
    `Sources list. Market context draws on Toni's section and names its sources. Apply your Required ` +
    `Behaviors in subagent form: the root-cause chain under Problem (idea, why, why, why, ending at a root ` +
    `cause or a symptom, saying which); a smaller first version under Executive summary when the verdict is ` +
    `worth-doing-smaller; the premortem belongs to the review, not here. At least three stage gates, each with ` +
    `what must be true to proceed and the kill condition. Every risk with a mitigation or an explicit ` +
    `acceptance. Open questions present even when empty, each with the assumption you proceeded on. Date the ` +
    `document ${stamp}. Under 4,000 words before Sources.\n` +
    `Return only the object: path must be '${outPath}'; verdict, the deciding number, counts of stage gates, ` +
    `risks, and sources, and the open questions one line each. Do not repeat the document in the return value.`,
    { label: 'river:assemble', phase: 'Assemble', agentType: 'ck:river', effort: 'medium', schema: DOC_SCHEMA },
  )
  if (!doc) throw new Error('opportunity: River returned nothing for the assembly; the sections are under ' + runDir + '/sections/')
  log(`assemble: ${doc.verdict}; ${doc.stageGates} stage gate(s), ${doc.risks} risk(s), ${doc.sources} source(s), ${doc.openQuestions.length} open question(s)`)
}

// ---- Validate ----
let validation = null
if (runs('validate')) {
  phase('Validate')
  for (let round = 1; round <= MAX_REVISIONS + 1; round++) {
    validation = await agent(
      `${contractStep} Read ${outPath} and list the files under ${runDir}/sections/. Check the document ` +
      `against every numbered item in the contract's checklist and against the section order, including that ` +
      `every contributor's section file appears in the document under its heading. Return valid=true only if ` +
      `every item holds. For each unmet item, one line in missing that quotes the checklist item and says what ` +
      `is absent or wrong. Judge the shape, not the idea.`,
      { label: `validate:${round}`, phase: 'Validate', model: VALIDATOR_MODEL, effort: 'low', schema: VALIDATION_SCHEMA },
    )
    if (!validation) { log('validate: validator returned nothing; proceeding unvalidated'); break }
    if (validation.valid) { log(`validate: document passes the contract checklist (round ${round})`); break }
    if (round > MAX_REVISIONS) { log(`validate: still unmet after ${MAX_REVISIONS} revision(s): ${validation.missing.join(' | ')}`); break }
    log(`validate: ${validation.missing.length} unmet item(s); River revises (revision ${round} of ${MAX_REVISIONS})`)
    const revised = await agent(
      `${contractStep} Read ${outPath}. A checker found these unmet ` +
      `checklist items:\n` + validation.missing.map(m => '- ' + m).join('\n') + '\n' +
      `Revise ${outPath} so each item holds. ` + SMALLEST_EDITS + `Return only the updated object; path must be '${outPath}'.`,
      { label: `river:revise:${round}`, phase: 'Validate', agentType: 'ck:river', effort: 'medium', schema: DOC_SCHEMA },
    )
    if (!revised) { log('validate: revision returned nothing; keeping the previous document'); break }
    doc = revised
  }
}

return {
  runId,
  startedAt: startAt,
  path: doc ? doc.path : outPath,
  verdict: doc ? doc.verdict : null,
  decidingNumber: doc ? doc.decidingNumber : null,
  contributors: frame ? frame.contributors.map(c => c.persona) : sections.map(s => s.persona),
  openQuestions: doc ? doc.openQuestions : [],
  validation,
  generated: stamp,
}
