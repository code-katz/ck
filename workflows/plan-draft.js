export const meta = {
  name: 'plan-draft',
  description: 'The staged plan: one author lays the work out in phases and stages, one job and one owner per row, each row with a state and an entry a new session can start from; a checker runs the plan script on it and the author revises at most twice. With no item it plans the release from ROADMAP.md, docs/ARCHITECTURE.md, and docs/TEAM.md, as docs/build-plan.md; with an item it plans that one piece of work, under docs/plan/. Normally launched by /ck:plan, which mints the run directory and owns the review, with an object: runId, runDir (absolute cache directory), projectRoot (absolute path of the project repository), pluginRoot, timestamp, item (the piece of work, in the author\'s words; omit for the release plan), itemId (short id for an item plan), author (persona who writes it; default quinn for the release, akira for an item), inputs (absolute paths of the documents that exist), existing (absolute path of an earlier plan to carry over), outputPath, startAt (optional: draft | check). A direct /ck:plan-draft [item] works too, with everything defaulted to the current project and no run record.',
  phases: [
    { title: 'Draft', detail: 'the author persona writes the plan to the staged plan contract: phases, a stage table per phase, and an entry per stage' },
    { title: 'Check', detail: 'one neutral Haiku agent runs the plan script (refresh, then check) and reads for what the script cannot see; the author revises at most twice' },
  ],
  personas: ['quinn', 'akira', 'sasha', 'alex', 'kai', 'river'],
}

// Direct invocation (/ck:plan-draft [item]) hands the typed text to the script as a string; a skill
// launch passes an object. Both are accepted. Paths default to the project the session is in, and
// without a plugin root the contract is loaded by skill name and the plan script cannot be run.
const a = (args && typeof args === 'object') ? args : { item: typeof args === 'string' ? args.trim() : '' }
const projectRoot = a.projectRoot || '.'
const runDir = a.runDir || (projectRoot + '/.ck/runs/plan-latest')
const runId = a.runId || 'plan-direct'
const stamp = a.timestamp || 'today (write the date from `date -u`)'
const item = (a.item || '').trim()
const release = !item
const AUTHORS = ['quinn', 'akira', 'sasha', 'alex', 'kai', 'river']
const author = AUTHORS.includes(a.author) ? a.author : (release ? 'quinn' : 'akira')
const outPath = a.outputPath || (release ? projectRoot + '/docs/build-plan.md' : '')
const where = outPath || `${projectRoot}/docs/plan/<today's date as YYYY-MM-DD>-<three or four words naming the item, lower case, joined by hyphens>.md`
const inputs = Array.isArray(a.inputs) && a.inputs.length
  ? a.inputs
  : (release
    ? [projectRoot + '/ROADMAP.md (required)', 'and whichever of ' + projectRoot + '/docs/ARCHITECTURE.md, ' + projectRoot + '/docs/TEAM.md, ' + projectRoot + '/docs/PRD.md, ' + projectRoot + '/docs/brand-guide.md, and the folders under ' + projectRoot + '/docs/design/ exist']
    : ['whichever of ' + projectRoot + '/CLAUDE.md, ' + projectRoot + '/docs/TEAM.md, ' + projectRoot + '/docs/ARCHITECTURE.md, ' + projectRoot + '/docs/PRD.md, and ' + projectRoot + '/ROADMAP.md exist'])
const contractStep = a.pluginRoot
  ? 'Read ' + a.pluginRoot + '/skills/plan-artifact/SKILL.md (the staged plan contract).'
  : 'Load the skill ck:plan-artifact with the Skill tool (the staged plan contract).'
const rosterStep = a.pluginRoot
  ? 'Read the roster: ' + a.pluginRoot + '/profiles/ROSTER.md (one line per persona: name, role, tier model, domain).'
  : 'Load the skill ck:roster with the Skill tool (the roster: one line per persona with name, role, tier model, domain).'
const housekeeping = a.runDir ? '' : 'If ' + projectRoot + '/.git exists, run this with the Bash tool so the run cache stays out of git status: grep -qxF ".ck/" ' + projectRoot + '/.git/info/exclude 2>/dev/null || echo ".ck/" >> ' + projectRoot + '/.git/info/exclude . If it is refused, skip it and never mention it in a document. '
const ONE_WRITE = 'Write the whole file with one Write call; do not build it with piecemeal edits, and do not re-read, edit, count, or check it after writing: return as soon as it is written, because a checker runs next and names anything unmet. '
const SMALLEST_EDITS = 'Make the smallest edits that satisfy each listed item, with the Edit tool on the passages concerned, in at most ten Edit calls; where the item is length, cut whole paragraphs of repetition until the document is at least five percent under the cap, so one revision settles it. Do not rewrite the document, do not re-read files you were not asked to read, do not run web searches, and do not count, grep, or check the result: the checker runs again next. '
const VALIDATOR_MODEL = 'claude-haiku-4-5-20251001'
const MAX_REVISIONS = 2
const SECTIONS = ['What this covers', 'Phases', 'Stage by stage', 'Open points']

const ORDER = ['draft', 'check']
const startAt = ORDER.includes(a.startAt) ? a.startAt : 'draft'
const runs = stage => ORDER.indexOf(stage) >= ORDER.indexOf(startAt)
if (startAt !== 'draft') log(`plan: starting at ${startAt}; the plan on disk is checked as it is`)

const DOC_SCHEMA = {
  type: 'object',
  properties: {
    path: { type: 'string' },
    title: { type: 'string' },
    itemId: { type: 'string' },
    phases: { type: 'number' },
    stages: { type: 'number' },
    openPoints: { type: 'array', items: { type: 'string' } },
    stopReason: { type: 'string' },
  },
  required: ['path', 'title', 'phases', 'stages', 'openPoints'],
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

// ---- Draft ----
let doc = null
if (runs('draft')) {
  phase('Draft')
  doc = await agent(
    `The project repository is ${projectRoot}. ` + housekeeping + `${contractStep} It gives the file's shape, the four state forms, and the checklist. The sections, in order: ` + SECTIONS.map(s => '"' + s + '"').join(', ') + `. ${rosterStep}\n` +
    `Length first: the plan is capped at 3,500 words. A What is one phrase, a Does is two sentences at most, and an entry's title is short enough that its session name, "[<stage>] [<Persona> <Model>] <title>", is 59 characters or fewer.\n` +
    (release
      ? `Write the release plan. Read: ${inputs.join(', ')}. ROADMAP.md is the spine: its steps, in their approved order, are what this plan stages, and the plan adds nothing to its scope. If ROADMAP.md does not exist, write nothing: return stages 0 and set stopReason to "Run /ck:roadmap first. It writes ROADMAP.md, the order this plan stages." That is the only case with a stopReason; otherwise leave the field out. From the architecture document take what must exist before what; from the team document take who owns each kind of work; from the PRD take the requirement numbers for each entry's Serves line; from the brand guide and the design folders see which screens have a chosen design.\n`
      : `Write an item plan for this piece of work, in the author's words: ${item}\n` + (a.itemId ? `Its id is ${a.itemId}.\n` : `Give it a short id of capitals and digits, eight characters at most, and return it as itemId.\n`) +
        `Read: ${inputs.join(', ')}. Then find where the item lives in the code with your own searches, and read enough of it to split the work into stages that one session each can finish. If the item cannot be staged from what is here, write nothing: return stages 0 and say why in stopReason; otherwise leave that field out.\n`) +
    (a.existing ? `An earlier plan is at ${a.existing}. Read it and carry it over: keep its phases, its order, its owners, and its decisions, and mark as done what it says is done.\n` : '') +
    `How to stage the work:\n` +
    `- One row is one job for one owner, sized so one session can finish it and it can be checked on its own. Drawing, building, writing, and checking are separate rows. A row never has two owners.\n` +
    `- An owner is a persona from the team document when there is one, otherwise from the roster by what the job needs, written with the model word for that persona's tier (a tier model that starts with claude-fable is Fable, claude-opus is Opus, claude-sonnet is Sonnet, claude-haiku is Haiku). A job that is the author's own (a decision, a seat to fill, a pick on a page) is a row owned by You, with Kind yours. A job nobody on the team document or the roster can own is owned by Open, and goes under Open points with the stage it holds up.\n` +
    `- Before a set of screens is built, it needs a chosen design. When docs/design/<feature>/spec.md does not exist for it, put a row of Kind "design round" before the build, owned by Kai: the author types /ck:design <feature> for it. When one small change to an existing screen is enough, a drawing row is enough.\n` +
    `- Put a tests row before a change that could break behavior nothing tests today, and a check row (Robin; Morgan when sign-in, payments, or personal data are touched) after the builds it checks.\n` +
    `- Phases are what the author can judge: each ends at something he can see or try for himself, said in its "Ends when" line. Order stages by what each one waits on, and say it in Follows; do not chain stages that could run side by side.\n` +
    `- Every row starts as not started: "could start now" when it follows nothing, otherwise "follows" and the stages it waits on.\n` +
    `- No hours, no effort estimates, and no dates for stages. Plain words, no em-dash, and never the total size of the roster.\n` +
    `Write the plan to ${where} (create the folder if needed), dated ${stamp}, with Status "draft, not approved". ` + ONE_WRITE +
    `Return only the object: path is the file you wrote; phases and stages are counts; openPoints is the list under Open points, one line each. Do not repeat the plan in the return value.`,
    { label: `${author}:draft`, phase: 'Draft', agentType: 'ck:' + author, effort: 'medium', schema: DOC_SCHEMA },
  )
  if (!doc) throw new Error(`plan: ${author} returned nothing for the plan`)
  // The stage count decides whether to stop; stopReason only words the stop. Text beside a written plan is a note.
  const note = (doc.stopReason || '').trim()
  if (!doc.stages) throw new Error('plan: ' + (note || (release ? 'nothing was staged. If ROADMAP.md does not exist, run /ck:roadmap first; it writes the order this plan stages.' : 'the item could not be staged from what is in the project. Say more about it after the command and run /ck:plan again.')))
  if (note) log(`draft: ${author} left a note beside the plan, which does not stop the run: ${note}`)
  log(`draft: ${doc.title}; ${doc.phases} phase(s), ${doc.stages} stage(s), ${doc.openPoints.length} open point(s)`)
}
const planPath = (doc && doc.path) || outPath
if (!planPath) throw new Error('plan: nothing to check. Starting at the check step needs outputPath, the plan file to check.')

// ---- Check ----
// The plan script is the oracle for the plan's shape; the checker runs it and adds only what a script cannot read.
phase('Check')
const scriptCheck = a.pluginRoot
  ? `With the Bash tool run these two commands, in order, exactly: python3 "${a.pluginRoot}/scripts/plan.py" refresh "${planPath}" ; python3 "${a.pluginRoot}/scripts/plan.py" check "${planPath}" . The first writes the State of every row that is not started. Of the lines the second prints, one that starts with "note:" or "roster:" is not a problem, and the last line, "words:", is the word count: put those in notes. Every other line is an unmet item: put each in missing word for word. `
  : `${contractStep} Read ${planPath} and check it against every numbered item in the contract's checklist, counting its words with wc -w and putting the count in notes. `
let validation = null
for (let round = 1; round <= MAX_REVISIONS + 1; round++) {
  validation = await agent(
    scriptCheck +
    `Then read ${planPath} for the three things no script reads, and add one line to missing for each that fails, quoting the words concerned: any hours, effort estimates, or dates given for a stage; any em-dash; any statement of the total size of the persona roster (a count of some of them is fine). Judge the shape, not the plan's choices. Return valid=true only when missing is empty.`,
    { label: `check:${round}`, phase: 'Check', model: VALIDATOR_MODEL, effort: 'low', schema: VALIDATION_SCHEMA },
  )
  if (!validation) { log('check: the checker returned nothing; proceeding unchecked'); break }
  if (validation.valid) { log(`check: the plan passes (round ${round}; ${validation.notes})`); break }
  if (round > MAX_REVISIONS) { log(`check: still unmet after ${MAX_REVISIONS} revision(s): ${validation.missing.join(' | ')}`); break }
  log(`check: ${validation.missing.length} unmet item(s); ${author} revises (revision ${round} of ${MAX_REVISIONS})`)
  const revised = await agent(
    `${contractStep} Read ${planPath}. A checker found these unmet items:\n` + validation.missing.map(m => '- ' + m).join('\n') + '\n' +
    `Revise ${planPath} so each holds. ` + SMALLEST_EDITS + `Where an item ends "(run refresh)", leave that State cell alone: the checker rewrites it. Return only the updated object; path must be '${planPath}'.`,
    { label: `${author}:revise:${round}`, phase: 'Check', agentType: 'ck:' + author, effort: 'medium', schema: DOC_SCHEMA },
  )
  if (!revised) { log('check: the revision returned nothing; keeping the plan as it is'); break }
  doc = revised
}

return {
  runId,
  startedAt: startAt,
  path: planPath,
  title: doc ? doc.title : null,
  itemId: doc ? (doc.itemId || a.itemId || null) : (a.itemId || null),
  phases: doc ? doc.phases : null,
  stages: doc ? doc.stages : null,
  openPoints: doc ? doc.openPoints : [],
  validation,
  generated: stamp,
}
