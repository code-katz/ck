// tests/workflows.mjs: run every workflow script with stub agents (tests/run.sh, section 14).
//
// Usage: node tests/workflows.mjs
//
// Each script is loaded the way the runtime loads it: the export dropped, the body run as an async
// function with args, agent, parallel, pipeline, phase, log, workflow, and budget in scope. No model
// is called. A stub agent answers from the schema the script handed it, or with the answer a case
// supplies; an answer the schema would refuse fails the case, because the runtime would refuse it too.
//
// Prints one line per check, "ok<TAB>name" or "fail<TAB>name: why", and exits 0. A crash of this
// file itself exits non-zero.

import assert from 'node:assert/strict'
import { readFileSync, readdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const REPO = join(dirname(fileURLToPath(import.meta.url)), '..')
const AsyncFunction = (async () => {}).constructor
const HOOKS = ['args', 'agent', 'parallel', 'pipeline', 'phase', 'log', 'workflow', 'budget']
const source = name => readFileSync(join(REPO, 'workflows', name + '.js'), 'utf8')

// The fullest answer a schema allows: every property present, every string and list non-empty.
// A script must finish on it, so a field the script reads as a stop signal cannot be one an agent
// is free to fill with a note.
function fill(s) {
  if (s.enum) return s.enum[0]
  if (s.type === 'object') return Object.fromEntries(Object.entries(s.properties || {}).map(([k, v]) => [k, fill(v)]))
  if (s.type === 'array') return [fill(s.items || { type: 'string' })]
  if (s.type === 'number') return 1
  if (s.type === 'boolean') return true
  return 'x'
}

// Why the runtime would refuse this answer against this schema, or null when it would accept it.
function refusal(v, s, at = 'answer') {
  if (s.enum && !s.enum.includes(v)) return `${at} is not one of ${s.enum.join(', ')}`
  if (s.type === 'object') {
    if (!v || typeof v !== 'object' || Array.isArray(v)) return `${at} is not an object`
    for (const k of s.required || []) if (!(k in v)) return `${at}.${k} is required`
    for (const [k, sub] of Object.entries(s.properties || {})) {
      const why = k in v ? refusal(v[k], sub, `${at}.${k}`) : null
      if (why) return why
    }
    return null
  }
  if (s.type === 'array') {
    if (!Array.isArray(v)) return `${at} is not a list`
    for (let i = 0; i < v.length; i++) {
      const why = refusal(v[i], s.items || {}, `${at}[${i}]`)
      if (why) return why
    }
    return null
  }
  return s.type && typeof v !== s.type ? `${at} is not a ${s.type}` : null
}

// Run one script. answers maps an agent's label to its answer, or to a function of the call that
// returns one. A label with no entry gets fill(schema); null stands for an agent that was skipped
// or died. Returns what the script returned or threw, with every agent call and log line.
async function run(name, args, answers = {}, shared = { calls: [], logs: [], refused: [] }) {
  const { calls, logs, refused } = shared
  const agent = async (prompt, opts = {}) => {
    const call = { label: opts.label || '', prompt, opts }
    calls.push(call)
    const given = answers[call.label]
    const answer = typeof given === 'function' ? given(call) : given
    if (answer === null) return null
    if (answer === undefined) return opts.schema ? fill(opts.schema) : 'x'
    const why = opts.schema ? refusal(answer, opts.schema) : null
    if (why) refused.push(`the answer this case gives ${call.label} would be refused by the script's schema: ${why}`)
    return structuredClone(answer)
  }
  const settle = async thunk => { try { return await thunk() } catch { return null } }
  const parallel = thunks => Promise.all(thunks.map(settle))
  const pipeline = (items, ...stages) => Promise.all(items.map((item, i) => settle(async () => {
    let value = item
    for (const stage of stages) value = await stage(value, item, i)
    return value
  })))
  const workflow = async (ref, childArgs) => {
    const child = await run(String(ref).replace(/^ck:/, ''), childArgs, answers, shared)
    if (child.error) throw child.error
    return child.result
  }
  const budget = { total: null, spent: () => 0, remaining: () => Infinity }
  const body = new AsyncFunction(...HOOKS, source(name).replace(/^export const meta/m, 'const meta'))
  let result, error
  try { result = await body(args, agent, parallel, pipeline, () => {}, m => logs.push(m), workflow, budget) } catch (e) { error = e }
  if (refused.length) throw new Error(refused[0])
  return { result, error, calls, logs }
}

async function check(name, body) {
  try {
    await body()
    console.log('ok\t' + name)
  } catch (e) {
    console.log('fail\t' + name + ': ' + String((e && e.message) || e).split('\n')[0])
  }
}
const finished = (outcome, what) => assert.equal(outcome.error, undefined, `${what} stopped with "${outcome.error && outcome.error.message}"`)
const stopped = (outcome, pattern, what) => {
  assert.ok(outcome.error, `${what} did not stop`)
  assert.match(outcome.error.message, pattern, `${what} stopped with "${outcome.error.message}"`)
}
const labeled = (outcome, prefix) => outcome.calls.filter(c => c.label.startsWith(prefix))

// ---- Every script, from every step it can start at ----

// The arguments each script refuses to start without, one launch per entry.
const NEEDS = {
  'brand': [{ pluginRoot: '/plugin', source: '/p/docs/brief.md', chosen: ['A'] }],
  'design-round': [{ pluginRoot: '/plugin', feature: '3', prd: '/p/docs/PRD.md', chosen: 'A' }],
  'draft': [{ artifact: 'prd' }, { artifact: 'architecture' }, { artifact: 'prd', panel: false }],
  'opportunity-draft': [{ idea: 'A two-player card game.' }],
  'panel': [{ question: 'Should the first release include the brand guide step?' }],
  'brief-draft': [{ idea: 'An app that reminds you to water each plant.' }],
}

// The steps a script accepts as startAt, read from its ORDER list or, per stage, its ORDERS table.
function starts(name) {
  const js = source(name)
  const quoted = text => [...text.matchAll(/'([a-z]+)'/g)].map(m => m[1])
  const stages = js.match(/^const ORDERS = \{([\s\S]*?)\}/m)
  if (stages) return [...stages[1].matchAll(/(\w+): \[(.*?)\]/g)].flatMap(([, stage, steps]) => quoted(steps).map(startAt => ({ stage, startAt })))
  const order = js.match(/^const ORDER = \[(.*?)\]/m)
  return order ? quoted(order[1]).map(startAt => ({ startAt })) : [{}]
}

for (const file of readdirSync(join(REPO, 'workflows')).filter(f => f.endsWith('.js')).sort()) {
  const name = file.slice(0, -3)
  const steps = starts(name)
  const from = steps.length > 1 ? `from each of the ${steps.length} steps it can start at` : 'from the start'
  await check(`workflows/${file} finishes ${from} when every agent fills every field`, async () => {
    const broken = []
    for (const needs of NEEDS[name] || [{}]) {
      for (const step of steps) {
        const { error } = await run(name, { runId: 'r1', runDir: '/p/.ck/runs/r1', projectRoot: '/p', ...needs, ...step })
        if (error) broken.push(`${[needs.artifact, needs.panel === false ? 'no panel' : '', step.stage, step.startAt].filter(Boolean).join(' ') || 'the start'}: ${error.message}`)
      }
    }
    assert.equal(broken.length, 0, broken.join(' | '))
  })
}

// ---- Market research ----

const RUN = { runId: 'r1', runDir: '/p/.ck/runs/r1', projectRoot: '/p', pluginRoot: '/plugin', timestamp: '20261007T120000Z' }
const AREAS = ['market-size-and-trends', 'competitors-and-substitutes', 'customers-and-channels', 'pricing-and-business-models', 'constraints', 'competitors-and-substitutes']
const PLAN = {
  product: 'A watering reminder for house plants',
  inputsRead: ['/p/docs/brief.md'],
  questions: AREAS.map((area, i) => ({ id: i + 1, area, question: `Question ${i + 1}, on ${area}?`, goodAnswer: 'Named figures, each with a source.' })),
}
// What Toni wrote in the required stopReason beside a good plan on 2026-10-07.
const NOTE = 'Six questions across the five areas, weighted toward competitors.'
const NO_PLAN = { product: '', inputsRead: [], questions: [] }

await check('market research: a plan with questions and a note in stopReason is researched, not stopped', async () => {
  const outcome = await run('market-research-draft', RUN, { 'toni:plan': { ...PLAN, stopReason: NOTE } })
  finished(outcome, 'the run')
  assert.equal(labeled(outcome, 'research:').length, PLAN.questions.length, 'not every question got a researcher')
  assert.equal(outcome.result.questions, PLAN.questions.length, 'the result does not count the questions')
})

await check('market research: a plan with no stopReason at all is accepted and researched', async () => {
  const outcome = await run('market-research-draft', RUN, { 'toni:plan': PLAN })
  finished(outcome, 'the run')
  assert.equal(labeled(outcome, 'research:').length, PLAN.questions.length, 'not every question got a researcher')
})

await check('market research: an empty questions list stops the run with the sentence Toni gave', async () => {
  const outcome = await run('market-research-draft', RUN, { 'toni:plan': { ...NO_PLAN, stopReason: 'Run /ck:brief first.' } })
  stopped(outcome, /^market-research: Run \/ck:brief first\.$/, 'the run')
  assert.equal(labeled(outcome, 'research:').length, 0, 'researchers ran with no questions')
})

await check('market research: an empty questions list with no stopReason stops and names what to run first', async () => {
  const outcome = await run('market-research-draft', RUN, { 'toni:plan': NO_PLAN })
  stopped(outcome, /\/ck:opportunity.*\/ck:brief/, 'the run')
})

await check('market research: starting at research reads plan.json back and researches every question', async () => {
  const outcome = await run('market-research-draft', { ...RUN, startAt: 'research' }, { 'plan:reload': { ...PLAN, stopReason: NOTE } })
  finished(outcome, 'the resumed run')
  assert.equal(labeled(outcome, 'toni:plan').length, 0, 'Toni planned again')
  assert.ok(outcome.calls[0].prompt.includes('/p/.ck/runs/r1/plan.json'), 'the first agent was not sent to plan.json')
  const researchers = labeled(outcome, 'research:')
  for (const q of PLAN.questions) assert.ok(researchers.some(c => c.prompt.includes(q.question) && c.prompt.includes(PLAN.product)), `question ${q.id} was not researched as saved`)
  assert.equal(researchers.length, PLAN.questions.length, 'the researchers do not match the saved questions')
  assert.equal(outcome.result.questions, PLAN.questions.length, 'the result does not count the saved questions')
})

await check('market research: starting at research with no saved plan says to start at plan', async () => {
  for (const answer of [NO_PLAN, null]) {
    const outcome = await run('market-research-draft', { ...RUN, startAt: 'research' }, { 'plan:reload': answer })
    stopped(outcome, /plan\.json.*start at plan/, 'the resumed run')
    assert.equal(labeled(outcome, 'research:').length, 0, 'researchers ran with no plan')
  }
})

await check('market research: starting at crosscheck, write, or validate asks nobody for the plan', async () => {
  for (const startAt of ['crosscheck', 'write', 'validate']) {
    const outcome = await run('market-research-draft', { ...RUN, startAt })
    finished(outcome, `the run from ${startAt}`)
    assert.equal(labeled(outcome, 'toni:plan').length + labeled(outcome, 'plan:reload').length, 0, `the run from ${startAt} asked for the plan`)
  }
})

// ---- Roadmap ----

const PRIORITIES = {
  product: 'A watering reminder for house plants',
  existingRoadmap: false,
  snapshot: 'Nothing has shipped.',
  tier1: [{ opportunity: 'Per-plant schedules', whyNow: 'It is the product.', successSignal: 'Forty percent of users add three plants.', requirement: '1' }],
  tier2: [],
  tier3: [],
  okrs: [{ keyResult: 'Weekly active users', target: '500', current: '0' }],
  openQuestions: [],
}
const NO_PRIORITIES = { ...PRIORITIES, product: '', snapshot: '', tier1: [], okrs: [] }

await check('roadmap: priorities with a note in stopReason are sequenced, not stopped', async () => {
  const outcome = await run('roadmap-draft', RUN, { 'river:prioritize': { ...PRIORITIES, stopReason: 'One Tier 1 item, traced to requirement 1.' } })
  finished(outcome, 'the run')
  assert.equal(labeled(outcome, 'quinn:sequence').length, 1, 'Quinn did not sequence')
})

await check('roadmap: priorities with no stopReason at all are accepted and sequenced', async () => {
  const outcome = await run('roadmap-draft', RUN, { 'river:prioritize': PRIORITIES })
  finished(outcome, 'the run')
  assert.equal(labeled(outcome, 'quinn:sequence').length, 1, 'Quinn did not sequence')
})

await check('roadmap: empty tiers stop the run, with the sentence River gave or with what to run first', async () => {
  const told = await run('roadmap-draft', RUN, { 'river:prioritize': { ...NO_PRIORITIES, stopReason: 'Run /ck:prd first.' } })
  stopped(told, /^roadmap: Run \/ck:prd first\.$/, 'the run')
  const silent = await run('roadmap-draft', RUN, { 'river:prioritize': NO_PRIORITIES })
  stopped(silent, /\/ck:prd/, 'the run with no stopReason')
  assert.equal(labeled(told, 'quinn:sequence').length + labeled(silent, 'quinn:sequence').length, 0, 'Quinn sequenced nothing')
})

// ---- Opportunity ----

const IDEA = { ...RUN, idea: 'A two-player card game set in the 1944 Ardennes.' }
const FRAME = {
  productKind: 'A two-player card game',
  concept: 'A card game for two, played in under an hour.',
  hypothesis: 'Players who like short wargames will pay for a boxed one.',
  contributors: ['toni', 'akira', 'reiner'].map(persona => ({ persona, lens: persona + 'lens', title: 'A title', why: 'A reason.', questions: ['What must be true?'] })),
}

await check('opportunity: starting at sections reads frame.json back and runs every contributor', async () => {
  const outcome = await run('opportunity-draft', { ...IDEA, startAt: 'sections' }, { 'frame:reload': FRAME })
  finished(outcome, 'the resumed run')
  assert.equal(labeled(outcome, 'river:frame').length, 0, 'River framed again')
  assert.ok(outcome.calls[0].prompt.includes('/p/.ck/runs/r1/frame.json'), 'the first agent was not sent to frame.json')
  const written = outcome.calls.filter(c => c.opts.phase === 'Sections' && c.label !== 'frame:reload')
  assert.deepEqual(written.map(c => c.opts.agentType).sort(), ['ck:akira', 'ck:reiner', 'ck:toni'], 'the section writers are not the saved contributors')
  for (const c of written) assert.ok(c.prompt.includes(FRAME.concept) && c.prompt.includes(FRAME.hypothesis), `${c.label} was not given the saved concept and hypothesis`)
})

await check('opportunity: starting at sections with no saved frame says to start at frame', async () => {
  for (const answer of [{ ...FRAME, contributors: [] }, null]) {
    const outcome = await run('opportunity-draft', { ...IDEA, startAt: 'sections' }, { 'frame:reload': answer })
    stopped(outcome, /frame\.json.*start at frame/, 'the resumed run')
  }
})

await check('opportunity: starting at assemble or validate asks nobody for the frame', async () => {
  for (const startAt of ['assemble', 'validate']) {
    const outcome = await run('opportunity-draft', { ...IDEA, startAt })
    finished(outcome, `the run from ${startAt}`)
    assert.equal(labeled(outcome, 'river:frame').length + labeled(outcome, 'frame:reload').length, 0, `the run from ${startAt} asked for the frame`)
  }
})

// ---- Draft (PRD and architecture) ----

await check('draft: starting at synthesize returns the earlier panel memo, and none when the panel is off', async () => {
  const withPanel = await run('draft', { ...RUN, artifact: 'prd', startAt: 'synthesize' })
  finished(withPanel, 'the resumed run')
  assert.equal(withPanel.result.memoPath, '/p/docs/decisions/20261007T120000Z-prd-review.md', 'memoPath is not the earlier memo')
  const without = await run('draft', { ...RUN, artifact: 'prd', startAt: 'synthesize', panel: false })
  finished(without, 'the resumed run with the panel off')
  assert.equal(without.result.memoPath, null, 'a memo is named though the panel is off')
})
