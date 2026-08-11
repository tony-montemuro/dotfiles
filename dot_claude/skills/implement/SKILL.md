---
name: implement
description: "Implement a piece of work based on a ticket."
disable-model-invocation: true
---

# Implement

Implement one unit of work, and verify that the result is correct.

The input to this skill is one work item, given as:

1. An item URL
2. A tracker identifier, such as `SMB-5`
3. Nothing, in which case the current git branch carries the identifier

The work always comes from the issue tracker.

The following should be done in order.

## Orient

### Identify the item

Read `~/.claude/skills/trackers/README.md`, and the matching adapter file. The
README states how to find the tracker and the team, and it defines the repository
file `.claude/issue-tracker.md`.

`.claude/issue-tracker.md` names two kinds. The **work kind** is the one this
skill implements. The **epic kind** is the parent, and this skill only reads it.

Resolve the input:

- **A URL, or an identifier:** `resolve` it.
- **Nothing:** read the identifier off the front of the current git branch, and
`resolve` that. When the branch carries no identifier, ask which item to
implement. Do not guess from recent activity.

Check the kind that comes back:

- The work kind continues the run.
- The epic kind stops the run. Say so, and recommend `breakdown` instead.
- Any other kind stops the run. Say which kind came back, and ask for the right
item.

### Read the item

- `read_item` on the item. This is the primary input of the skill.
- `read_item` on its `parent`, when it has one. The epic holds the wider why.
Read it for context only. Never write to it.
- `list_children`, so a run sees the sub-items that already exist. A child that
holds its own unit of work belongs to its own run of this skill.
- If the item does not concern this repository, stop and ask the user to confirm.
Treat it as a mismatch when the item names services, components, or repositories
that do not exist here.

### Check that the item is ready

The `operationalize` skill turns a why into a how. This skill needs the how.

- Compare the headings of the item against the template for the work kind in
`.claude/issue-tracker.md`.
- When the item holds the why alone, or when large parts of the template are
missing, stop. Recommend `operationalize` on the item first.
- When the item is filled, but one detail is open, ask the user that one
question, and continue.
- Read the assumptions recorded on the item. An assumption that is still open,
and that changes the work, goes to the user before you write code.

This skill reads the tracker, and it does not write to it. Report the outcome to
the user, and let them update the item.

## Implement

Implement the work described by the item. Verify that all your work is correct.

Once done, use /code-review to review the work. Allow the user to decide what
suggestions to apply.
