export const meta = {
  name: 'brand',
  description: 'Brand identity in three stages, one launch per stage, with a gallery review between them. proposals: Toni writes one positioning line per candidate direction, Iris designs four to six directions (mark, palette, type pairing, mood), Kai skins one UI surface per direction, and the gallery is rendered and checked. finalists: for the directions the author chose, Iris works up the full token set, the logo system, the type scale, and the app icon, Kai three UI surfaces, as a second gallery. guide: Kai exports brand/final/, Iris writes the brand direction record and docs/brand-guide.md, a checker validates both. Run through /ck:brand-guide, which owns the two reviews and passes an object: stage (proposals | finalists | guide), runId, runDir (absolute cache directory), projectRoot (absolute path of the project repository), pluginRoot (required; the gallery renderer lives there), timestamp, source (absolute path of docs/opportunity.md or docs/brief.md), inputs (absolute paths of docs/PRD.md and docs/market-research.md when they exist), chosen (the labels picked at the previous review), changes (what the author asked to change, one string), startAt (optional step within the stage).',
  phases: [
    { title: 'Positioning', detail: 'ck:toni: the product name, the audience, and one positioning line per candidate direction' },
    { title: 'Directions', detail: 'ck:iris: four to six brand directions, each with a mark, a palette, a type pairing, and mood words; or the full system for each finalist' },
    { title: 'Surfaces', detail: 'ck:kai: one UI surface per direction in its skin; three per finalist' },
    { title: 'Gallery', detail: 'the page rendered by scripts/render-gallery.py and checked against the gallery contract; ck:iris fixes at most twice' },
    { title: 'Export', detail: 'ck:kai writes brand/final/: the marks, tokens.json, tokens.css, the surfaces, and a file list' },
    { title: 'Documents', detail: 'ck:iris writes the brand direction record and docs/brand-guide.md; one neutral Haiku agent checks both contracts; ck:iris revises at most twice' },
  ],
  personas: ['iris', 'kai', 'toni'],
}

// This workflow is launched by the brand-guide skill with an object; it needs the plugin root to find the
// gallery renderer, so a direct launch with typed text is refused with the command to use instead.
const a = (args && typeof args === 'object') ? args : {}
if (!a.pluginRoot) {
  throw new Error('brand: run /ck:brand-guide. It passes the plugin root this workflow needs to render the galleries with scripts/render-gallery.py, and it owns the two reviews between the stages.')
}
if (!a.source) {
  throw new Error('brand: needs docs/opportunity.md or docs/brief.md as the source of the positioning. Run /ck:opportunity <idea> or /ck:brief <idea> first.')
}
const STAGES = ['proposals', 'finalists', 'guide']
const stage = STAGES.includes(a.stage) ? a.stage : 'proposals'
const projectRoot = a.projectRoot || '.'
const runDir = a.runDir || (projectRoot + '/.ck/runs/brand-latest')
const runId = a.runId || 'brand-direct'
const stamp = a.timestamp || 'today (write the date from `date -u`)'
const brandDir = projectRoot + '/brand'
const inputs = Array.isArray(a.inputs) ? a.inputs : []
const chosen = Array.isArray(a.chosen) ? a.chosen.map(c => String(c).trim().toUpperCase()).filter(Boolean) : []
const changes = typeof a.changes === 'string' && a.changes.trim() ? a.changes.trim() : ''
const renderer = 'python3 "' + a.pluginRoot + '/scripts/render-gallery.py"'
const contractStep = 'Read ' + a.pluginRoot + '/skills/brand-artifact/SKILL.md (the brand contracts: Part A is the direction record, Part B the guide, each with its checklist).'
const galleryContractStep = 'Read ' + a.pluginRoot + '/skills/gallery-artifact/SKILL.md (the gallery contract).'
const readInputs = inputs.length ? `Also read: ${inputs.join(', ')}. ` : ''
const changesLine = changes ? `The author asked for these changes at the review, apply them: ${changes}\n` : ''
const housekeeping = a.runDir ? '' : 'If ' + projectRoot + '/.git exists, run this with the Bash tool so the run cache stays out of git status: grep -qxF ".ck/" ' + projectRoot + '/.git/info/exclude 2>/dev/null || echo ".ck/" >> ' + projectRoot + '/.git/info/exclude . If it is refused, skip it and never mention it in a document. '
const ONE_WRITE = 'Write each file whole with one Write call; do not build a file with piecemeal edits, and do not re-read, edit, count, or check it after writing: return as soon as the files are written, because a checker runs next and names anything unmet. '
const SMALLEST_EDITS = 'Make the smallest edits that satisfy each listed item, with the Edit tool on the passages concerned, in at most ten Edit calls; where the item is length, cut whole paragraphs of repetition until the document is at least five percent under the cap, so one revision settles it. Do not rewrite the document, do not re-read files you were not asked to read, do not run web searches, and do not count, grep, or check the result: the checker runs again next. If an item needs a source you do not have, mark the claim unverified instead of inventing one. '
const SVG_RULES = 'Every SVG is a single inline <svg> element with a viewBox, no XML prolog, no external references, no raster images, no scripts, and under 60 lines; text uses the direction\'s font families with a generic fallback. '
const HTML_RULES = 'Every HTML file is a fragment (no html, head, or body tags, no style or script elements): elements with inline style attributes only, using the direction\'s hex values and font families, no external references. '
const MIN_DIRECTIONS = 4
const MAX_DIRECTIONS = 6
const MAX_REVISIONS = 2
const VALIDATOR_MODEL = 'claude-haiku-4-5-20251001'
// The section order of the two brand documents, from skills/brand-artifact/SKILL.md (test 7 checks they agree).
const RECORD_SECTIONS = ['Decision', 'Locked layout system', 'House tokens', 'Theme lineup', 'Rationale', 'Open items', 'Asset list']
const GUIDE_SECTIONS = ['Brand overview and personality', 'Brand architecture', 'Logo system', 'Color system', 'Typography', 'UI surface system', 'Art direction', 'Product-specific sections', 'App icon', 'Publisher credit and legal']
const FINAL_SVGS = ['mark.svg', 'secondary.svg', 'lockup-horizontal.svg', 'lockup-stacked.svg', 'clearspace.svg', 'misuse.svg', 'icon.svg']

const ORDERS = {
  proposals: ['positioning', 'directions', 'surfaces', 'gallery'],
  finalists: ['directions', 'surfaces', 'gallery'],
  guide: ['export', 'documents', 'validate'],
}
const ORDER = ORDERS[stage]
const startAt = ORDER.includes(a.startAt) ? a.startAt : ORDER[0]
const runs = step => ORDER.indexOf(step) >= ORDER.indexOf(startAt)
if (startAt !== ORDER[0]) log(`brand ${stage}: starting at ${startAt}; the earlier steps' files are already on disk`)
if ((stage === 'finalists' || stage === 'guide') && !chosen.length) {
  throw new Error(`brand: the ${stage} stage needs the labels chosen at the previous review, for example chosen: ["A", "C"]${stage === 'guide' ? ' (one label for the guide)' : ''}.`)
}
const pick = stage === 'guide' ? chosen[0] : null

const POSITIONING_SCHEMA = {
  type: 'object',
  properties: {
    product: { type: 'string' },
    audience: { type: 'string' },
    directions: {
      type: 'array',
      items: {
        type: 'object',
        properties: { angle: { type: 'string' }, line: { type: 'string' }, audience: { type: 'string' } },
        required: ['angle', 'line', 'audience'],
      },
    },
  },
  required: ['product', 'audience', 'directions'],
}
const VARIANTS_SCHEMA = {
  type: 'object',
  properties: {
    path: { type: 'string' },
    labels: { type: 'array', items: { type: 'string' } },
    names: { type: 'array', items: { type: 'string' } },
    files: { type: 'number' },
  },
  required: ['path', 'labels', 'names', 'files'],
}
const SURFACES_SCHEMA = {
  type: 'object',
  properties: { labels: { type: 'array', items: { type: 'string' } }, files: { type: 'number' } },
  required: ['labels', 'files'],
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
const ASSETS_SCHEMA = {
  type: 'object',
  properties: {
    dir: { type: 'string' },
    files: { type: 'array', items: { type: 'object', properties: { name: { type: 'string' }, purpose: { type: 'string' } }, required: ['name', 'purpose'] } },
    tokens: { type: 'number' },
  },
  required: ['dir', 'files', 'tokens'],
}
const DOCS_SCHEMA = {
  type: 'object',
  properties: {
    recordPath: { type: 'string' },
    guidePath: { type: 'string' },
    personality: { type: 'array', items: { type: 'string' } },
    tokens: { type: 'number' },
    openItems: { type: 'number' },
    questions: { type: 'array', items: { type: 'string' } },
  },
  required: ['recordPath', 'guidePath', 'personality', 'tokens', 'openItems', 'questions'],
}

// Render the round's gallery and check it, with Iris fixing what the checker names, at most twice.
async function gallery(roundDir, roundName) {
  phase('Gallery')
  const out = roundDir + '/gallery.html'
  let validation = null
  for (let round = 1; round <= MAX_REVISIONS + 1; round++) {
    validation = await agent(
      `Run this command with the Bash tool, exactly: ${renderer} --dir "${roundDir}" --out "${out}"\n` +
      `If it exits non-zero, return valid=false with its error text as the one item in missing (it names the ` +
      `file that is missing or wrong). If it succeeds: ${galleryContractStep} Then check ${out} against the ` +
      `contract's checklist with grep and wc, not by reading the whole page: the count of 'class="variant"' ` +
      `equals the number of variants in ${roundDir}/variants.json; each variant section has 'class="mark"', ` +
      `'class="swatches"', 'class="specimen"', and 'class="frame"'; '@claude' appears in the banner; the file ` +
      `is under 16 MB. Return valid=true only if every item holds, and one line per unmet item in missing.`,
      { label: `gallery:${roundName}:${round}`, phase: 'Gallery', model: VALIDATOR_MODEL, effort: 'low', schema: VALIDATION_SCHEMA },
    )
    if (!validation) { log('gallery: the checker returned nothing; the page may not have been rendered'); break }
    if (validation.valid) { log(`gallery: ${out} rendered and passes the gallery contract (round ${round})`); break }
    if (round > MAX_REVISIONS) { log(`gallery: still unmet after ${MAX_REVISIONS} fix(es): ${validation.missing.join(' | ')}`); break }
    log(`gallery: ${validation.missing.length} unmet item(s); Iris fixes (fix ${round} of ${MAX_REVISIONS})`)
    const fixed = await agent(
      `The gallery renderer or the checker found these problems with the files under ${roundDir}:\n` +
      validation.missing.map(m => '- ' + m).join('\n') + '\n' +
      `Fix the files named so each item holds (a missing file is written whole; a wrong one is edited). ` +
      SVG_RULES + HTML_RULES + SMALLEST_EDITS +
      `Return the object: path '${roundDir}/variants.json', the labels and names from it, and the number of files you wrote or edited.`,
      { label: `iris:fix:${roundName}:${round}`, phase: 'Gallery', agentType: 'ck:iris', effort: 'medium', schema: VARIANTS_SCHEMA },
    )
    if (!fixed) { log('gallery: the fix returned nothing; keeping the files as they are'); break }
  }
  return { path: out, validation }
}

// ---- proposals ----
if (stage === 'proposals') {
  const roundDir = brandDir + '/proposals'
  let positioning = null
  if (runs('positioning')) {
    phase('Positioning')
    positioning = await agent(
      `Read ${a.source} (the product's opportunity analysis or brief). ${readInputs}` +
      `The project repository is ${projectRoot}. ` + housekeeping +
      `Name the product as it should appear in a brand guide (product) and its audience in one sentence (audience). ` +
      `Then write between ${MIN_DIRECTIONS} and ${MAX_DIRECTIONS} candidate positioning angles for a brand ` +
      `direction, each with: angle (two or three words naming the territory, such as "field manual" or "winter ` +
      `quiet"), line (the positioning line in one sentence that the brand direction must serve), and audience ` +
      `(who this angle wins, one sentence). Make them different from each other: at least one is what the ` +
      `category expects, at least one refuses it, and none repeats another's line. Apply your Required Behaviors ` +
      `in subagent form. ` + ONE_WRITE +
      `Write the object as JSON to ${runDir}/positioning.json (create the directory if needed) and return it.`,
      { label: 'toni:positioning', phase: 'Positioning', agentType: 'ck:toni', effort: 'medium', schema: POSITIONING_SCHEMA },
    )
    if (!positioning) throw new Error('brand: Toni returned no positioning')
    positioning.directions = positioning.directions.slice(0, MAX_DIRECTIONS)
    if (positioning.directions.length < MIN_DIRECTIONS) log(`positioning: only ${positioning.directions.length} angle(s); the gallery will have that many directions`)
    log(`positioning: ${positioning.product}; ${positioning.directions.length} angle(s): ${positioning.directions.map(d => d.angle).join(', ')}`)
  }

  let directions = null
  if (runs('directions')) {
    phase('Directions')
    directions = await agent(
      `Read ${runDir}/positioning.json (the product, the audience, and one positioning angle per direction) ` +
      `and ${a.source}. ${readInputs}` +
      `Design one brand direction per angle, in the angles' order, labeled A, B, C, and so on. ` + changesLine +
      `Write ${roundDir}/variants.json (create the directories if needed) as JSON: {"product": the product name, ` +
      `"round": "Proposals, round 1", "kind": "brand", "variants": [ one object per direction: "label", "name" ` +
      `(the direction's name, two or three words), "rationale" (why this direction, three sentences), ` +
      `"tradeoff" (what it gives up, one or two sentences), "satisfies" (the text "Positioning line: " followed ` +
      `by the angle's line verbatim), "mood" (three to five words), "swatches" (three to six objects with ` +
      `"name", "hex" as #rrggbb, and "role" among background, ink, accent, functional), "typePair" ` +
      `({"heading": a Google Fonts family, "body": a Google Fonts family}) ] }. ` +
      `Then write the hero mark for each direction to ${roundDir}/<label>/mark.svg: a name treatment or a ` +
      `symbol with the name, in the direction's palette and type. ` + SVG_RULES + ONE_WRITE +
      `Apply your Required Behaviors in subagent form. Return the object: path '${roundDir}/variants.json', ` +
      `the labels and names in order, and the number of files written.`,
      { label: 'iris:directions', phase: 'Directions', agentType: 'ck:iris', effort: 'medium', schema: VARIANTS_SCHEMA },
    )
    if (!directions) throw new Error('brand: Iris returned no directions')
    log(`directions: ${directions.labels.length} written: ${directions.labels.map((l, i) => l + ' ' + directions.names[i]).join(', ')}`)
  }

  if (runs('surfaces')) {
    phase('Surfaces')
    const surfaces = await agent(
      `Read ${roundDir}/variants.json and each direction's ${roundDir}/<label>/mark.svg. ${readInputs}` +
      `For each direction, write one UI surface in that direction's skin to ${roundDir}/<label>/surface.html: ` +
      `the surface the product's users see most (a screen fragment with a heading, body text, one list or table, ` +
      `and a primary and a secondary button), at most 80 lines, so the author can see the direction as a product ` +
      `and not only as a mark. ` + HTML_RULES + ONE_WRITE +
      `Apply your Required Behaviors in subagent form. Return the labels you wrote a surface for and the file count.`,
      { label: 'kai:surfaces', phase: 'Surfaces', agentType: 'ck:kai', effort: 'medium', schema: SURFACES_SCHEMA },
    )
    if (!surfaces) throw new Error('brand: Kai returned no surfaces')
    log(`surfaces: ${surfaces.files} written`)
  }

  const g = runs('gallery') ? await gallery(roundDir, 'proposals') : { path: roundDir + '/gallery.html', validation: null }
  return {
    runId, stage, startedAt: startAt,
    gallery: g.path,
    variants: directions ? directions.labels.map((l, i) => ({ label: l, name: directions.names[i] })) : [],
    product: positioning ? positioning.product : null,
    validation: g.validation,
    generated: stamp,
  }
}

// ---- finalists ----
if (stage === 'finalists') {
  const roundDir = brandDir + '/finalists'
  let finalists = null
  if (runs('directions')) {
    phase('Directions')
    finalists = await agent(
      `Read ${brandDir}/proposals/variants.json and, for the directions the author chose at the review ` +
      `(${chosen.join(', ')}), the files under ${brandDir}/proposals/<label>/. Also read ${a.source}. ${readInputs}` +
      changesLine +
      `Work each chosen direction up in full, in the order given, relabeled from A (the name carries the ` +
      `proposal it came from, for example "Snow Line (from proposal C)"). ` +
      `Write ${roundDir}/variants.json (create the directories if needed) as JSON: {"product", "round": ` +
      `"Finalists", "kind": "brand", "variants": [ per finalist: "label", "name", "rationale" (three sentences), ` +
      `"tradeoff", "satisfies" ("Positioning line: " and the line), "mood", "swatches" (the full token set, each ` +
      `with "name", "hex", "role": background, surface, ink, muted ink, accent, second accent if any, success, ` +
      `warning, error, info), "typePair", "typeScale" ([{"role", "family", "size", "weight"}] for display, h1, h2, ` +
      `body, caption) ] }. ` +
      `Then write the logo system for each finalist under ${roundDir}/<label>/: ${FINAL_SVGS.join(', ')} ` +
      `(the primary mark; the secondary mark or symbol alone; the horizontal and the stacked lockup; the ` +
      `primary mark with its clear space and minimum size drawn and labeled; one misuse example, struck ` +
      `through, with a caption saying what is wrong; the app icon on a square viewBox with a safe area). ` +
      SVG_RULES + ONE_WRITE +
      `Apply your Required Behaviors in subagent form. Return the object: path '${roundDir}/variants.json', ` +
      `the labels and names in order, and the number of files written.`,
      { label: 'iris:finalists', phase: 'Directions', agentType: 'ck:iris', effort: 'medium', schema: VARIANTS_SCHEMA },
    )
    if (!finalists) throw new Error('brand: Iris returned no finalists')
    log(`finalists: ${finalists.labels.length} worked up from ${chosen.join(', ')}; ${finalists.files} file(s)`)
  }

  if (runs('surfaces')) {
    phase('Surfaces')
    const surfaces = await agent(
      `Read ${roundDir}/variants.json and each finalist's files under ${roundDir}/<label>/. ${readInputs}` +
      changesLine +
      `For each finalist, write three UI surfaces in that skin to one file, ${roundDir}/<label>/surface.html, ` +
      `side by side in a flex row that wraps: a card with a heading, body, and a tag; a form with a text input, ` +
      `a select, and the primary and secondary buttons in their default, hover (drawn as a second instance), and ` +
      `disabled states; and the product's main screen fragment (a game's HUD, a data product's dashboard, an ` +
      `app's home). At most 150 lines. ` + HTML_RULES + ONE_WRITE +
      `Apply your Required Behaviors in subagent form. Return the labels and the file count.`,
      { label: 'kai:finalist-surfaces', phase: 'Surfaces', agentType: 'ck:kai', effort: 'medium', schema: SURFACES_SCHEMA },
    )
    if (!surfaces) throw new Error('brand: Kai returned no surfaces')
    log(`surfaces: ${surfaces.files} written`)
  }

  const g = runs('gallery') ? await gallery(roundDir, 'finalists') : { path: roundDir + '/gallery.html', validation: null }
  return {
    runId, stage, startedAt: startAt,
    gallery: g.path,
    from: chosen,
    variants: finalists ? finalists.labels.map((l, i) => ({ label: l, name: finalists.names[i] })) : [],
    validation: g.validation,
    generated: stamp,
  }
}

// ---- guide ----
const finalDir = brandDir + '/final'
const recordPath = projectRoot + '/docs/decisions/' + (a.timestamp ? a.timestamp + '-' : '') + 'brand-direction.md'
const guidePath = projectRoot + '/docs/brand-guide.md'
let assets = null
if (runs('export')) {
  phase('Export')
  assets = await agent(
    `Read ${brandDir}/finalists/variants.json and the files under ${brandDir}/finalists/${pick}/ (the finalist ` +
    `the author chose, label ${pick}). ` + changesLine +
    `Write the final assets under ${finalDir}/ (create it; replace what is there): ${FINAL_SVGS.join(', ')} ` +
    `from the finalist's files, with the author's changes applied (copy a file with cp when it is unchanged); ` +
    `tokens.json ({"color": {token name: hex} for every swatch, "type": {role: {"family", "size", "weight"}} ` +
    `from the type scale, "space": the spacing scale in px, "radius": {name: px}, "elevation": {name: a CSS ` +
    `box-shadow}}); tokens.css (the same values as custom properties on :root, named --color-<token>, ` +
    `--font-<role>, --space-<n>, --radius-<name>, --shadow-<name>); surfaces.html (the three surfaces from ` +
    `${brandDir}/finalists/${pick}/surface.html rewritten to use the custom properties, with a style element ` +
    `that imports tokens.css); and README.md, a table of every file in the directory with its purpose. ` +
    ONE_WRITE + SVG_RULES +
    `Apply your Required Behaviors in subagent form. Return dir '${finalDir}', the files with their purposes, ` +
    `and the number of color tokens.`,
    { label: 'kai:export', phase: 'Export', agentType: 'ck:kai', effort: 'medium', schema: ASSETS_SCHEMA },
  )
  if (!assets) throw new Error('brand: Kai returned no assets')
  log(`export: ${assets.files.length} file(s) under ${finalDir}, ${assets.tokens} color token(s)`)
}

let docs = null
if (runs('documents')) {
  phase('Documents')
  docs = await agent(
    `${contractStep} Read ${a.source}, ${brandDir}/finalists/variants.json, ${finalDir}/tokens.json, and ` +
    `${finalDir}/README.md. ${readInputs}The author chose finalist ${pick} at the review. ` + changesLine +
    `Write two documents. ` +
    `First, the brand direction record at ${recordPath} (create the directory if needed) to Part A, sections ` +
    `in this order: ` + RECORD_SECTIONS.map(s => '"' + s + '"').join(', ') + `. Decision names the chosen ` +
    `finalist by label and name and every other finalist by label with the reason it was not chosen. House ` +
    `tokens is a table, token | value | role, with every color token from tokens.json at the same value. Asset ` +
    `list names every file under ${finalDir}/ with its purpose, from README.md. Open items is present even ` +
    `when empty. ` +
    `Second, the brand identity guide at ${guidePath} to Part B, sections in this order: ` +
    GUIDE_SECTIONS.map(s => '"' + s + '"').join(', ') + `. The personality words are the same three to five as ` +
    `the record's rationale uses, each with what it rules out. Logo system names each asset by its path under ` +
    `brand/final/ and describes the misuse example. Color system lists every token with its value, and states ` +
    `the contrast ratio (WCAG 2, one decimal, computed from the hex values) for every text-on-background pair, ` +
    `marking any pair under 4.5:1 as decorative or changing the pairing. Product-specific sections is present ` +
    `even when empty, saying so. Under 3,000 words. Date both documents ${stamp}. ` + ONE_WRITE +
    `Apply your Required Behaviors in subagent form. Return only the object: both paths, the personality words, ` +
    `the number of color tokens, the number of open items, and any questions for the author.`,
    { label: 'iris:documents', phase: 'Documents', agentType: 'ck:iris', effort: 'medium', schema: DOCS_SCHEMA },
  )
  if (!docs) throw new Error('brand: Iris returned no documents; the assets are under ' + finalDir)
  log(`documents: ${docs.recordPath}; ${docs.guidePath}; personality ${docs.personality.join(', ')}; ${docs.openItems} open item(s)`)
}

let validation = null
if (runs('validate')) {
  phase('Documents')
  for (let round = 1; round <= MAX_REVISIONS + 1; round++) {
    validation = await agent(
      `${contractStep} Read ${recordPath}, ${guidePath}, and ${finalDir}/tokens.json, and list the files under ` +
      `${finalDir}/. Check the record against every numbered item of Checklist A and the guide against every ` +
      `numbered item of Checklist B, including the section orders. Return valid=true only if every item holds. ` +
      `For each unmet item, one line in missing that quotes the item and says what is absent or wrong. Judge ` +
      `the shape, not the design.`,
      { label: `validate:${round}`, phase: 'Documents', model: VALIDATOR_MODEL, effort: 'low', schema: VALIDATION_SCHEMA },
    )
    if (!validation) { log('validate: validator returned nothing; proceeding unvalidated'); break }
    if (validation.valid) { log(`validate: both documents pass their checklists (round ${round})`); break }
    if (round > MAX_REVISIONS) { log(`validate: still unmet after ${MAX_REVISIONS} revision(s): ${validation.missing.join(' | ')}`); break }
    log(`validate: ${validation.missing.length} unmet item(s); Iris revises (revision ${round} of ${MAX_REVISIONS})`)
    const revised = await agent(
      `${contractStep} Read ${recordPath} and ${guidePath}. A checker found these unmet checklist items:\n` +
      validation.missing.map(m => '- ' + m).join('\n') + '\n' +
      `Revise the document concerned so each item holds. ` + SMALLEST_EDITS +
      `Return only the updated object; recordPath must be '${recordPath}' and guidePath '${guidePath}'.`,
      { label: `iris:revise:${round}`, phase: 'Documents', agentType: 'ck:iris', effort: 'medium', schema: DOCS_SCHEMA },
    )
    if (!revised) { log('validate: revision returned nothing; keeping the previous documents'); break }
    docs = revised
  }
}

return {
  runId, stage, startedAt: startAt,
  chosen: pick,
  record: recordPath,
  guide: guidePath,
  assets: assets ? assets.files.length : null,
  personality: docs ? docs.personality : [],
  questions: docs ? docs.questions : [],
  validation,
  generated: stamp,
}
