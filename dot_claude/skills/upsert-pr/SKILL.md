---
name: upsert-pr
description: Create or update the draft pull request for the current branch, writing the body from the branch's diff against the base branch and the repository's PR template. Use whenever the user asks to open, create, draft, or refresh a pull request, including bare invocations such as "open a PR" or "update the PR description".
---

# Upsert PR

If the current branch has no pull request, open one as a draft. If it already
has one, bring its description back in line with what the branch now contains.

Running this twice on the same branch is expected. The second run must not undo
the first.

## Preconditions

Check these first, and stop with a clear message if any fails:

- `gh auth status` succeeds. This skill drives GitHub only through the `gh` CLI.
- The current branch is not the base branch.
- `git log <base>..HEAD` is non-empty. A branch with no commits of its own has
nothing to describe.

The base branch is the repository default from
`gh repo view --json defaultBranchRef`, unless the guidance file or the user
names a different one.

## Repository guidance

Read `.claude/upsert-pr.md` from the repository root if it exists. It holds the
conventions of this repository: the title format, the issue tracker, the
verification commands, and notes on the sections of the PR template. Follow it
exactly. Where it is silent, use your judgement.

If the file does not exist, the defaults in this skill apply, and you offer to
write one. See [Creating the guidance file](#creating-the-guidance-file).

## Process

1. **Read the guidance file**, then resolve the base branch.
2. **Find any existing pull request** with
`gh pr view --json number,title,body,isDraft,url`. Success means update mode. A
"no pull requests found" error means create mode.
3. **Confirm the branch is on the remote.** See [Pushing](#pushing).
4. **Read the change.** Use `git log <base>..HEAD` for intent, and
`git diff <base>...HEAD` for content. The three dots are important: two dots
compares against the current tip of the base branch, and attributes other
people's commits to this branch.
5. **Write the body.** See [Body](#body).
6. **Create or update.** Create mode: `gh pr create --draft --base <base>`.
Update mode: `gh pr edit <number>`, and leave the title alone.
7. **Report** the URL, the title, whether you created or updated the pull
request, and every section you filled, deleted, or left for the user.

Always write the body to a file in the scratchpad and pass it with
`--body-file`. Markdown through `--body` puts backticks, newlines, and `#` at
the mercy of the shell.

## Body

Read `.github/pull_request_template.md` at run time and follow it. It is a file
in the repository, so there is no excuse for writing the sections from memory.
The template changes, and a stale copy produces a body that reviewers do not
expect.

Replace each HTML comment with real content. Delete a section, heading and
comment together, when its comment says it is deletable and it does not apply.

If there is no template, write a short body: what the branch does, and why it
exists. The reason is rarely in the diff. Look for it in the commit messages
and in the linked issue.

Describe the change, not the file list. Never write a verification step that
did not run.

## Title

Set a title only in create mode. In update mode leave it alone, unless the user
asks, because they may have edited it deliberately.

Follow the title format in the guidance file. With no guidance, write a short
sentence that says what the branch does.

## Update mode

Read the existing body before you write anything, and use it as evidence. It
holds reasons, context, and decisions that the diff does not carry. Then write
the best description of the branch as it stands now. Wording and structure are
your judgement.

- Carry forward the meaning that the diff cannot supply on its own: why the
branch exists, known limits, and anything the user added by hand.
- Drop statements the diff no longer supports, and name each drop in your
report so the user can push back.
- Add sections the body is missing, and detail for commits that landed since
the body was last written.
- Do not restore a section the user deleted, unless the change now makes it
applicable. Say so in the report when you do.

Never run `gh pr ready`. This skill only works in draft. Marking a pull request
ready for review is the user's decision.

## Pushing

`gh pr create` needs the branch on the remote. When it is not there, ask the
user before you push. A push is outward-facing, so it is their call each time.

Once they agree, prove that the remote accepts your credentials before you
push:

```bash
git ls-remote origin HEAD
```

Exit 0 means the push will go through. `Permission denied (publickey)` means
the key is not available to this session. Stop, tell the user, and wait for
them to load it. Do not route around a failed push by rewriting the remote URL
or by reaching for a different credential.

In update mode, local commits that are ahead of the remote produce a
description that does not match what a reviewer sees. Point that out, and offer
to push, rather than describing work that is not there yet.

## Creating the guidance file

When `.claude/upsert-pr.md` does not exist, offer to write it from
`template.md`, beside this file. `example-guidance.md` shows a filled one.

Never write the file without the user's agreement, and never block the pull
request on it. If the user declines, or wants it later, continue with the
defaults and say so in your report.

Once they agree:

1. **Gather the evidence first.** The repository answers most of it:
   - Title convention: `git log <base> --format='%s' -n 50`.
   - Issue tracker: branch names, `.claude/issue-tracker.md` if it exists, and
   the bodies of recent pull requests.
   - Verification commands: the scripts in `package.json`, a `Makefile`, or the
   workflows in `.github/workflows`.
   - Template sections that need a rule: `.github/pull_request_template.md`.
2. **Ask only what the repository cannot answer.** The merge style, and any
convention that the history shows inconsistently. Ask in one round, not one
question at a time.
3. **Fill the template**, and mark anything you inferred rather than confirmed.
4. **Show the draft, and get approval** before you write
`.claude/upsert-pr.md`.

Leave out any section you have nothing true to say about. An empty heading is
noise, and the model falls back to its own judgement anyway. Then continue with
the pull request, using the new file.

## When to ask

Ask before you act, not after, when the branch has no remote counterpart, or
when the base branch is in doubt. Do not ask about wording that the template
and the guidance file already settle.
