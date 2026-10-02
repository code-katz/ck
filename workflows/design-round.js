export const meta = {
  name: 'design-round',
  description: 'One feature from the PRD to design mockups, in two stages with a gallery review between them. variants: River extracts the feature (its requirements, acceptance criteria, user, metric, constraints, and the screens it implies) into the run directory, Kai writes three labeled concepts and then the screens of each with their empty, loading, and error states, the gallery is rendered and checked. refine: Kai writes the chosen variant at full fidelity (chosen.html) and the design spec, Robin adds the acceptance checks, a checker validates the spec. Run through /ck:design, which owns the review and passes an object: stage (variants | refine), feature (the name or requirement number typed), slug (the docs/design/<slug>/ folder), runId, runDir (absolute cache directory), projectRoot (absolute path of the project repository), pluginRoot (required; the gallery renderer lives there), timestamp, prd (absolute path of docs/PRD.md), brand (absolute path of docs/brand-guide.md or empty), tokens (absolute path of brand/final/tokens.css or empty), architecture (absolute path of docs/ARCHITECTURE.md or empty), chosen (the label picked at the review), changes (what the author asked to change), startAt (optional step within the stage).',
  phases: [
    { title: 'Extract', detail: 'ck:river, low effort: the feature from the PRD, in one page under the run directory' },
    { title: 'Concepts', detail: 'ck:kai: three labeled variants, each a different answer to the feature, with the screens each needs' },
    { title: 'Screens', detail: 'three ck:kai agents in parallel, one per variant: every screen with its empty, loading, and error states, in the brand skin or a neutral one' },
    { title: 'Gallery', detail: 'the page rendered by scripts/render-gallery.py and checked against the gallery contract; ck:kai fixes at most twice' },
    { title: 'Refine', detail: 'ck:kai applies the review changes to the chosen variant\'s files, adds the success states, renders chosen.html with scripts/render-gallery.py, and writes the design spec' },
    { title: 'Acceptance', detail: 'ck:robin: one check per screen a tester could verify, appended to the spec' },
    { title: 'Validate', detail: 'one neutral Haiku agent checks the design spec contract; ck:kai revises at most twice' },
  ],
  personas: ['river', 'kai', 'robin'],
}

// Launched by the design skill with an object; a direct launch with typed text is refused with the command to use.
const a = (args && typeof args === 'object') ? args : {}
if (!a.pluginRoot) {
  throw new Error('design-round: run /ck:design <feature>. It passes the plugin root this workflow needs to render the gallery with scripts/render-gallery.py, and it owns the review between the stages.')
}
if (!a.feature || !a.prd) {
  throw new Error('design-round: needs the feature (a name or a requirement number from docs/PRD.md) and the path of docs/PRD.md. Run /ck:prd first if there is no PRD.')
}
const STAGES = ['variants', 'refine']
const stage = STAGES.includes(a.stage) ? a.stage : 'variants'
const projectRoot = a.projectRoot || '.'
const runDir = a.runDir || (projectRoot + '/.ck/runs/design-latest')
const runId = a.runId || 'design-direct'
const stamp = a.timestamp || 'today (write the date from `date -u`)'
const slug = a.slug || 'feature'
const designDir = projectRoot + '/docs/design/' + slug
const featurePath = runDir + '/feature.md'
const chosen = typeof a.chosen === 'string' ? a.chosen.trim().toUpperCase() : ''
const changes = typeof a.changes === 'string' && a.changes.trim() ? a.changes.trim() : ''
const brand = a.brand || ''
const tokens = a.tokens || ''
const skinNote = brand ? 'Brand skin from docs/brand-guide.md.' : 'Neutral skin: no brand guide yet; run /ck:brand-guide to add one.'
const skinStep = brand
  ? `Read ${brand}${tokens ? ' and ' + tokens : ''}: the screens use the brand's tokens (colors, type, radii) and its UI surface system. `
  : 'There is no brand guide, so use a neutral skin: system fonts, a near-black ink on white, one gray, one blue accent for primary actions. '
const renderer = 'python3 "' + a.pluginRoot + '/scripts/render-gallery.py"'
const contractStep = 'Read ' + a.pluginRoot + '/skills/design-spec-artifact/SKILL.md (the design spec contract and its checklist).'
const galleryContractStep = 'Read ' + a.pluginRoot + '/skills/gallery-artifact/SKILL.md (the gallery contract).'
const archStep = a.architecture ? `Read ${a.architecture} for the constraints the architecture puts on this feature. ` : ''
const changesLine = changes ? `The author asked for these changes at the review, apply them: ${changes}\n` : ''
const housekeeping = a.runDir ? '' : 'If ' + projectRoot + '/.git exists, make sure the line ".ck/" is in ' + projectRoot + '/.git/info/exclude (append it if missing). '
const ONE_WRITE = 'Write each file whole with one Write call; do not build a file with piecemeal edits, and do not re-read, edit, count, or check it after writing: return as soon as the files are written, because a checker runs next and names anything unmet. '
const SMALLEST_EDITS = 'Make the smallest edits that satisfy each listed item, with the Edit tool on the passages concerned, in at most ten Edit calls; where the item is length, cut whole sentences and paragraphs of repetition rather than trimming words. Do not rewrite the document, do not re-read files you were not asked to read, do not run web searches, and do not count, grep, or check the result: the checker runs again next. If an item needs a source you do not have, mark the claim unverified instead of inventing one. '
const HTML_RULES = 'Every screen file is an HTML fragment (no html, head, body, style, or script elements): elements with inline style attributes only, no external references, no raster images; an inline SVG is fine for an icon. '
const VARIANT_LABELS = ['A', 'B', 'C']
const MAX_REVISIONS = 2
const VALIDATOR_MODEL = 'claude-haiku-4-5-20251001'
// The section order of the design spec, from skills/design-spec-artifact/SKILL.md (test 7 checks they agree).
const SPEC_SECTIONS = ['Feature', 'Chosen variant', 'Screens', 'Components', 'Interactions', 'States', 'Copy', 'Accessibility', 'Requirement traceability', 'Acceptance']

const ORDERS = { variants: ['extract', 'concepts', 'screens', 'gallery'], refine: ['refine', 'acceptance', 'validate'] }
const ORDER = ORDERS[stage]
const startAt = ORDER.includes(a.startAt) ? a.startAt : ORDER[0]
const runs = step => ORDER.indexOf(step) >= ORDER.indexOf(startAt)
if (startAt !== ORDER[0]) log(`design-round ${stage}: starting at ${startAt}; the earlier steps' files are already on disk`)
if (stage === 'refine' && !chosen) throw new Error('design-round: the refine stage needs the label chosen at the review, for example chosen: "B".')

const FEATURE_SCHEMA = {
  type: 'object',
  properties: {
    found: { type: 'boolean' },
    path: { type: 'string' },
    name: { type: 'string' },
    requirements: { type: 'array', items: { type: 'number' } },
    acceptanceCriteria: { type: 'number' },
    screens: { type: 'array', items: { type: 'string' } },
    notes: { type: 'string' },
  },
  required: ['found', 'path', 'name', 'requirements', 'acceptanceCriteria', 'screens', 'notes'],
}
const CONCEPTS_SCHEMA = {
  type: 'object',
  properties: {
    path: { type: 'string' },
    variants: {
      type: 'array',
      items: {
        type: 'object',
        properties: { label: { type: 'string' }, name: { type: 'string' }, screens: { type: 'array', items: { type: 'string' } } },
        required: ['label', 'name', 'screens'],
      },
    },
  },
  required: ['path', 'variants'],
}
const SCREENS_SCHEMA = {
  type: 'object',
  properties: { label: { type: 'string' }, files: { type: 'number' }, screens: { type: 'array', items: { type: 'string' } } },
  required: ['label', 'files', 'screens'],
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
const SPEC_SCHEMA = {
  type: 'object',
  properties: {
    chosenPath: { type: 'string' },
    specPath: { type: 'string' },
    screens: { type: 'number' },
    components: { type: 'number' },
    traceabilityRows: { type: 'number' },
    questions: { type: 'array', items: { type: 'string' } },
  },
  required: ['chosenPath', 'specPath', 'screens', 'components', 'traceabilityRows', 'questions'],
}
const CHECKS_SCHEMA = {
  type: 'object',
  properties: { specPath: { type: 'string' }, checks: { type: 'number' }, screens: { type: 'number' } },
  required: ['specPath', 'checks', 'screens'],
}

// ---- variants ----
if (stage === 'variants') {
  let feature = null
  if (runs('extract')) {
    phase('Extract')
    feature = await agent(
      `Read ${a.prd}. The author asked to design this feature: "${a.feature}". It is a requirement number or a ` +
      `name or phrase from the PRD's Requirements section. ` + housekeeping +
      `If you cannot find it in the PRD with reasonable confidence, return found=false, say in notes what the ` +
      `nearest requirements are, and write nothing. Otherwise write ${featurePath} (create the directory if ` +
      `needed): "# <feature name>"; "## Requirements" with each requirement's number and text verbatim, ` +
      `including every acceptance criterion; "## User" and "## Success metric" from the PRD; "## Constraints" ` +
      `(the scope, non-goals, assumptions, and sequencing lines that bind this feature); "## Screens" with the ` +
      `two to four screens the feature implies, one line each saying what the user does there. One page. ` +
      ONE_WRITE + `Return the object: found, path '${featurePath}', the name, the requirement numbers, the ` +
      `count of acceptance criteria, the screen names, and notes.`,
      { label: 'river:extract', phase: 'Extract', agentType: 'ck:river', effort: 'low', schema: FEATURE_SCHEMA },
    )
    if (!feature) throw new Error('design-round: River returned nothing for the feature')
    if (!feature.found) {
      log(`extract: "${a.feature}" was not found in the PRD; ${feature.notes}`)
      return { runId, stage, found: false, feature: a.feature, notes: feature.notes, gallery: null, variants: [], validation: null, generated: stamp }
    }
    log(`extract: ${feature.name}; requirements ${feature.requirements.join(', ')}; ${feature.acceptanceCriteria} acceptance criteria; screens ${feature.screens.join(', ')}`)
  }

  let concepts = null
  if (runs('concepts')) {
    phase('Concepts')
    concepts = await agent(
      `Read ${featurePath} (the feature, its requirements with acceptance criteria, user, metric, constraints, ` +
      `and the screens it implies). ${archStep}${brand ? 'Read ' + brand + ' for the brand personality. ' : ''}` +
      changesLine +
      `Write three variants of this feature's design, labeled ${VARIANT_LABELS.join(', ')}, each a different ` +
      `answer to the same requirements (a different structure or interaction model, not a different color). ` +
      `Write ${designDir}/variants.json (create the directories if needed) as JSON: {"product": the product ` +
      `name from the PRD, "round": "<feature name>: variants", "kind": "design", "skin": "${skinNote}", ` +
      `"variants": [ per variant: "label", "name" (two or three words), "rationale" (why this, three ` +
      `sentences), "tradeoff" (what it gives up, one or two sentences), "satisfies" ("Requirement <n>: <the ` +
      `first words of its text>" for each requirement number this variant serves, comma-separated), ` +
      `"screens": [ {"name": the screen name, "frame": "phone" or "desktop" by where the product lives} ] ] }. ` +
      `Every variant covers every screen the feature implies. Write nothing else. ` + ONE_WRITE +
      `Apply your Required Behaviors in subagent form. Return path '${designDir}/variants.json' and, per ` +
      `variant, its label, name, and screen names.`,
      { label: 'kai:concepts', phase: 'Concepts', agentType: 'ck:kai', effort: 'medium', schema: CONCEPTS_SCHEMA },
    )
    if (!concepts) throw new Error('design-round: Kai returned no concepts')
    concepts.variants = concepts.variants.slice(0, VARIANT_LABELS.length)
    log(`concepts: ${concepts.variants.map(v => v.label + ' ' + v.name + ' (' + v.screens.length + ' screens)').join('; ')}`)
  }

  if (runs('screens')) {
    phase('Screens')
    const list = concepts ? concepts.variants : VARIANT_LABELS.map(l => ({ label: l, name: '', screens: [] }))
    const written = (await parallel(list.map(v => () => agent(
      `Read ${featurePath} and ${designDir}/variants.json; you are writing variant ${v.label}${v.name ? ' (' + v.name + ')' : ''}. ` +
      skinStep + changesLine +
      `For each screen of this variant, write four files under ${designDir}/${v.label}/, named after the ` +
      `screen in lower case with hyphens for anything that is not a letter or digit: <screen>.html (the screen ` +
      `with realistic content from the feature, not lorem ipsum), <screen>.empty.html (nothing to show yet, ` +
      `with the one action that fills it), <screen>.loading.html, and <screen>.error.html (a failure the user ` +
      `can recover from, with the recovery action). A phone screen is 360 pixels wide; a desktop screen fills ` +
      `its frame. Each file is under 80 lines. ` + HTML_RULES + ONE_WRITE +
      `Apply your Required Behaviors in subagent form. Return the label, the file count, and the screen names.`,
      { label: `kai:screens:${v.label}`, phase: 'Screens', agentType: 'ck:kai', effort: 'medium', schema: SCREENS_SCHEMA },
    )))).filter(Boolean)
    if (!written.length) throw new Error('design-round: no variant\'s screens were written')
    const missing = list.filter(v => !written.some(w => w.label === v.label)).map(v => v.label)
    if (missing.length) log(`screens: variant(s) ${missing.join(', ')} returned nothing; the gallery check will name the missing files`)
    log(`screens: ${written.reduce((n, w) => n + w.files, 0)} file(s) for ${written.map(w => w.label).join(', ')}`)
  }

  let validation = null
  const galleryPath = designDir + '/gallery.html'
  if (runs('gallery')) {
    phase('Gallery')
    for (let round = 1; round <= MAX_REVISIONS + 1; round++) {
      validation = await agent(
        `Run this command with the Bash tool, exactly: ${renderer} --dir "${designDir}" --out "${galleryPath}"\n` +
        `If it exits non-zero, return valid=false with its error text as the one item in missing (it names the ` +
        `file that is missing or wrong). If it succeeds: ${galleryContractStep} Then check ${galleryPath} ` +
        `against the contract's checklist with grep and wc, not by reading the whole page: the count of ` +
        `'class="variant"' is ${VARIANT_LABELS.length}; each variant section has at least one 'class="device' ` +
        `and one '<h3>States</h3>'; '@claude' appears in the banner; and every requirement number named under ` +
        `Satisfies in ${designDir}/variants.json is a numbered item of the Requirements section of ${a.prd} ` +
        `(grep for the line starting with that number and a period). Return valid=true only if every item ` +
        `holds, and one line per unmet item in missing.`,
        { label: `gallery:${round}`, phase: 'Gallery', model: VALIDATOR_MODEL, effort: 'low', schema: VALIDATION_SCHEMA },
      )
      if (!validation) { log('gallery: the checker returned nothing; the page may not have been rendered'); break }
      if (validation.valid) { log(`gallery: ${galleryPath} rendered and passes the gallery contract (round ${round})`); break }
      if (round > MAX_REVISIONS) { log(`gallery: still unmet after ${MAX_REVISIONS} fix(es): ${validation.missing.join(' | ')}`); break }
      log(`gallery: ${validation.missing.length} unmet item(s); Kai fixes (fix ${round} of ${MAX_REVISIONS})`)
      const fixed = await agent(
        `The gallery renderer or the checker found these problems with the files under ${designDir}:\n` +
        validation.missing.map(m => '- ' + m).join('\n') + '\n' +
        `Fix the files named so each item holds (a missing file is written whole; a wrong one is edited). ` +
        HTML_RULES + SMALLEST_EDITS + `Return the label 'all', the number of files written or edited, and the screens touched.`,
        { label: `kai:fix:${round}`, phase: 'Gallery', agentType: 'ck:kai', effort: 'medium', schema: SCREENS_SCHEMA },
      )
      if (!fixed) { log('gallery: the fix returned nothing; keeping the files as they are'); break }
    }
  }

  return {
    runId, stage, startedAt: startAt, found: true,
    feature: feature ? feature.name : a.feature,
    requirements: feature ? feature.requirements : [],
    gallery: galleryPath,
    skin: skinNote,
    variants: concepts ? concepts.variants.map(v => ({ label: v.label, name: v.name })) : [],
    validation,
    generated: stamp,
  }
}

// ---- refine ----
const chosenPath = designDir + '/chosen.html'
const specPath = designDir + '/spec.md'
let spec = null
if (runs('refine')) {
  phase('Refine')
  spec = await agent(
    `Read ${featurePath}, ${designDir}/variants.json, and every file under ${designDir}/${chosen}/ (the variant ` +
    `the author chose, label ${chosen}). ${skinStep}${archStep}` + changesLine +
    `Three steps, in order. First, the files: apply the author's changes to the chosen variant's screens under ` +
    `${designDir}/${chosen}/ with the smallest edits, and write one more state per screen, <screen>.success.html ` +
    `(the screen after its action succeeded). ` + HTML_RULES +
    `Second, run this command with the Bash tool, exactly: ${renderer} --dir "${designDir}" --chosen ${chosen} ` +
    `--out "${chosenPath}" . It builds ${chosenPath}, the chosen variant at full fidelity with every state, from ` +
    `those files; if it fails, fix the file it names and run it again. Do not write ${chosenPath} yourself, do ` +
    `not install anything, and do not take screenshots: the renderer and the files are the check. ` +
    `Third, write ${specPath} to the design spec contract (${contractStep.replace('Read ', 'read ')}), sections in ` +
    `this order: ` + SPEC_SECTIONS.map(s => '"' + s + '"').join(', ') + `. Feature names the PRD requirement ` +
    `numbers, the user, and the success metric from ${featurePath}. Chosen variant gives the label and one ` +
    `paragraph on why, from the author's review. Requirement traceability has one row per acceptance criterion ` +
    `of every requirement named under Feature. Components name the brand token or surface each uses, or ` +
    `"neutral" when there is no brand guide. Leave the "## Acceptance" section with its heading and one line, ` +
    `"Robin's checks follow.", for Robin to replace. Under 2,500 words. Date it ${stamp}. ` + ONE_WRITE +
    `Apply your Required Behaviors in subagent form. Return only the object: both paths, the counts of screens, ` +
    `components, and traceability rows, and any questions for the author.`,
    { label: 'kai:refine', phase: 'Refine', agentType: 'ck:kai', effort: 'medium', schema: SPEC_SCHEMA },
  )
  if (!spec) throw new Error('design-round: Kai returned nothing for the refine step; the variant files are under ' + designDir + '/' + chosen + '/')
  log(`refine: ${chosenPath}; ${specPath} with ${spec.screens} screen(s), ${spec.components} component(s), ${spec.traceabilityRows} traceability row(s)`)
}

if (runs('acceptance')) {
  phase('Acceptance')
  const checks = await agent(
    `Read ${featurePath} and ${specPath}. Replace the "## Acceptance" section's body in ${specPath} with your ` +
    `checks: at least one per screen named under Screens, each a single statement a tester could verify ` +
    `without asking the designer, each naming the screen and the PRD requirement it tests, numbered. Edit only ` +
    `that section, with the Edit tool. Apply your Required Behaviors in subagent form. Return the path, the ` +
    `number of checks, and the number of screens covered.`,
    { label: 'robin:acceptance', phase: 'Acceptance', agentType: 'ck:robin', effort: 'medium', schema: CHECKS_SCHEMA },
  )
  if (!checks) log('acceptance: Robin returned nothing; the spec keeps its placeholder line')
  else log(`acceptance: ${checks.checks} check(s) over ${checks.screens} screen(s)`)
}

let validation = null
if (runs('validate')) {
  phase('Validate')
  for (let round = 1; round <= MAX_REVISIONS + 1; round++) {
    validation = await agent(
      `${contractStep} Read ${specPath}, ${featurePath}, and the Requirements section of ${a.prd}. Check the spec ` +
      `against every numbered item of the contract's checklist and the section order, including that every ` +
      `acceptance criterion of every requirement named under Feature has a traceability row and that the ` +
      `Acceptance section holds checks, not a placeholder. Return valid=true only if every item holds. For each ` +
      `unmet item, one line in missing that quotes the item and says what is absent or wrong. Judge the shape, ` +
      `not the design.`,
      { label: `validate:${round}`, phase: 'Validate', model: VALIDATOR_MODEL, effort: 'low', schema: VALIDATION_SCHEMA },
    )
    if (!validation) { log('validate: validator returned nothing; proceeding unvalidated'); break }
    if (validation.valid) { log(`validate: the spec passes the contract checklist (round ${round})`); break }
    if (round > MAX_REVISIONS) { log(`validate: still unmet after ${MAX_REVISIONS} revision(s): ${validation.missing.join(' | ')}`); break }
    log(`validate: ${validation.missing.length} unmet item(s); Kai revises (revision ${round} of ${MAX_REVISIONS})`)
    const revised = await agent(
      `${contractStep} Read ${specPath}. A checker found these unmet checklist items:\n` +
      validation.missing.map(m => '- ' + m).join('\n') + '\n' +
      `Revise ${specPath} so each item holds; keep Robin's Acceptance checks. ` + SMALLEST_EDITS +
      `Return only the updated object; chosenPath must be '${chosenPath}' and specPath '${specPath}'.`,
      { label: `kai:revise:${round}`, phase: 'Validate', agentType: 'ck:kai', effort: 'medium', schema: SPEC_SCHEMA },
    )
    if (!revised) { log('validate: revision returned nothing; keeping the previous spec'); break }
    spec = revised
  }
}

return {
  runId, stage, startedAt: startAt,
  chosen,
  chosenPath,
  spec: specPath,
  screens: spec ? spec.screens : null,
  questions: spec ? spec.questions : [],
  validation,
  generated: stamp,
}
