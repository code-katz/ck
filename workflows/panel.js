export const meta = {
  name: 'panel',
  description: 'Three-lens decision panel: product (river, Fable 5.1), marketing (toni, Opus 5), and UX (kai, Sonnet 5) personas, each on a different model and each reading its own evidence, argue one question; a neutral memo surfaces where they disagree and leaves the decision to the author. Type /ck:panel followed by the question; the text is the only argument needed. A skill may instead pass an object: runId, runDir (absolute cache directory), projectRoot (absolute path of the project repository), pluginRoot, timestamp (UTC, minted by the caller with date -u), question, contextPath (optional), rationalePath (optional; each lens reads it only after forming its view), memoPath (optional; default <projectRoot>/docs/decisions/<timestamp>-panel.md), lenses (optional [{persona, lens, model, reads}]).',
  phases: [
    { title: 'Lenses', detail: 'ck:river, ck:toni, ck:kai in parallel, one model each, each reading its own evidence, each forced to argue against itself' },
    { title: 'Synthesis', detail: 'one neutral agent writes the decision memo: agreement flagged as low-information, disagreement preserved, decision left to the author' },
  ],
  personas: ['river', 'toni', 'kai'],
}

// Direct invocation (/ck:panel <question>) hands the typed text to the script as a string; a skill
// launch passes an object. Both are accepted. Paths default to the project the session is in, and
// without a plugin root the memo contract is loaded by skill name instead of by path.
const a = (args && typeof args === 'object') ? args : { question: typeof args === 'string' ? args.trim() : '' }
if (!a.question) {
  throw new Error('panel: type the question after the command, for example /ck:panel Should the first release include the brand guide step?')
}
const question = a.question
const projectRoot = a.projectRoot || '.'
const runDir = a.runDir || (projectRoot + '/.ck/runs/panel-latest')
const runId = a.runId || 'panel-direct'
const stamp = a.timestamp || 'today (write the date from `date -u`)'
const slug = question.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 40) || 'panel'
const contextPath = a.contextPath || null
const rationalePath = a.rationalePath || null
const memoPath = a.memoPath || (projectRoot + '/docs/decisions/' + (a.timestamp ? a.timestamp + '-' : '') + slug + '.md')
const memoContract = a.pluginRoot
  ? 'Read ' + a.pluginRoot + '/skills/memo-artifact/SKILL.md (the memo contract).'
  : 'Load the skill ck:memo-artifact with the Skill tool (the memo contract).'
const housekeeping = a.runDir ? '' : 'If ' + projectRoot + '/.git exists, make sure the line ".ck/" is in ' + projectRoot + '/.git/info/exclude (append it if missing). '

// Three lenses, three models, three bodies of evidence. The same model in three
// costumes is one opinion; the same evidence read three times is one reading.
// River and Toni run on their own tiers. Kai is moved down from Opus 5 to
// Sonnet 5 so that three lenses are three models. This is the one script in ck
// allowed to set `model` on a persona agent, and it only ever moves a lens down.
const DEFAULT_LENSES = [
  { persona: 'river', lens: 'product', model: 'claude-fable-5-1', reads: ['docs/PRD.md', 'docs/opportunity.md', 'ROADMAP.md'] },
  { persona: 'toni', lens: 'marketing', model: 'claude-opus-5', reads: ['docs/market-research.md', 'docs/opportunity.md'] },
  { persona: 'kai', lens: 'ux', model: 'claude-sonnet-5', reads: ['brand/', 'docs/design/'] },
]
const lenses = Array.isArray(a.lenses) && a.lenses.length
  ? a.lenses.map((l, i) => {
      if (!l || !l.persona) throw new Error('panel: every entry in args.lenses needs a persona')
      const d = DEFAULT_LENSES[i % DEFAULT_LENSES.length]
      return { persona: l.persona, lens: l.lens || l.persona, model: l.model || d.model, reads: Array.isArray(l.reads) ? l.reads : [] }
    })
  : DEFAULT_LENSES
if (new Set(lenses.map(l => l.model)).size < lenses.length) {
  log('panel: two or more lenses share a model; their agreement counts as one opinion')
}

const QUESTION = {
  type: 'object',
  properties: { to: { type: 'string' }, question: { type: 'string' } },
  required: ['to', 'question'],
}
const YES_NO_UNKNOWN = { type: 'string', enum: ['yes', 'no', 'unknown'] }

const LENS_SCHEMA = {
  type: 'object',
  properties: {
    persona: { type: 'string' },
    lens: { type: 'string' },
    recommendation: { type: 'string', enum: ['yes', 'no', 'yes-if', 'not-yet'] },
    position: { type: 'string' },
    reasoning: { type: 'string' },
    evidenceRead: { type: 'array', items: { type: 'string' } },
    strongestArgumentAgainstOwnRecommendation: { type: 'string' },
    killCondition: { type: 'string' },
    killConditionMet: YES_NO_UNKNOWN,
    killConditionEvidence: { type: 'string' },
    viewChangedByRationale: { type: 'string', enum: ['yes', 'no', 'not-read'] },
    questionsForOtherLenses: { type: 'array', items: QUESTION },
    handoffBrief: { type: 'string' },
  },
  required: [
    'persona', 'lens', 'recommendation', 'position', 'reasoning', 'evidenceRead',
    'strongestArgumentAgainstOwnRecommendation', 'killCondition', 'killConditionMet',
    'killConditionEvidence', 'viewChangedByRationale', 'questionsForOtherLenses', 'handoffBrief',
  ],
}

const MEMO_SCHEMA = {
  type: 'object',
  properties: {
    memoPath: { type: 'string' },
    question: { type: 'string' },
    recommendations: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          persona: { type: 'string' }, lens: { type: 'string' },
          model: { type: 'string' }, recommendation: { type: 'string' },
        },
        required: ['persona', 'lens', 'model', 'recommendation'],
      },
    },
    agreementRate: { type: 'number' },
    agreement: { type: 'string' },
    agreementIsLowInformationBecause: { type: 'string', enum: ['obviously-true', 'shared-blind-spot', 'mixed', 'no-agreement'] },
    disagreements: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          topic: { type: 'string' },
          positions: {
            type: 'array',
            items: {
              type: 'object',
              properties: { persona: { type: 'string' }, position: { type: 'string' } },
              required: ['persona', 'position'],
            },
          },
          decisionForAuthor: { type: 'string' },
        },
        required: ['topic', 'positions', 'decisionForAuthor'],
      },
    },
    killConditions: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          persona: { type: 'string' }, condition: { type: 'string' },
          met: YES_NO_UNKNOWN, evidence: { type: 'string' },
        },
        required: ['persona', 'condition', 'met', 'evidence'],
      },
    },
    uniqueFindings: {
      type: 'array',
      items: {
        type: 'object',
        properties: { persona: { type: 'string' }, finding: { type: 'string' } },
        required: ['persona', 'finding'],
      },
    },
    nobodyChecked: { type: 'array', items: { type: 'string' } },
    panelFailedToDisagree: { type: 'boolean' },
    summary: { type: 'string' },
  },
  required: [
    'memoPath', 'question', 'recommendations', 'agreementRate', 'agreement',
    'agreementIsLowInformationBecause', 'disagreements', 'killConditions',
    'uniqueFindings', 'nobodyChecked', 'panelFailedToDisagree', 'summary',
  ],
}

// ---- Lenses ----
phase('Lenses')
const roster = lenses.map(l => `${l.persona}: ${l.lens}`).join('; ')
const results = (await parallel(lenses.map(l => () => agent(
  `You are ${l.persona}, the ${l.lens} lens on a ${lenses.length}-lens decision panel (${roster}).\n` +
  `The project repository is ${projectRoot}; relative paths below are relative to it. ` + housekeeping + `\n` +
  `The question: ${question}\n` +
  `Work in two passes and keep them separate.\n` +
  `Pass 1. Read ` + (contextPath ? `${contextPath} (the material the question is about) and ` : '') +
  `your own evidence: ${l.reads.length ? l.reads.join(', ') : 'nothing beyond the material'}. Skip any file or ` +
  `directory that does not exist and record what you actually read in evidenceRead. Form your view and write it ` +
  `down: recommendation (yes, no, yes-if, not-yet); position (one paragraph); reasoning (evidence from what you ` +
  `read or from your domain, not from the other lenses); strongestArgumentAgainstOwnRecommendation (the best ` +
  `case a smart colleague would make against you; a weak one is a failed answer); killCondition (the specific, ` +
  `observable condition under which this should not be done at all); killConditionMet (does the material already ` +
  `show it: yes, no, unknown) with killConditionEvidence (where, or why unknown).\n` +
  (rationalePath
    ? `Pass 2. Only now read ${rationalePath}, the author's rationale. Check whether the claims you relied on ` +
      `are supported there. Set viewChangedByRationale to yes or no and, if yes, say how in reasoning. Do not ` +
      `rewrite pass 1 to agree with it.\n`
    : `Pass 2. There is no rationale document; set viewChangedByRationale to not-read.\n`) +
  `Answer from your own domain only. Apply your Required Behaviors in subagent form: where a behavior tells you ` +
  `to ask the user, put the question in questionsForOtherLenses addressed to 'author' or to a lens persona, ` +
  `state your assumption, and proceed.\n` +
  `handoffBrief: decisions you want recorded, open risks in your domain, one direct question to a named lens.\n` +
  `Write the same object as JSON to ${runDir}/panel/${l.persona}.json (create the directory if needed) and ` +
  `return it with persona '${l.persona}' and lens '${l.lens}'.`,
  { label: `${l.lens}:${l.persona}`, phase: 'Lenses', agentType: 'ck:' + l.persona, model: l.model, schema: LENS_SCHEMA },
)))).filter(Boolean)

if (results.length === 0) throw new Error('panel: every lens was stopped or failed; nothing to synthesize')
const missing = lenses.filter(l => !results.some(r => r.persona === l.persona)).map(l => l.persona)
if (missing.length) {
  log(`panel: ${missing.join(', ')} returned nothing (stopped or API error); the memo runs on ${results.length} lens(es)`)
}

// ---- Synthesis ----
phase('Synthesis')
const modelOf = persona => (lenses.find(l => l.persona === persona) || {}).model || 'unknown'
const memo = await agent(
  `Write the decision memo for a ${lenses.length}-lens panel. Question: ${question}. Run ${runId}, generated ${stamp}.\n` +
  `Lens results, also on disk under ${runDir}/panel/:\n` +
  JSON.stringify(results.map(r => ({ ...r, model: modelOf(r.persona) })), null, 1) + '\n' +
  (missing.length ? `Lenses that returned nothing: ${missing.join(', ')}. Say so in the memo header.\n` : '') +
  `Rules. You are neutral and hold no lens. Surface where the lenses disagree and do not resolve it; the ` +
  `decision is the author's. Never average positions or pick a winner. Quote each lens's strongest argument ` +
  `against itself and its kill condition verbatim.\n` +
  `agreementRate is the share of lenses on the most common recommendation (two of three is 0.67). Treat ` +
  `agreement as low-information: say whether what they agree on is obviously true or a shared blind spot, and ` +
  `which. If every lens recommends the same thing and no self-argument is substantive, set ` +
  `panelFailedToDisagree to true and say in the header that the panel should be re-run with a different ` +
  `question or lens set. State in the header that all lenses are Claude models from one training pipeline, so ` +
  `decorrelation is partial, and list what each lens actually read.\n` +
  `${memoContract} Write ${memoPath} (create the directory if needed) with these sections: ` +
  `1 Question and context (run id, timestamp, lens table with models and evidence read, the limitation, any ` +
  `missing lens); 2 Recommendations (table: lens | persona | model | recommendation | one-line position); ` +
  `3 Agreement, flagged as low-information, with why; 4 Disagreement (every point where two lenses conflict, ` +
  `both positions at full strength, the decision the author must make); 5 Kill conditions, verbatim, each with ` +
  `the lens's own answer to whether the material already shows it met; 6 Each lens against itself, verbatim; ` +
  `7 Unique findings (anything only one lens saw); 8 What nobody checked; 9 Questions between lenses ` +
  `(to -> question, verbatim); 10 Handoff briefs (verbatim, one per lens). Then return the memo object; ` +
  `memoPath must be '${memoPath}'.`,
  { label: 'synthesis', phase: 'Synthesis', schema: MEMO_SCHEMA },
)

if (!memo) {
  log('panel: synthesis returned nothing; returning raw lens results')
  const recs = results.map(r => r.recommendation)
  const top = recs.sort((a, b) => recs.filter(x => x === b).length - recs.filter(x => x === a).length)[0]
  return {
    runId, question, memoPath: null, lenses: lenses.map(l => l.persona), missing,
    recommendations: results.map(r => ({ persona: r.persona, lens: r.lens, model: modelOf(r.persona), recommendation: r.recommendation })),
    agreementRate: recs.filter(x => x === top).length / recs.length,
    agreement: '', agreementIsLowInformationBecause: 'no-agreement', disagreements: [],
    killConditions: results.map(r => ({ persona: r.persona, condition: r.killCondition, met: r.killConditionMet, evidence: r.killConditionEvidence })),
    uniqueFindings: [], nobodyChecked: [], panelFailedToDisagree: false,
    summary: 'synthesis agent returned nothing; see panel/*.json',
  }
}
if (memo.panelFailedToDisagree) log('panel: the panel failed to disagree; re-run with a different question or lens set')
log(`panel: agreement rate ${memo.agreementRate}; ${memo.disagreements.length} disagreement(s); ${memo.killConditions.filter(k => k.met === 'yes').length} kill condition(s) already met`)
return { runId, ...memo, lenses: lenses.map(l => l.persona), missing }
