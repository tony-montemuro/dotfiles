# Issue tracker

Copy this file to `.claude/issue-tracker.md` in the repository, then fill it in.
Delete the parenthesised notes as you go.

- Tracker: (the host of the tracker, for example `linear.app`)
- Team: (the team name, with its key when it has one, for example `SMBElite (SMB)`)
- Epic kind: (the concrete kind that groups work, for example `project`)
- Work kind: (the concrete kind of a single unit of work, for example `issue`)

Both kinds must be ones the adapter for this tracker supports. Its kinds section
lists them.

## Template: (the epic kind)

```markdown
(The markdown skeleton every epic carries: the headings, in order, plus any
fixed text that belongs inside a section.)
```

## Template: (the work kind)

```markdown
(The same, for a single unit of work.)
```

Keep each template body inside its fence. The fence stops the headings of the
template from ending the section that holds them. When a template body contains
a fence of its own, open and close the wrapper with four backticks instead of
three, so the inner fence does not close it early.

## Guidance: (the work kind)

(Optional. One `###` heading per heading of the template above, matching it word
for word, holding the advice for filling that section. A heading with no guidance
here is filled with judgement. Delete this whole section when there is nothing to
say. Guidance describes how to fill a section; it never goes into the item.)

### (a heading from the template above)

(How to fill that section in this repository: the roles that exist, the house
style, what belongs there and what does not.)

## Guidance: (the epic kind)

(The same, for the epic kind. Optional in the same way.)

## Conventions

(Prose. Anything a planning skill must respect that the tracker cannot state on
its own: which labels are meaningful, when to open a new epic instead of
extending one, house style for titles.)
