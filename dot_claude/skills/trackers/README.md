# Tracker adapters

This directory is not a skill. It holds the mapping between a set of generic
issue tracker verbs and the concrete tools of each tracker. Planning skills such
as `breakdown` and `refine` are written against the verbs only. They must never
name a tracker tool directly.

## Selecting an adapter

Every planning skill starts from a URL that points at an epic, a project, or an
issue.

1. Read the host of the URL.
2. Read the adapter file for that host in this directory:
   - `linear.app` -> `~/.claude/skills/trackers/linear.md`
3. If no adapter file exists for the host, stop. Tell the user which trackers
   have an adapter. Do not improvise with a web fetch or a shell command.

Read one adapter file only. The others stay out of context.

## Verbs

An adapter must define each verb below, or state that the tracker cannot do it.

| Verb | Input | Output |
| --- | --- | --- |
| `resolve` | the URL, when one was given | `tracker`, `kind`, `id`, `team`, `project` |
| `find_epic` | search terms | candidate epics: id, title, url, `kind` |
| `create_epic` | title, description, scope | the same shape as `resolve`: `kind`, `id` |
| `read_epic` | `id` | title, description, current state |
| `update_epic` | `id`, new or partial description | confirmation |
| `list_children` | `id` | existing child tickets: id, title, url, status |
| `create_child` | title, description, parent reference | the new ticket |
| `update_child` | child id, new or partial description | confirmation |
| `delete_child` | child id | confirmation |
| `set_dependency` | blocked ticket, blocking ticket | confirmation |
| `read_conventions` | `team` or `project` | labels, statuses, templates |

`kind` tells later verbs which shape of parent they work with. A tracker can
have more than one shape of epic, so an adapter can map the same verb to
different calls per `kind`.

`delete_child` means "remove this child from the plan", not "erase it". Most
trackers cannot delete a ticket, and the ones that can should not be trusted to
do it inside a batch. An adapter maps this verb to the cancelled or closed state
of the tracker, and states which state it uses. The result must be reversible by
hand.

`resolve`, `find_epic`, and `create_epic` are the three ways to reach an epic.
`resolve` needs a URL. `find_epic` turns a description into candidates that the
user confirms, which is how a named reference becomes a resolved epic.
`create_epic` runs only after the approval gate, when no epic exists yet. Every
other verb needs an `id`, so one of these three runs first.

## Rules for every tracker

These rules hold whatever the tracker is. An adapter repeats them only when the
tracker needs a specific technique to obey them.

- **Read before you write.** Call `read_epic` and `list_children` before any
  create or update. An epic with children is the normal case, not the
  exception.
- **Reconcile, never duplicate.** Match each proposed unit of work against the
  existing children by title and intent. Classify each one as create, update, or
  leave alone. A second run on the same epic must not create a second set of
  tickets.
- **Get approval before the first write.** Show the full plan, including the
  reconcile classification, as plain text. Wait for the user to accept it. Then
  do all of the writes together.
- **Maintain human ideas, but refine grammar.** When an item has human text,
  ensure ideas are maintained, but feel free to update the prose. When the 
  tracker has no partial update, careful not to overwrite existing text.
- **Do not set planning fields.** Assignee, estimate, priority, due date, and
  sprint or cycle belong to the human. Set only what the skill is responsible
  for.
- **Prefer identifiers the user can read.** When a tracker accepts both a short
  identifier and an internal id, use the short one, so the plan text stays
  readable.

## Adding an adapter

Copy the section shape of `linear.md`: preflight, `resolve`, a verb table per
`kind`, then a rules section for the traps of that tracker. Keep every tool name
inside the adapter file.
