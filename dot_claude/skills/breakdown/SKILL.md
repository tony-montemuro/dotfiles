---
name: breakdown 
description: Take an idea that requires a huge amount of work, and break it down into units of work that are individually valuable & useful.
disable-model-invocation: true
---

# Breakdown

A loose idea has arrived, and it's unclear how the idea can be transformed into 
a workable solution. Breakdown is the process of taking one idea, and breaking 
that idea down into multiple useful, workable items.

The input to this skill is either:

1. An Epic URL
2. An idea in prose

The following should be done in order:

## Orient

### Identify the epic

Read `/home/tony/.claude/skills/trackers/README.md`, and the matching adapter
file. The README states how to find the tracker and the team, and it defines the
repository file `.claude/issue-tracker.md`.

`.claude/issue-tracker.md` names two kinds. The **epic kind** is the one this
skill works on. The **work kind** is the one every slice is created as. When the
file does not exist, or does not name them, take the kinds the adapter uses to
group work and to hold a unit of work, and confirm both with the user.

**If a URL is provided:** 

- `resolve` the URL.
   - If `resolve` does *not* return the epic kind, stop and ask for a URL of
   that kind.

**If an idea in prose is provided:** 

- Execute `find_item`, with the epic kind and a few keywords from the idea. If
there are near matches, confirm with the user if any of them are a true match.
   - A confirmed match becomes the epic: take its `id` and `kind`, and treat the
   input as an Epic URL from here on.
   - No match means the epic does not exist yet: `id` = none, and `kind` = the
   epic kind, to be created later.

### Establish the current state

This applies to both cases above.

- If the epic exists, call `read_item` and `list_children`. Specify to the user
whether this is a first run or re-run. An epic that does not exist yet is a
first run by definition.
- If the epic does not concern this repository, stop and ask the user to
confirm. Treat it as a mismatch when the epic names services, components, or
repositories that do not exist here.
- If the repo does not include a `.claude/issue-tracker.md` file, offer to
create it from the template beside the README.
- At the end of this process, you should have the following information:
   - The primary input of this skill: the contents of the epic, or the prose
   provided by the user when the epic does not exist yet
   - `tracker`
   - `kind` = the epic kind
   - The work kind, for the slices
   - `id`, or none when the epic is still to be created
   - `team`
   - The template for the epic kind, when `.claude/issue-tracker.md` defines one
   - The guidance for the epic kind, when the file defines it

## Align on the why

- Before digging into the code, ask the questions that cannot be answered by
the codebase. Some examples include:
   - Why is this a problem?
   - Who is affected by this problem?
   - Ask for scope to be more clearly defined.
   - What is the definition of done for the epic?
- These examples do not all need to be asked; use your best judgement to figure
out the why.
- If the epic exists, the output of this step should be a refined description
of the epic.
- If the epic does not exist, the output of this step should be the epic's 
title, as well as a description.
- If the goal of the epic is ultimately still unclear by the end of this stage,
say so and stop; unable to proceed.

## Build Context

- Perform an investigation of the codebase, based on current understanding of
the epic. Take note of interesting findings.
- Go through a secondary alignment round with the user. Address interesting
findings, point out things the code raised. Pay closest attention to things
that might re-define the epic. Hand open questions off to the grilling skill.
- Keep track of:
  - The affected areas of the codebase
  - Common patterns the codebase utilizes
  - Any constraints that limit how work can be broken apart
- These items will help in the next step. Do not produce a design; this planning
phase is not concerned with that level of detail.
- Use your best judgement to figure out how *much* to read. Ideally, you
want to read enough to understand the boundary of the problem well. If that
starts to be an excessive amount; say so and stop. This is a signal
that the epic is too large in scope; propose a way of breaking the single epic
into multiple epics.
- For any issues that remain open, record them as assumptions.

## Slice up the work

- Produce the slices of work. These should be independently valuable, and
independently mergable. If a slice only makes sense beside its neighbour, fold
it in to the neighbour slice.
- Each slice is **lightweight**: a title, and 2-5 sentences of the "why" behind 
the slice. A slice should NOT include any of the following:
   - Implementation details (file paths, function names, etc.)
   - User stories
   - Acceptance criteria
   - Estimates
- A slice does not follow the template of its kind, and the guidance for that
kind does not apply here either. Filling both is the work of the `operationalize`
skill, one slice at a time.
- Order the slices. Identify dependencies between them, and any slices that
can be solved in parallel.
- Perform a classification of all slices, new and existing. New slices should
always be classified as "create". Existing slices can be classified as:
   - "leave alone"
   - "update"
   - "delete"
- A child that is already started, completed, or cancelled is always classified
as "leave alone". If your plan conflicts with one of them, say so, and let the
user decide what to do about it.
- If you produce more than 10 slices, say so and stop. Warn the user this idea
is too large for a single epic, and propose a way of breaking the single
epic into multiple epics.

## Commit

- Output the work you have done to the user:
   - The name of the epic
   - The description of the epic 
   - All recorded assumptions, with their status
   - The ordered slices. For each slice, output:
      - The title of the slice
      - The description of the slice
      - Dependent slices
      - The classification of the slice: "create", "update", "leave alone", or
      "delete"
- Now begins an iterative process:
   - Give the user the option to make critiques of the work you have done.
   - If there are no critiques, and they approve, write the result to the
  issue tracker.
   - If there are critiques, use your best judgement to incorporate them
  into what you have, and repeat.
   - If the user flat out rejects your work, stop the skill, it's over. 
- The description of the epic follows the template for the epic kind, when
`.claude/issue-tracker.md` defines one:
   - Reproduce the headings of the template exactly, in its order, with every
   heading present even when a section is short. Include any fixed text the
   template body places inside a section.
   - Read the guidance for a section immediately before writing that section. The
   `## Guidance: <epic kind>` section of the same file holds it, with one `###`
   heading per template heading.
      - Guidance is optional. A heading with no guidance is filled with
      judgement.
      - A `###` heading that matches no template heading is stale. Report it, and
      continue.
   - Never copy the guidance itself into the epic. It describes how to fill a
   section; it is not content.
- Respect the `## Conventions` section of the same file, for the epic and for
every slice.
- Assumptions live in the epic's description, as a running log. The log is
never wiped: it is the record of what was believed at each pass of planning.
Each assumption is a single line, with the date it was first recorded and its
current status:
   - `2026-08-02 (open): the export job can stay synchronous`
   - `2026-08-02 (resolved: we move it to the queue): the export job can stay
   synchronous`
- Before writing, read the assumptions already in the description, and reconcile
each one against the assumptions from this run:
   - Still open: leave the entry exactly as it is.
   - Answered during this run, usually by grilling: rewrite it as resolved, and
   record the decision. Keep the original date; the entry is history, not news.
   - The same assumption in different words: merge it into the existing entry.
   Never add a second copy.
   - Genuinely new: append it, dated today, with the status open.
- Anchor each of these on the single line it changes. Do not rewrite the whole
assumptions section to change one entry.
- Once the assumptions are reconciled, write everything in this order:
   1. If the epic already exists, execute `update_item`. Otherwise, execute
   `create_item`.
   2. Per slice, execute the verb its classification calls for. Every slice is
   created with the work kind, and with the epic as its parent:
      - "create": `create_item`
      - "update": `update_item`
      - "delete": `delete_item`
      - "leave alone": nothing
   3. Execute `set_dependency` per edge. Slices created in step 2 only have an
   id once they exist, so this always comes last.
- For the final report, output links to everything that was created/updated
in the issue tracker.
