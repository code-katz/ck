export const meta = {
  name: 'team',
  description: 'Team selection and roles and responsibilities. River reads the product documents and the roster and nominates a cast with an owner per document and stage; each nominee confirms or declines on its own tier and names what it needs and one missing seat; River writes docs/TEAM.md; a checker validates it. Args: runId, runDir (absolute cache directory), projectRoot (absolute path of the project repository), pluginRoot, timestamp, inputs (absolute paths of the documents that exist: opportunity, brief, PRD, market research; at least one of the first two), teamPath (optional; default <projectRoot>/docs/TEAM.md), maxCast (optional; default 8).',
  phases: [
    { title: 'Nominate', detail: 'ck:river proposes the cast: an owner and reviewers per pipeline document and stage, and the missing seats' },
    { title: 'Confirm', detail: 'every nominee, in parallel on its own tier at low effort, accepts or declines each responsibility, names its needs, one risk, and one missing seat' },
    { title: 'Assemble', detail: 'ck:river writes docs/TEAM.md: cast, roles and responsibilities matrix, hand-off order, needs, missing seats, declined nominations' },
    { title: 'Validate', detail: 'one neutral Haiku agent checks the team contract; ck:river revises at most once' },
  ],
  personas: ['river', 'akira', 'alex', 'casey', 'cornelius', 'ernie', 'iris', 'jordan', 'kai', 'morgan', 'noon', 'piper', 'quinn', 'reiner', 'rez', 'robin', 'sage', 'sasha', 'toni', 'tracy', 'travolta'],
}

if (!args || !args.runId || !args.runDir || !args.projectRoot || !args.pluginRoot || !args.timestamp) {
  throw new Error('team: args.runId, args.runDir, args.projectRoot, args.pluginRoot, and args.timestamp are required')
}
if (!Array.isArray(args.inputs) || !args.inputs.length) {
  throw new Error('team: args.inputs must list at least one of docs/opportunity.md or docs/brief.md')
}
const projectRoot = args.projectRoot
const runDir = args.runDir
const stamp = args.timestamp
const inputs = args.inputs
const teamPath = args.teamPath || (projectRoot + '/docs/TEAM.md')
const roster = args.pluginRoot + '/profiles/ROSTER.md'
const contract = args.pluginRoot + '/skills/team-artifact/SKILL.md'
const MAX_CAST = Number.isInteger(args.maxCast) && args.maxCast > 0 ? Math.min(args.maxCast, 12) : 8
const VALIDATOR_MODEL = 'claude-haiku-4-5-20251001'
const SECTIONS = ['Cast', 'Roles and responsibilities', 'Hand-off order', 'Needs', 'Missing seats', 'Declined nominations']

const RESPONSIBILITY = {
  type: 'object',
  properties: {
    item: { type: 'string' },
    role: { type: 'string', enum: ['owner', 'contributor', 'reviewer'] },
  },
  required: ['item', 'role'],
}

const NOMINATIONS_SCHEMA = {
  type: 'object',
  properties: {
    productKind: { type: 'string' },
    cast: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          persona: { type: 'string' },
          why: { type: 'string' },
          responsibilities: { type: 'array', items: RESPONSIBILITY },
        },
        required: ['persona', 'why', 'responsibilities'],
      },
    },
    missingSeats: {
      type: 'array',
      items: {
        type: 'object',
        properties: { need: { type: 'string' }, wouldOwn: { type: 'string' }, recommendation: { type: 'string' } },
        required: ['need', 'wouldOwn', 'recommendation'],
      },
    },
  },
  required: ['productKind', 'cast', 'missingSeats'],
}

const CONFIRMATION_SCHEMA = {
  type: 'object',
  properties: {
    persona: { type: 'string' },
    decisions: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          item: { type: 'string' },
          role: { type: 'string' },
          accept: { type: 'boolean' },
          reason: { type: 'string' },
          replacement: { type: 'string' },
        },
        required: ['item', 'role', 'accept', 'reason', 'replacement'],
      },
    },
    needs: { type: 'array', items: { type: 'object', properties: { from: { type: 'string' }, what: { type: 'string' } }, required: ['from', 'what'] } },
    risk: { type: 'string' },
    missingSeat: { type: 'string' },
  },
  required: ['persona', 'decisions', 'needs', 'risk', 'missingSeat'],
}

const TEAM_SCHEMA = {
  type: 'object',
  properties: {
    teamPath: { type: 'string' },
    cast: { type: 'array', items: { type: 'string' } },
    owners: {
      type: 'array',
      items: { type: 'object', properties: { item: { type: 'string' }, owner: { type: 'string' } }, required: ['item', 'owner'] },
    },
    missingSeats: { type: 'array', items: { type: 'string' } },
    declined: { type: 'number' },
  },
  required: ['teamPath', 'cast', 'owners', 'missingSeats', 'declined'],
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

// ---- Nominate ----
phase('Nominate')
const nominations = await agent(
  `The project repository is ${projectRoot}. Read the product documents: ${inputs.join(', ')}. Read the ` +
  `roster: ${roster} (one line per persona: name, role, tier, domain).\n` +
  `Say what kind of product this is in one line (productKind). Then propose the cast, at most ${MAX_CAST} ` +
  `personas, choosing by what the product needs, not by seniority: for each pipeline document and stage ` +
  `(opportunity, market research, brief, PRD, roadmap, architecture, brand guide, design, and any build ` +
  `stages the documents imply), one owner and the reviewers; when a PRD exists, one owner per requirement ` +
  `area. Every persona in the cast gets a one-sentence why.\n` +
  `Then the missing seats: needs no persona on the roster covers (a specific domain, legal, audio, ` +
  `localization, and so on), what a person in that seat would own, and your recommendation: recruit, cover ` +
  `from an existing seat (name it), or accept the gap.\n` +
  `Write the object as JSON to ${runDir}/nominations.json and return it.`,
  { label: 'river:nominate', phase: 'Nominate', agentType: 'ck:river', schema: NOMINATIONS_SCHEMA },
)
if (!nominations) throw new Error('team: River returned no nominations')
const cast = nominations.cast.slice(0, MAX_CAST)
log(`nominate: ${nominations.productKind}; ${cast.length} nominated; ${nominations.missingSeats.length} missing seat(s)`)

// ---- Confirm ----
phase('Confirm')
const confirmations = (await parallel(cast.map(n => () => agent(
  `You are ${n.persona}. You have been nominated to this product's team. Read ${inputs.join(', ')} and ` +
  `${roster}.\n` +
  `Your nomination: ${n.why}. Responsibilities proposed for you:\n` +
  n.responsibilities.map(r => `- ${r.role} of ${r.item}`).join('\n') + '\n' +
  `For each responsibility: accept or decline, with a reason from your domain; when you decline, name the ` +
  `roster persona who should have it instead (replacement), or "none" with the gap stated. Then: what you need ` +
  `from whom before you can start (needs); one risk in your domain for this product (risk); and one seat you ` +
  `think is missing from the roster for this product, or "none" (missingSeat). Be brief; this is a staffing ` +
  `check, not the work itself. Write the object as JSON to ${runDir}/confirmations/${n.persona}.json (create ` +
  `the directory if needed) and return it with persona '${n.persona}'.`,
  { label: `confirm:${n.persona}`, phase: 'Confirm', agentType: 'ck:' + n.persona, effort: 'low', schema: CONFIRMATION_SCHEMA },
)))).filter(Boolean)
const silent = cast.filter(n => !confirmations.some(c => c.persona === n.persona)).map(n => n.persona)
if (silent.length) log(`confirm: ${silent.join(', ')} returned nothing; treated as accepting their nomination as proposed`)
const declined = confirmations.reduce((sum, c) => sum + c.decisions.filter(d => !d.accept).length, 0)
log(`confirm: ${confirmations.length} confirmation(s), ${declined} declined responsibility(ies)`)

// ---- Assemble ----
phase('Assemble')
let team = await agent(
  `Read ${contract}. It is the team contract: section order, required fields, and the checklist. The ` +
  `sections, in order: ` + SECTIONS.map(s => '"' + s + '"').join(', ') + `.\n` +
  `Your nominations: ${runDir}/nominations.json. The confirmations: every file under ${runDir}/confirmations/ ` +
  (silent.length ? `(${silent.join(', ')} did not answer; treat their nominations as accepted and say so). ` : '') +
  `The product documents: ${inputs.join(', ')}. The roster: ${roster}.\n` +
  `Write ${teamPath} (create the directory if needed): the Cast table (persona, role, tier, why on this ` +
  `product); the Roles and responsibilities matrix (one row per pipeline document and stage, and per PRD ` +
  `requirement area when a PRD exists; columns owner, contributors, reviewers; exactly one owner per row); ` +
  `the Hand-off order (who hands to whom, in pipeline order, and what each hand-off carries); Needs (per ` +
  `persona, from the confirmations); Missing seats (yours and the nominees', merged, with a recommendation ` +
  `each); Declined nominations (persona, responsibility, reason, replacement). Where a nominee declined and ` +
  `named a replacement, take it or say why not. Generated ${stamp}, run ${args.runId}.\n` +
  `Return the object; teamPath must be '${teamPath}'; declined is the number of declined responsibilities.`,
  { label: 'river:assemble', phase: 'Assemble', agentType: 'ck:river', schema: TEAM_SCHEMA },
)
if (!team) throw new Error('team: River returned nothing for the assembly; nominations and confirmations are under ' + runDir)

// ---- Validate ----
phase('Validate')
const validation = await agent(
  `Read ${contract} and ${teamPath}. Check the document against every numbered item in the contract's ` +
  `checklist and against the section order, including "every pipeline document has exactly one owner". ` +
  `Return valid=true only if every item holds; for each unmet item, one line in missing that quotes the ` +
  `checklist item and says what is absent or wrong.`,
  { label: 'validate', phase: 'Validate', model: VALIDATOR_MODEL, effort: 'low', schema: VALIDATION_SCHEMA },
)
if (validation && !validation.valid) {
  log(`validate: ${validation.missing.length} unmet item(s); River revises once`)
  const revised = await agent(
    `Read ${contract} and ${teamPath}. A checker found these unmet checklist items:\n` +
    validation.missing.map(m => '- ' + m).join('\n') + '\n' +
    `Revise ${teamPath} in place so each item holds. Return the updated object; teamPath must be '${teamPath}'.`,
    { label: 'river:revise', phase: 'Validate', agentType: 'ck:river', schema: TEAM_SCHEMA },
  )
  if (revised) team = revised
  else log('validate: revision returned nothing; keeping the first assembly')
} else if (!validation) {
  log('validate: validator returned nothing; proceeding unvalidated')
} else {
  log('validate: TEAM.md passes the contract checklist')
}

return {
  runId: args.runId,
  teamPath: team.teamPath,
  productKind: nominations.productKind,
  cast: team.cast,
  owners: team.owners,
  missingSeats: team.missingSeats,
  declined: team.declined,
  silent,
  validation,
  generated: stamp,
}
