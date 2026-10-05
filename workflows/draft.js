export const meta = {
  name: 'draft',
  description: "One author drafts a document to its contract, a checker validates it, optionally the three-lens panel challenges it (forming its view before reading the rationale) and the author rewrites it with a Challenged claims appendix; the author adds a premortem either way. Serves the PRD (river; lenses river, toni, kai) and the architecture document (akira; lenses morgan, alex, jordan). Normally launched by /ck:prd or /ck:architecture with an object: artifact ('prd' | 'architecture'), runId, runDir (absolute cache directory), projectRoot (absolute path of the project repository), pluginRoot, timestamp, inputs (absolute paths of the documents to read; the skill lists the ones that exist), outputPath (optional; default from the artifact table), startAt (optional: draft | validate | panel | synthesize; earlier stages are skipped and the document on disk is used), lenses (optional), panel (optional; false skips the panel and the rewrite: the author appends the premortem with a few edits instead, which is the cheap path). A direct /ck:draft prd works too, with everything defaulted to the current project.",
  phases: [
    { title: 'Draft', detail: 'the author writes the document from its inputs to the contract; every claim not from the inputs tagged [C<n>]' },
    { title: 'Validate', detail: 'one neutral Haiku agent checks the contract checklist; the author revises at most twice' },
    { title: 'Panel', detail: 'nested /ck:panel on the draft, three lenses on three models, each reading its own evidence' },
    { title: 'Synthesize', detail: 'the author rewrites the document: revised body, Appendix A Challenged claims, Appendix B Premortem' },
    { title: 'Check', detail: 'the checker runs once more on the rewrite, length first; the author trims at most once' },
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
    targetWords: 2500,
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
    targetWords: 2500,
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
const withPanel = a.panel !== false
const SECTIONS = A.sections
const MAX_REVISIONS = 2
const SMALLEST_EDITS = 'Make the smallest edits that satisfy each listed item, with the Edit tool on the passages concerned, in at most ten Edit calls; where the item is length, cut whole paragraphs of repetition until the document is at least five percent under the cap, so one revision settles it. Do not rewrite the document, do not re-read files you were not asked to read, do not run web searches, and do not count, grep, or check the result: the checker runs again next. If an item needs a source you do not have, mark the claim unverified instead of inventing one. '
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
    `Length first: aim for about ${A.targetWords} words before the appendices and never more than ${A.maxWords}, which is the contract's cap; a draft over the cap is sent back for a trim at your own cost.\n` +
    `${contractStep} It gives the section order, required fields, and the checklist your draft will be ` +
    `validated against.\n` +
    `Write ${outPath} to that contract, all sections in this order (create the directory if needed). Write the whole file with one Write call; do not build it with piecemeal edits, and do not re-read, edit, count, or check it after writing: return as soon as it is written, because a checker runs next and names anything unmet. ` +
    SECTIONS.map(s => '"' + s + '"').join(', ') + `.\n` +
    `Apply your Required Behaviors in subagent form. Leave Appendix B (the premortem) for the pass after the ` +
    `panel, and say so under its heading.\n` +
    `Tag every claim that is not taken directly from the inputs with an inline marker [C1], [C2], ... so the ` +
    `panel can address it, and list those claims with their section. Put anything you would have asked the ` +
    `author under Open questions, with your assumption.\n` +
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
      `${contractStep} With the Bash tool, count the words of ${outPath} before its first "## Appendix" heading ` +
      `(for example: awk '/^## Appendix/{exit} {print}' "${outPath}" | wc -w) and put the number in notes; never judge ` +
      `length by impression. Item 1: that count is under ${A.maxWords}. Then read the document and check it against every ` +
      `numbered item in the contract's checklist and against the section order. Return valid=true only if every item holds. ` +
      `For each unmet item, one line in missing that quotes the checklist item and says what is absent or wrong, the length ` +
      `first with the count. Judge the shape, not the product.`,
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
      `${contractStep} Read ${outPath}. A checker found these unmet ` +
      `checklist items:\n` + validation.missing.map(m => '- ' + m).join('\n') + '\n' +
      `Revise ${outPath} so each item holds. ` + SMALLEST_EDITS + `Keep every existing [C<n>] tag and add tags for any new ` +
      `claim not from the inputs. Return the updated draft object; path must be '${outPath}'.`,
      { label: `${A.author}:revise:${round}`, phase: 'Validate', agentType: author, effort: 'medium', schema: DRAFT_SCHEMA },
    )
    if (!revised) { log('validate: revision returned nothing; keeping the previous draft'); break }
    draft = revised
  }
}

// ---- Panel (nested by name; one level only; each lens reads its own evidence and sees the rationale last) ----
let panel = null
if (!withPanel) log('panel: skipped by the caller (panel: false); the author appends the premortem and no rewrite runs')
if (runs('panel') && withPanel) {
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

// ---- Premortem only (panel off) ----
let final = null
let check = null
if (!withPanel) {
  phase('Synthesize')
  final = await agent(
    `${contractStep} Read ${outPath}. The panel did not run for this document, by the author's choice. With the Edit tool and at most four Edit calls, and without rewriting or re-reading anything else: ` +
    `(1) replace the placeholder under "Appendix A. Challenged claims" (or add the heading after the last section) with one sentence: the panel did not run; /ck:panel can challenge the tagged claims later. ` +
    `(2) Write "Appendix B. Premortem" after it: the 2-3 sentence scenario in which ${A.premortem}; the hidden assumption it exposes; and the question "What went wrong?" verbatim for the author. ` +
    `(3) Add that assumption as one line under the Assumptions section. Do not change anything else, do not count or check the file, and return as soon as the edits are made. ` +
    `challengedClaims is an empty list; openDecisions lists the decisions the document leaves open. Return the object; path must be '${outPath}'.`,
    { label: `${A.author}:premortem`, phase: 'Synthesize', agentType: author, effort: 'medium', schema: FINAL_SCHEMA },
  )
  if (!final) throw new Error(`draft: ${A.author} returned nothing for the premortem; the draft is at ` + outPath)
} else {
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
final = await agent(
  `${contractStep} Read the inputs (${inputs.join(', ')}), ${outPath}, and ${panelInputs}.\n` +
  `Rewrite ${outPath}: the same sections, in contract order, revised where the panel showed a claim wrong or ` +
  `unsupported, followed by two appendices. Write the whole file with one Write call; do not build it with piecemeal edits, and do not re-read, edit, count, or check it after writing: return as soon as it is written, because a checker runs next and names anything unmet. \n` +
  `Appendix A, Challenged claims: one row per point a lens raised against a [C<n>] claim or against something ` +
  `untagged: claim | challenged by (persona and lens) | severity (blocking, major, minor: your call from the ` +
  `memo) | status | resolution. Status is upheld (you kept it; say why), revised (you changed it; quote the ` +
  `change), withdrawn, or open (the author must decide). Never delete a challenge. Reproduce the memo's ` +
  `Disagreement section and its Kill conditions verbatim below the table.\n` +
  `Appendix B, Premortem: write the 2-3 sentence scenario in which ${A.premortem}; name the hidden assumption ` +
  `it exposes; add that assumption to the Assumptions section; leave the question "What went wrong?" ` +
  `verbatim for the author. The review asks it.\n` +
  `Length rule: the body before the appendices must be no longer than the draft you are rewriting, and under ${A.maxWords} words; ` +
  `aim for about ${A.targetWords}. Revisions replace text, they do not add it: for every sentence the panel makes you add, ` +
  `take one out. The appendices are separate and uncounted. A checker runs next and names anything unmet, ` +
  `so do not check or count it yourself. List every decision you left open under openDecisions. Generated ${stamp}, run ${runId}. Return the object; path must be '${outPath}'.`,
  { label: `${A.author}:synthesize`, phase: 'Synthesize', agentType: author, effort: 'medium', schema: FINAL_SCHEMA },
)
if (!final) throw new Error(`draft: ${A.author} returned nothing for the synthesis; the draft is at ` + outPath)

// ---- Check ----
// The checker ran on the draft, before the panel; the rewrite is the stage that overruns the cap, so it is
// checked too, with the length first, and the author gets one revision to bring it under.
phase('Check')
for (let round = 1; round <= 2; round++) {
  check = await agent(
    `${contractStep} With the Bash tool, count the words of ${outPath} before its first "## Appendix" heading ` +
    `(for example: awk '/^## Appendix/{exit} {print}' "${outPath}" | wc -w) and put the number in notes. ` +
    `Item 1: that count is under ${A.maxWords}. Then check the whole document against every numbered item in ` +
    `the contract's checklist and the section order, with Appendix A (Challenged claims) and Appendix B ` +
    `(Premortem) present after the sections. Return valid=true only if every item holds; for each unmet item, ` +
    `one line in missing that quotes the item and says what is absent or wrong, the length first.`,
    { label: `check:${round}`, phase: 'Check', model: VALIDATOR_MODEL, effort: 'low', schema: VALIDATION_SCHEMA },
  )
  if (!check) { log('check: checker returned nothing after the rewrite; proceeding unchecked'); break }
  if (check.valid) { log(`check: the rewritten document passes (${check.notes})`); break }
  if (round === 2) { log(`check: still unmet after the revision: ${check.missing.join(' | ')}`); break }
  log(`check: ${check.missing.length} unmet item(s) after the rewrite; ${A.author} revises once`)
  const trimmed = await agent(
    `${contractStep} Read ${outPath}. A checker found these unmet items after your rewrite:\n` +
    check.missing.map(m => '- ' + m).join('\n') + '\n' +
    `The checker's notes: ${check.notes}\n` +
    `Revise ${outPath} so each holds. Where the body is over ${A.maxWords} words: take the checker's count, subtract ` +
    `${Math.round(A.maxWords * 0.9)}, and cut at least that many words, so one revision settles it. Cut whole paragraphs of ` +
    `repetition and move detail into Open questions or the appendices; never shorten Appendix A or Appendix B, and never ` +
    `delete a challenge. ` + SMALLEST_EDITS + `The one exception to the no-counting rule: when you believe you are done, run the ` +
    `count once (awk '/^## Appendix/{exit} {print}' "${outPath}" | wc -w); if it is still ${A.maxWords} or more, cut more and ` +
    `return without counting again. Return only the updated object; path must be '${outPath}'.`,
    { label: `${A.author}:trim`, phase: 'Check', agentType: author, effort: 'medium', schema: FINAL_SCHEMA },
  )
  if (!trimmed) { log('check: revision returned nothing; keeping the rewrite as it is'); break }
}

}

return {
  runId,
  artifact: a.artifact,
  startedAt: startAt,
  path: final.path,
  memoPath: panel ? panel.memoPath : (startAt === 'synthesize' ? earlierMemo : null),
  lenses: panel ? panel.lenses : [],
  validation,
  check,
  challengedClaims: final.challengedClaims,
  premortem: final.premortem,
  openDecisions: final.openDecisions,
  summary: final.summary,
}
