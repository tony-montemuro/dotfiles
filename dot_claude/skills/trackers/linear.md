# Tracker adapter: Linear

Applies when the host of the epic URL is `linear.app`.

## Preflight

Check that the session has tools with the prefix `mcp__claude_ai_Linear__`. If
it does not, stop and tell the user to connect the Linear MCP server. Do not
fetch `linear.app` over the web: the page needs authentication and returns an
application shell, not the content of the ticket.

## resolve(url)

In Linear, an epic is either a **project** or a **parent issue**. Match the path
of the URL in this order:

| Path shape | `kind` | `id` |
| --- | --- | --- |
| `/{workspace}/project/{slug-id}`, with or without a suffix such as `/overview` | `project` | `{slug-id}` |
| `/{workspace}/issue/{TEAM-123}/{slug}` | `issue` | `TEAM-123` |
| `/{workspace}/initiative/...` | not supported | stop, ask for a project or issue URL |
| `/{workspace}/document/...` | not supported | stop, ask for a project or issue URL |

The Linear tools accept both of these ids directly, so no lookup of an internal
UUID is necessary.

### Resolving `team`

A team is required to create an issue, and the URL does not contain one.

- `kind` = `issue`: read the team from the parent issue. `get_issue` returns it.
- `kind` = `project`: call `list_projects` with `query` set to the slug and
  `fields: ["id", "name", "teams"]`. If the project has one team, use it. If it
  has more than one, ask the user which team the new tickets belong to. Do not
  guess.

### Resolving `project`

- `kind` = `project`: the project is the epic itself.
- `kind` = `issue`: read the project of the parent issue, if it has one. New
  children must go in the same project.

## Verbs before the epic exists

These two run when no epic URL was given. They do not depend on `kind`.

| Verb | Call |
| --- | --- |
| `find_epic` | `list_projects` with `query` and `fields: ["id", "name", "summary", "url", "teams", "status"]`. Also `list_issues` with `query` and `team` when a parent issue could be the epic |
| `create_epic` | `save_project` with `name`, `description`, `addTeams: [team]`, and no `id` |

- **Search with a few keywords, not with the whole idea.** The `query` of
  `list_projects` matches the project name only. The `query` of `list_issues`
  matches the title and the description.
- **`save_project` takes `name`, not `title`.** `summary` is a separate field,
  limited to 255 characters, and it is the text shown in list views. Put the one
  line why there, and the full description in `description`.
- **A new epic is a project by default.** Create a parent issue instead only
  when the user asks for it. That maps to `save_issue` with `title` and `team`
  and no `id`.

## Verbs, `kind` = project

| Verb | Call |
| --- | --- |
| `read_epic` | `get_project` with `query` = `id`, `includeMilestones: true`, `includeResources: true` |
| `update_epic` | `save_project` with `id`, plus `description` or `patch` |
| `list_children` | `list_issues` with `project` = `id`, `includeArchived: false`, `fields: ["id", "title", "description", "url", "status", "parentId", "labels"]` |
| `create_child` | `save_issue` with `title`, `description`, `team`, `project` = `id` |
| `update_child` | `save_issue` with `id` = the child, plus `description` or `patch` |
| `delete_child` | `save_issue` with `id` = the child and `state: "canceled"` |
| `set_dependency` | `save_issue` with `id` = the blocked ticket and `blockedBy: ["<blocking ticket>"]` |
| `read_conventions` | `list_issue_labels` and `list_issue_statuses`, both with `team` |

## Verbs, `kind` = issue

| Verb | Call |
| --- | --- |
| `read_epic` | `get_issue` with `id`, `includeRelations: true` |
| `update_epic` | `save_issue` with `id`, plus `description` or `patch` |
| `list_children` | `list_issues` with `parentId` = `id`, `includeArchived: false`, `fields: ["id", "title", "description", "url", "status", "parentId", "labels"]` |
| `create_child` | `save_issue` with `title`, `description`, `team`, `parentId` = `id`, and `project` = the project of the parent when it has one |
| `update_child` | `save_issue` with `id` = the child, plus `description` or `patch` |
| `delete_child` | `save_issue` with `id` = the child and `state: "canceled"` |
| `set_dependency` | `save_issue` with `id` = the blocked ticket and `blockedBy: ["<blocking ticket>"]` |
| `read_conventions` | `list_issue_labels` and `list_issue_statuses`, both with `team` |

`save_issue` creates when `id` is absent and updates when `id` is present. Never
pass `id` on a create.

## Rules

- **Set `includeArchived: false` on every `list_issues` call.** The parameter
  defaults to true. Without it, archived and cancelled tickets look like live
  children during the reconcile step.
- **Update a description with `patch`, not with `description`.** `patch` is
  valid on update only, in place of `description`. It applies its operations in
  order and atomically, and each anchor string must match the current content
  exactly once. Read the current description first and build the anchors from
  it. A full `description` replaces everything, including text a human wrote.
- **Do not pass `labels` on an update unless the current labels are known.**
  `labels` replaces the whole set. Any label left out is removed from the ticket.
  Read the labels through `list_children` or `get_issue` first, then send the
  full intended set.
- **Send literal newlines in `description` and in `patch` text.** Do not send
  the escape sequence `\n`.
- **Linear cannot delete an issue, and `delete_child` does not try.** It sets
  the issue to the cancelled state, which is reversible by hand. Pass the state
  *type* `canceled`, not a status name: `state` accepts a type, a name, or an
  id, and the names are configurable per team, while the type is not. Use
  `list_issue_statuses` with `team` only when the user asks for a specific
  status.
- **Do not set `assignee`, `estimate`, `priority`, `cycle`, or `dueDate`.**
  These belong to the human.
- **`blocks` and `blockedBy` are append only.** They never remove an existing
  relation. To remove one, use `removeBlocks` or `removeBlockedBy`.
- **Linear has no issue template in the repository.** Templates live in the
  workspace and these tools cannot read them. Use the default ticket shape of
  the skill, unless the repository defines one in `CLAUDE.md`.
- **A comment is the right place for a note to the human.** Use `save_comment`
  with `issueId` or `projectId` for anything that is not part of the ticket
  itself, such as an open question or an assumption.
