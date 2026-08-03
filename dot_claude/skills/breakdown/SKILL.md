---
name: breakdown 
description: Take an idea that requires a huge amount of work, and break it down into units of work that are individually valuable & useful.
disable-model-invocation: true
---

A loose idea has arrived, and it's unclear how the idea can be transformed into 
a workable solution. Breakdown is the process of taking one idea, and breaking 
that idea down into multiple useful, workable items.

The input to this skill is either:

1. An Epic URL
2. An idea in prose

The following should be done in order:

## Orient

### Identify the epic

**If a URL is provided:** 

- Parse the host 
- Read `/home/tony/.claude/skills/trackers/README.md`, and the matching adapter 
file. 
- `resolve` the URL.
   - If `resolve` does *not* resolve `kind` to `project`, stop and ask for a
   project URL.

**If an idea in prose is provided:** 

- Use the following methods, in order, to discover the issue tracker:
   1. An explicit repository file: `.claude/issue-tracker.md`. This file should
   clearly state the issue tracker used, as well as the team name. Read it once:
   a hit here answers the team chain below as well.
   2. Evidence of use in the recent history. Run `git log -50 --pretty=%s`, and
   list the recent branch names, then look for:
      - `ABC-123` in a commit subject or a branch name, which points to Linear
      or Jira, and which also names the team.
      - `#123`, or `Fixes #123`, which points to GitHub Issues.
   3. Ask the user. Offer only the trackers that have an adapter file.
- Use the following methods, in order, to discover the team:
   1. An explicit repository file: `.claude/issue-tracker.md`.
   2. The `ABC-123` keys already found in the history above. A key that appears
   repeatedly is a strong match against a team.
   3. Try to match details of the repository with the existing team names.
   4. Ask the user.
- Read `/home/tony/.claude/skills/trackers/README.md`, and the matching adapter 
file. 
- Execute `find_epic` on the idea. If there are near matches, confirm with
the user if any of them are a true match.
   - A confirmed match becomes the epic: take its `id` and `kind`, and treat the
   input as an Epic URL from here on.
   - No match means the epic does not exist yet: `id` = none, and `kind` = 
   `project`, to be created later.

### Establish the current state

This applies to both cases above.

- If the epic exists, call `read_epic` and `list_children`. Specify to the user
whether this is a first run or re-run. An epic that does not exist yet is a
first run by definition.
- If the epic does not concern this repository, stop and ask the user to
confirm. Treat it as a mismatch when the epic names services, components, or
repositories that do not exist here.
- If the repo does not include a `.claude/issue-tracker.md` file, offer to
create it, including the tracker name & team name.
- At the end of this process, you should have the following information:
   - The primary input of this skill: the contents of the epic, or the prose
   provided by the user when the epic does not exist yet
   - `tracker`
   - `kind` = `project` 
   - `id`, or none when the epic is still to be created
   - `team`

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
   1. If the epic already exists, execute `update_epic`. Otherwise, execute
   `create_epic`.
   2. Per slice, execute the verb its classification calls for:
      - "create": `create_child`
      - "update": `update_child`
      - "delete": `delete_child`
      - "leave alone": nothing
   3. Execute `set_dependency` per edge. Slices created in step 2 only have an
   id once they exist, so this always comes last.
- For the final report, output links to everything that was created/updated
in the issue tracker.
