# Tracker adapter: Linear

Applies when the tracker is `linear.app`.

## Preflight

Check that the session has tools with the prefix `mcp__claude_ai_Linear__`. If
it does not, stop and tell the user to connect the Linear MCP server. Do not
fetch `linear.app` over the web: the page needs authentication and returns an
application shell, not the content of the ticket.

## Kinds

| Kind | What it is |
| --- | --- |
| `project` | groups work |
| `issue` | a single unit of work, which can also be the parent of other issues |

This adapter refuses `initiative` and `document`. A repository file that names
either of those, or any other kind, stops the run.

## resolve(url or identifier)

**A URL.** Match the path in this order:

| Path shape | `kind` | `id` |
| --- | --- | --- |
| `/{workspace}/project/{slug-id}`, with or without a suffix such as `/overview` | `project` | `{slug-id}` |
| `/{workspace}/issue/{TEAM-123}/{slug}` | `issue` | `TEAM-123` |
| `/{workspace}/initiative/...` | not supported | stop, ask for a project or issue URL |
| `/{workspace}/document/...` | not supported | stop, ask for a project or issue URL |

**An identifier.** A bare key of the shape `TEAM-123` is `kind` = `issue` and
`id` = `TEAM-123`. A git branch name carries the same key
(`smb-5-add-basic-claude-configuration`); read it off the front of the branch
and uppercase it. A project has no short identifier, so a project always arrives
as a URL, or through `find_item`.

The Linear tools accept both of these ids directly, so no lookup of an internal
UUID is necessary.

### Resolving `team`

A team is required to create an item, and the URL does not contain one.

- `kind` = `issue`: read the team from the issue. `get_issue` returns it.
- `kind` = `project`: call `list_projects` with `query` set to the slug and
  `fields: ["id", "name", "teams"]`. If the project has one team, use it. If it
  has more than one, ask the user which team the new tickets belong to. Do not
  guess.

This team owns the item, so it wins over the team named in
`.claude/issue-tracker.md`. When the two differ, say so, and continue.

### Resolving `project`

- `kind` = `project`: the project is the item itself.
- `kind` = `issue`: read the project of the issue, if it has one. New siblings
  must go in the same project.

### Resolving `parent`

- `kind` = `project`: empty. A project can sit under an initiative, and this
  adapter does not support initiatives.
- `kind` = `issue`: `get_issue` returns `parentId`. Report the parent issue when
  there is one, as `kind` = `issue`. When there is no parent issue, but the
  issue belongs to a project, report the project, as `kind` = `project`. An
  issue can have both, and the parent issue is the closer of the two, so it
  wins.

## Verbs

| Verb | `kind` = project | `kind` = issue |
| --- | --- | --- |
| `find_item` | `list_projects` with `query` and `fields: ["id", "name", "summary", "url", "teams", "status"]` | `list_issues` with `query`, `team` when it is known, `includeArchived: false`, and `fields: ["id", "title", "description", "url", "status", "parentId", "projectId"]` |
| `read_item` | `get_project` with `query` = `id`, `includeMilestones: true`, `includeResources: true` | `get_issue` with `id` and `includeRelations: true` |
| `create_item` | `save_project` with `name`, `summary`, `description`, `addTeams: [team]`, and no `id`. A project takes no parent: the only one Linear offers is an initiative, which this adapter refuses | `save_issue` with `title`, `description`, `team`, no `id`, and the parent: `parentId` when the parent is an issue, `project` when it is a project. Set both when the parent issue belongs to a project |
| `update_item` | `save_project` with `id` and `description` | `save_issue` with `id` and `patch` |
| `delete_item` | `save_project` with `id` and `state` set to the cancelled project status of the workspace, which the user supplies | `save_issue` with `id` and `state: "canceled"` |
| `list_children` | `list_issues` with `project` = `id`, `includeArchived: false`, and `fields: ["id", "title", "description", "url", "status", "parentId", "labels"]` | `list_issues` with `parentId` = `id`, and the same parameters |
| `set_dependency` | not supported | `save_issue` with `id` = the blocked issue and `blockedBy: ["<blocking issue>"]` |
| `read_conventions` | `list_issue_labels` and `list_issue_statuses`, both with `team` | the same |

`save_issue` and `save_project` create when `id` is absent, and update when `id`
is present. Never pass `id` on a create.

Linear has no blocking relation between projects. When `set_dependency` gets two
projects, say so, and put the dependency on the issues inside them instead.

## Rules

- **`save_project` has no `patch`. Only `save_issue` has one.** To change a
  project description, call `read_item` first and send the whole description
  back with the change inside it. A `description` built from anything other than
  the current text will drop what a human wrote.
- **Update an issue description with `patch`, not with `description`.** `patch`
  is valid on update only, in place of `description`. It applies its operations
  in order and atomically, and each anchor string must match the current content
  exactly once. Read the current description first and build the anchors from
  it. A full `description` replaces everything.
- **Set `includeArchived: false` on every `list_issues` call.** The parameter
  defaults to true. Without it, archived and cancelled tickets look like live
  children during the reconcile step. `list_projects` defaults to false already.
- **`save_project` takes `name`, not `title`.** `summary` is a separate field,
  limited to 255 characters, and it is the text shown in list views. Put the one
  line why there, and the full description in `description`.
- **Search with a few keywords, not with the whole idea.** The `query` of
  `list_projects` matches the project name only. The `query` of `list_issues`
  matches the title and the description.
- **Do not pass `labels` on an update unless the current labels are known.**
  `labels` replaces the whole set. Any label left out is removed from the item.
  Read the labels through `list_children` or `get_issue` first, then send the
  full intended set.
- **Send literal newlines in `description` and in `patch` text.** Do not send
  the escape sequence `\n`.
- **`list_children` on a project returns the whole project, at every depth.**
  `list_issues` with `project` does not stop at the first level, so a sub-issue
  of a slice comes back looking like a direct child of the epic. A direct child
  is an issue with an empty `parentId`. Filter on it, or the reconcile step
  counts children that belong to somebody else.
- **Linear cannot delete, and `delete_item` does not try.** It sets the item to
  the cancelled state, which is reversible by hand. On an issue, pass the state
  *type* `canceled`, not a status name: `save_issue` takes a type, a name, or an
  id, and the names are configurable per team, while the type is not. Use
  `list_issue_statuses` with `team` only when the user asks for a specific
  status.
- **Cancelling a project is not a routine write.** It takes every issue in the
  project out of the normal views. Confirm that single act with the user, apart
  from the approval of the plan as a whole. Ask them for the status name to
  pass, in the same breath: `save_project` documents `state` only as "Project
  state", the forms it accepts are not stated, and no tool lists the project
  statuses of a workspace, so the name cannot be looked up.
- **Do not set `assignee`, `estimate`, `priority`, `cycle`, or `dueDate`.**
  These belong to the human.
- **`blocks` and `blockedBy` are append only.** They never remove an existing
  relation. To remove one, use `removeBlocks` or `removeBlockedBy`.
- **These tools cannot read a Linear template.** Templates live in the
  workspace, and `read_conventions` returns labels and statuses only. The
  template for each kind comes from `.claude/issue-tracker.md`.
