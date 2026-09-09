export const meta = {
  name: 'draft',
  description: "One author drafts a document to its contract, a checker validates it, the three-lens panel challenges it (forming its view before reading the rationale), and the author rewrites it with a Challenged claims appendix and a premortem. Serves the PRD (river; lenses river, toni, kai) and the architecture document (akira; lenses morgan, alex, jordan). Normally launched by /ck:prd or /ck:architecture with an object: artifact ('prd' | 'architecture'), runId, runDir (absolute cache directory), projectRoot (absolute path of the project repository), pluginRoot, timestamp, inputs (absolute paths of the documents to read; the skill lists the ones that exist), outputPath (optional; default from the artifact table), startAt (optional: draft | validate | panel | synthesize; earlier stages are skipped and the document on disk is used), lenses (optional). A direct /ck:draft prd works too, with everything defaulted to the current project.",
  phases: [
    { title: 'Draft', detail: 'the author writes the document from its inputs to the contract; every claim not from the inputs tagged [C<n>]' },
    { title: 'Validate', detail: 'one neutral Haiku agent checks the contract checklist; the author revises at most twice' },
    { title: 'Panel', detail: 'nested /ck:panel on the draft, three lenses on three models, each reading its own evidence' },
    { title: 'Synthesize', detail: 'the author rewrites the document: revised body, Appendix A Challenged claims, Appendix B Premortem' },
  ],
  personas: ['river', 'toni', 'kai', 'akira', 'morgan', 'alex', 'jordan'],
}

const ARTIFACTS = {
  prd: {
    author: 'river',
    path: 'docs/PRD.md',
    contract: 'skills/prd-artifact/SKILL.md',
    rationale: 'docs/brief.md',
    sections: ['Summary', 'Problem', 'User', 'Success metric and leading indicator', 'Scope', 'Non-goals', 'Requirements', 'Sequencing and dependencies', 'Assumptions', 'Risks', 'Open questions', 'Appendix A. Challenged claims', 'Appendix B. Premortem'],
    question: "Is this PRD ready for the author's review, and what would you change before it ships?",
    premortem: 'this shipped on time and did not move the success metric',
    memoSlug: 'prd-review',
    maxWords: 3000,
    lenses: [
      { persona: 'river', lens: 'product', model: 'claude-fable-5-1', reads: ['docs/brief.md', 'docs/opportunity.md', 'ROADMAP.md'] },
      { persona: 'toni', lens: 'marketing', model: 'claude-opus-5', reads: ['docs/market-research.md', 'docs/opportunity.md'] },
      { persona: 'kai', lens: 'ux', model: 'claude-sonnet-5', reads: ['brand/', 'docs/design/'] },
    ],
  },
  architecture: {
    author: 'akira',
    path: 'docs/ARCHITECTURE.md',
    contract: 'skills/architecture-artifact/SKILL.md',
    rationale: 'docs/PRD.md',
    sections: ['Context and constraints', 'Quality attributes', 'Recommended architecture', 'Components', 'Data model sketch', 'Integration points and external dependencies', 'Alternatives considered', 'Decision record', 'Sequencing against the roadmap', 'Risks', 'Open questions', 'Appendix A. Challenged claims', 'Appendix B. Premortem'],
    question: 'Would you build it this way, and what would you change before the first line of code?',
    premortem: 'this shipped and fell over in production in its first month',
    memoSlug: 'architecture-review',
    maxWords: 3000,
    lenses: [
      { persona: 'morgan', lens: 'security', model: 'claude-fable-5-1', reads: ['docs/PRD.md', 'SECURITY.md'] },
      { persona: 'alex', lens: 'platform', model: 'claude-sonnet-5', reads: ['infra/', 'Dockerfile', '.github/workflows/'] },
      { persona: 'jordan', lens: 'data', model: 'claude-opus-5', reads: ['docs/market-research.md', 'data/', 'schema/'] },
    ],
  },
}

// Launched by /ck:prd and /ck:architecture with an object. A direct /ck:draft prd or
// /ck:draft architecture also works: the text names the artifact and everything else defaults.
const a = (args && typeof args === 'object') ? args : { artifact: (typeof args === 'string' && args.trim()) ? args.trim().split(/\s+/)[0] : 'prd' }
if (!a.artifact || !ARTIFACTS[a.artifact]) {
  throw new Error('draft: the artifact must be one of ' + Object.keys(ARTIFACTS).join(', '))
}
const A = ARTIFACTS[a.artifact]
const projectRoot = a.projectRoot || '.'
const runDir = a.runDir || (projectRoot + '/.ck/runs/draft-' + a.artifact + '-latest')
const runId = a.runId || 'draft-' + a.artifact + '-direct'
const stamp = a.timestamp || 'today (write the date from `date -u`)'
const author = 'ck:' + A.author
const outPath = a.outputPath || (projectRoot + '/' + A.path)
const rationalePath = projectRoot + '/' + A.rationale
const contractStep = a.pluginRoot
  ? 'Read ' + a.pluginRoot + '/' + A.contract + ' (the contract).'
  : 'Load the skill ck:' + A.contract.split('/')[1] + ' with the Skill tool (the contract).'
const inputs = Array.isArray(a.inputs) && a.inputs.length ? a.inputs : [rationalePath]
const SECTIONS = A.sections
const MAX_REVISIONS = 2
const VALIDATOR_MODEL = 'claude-haiku-4-5-20251001'

const ORDER = ['draft', 'validate', 'panel', 'synthesize']
const startAt = ORDER.includes(a.startAt) ? a.startAt : 'draft'
const runs = stage => ORDER.indexOf(stage) >= ORDER.indexOf(startAt)
if (startAt !== 'draft') log(`draft: starting at ${startAt}; ${outPath} on disk is the draft`)

const QUESTION = {
  type: 'object',
  properties: { to: { type: 'string' }, question: { type: 'string' } },
  required: ['to', 'question'],
}

const DRAFT_SCHEMA = {
  type: 'object',
  properties: {
    path: { type: 'string' },
    title: { type: 'string' },
    claims: {
      type: 'array',
      items: {
        type: 'object',
        properties: { id: { type: 'string' }, text: { type: 'string' }, section: { type: 'string' } },
        required: ['id', 'text', 'section'],
      },
    },
    assumptions: { type: 'array', items: { type: 'string' } },
    questions: { type: 'array', items: QUESTION },
  },
  required: ['path', 'title', 'claims', 'assumptions', 'questions'],
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

const FINAL_SCHEMA = {
  type: 'object',
  properties: {
    path: { type: 'string' },
    title: { type: 'string' },
    challengedClaims: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          claim: { type: 'string' },
          challengedBy: { type: 'string' },
          severity: { type: 'string', enum: ['blocking', 'major', 'minor'] },
          status: { type: 'string', enum: ['upheld', 'revised', 'withdrawn', 'open'] },
          resolution: { type: 'string' },
        },
        required: ['claim', 'challengedBy', 'severity', 'status', 'resolution'],
      },
    },
    premortem: {
      type: 'object',
      properties: {
        scenario: { type: 'string' },
        exposedAssumption: { type: 'string' },
        question: { type: 'string' },
      },
      required: ['scenario', 'exposedAssumption', 'question'],
    },
    openDecisions: { type: 'array', items: { type: 'string' } },
    summary: { type: 'string' },
  },
  required: ['path', 'title', 'challengedClaims', 'premortem', 'openDecisions', 'summary'],
}

// ---- Draft ----
let draft = null
if (runs('draft')) {
  phase('Draft')
  draft = await agent(
    `The project repository is ${projectRoot}. Read these inputs: ${inputs.join(', ')}. They record what the ` +
    `author already decided; do not re-ask any of it.\n` +
    `${contractStep} It gives the section order, required fields, and the checklist your draft will be ` +
    `validated against.\n` +
    `Write ${outPath} to that contract, all sections in this order (create the directory if needed). Write the whole file with one Write call; do not build it with piecemeal edits, and do not re-read it after writing. ` +
    SECTIONS.map(s => '"' + s + '"').join(', ') + `.\n` +
    `Apply your Required Behaviors in subagent form. Leave Appendix B (the premortem) for the pass after the ` +
    `panel, and say so under its heading.\n` +
    `Tag every claim that is not taken directly from the inputs with an inline marker [C1], [C2], ... so the ` +
    `panel can address it, and list those claims with their section. Put anything you would have asked the ` +
    `author under Open questions, with your assumption. Keep the document under ${A.maxWords} words.\n` +
    `Return the draft object; path must be '${outPath}'.`,
    { label: `${A.author}:draft`, phase: 'Draft', agentType: author, effort: 'medium', schema: DRAFT_SCHEMA },
  )
  if (!draft) throw new Error(`draft: ${A.author} returned nothing for the draft`)
  log(`draft: ${draft.claims.length} tagged claim(s), ${draft.assumptions.length} assumption(s), ${draft.questions.length} open question(s)`)
}

// ---- Validate ----
let validation = null
if (runs('validate')) {
  phase('Validate')
  for (let round = 1; round <= MAX_REVISIONS + 1; round++) {
    validation = await agent(
      `${contractStep} Read ${outPath}. Check the document against every numbered item in the contract's ` +
      `checklist and against the section order. Return valid=true only if every item holds. For each unmet ` +
      `item, one line in missing that quotes the checklist item and says what is absent or wrong. Judge the ` +
      `shape, not the product.`,
      { label: `validate:${round}`, phase: 'Validate', model: VALIDATOR_MODEL, effort: 'low', schema: VALIDATION_SCHEMA },
    )
    if (!validation) { log('validate: validator returned nothing; proceeding unvalidated'); break }
    if (validation.valid) { log(`validate: draft passes the contract checklist (round ${round})`); break }
    if (round > MAX_REVISIONS) {
      log(`validate: still unmet after ${MAX_REVISIONS} revision(s): ${validation.missing.join(' | ')}`)
      break
    }
    log(`validate: ${validation.missing.length} unmet item(s); ${A.author} revises (revision ${round} of ${MAX_REVISIONS})`)
    const revised = await agent(
      `${contractStep} Read the inputs (${inputs.join(', ')}) and ${outPath}. A checker found these unmet ` +
      `checklist items:\n` + validation.missing.map(m => '- ' + m).join('\n') + '\n' +
      `Revise ${outPath} in place so each item holds. Keep every existing [C<n>] tag and add tags for any new ` +
      `claim not from the inputs. Return the updated draft object; path must be '${outPath}'.`,
      { label: `${A.author}:revise:${round}`, phase: 'Validate', agentType: author, schema: DRAFT_SCHEMA },
    )
    if (!revised) { log('validate: revision returned nothing; keeping the previous draft'); break }
    draft = revised
  }
}

// ---- Panel (nested by name; one level only; each lens reads its own evidence and sees the rationale last) ----
let panel = null
if (runs('panel')) {
  phase('Panel')
  const lenses = Array.isArray(a.lenses) && a.lenses.length ? a.lenses : A.lenses
  try {
    panel = await workflow('ck:panel', {
      runId,
      runDir,
      projectRoot,
      pluginRoot: a.pluginRoot,
      timestamp: stamp,
      question: A.question,
      contextPath: outPath,
      rationalePath,
      memoPath: projectRoot + '/docs/decisions/' + stamp + '-' + A.memoSlug + '.md',
      lenses,
    })
  } catch (e) {
    log('panel: failed (' + (e && e.message ? e.message : String(e)) + '); synthesizing without it')
  }
  if (panel) {
    log(`panel: ${panel.lenses.join(', ')}; agreement ${panel.agreementRate}; ${panel.disagreementCount || 0} disagreement(s)` +
      (panel.panelFailedToDisagree ? '; the panel failed to disagree' : '') +
      (panel.missing && panel.missing.length ? `; missing: ${panel.missing.join(', ')}` : ''))
  }
}

// ---- Synthesize ----
phase('Synthesize')
// A resumed run starts here with the panel's files already on disk from the earlier run.
const earlierMemo = projectRoot + '/docs/decisions/' + stamp + '-' + A.memoSlug + '.md'
const panelInputs = panel && panel.memoPath
  ? `${panel.memoPath} and every file under ${runDir}/panel/`
  : (panel
    ? `every file under ${runDir}/panel/ (the memo was not written)`
    : (startAt === 'synthesize'
      ? `${earlierMemo} and every file under ${runDir}/panel/, written by the earlier run of this workflow (if neither exists, say in the document header that the panel did not run)`
      : 'nothing else: the panel did not run, and the document header must say so'))
const final = await agent(
  `${contractStep} Read the inputs (${inputs.join(', ')}), ${outPath}, and ${panelInputs}.\n` +
  `Rewrite ${outPath}: the same sections, in contract order, revised where the panel showed a claim wrong or ` +
  `unsupported, followed by two appendices. Write the whole file with one Write call; do not build it with piecemeal edits, and do not re-read it after writing. \n` +
  `Appendix A, Challenged claims: one row per point a lens raised against a [C<n>] claim or against something ` +
  `untagged: claim | challenged by (persona and lens) | severity (blocking, major, minor: your call from the ` +
  `memo) | status | resolution. Status is upheld (you kept it; say why), revised (you changed it; quote the ` +
  `change), withdrawn, or open (the author must decide). Never delete a challenge. Reproduce the memo's ` +
  `Disagreement section and its Kill conditions verbatim below the table.\n` +
  `Appendix B, Premortem: write the 2-3 sentence scenario in which ${A.premortem}; name the hidden assumption ` +
  `it exposes; add that assumption to the Assumptions section; leave the question "What went wrong?" ` +
  `verbatim for the author. The review asks it.\n` +
  `Keep the document under ${A.maxWords} words. Check your own output against the contract's checklist before ` +
  `returning. List every decision you left open under openDecisions. Generated ${stamp}, run ${runId}. Return the object; path must be '${outPath}'.`,
  { label: `${A.author}:synthesize`, phase: 'Synthesize', agentType: author, effort: 'medium', schema: FINAL_SCHEMA },
)
if (!final) throw new Error(`draft: ${A.author} returned nothing for the synthesis; the draft is at ` + outPath)

return {
  runId,
  artifact: a.artifact,
  startedAt: startAt,
  path: final.path,
  memoPath: panel ? panel.memoPath : (startAt === 'synthesize' ? earlierMemo : null),
  lenses: panel ? panel.lenses : [],
  validation,
  challengedClaims: final.challengedClaims,
  premortem: final.premortem,
  openDecisions: final.openDecisions,
  summary: final.summary,
}
