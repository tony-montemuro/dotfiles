# Tracker adapters

This directory is not a skill. It holds the mapping between a set of generic
issue tracker verbs and the concrete tools of each tracker. Planning skills
(ex: `breakdown` and `operationalize`) are written against the verbs only. They
must never name a tracker tool directly.

## Items, kinds, and roles

An **item** is anything that lives in the tracker. Every verb below acts on an
item.

A **kind** is the type of an item: `project`, `issue`, `milestone`, etc. Kinds
are concrete, and they belong to the tracker, so each adapter declares the 
kinds it supports. A tracker has more than one, so an adapter maps each verb 
to a different call per kind.

A **role** is the job an item does in planning. There are two. The **epic**
groups work. The **work item** is one unit of that work. An epic and a work item
are both items; they differ by kind, and by their position in the tree.

Skills are written against roles, and trackers are built out of kinds.
`.claude/issue-tracker.md` joins the two: it names the kind that plays each role
in this repository. So a skill never hard-codes a kind. It reads the kind for
its role out of that file, passes the kind to the verbs, and checks the kind
that comes back. The same skill then works on a tracker whose epic is a project
and on one whose epic is a milestone.

## The repository file

`.claude/issue-tracker.md` records what a skill cannot learn from the tracker.
It holds:

- **Tracker**: the host, which selects the adapter.
- **Team**: the team that owns the work.
- **Epic kind** and **Work kind**: the kind that plays each of the two roles.
- **A template per kind**: one `## Template: <kind>` section for each of the two
  kinds above.
- **Guidance per kind**: an optional `## Guidance: <kind>` section, which says
  how to fill each heading of that kind's template.
- **Conventions**: prose that a planning skill must respect.

`issue-tracker.template.md`, beside this file, is the shape to fill in. Read it
only when the file has to be written. A file that already exists is read without
it.

- **The kind named for each role must be one the adapter supports.** When it is
  not, stop. Either the file names the wrong kind, or the adapter is missing
  one, and a human picks which.
- **A template body is the markdown skeleton of an item**: the headings, in
  order, plus any fixed text that belongs inside a section.
- **Each template body sits inside a fenced code block.** A template is
  markdown, and so is the file that holds it, so an unfenced body would end its
  own section at its first heading. The wrapper fence must be longer than any
  fence inside the template: three backticks normally, four when the template
  itself contains a fence.
- **The templates in this file are authoritative.** Most trackers keep their
  templates in the workspace, where the tools cannot read them, so this file is
  the only readable copy.
- **Guidance is joined to a template by the heading text.** Each `###` heading
  inside `## Guidance: <kind>` matches a heading of that kind's template, word
  for word. Guidance is optional, at every level: the section can be absent, and
  a template heading it says nothing about is filled with judgement. A `###`
  heading that matches no template heading is stale, and a skill reports it and
  continues.
- **Guidance is never written into an item.** It says how to fill a section. The
  template body is the only part of this file that is copied.
- **A skill that needs a template stops when it cannot get one.** That means the
  file is missing, or it holds no template for the kind in hand. Offer to write
  the file with the user. Never invent a template, and never copy one from
  another repository.
- When the file is missing and the skill can still proceed without a template,
  offer to write the file anyway before the run ends.

## Selecting an adapter

Find the host, in this order. Stop at the first answer.

1. The URL, when the input is one.
2. `.claude/issue-tracker.md`. A hit here also answers the team below.
3. Evidence in the history. Run `git log -50 --pretty=%s` and list the recent
   branch names, then look for:
   - `ABC-123` in a commit subject or a branch name, which points to Linear or
     Jira, and which also names the team.
   - `#123`, or `Fixes #123`, which points to GitHub Issues.
4. Ask the user. Offer only the trackers that have an adapter.

Then read the adapter file for that host:

- `linear.app` -> `~/.claude/skills/trackers/linear.md`

If no adapter file exists for the host, stop. Tell the user which trackers have
an adapter. Do not improvise with a web fetch or a shell command.

Read one adapter file only. The others stay out of context.

## Finding the team

A team is usually required to create an item, and a URL does not always carry
one.

When `resolve` returns a team, that team owns the item and wins. Use the chain
below only before an item has been resolved, which is the case when a skill
starts from prose. Find the team in this order, and stop at the first answer.

1. `.claude/issue-tracker.md`.
2. The `ABC-123` keys already found in the history above. A key that appears
   repeatedly is a strong match against a team.
3. A match between the details of the repository and the existing team names.
4. Ask the user. Do not guess.

## Verbs

An adapter must define each verb below, or state that the tracker cannot do it.

| Verb | Input | Output |
| --- | --- | --- |
| `resolve` | a URL, or a tracker identifier | `tracker`, `kind`, `id`, `team`, `project`, `parent` |
| `find_item` | `kind`, search terms | candidates: `kind`, `id`, title, url |
| `read_item` | `kind`, `id` | title, description, current state, `parent` |
| `create_item` | `kind`, title, description, `parent` when it has one | `kind`, `id` |
| `update_item` | `kind`, `id`, a partial or a whole description | confirmation |
| `delete_item` | `kind`, `id` | confirmation |
| `list_children` | `id` | children: `kind`, `id`, title, url, status |
| `set_dependency` | blocked item, blocking item | confirmation |
| `read_conventions` | `team` or `project` | labels, statuses |

- **`parent` is a pair: `kind` and `id`.** It is empty when the item sits at the
  top of the tree. An adapter states which relation it reports as the parent
  when a tracker has more than one.
- **`resolve` takes an identifier as well as a URL.** A bare key such as
  `SMB-5`, or one read off a git branch, is a resolve and not a search. With no
  URL there is no host to read, so the adapter comes from the repository file.
- **Only `resolve`, `find_item`, and `create_item` produce an `id`.** `resolve`
  turns a URL or an identifier into one, `find_item` searches for one, and
  `create_item` makes the item that does not exist yet. Every other verb needs
  an `id`, so a run starts with one of these three.
- **`delete_item` means "remove this from the plan", not "erase it".** Most
  trackers cannot delete an item, and the ones that can should not be trusted to
  do it inside a batch. An adapter maps this verb to the cancelled or closed
  state of the tracker, and states which state it uses. The result must be
  reversible by hand.

## Rules for every tracker

These rules hold whatever the tracker is. An adapter repeats them only when the
tracker needs a specific technique to obey them.

- **Check the kind before you act on an item.** The `kind` that `resolve` or
  `find_item` returns must be the kind the repository file gives to the role
  the skill works on. A mismatch stops the run: say which kind came back, and
  ask the user for the right item.
- **Read before you write.** Call `read_item`, and `list_children` when the item
  can have children, before any create or update. What is already there decides
  whether a write is a create or an update.
- **Reconcile, never duplicate.** Match each proposed unit of work against the
  existing children by title and intent. Classify each one as create, update, or
  leave alone. A second run on the same item must not create a second set of
  tickets.
- **Get approval before the first write.** Show the full plan, including the
  reconcile classification, as plain text. Wait for the user to accept it. Then
  do all of the writes together.
- **Maintain human ideas, but refine grammar.** When an item has human text,
  ensure ideas are maintained, but feel free to update the prose.
- **Prefer a partial update to a whole one.** When the tracker has no partial
  update for a kind, read the current description first, and send it back with
  the change inside it.
- **Do not set planning fields.** Assignee, estimate, priority, due date, and
  sprint or cycle belong to the human. Set only what the skill is responsible
  for.
- **Prefer identifiers the user can read.** When a tracker accepts both a short
  identifier and an internal id, use the short one, so the plan text stays
  readable.

## Adding an adapter

Copy the section shape of `linear.md`: preflight, kinds, `resolve`, one verb
table with a column per `kind`, then a rules section for the traps of that
tracker. Keep every tool name inside the adapter file.

The kinds section is not optional. List every concrete kind the adapter can map
to calls, say in one line what each one is for, and name the kinds the adapter
refuses. A repository file that asks for a kind outside that list stops the run,
so the list is the contract.
