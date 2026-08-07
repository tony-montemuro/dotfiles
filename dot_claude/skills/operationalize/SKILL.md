---
name: operationalize
description: Take the "why" for an individual piece of work, & transform it into a "how".
disable-model-invocation: true
---

# Operationalize

A work item states why the work matters, and nothing more. Operationalize is the
process of turning that item into one that can be picked up and worked without
further clarification.

This skill is the follow up to `breakdown`. That skill produces slices, one why
each, and it leaves the template of the work kind unfilled on purpose. This skill
fills it, one slice at a time.

Refinement needs research, not guesswork. Every claim written to the item traces
back to the codebase, the history, or something the user said.

The input to this skill is one work item, given as:

1. An item URL
2. A tracker identifier, such as `SMB-5`
3. Nothing, in which case the current git branch carries the identifier

This skill works on one item that already exists, and it never goes looking for
work to create. The scope guard is the single exception: when the slice turns out
to hold more than one unit of work, the extra units can become sibling items, and
only with the approval of the user, one by one.

The following should be done in order.

## Orient

### Identify the item

Read `~/.claude/skills/trackers/README.md`, and the matching adapter file. The
README states how to find the tracker and the team, and it defines the repository
file `.claude/issue-tracker.md`.

`.claude/issue-tracker.md` names two kinds. The **work kind** is the one this
skill acts on. The **epic kind** is the parent, and this skill only reads it.

Resolve the input:

- **A URL, or an identifier:** `resolve` it.
- **Nothing:** read the identifier off the front of the current git branch, and
`resolve` that. When the branch carries no identifier, ask which item to
operationalize. Do not guess from recent activity.

Check the kind that comes back:

- The work kind continues the run.
- The epic kind stops the run. Say so, and recommend `breakdown` instead.
- Any other kind stops the run. Say which kind came back, and ask for the right
item.

### Establish the current state

- `read_item` on the item. This is the primary input of the skill.
- `read_item` on its `parent`, when it has one. The epic holds the wider why, and
the assumptions recorded during planning. Read that log for context. Never write
to it.
- `list_children`, so a re-run sees the sub-items that already exist.
- `read_conventions`, for the labels and statuses of the team.
- If the item does not concern this repository, stop and ask the user to confirm.
Treat it as a mismatch when the item names services, components, or repositories
that do not exist here.
- If the repository does not include a `.claude/issue-tracker.md` file, offer to
create it from the template beside the README. This skill cannot proceed without
it, because the file holds the template.
- At the end of this process, you should have the following information:
   - The contents of the item
   - The contents of the parent, when there is one
   - `tracker`
   - `kind` = the work kind
   - `id`
   - `team`
   - The template for the work kind
   - The guidance for the work kind, when the file defines it

## Compare the item against the template

The template is the target shape, not a gate. An item that does not match it yet
is the normal case, because filling the template is the job of this skill.

- Read the template body for the work kind out of `.claude/issue-tracker.md`.
- When the file holds no template for the work kind, stop. Offer to write the
section with the user. Never invent a template, and never copy one from another
repository.
- Compare the headings of the item against the template, and classify the run:
   - **No headings, or only the why in prose:** a first run. This is what
   `breakdown` leaves behind. Add every heading.
   - **All headings present, in the template order:** a re-run. Fill and expand
   the sections, and keep what is already inside them.
   - **Some headings present, or renamed, or out of order:** partial or drifted.
   Move the existing content under the correct heading, add what is missing, and
   put the headings in template order.
- The template always wins. This skill makes the item obey it.
- Never drop text to make the shape fit. Text that belongs to no heading goes
into the closest matching section.
- Record every move and every rename. They go in the final report, so the user
can see where their words went.
- Say which of the three cases this run is, before going further.

## Read the why

The text already in the item is the why. It is authoritative in meaning, and not
in phrasing.

- Keep the meaning fully intact. Refine grammar and clarity without asking; this
is not something to put to the user.
- Correct a claim only when research proves it wrong. Flag every correction in
the report.
- If the why is missing, and it cannot be inferred from the item, the parent, or
the codebase, stop and ask. Do not research a goal you cannot state.

## Build context

Turn the why into a real understanding of the work.

- Follow the practices the repository establishes for reading the codebase. Use
the following as well:
   - **History:** `git log` and `git blame` explain why something is the way it
   is. That reasoning often belongs in the item.
   - **External behavior:** when the item names a library, a tool, or a service,
   confirm the current version rather than assuming it.
- Verify every path before it goes into the item. A file that does not exist yet
is fine; mark it `(new)` so it does not read as a mistake.
- Keep track of:
   - The areas of the codebase the work touches
   - The patterns the codebase already uses for this kind of change
   - The constraints that limit the solution
   - Every viable approach, with its trade-offs
- Use your best judgement to figure out how much to read. Read enough to state
the boundary of the work with confidence.

### Guard the scope

A slice should be one unit of work. When research shows it is not:

- **Two to five units:** keep the unit that matches the why of this item, and
propose the rest as siblings. Each proposal gets a title and 2 to 5 sentences of
why, in the same lightweight form `breakdown` produces. A proposal carries no
implementation detail, no acceptance criteria, and no template; a later run of
this skill fills those in, one sibling at a time.
- **Roughly six or more units:** stop. Say the slice was mis-sized, and recommend
`breakdown` on the parent. Expect this to be rare, because `breakdown` should
have caught it.

A sibling is created only when the user approves that one sibling at the commit
stage. Silence is not approval. A sibling the user rejects is dropped from the
plan, and the report says so.

Every sibling takes the parent of this item, so it lands beside it in the tree.
When this item has no parent, a sibling gets none either.

## Grill

Hand every open decision to the `grilling` skill, before writing anything.

- A *fact* is looked up in the codebase, the history, or the tracker. Never ask
for one.
- A *decision* goes to the user, one question at a time, each with a recommended
answer.
- Grill on:
   - The choice between viable approaches, when the trade-offs are real
   - What "done" means, when the acceptance criteria are not obvious
   - The boundary of the change
   - Anything research contradicts, when the correction changes the scope
- Do not grill on the phrasing inside a section, or on anything the template and
the guidance already settle.
- The output is the set of decisions, plus the items that stay open. Every open
item becomes an assumption.

## Draft the how

The reader of this item is an implementation agent, started fresh by the user,
with no memory of this run. Write enough for that agent to do the work without
asking a further question. Write no more than that. Record the decisions and the
constraints; do not write the code, the diff, or the function bodies.

That gives a test for every sentence. Too little, and the follow up agent has to
guess. Too much, and the item has become a patch.

### Follow the template

- Reproduce the headings of the template exactly, in its order, with every
heading present even when a section is short.
- Include any fixed text the template body places inside a section.
- Read the guidance for a section immediately before writing that section. The
`## Guidance: <work kind>` section of `.claude/issue-tracker.md` holds it, with
one `###` heading per template heading.
   - Guidance is optional. A heading with no guidance is filled with judgement.
   - A `###` heading that matches no template heading is stale. Report it, and
   continue.
- Respect the `## Conventions` section of the same file.
- Never copy the guidance itself into the item. It describes how to fill a
section; it is not content.
- Keep the human text that already sits inside a section.

### Record the assumptions

Every open item from the grill becomes an assumption on this work item.
Work specific assumptions live here, not on the epic.

The log is never wiped. It is the record of what was believed at each pass. Each
assumption is a single line, with the date it was first recorded and its current
status:

- `2026-08-02 (open): the export job can stay synchronous`
- `2026-08-02 (resolved: we move it to the queue): the export job can stay
synchronous`

Read the assumptions already in the item, and reconcile each one against the
assumptions from this run:

- Still open: leave the entry exactly as it is.
- Answered during this run, usually by grilling: rewrite it as resolved, and
record the decision. Keep the original date; the entry is history, not news.
- The same assumption in different words: merge it into the existing entry. Never
add a second copy.
- Genuinely new: append it, dated today, with the status open.

Anchor each of these on the single line it changes. Do not rewrite the whole
section to change one entry.

Put the log in the section the template gives it. When the template has no such
section, put it under a `## Assumptions` heading, after the last template
heading. Say so in the report, and offer to add the heading to the template.

### Close with the disclaimer

Every operationalized item ends with this, after a horizontal rule:

```markdown
---

*Issue groomed by Claude; please review before starting.*
```

The wording is fixed, and it belongs to this skill. A repository cannot override
it. Keep exactly one disclaimer on an item: a re-run replaces the existing one
rather than appending a second.

## Commit

- Output the full draft to the user as plain text, before any write. Include:
   - Which of the three template cases this run is
   - Every section, as it will be written
   - Every move or rename of existing content
   - Every correction made to a claim the item asserted
   - All assumptions, with their status
   - Any siblings proposed by the scope guard, each with its title and its why,
   listed apart from the item itself, because each one needs its own approval
- Now begins an iterative process:
   - Give the user the option to make critiques of the work you have done.
   - If there are no critiques, and they approve, write the result to the issue
   tracker.
   - If there are critiques, use your best judgement to incorporate them into
   what you have, and repeat.
   - If the user flat out rejects your work, stop the skill, it's over.
- When the plan holds siblings, ask for each one separately, and do it in the
same round as the approval of the item. Take a yes or a no per sibling. Approval
of the item alone never carries a sibling with it.
- Once approved, write everything in this order:
   1. `update_item` on the item, with a partial update. Anchor each change on the
   lines it touches. Do not send a whole description to change one section.
   2. `create_item` per approved sibling, with the work kind, and with the parent
   of this item. Nothing here for a sibling the user rejected.
   3. `set_dependency` per edge, when research found an item that blocks this
   one, or that this one blocks. A sibling created in step 2 only has an id once
   it exists, so this always comes last.
- Do not set assignee, estimate, priority, due date, or sprint. Those belong to
the user. Set a label only when the conventions state which label applies;
otherwise name the label you would pick in the report, and leave it unset.
- For the final report, output the link to the item, a short summary of each
section added or expanded, and every assumption that stays open. Add the link to
every sibling created, and name every sibling the user rejected.
