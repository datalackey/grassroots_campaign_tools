# Jira Configuration for a Four-Person Team (doikayt Repositories)

A single Kanban-style Jira Software project with WIP limits fits a four-person team working on
the `doikayt` libraries. Issue keys are tied to the Conventional Commit and changeset flow that
already drives releases, so Jira status follows git events instead of manual updates.

This page applies to teams using Jira Software. Teams that track work elsewhere can skip it.
The git-side conventions it relies on (squash merges, PR-title checks) are described in the
`typescript-build-config` release policy:
<https://github.com/doikayt/typescript-build-config/blob/main/docs/RELEASE-PROCESS.md>

<!-- TOC:START -->
- [1. Project structure](#1-project-structure)
- [2. Issue types](#2-issue-types)
- [3. Workflow](#3-workflow)
- [4. Git linkage conventions](#4-git-linkage-conventions)
- [5. Integration](#5-integration)
- [6. Fields, labels, versions](#6-fields-labels-versions)
- [7. Working agreements](#7-working-agreements)
- [Caveats](#caveats)
<!-- TOC:END -->

## 1. Project structure

| Setting | Value | Reason |
|---|---|---|
| Projects | One, key `DK` | The libraries share one release policy, so cross-repo work stays in one place. |
| Template | Kanban | Work arrives continuously, and releases are automated on merge, not sprint-based. |
| Components | `build-tools`, `typescript-build-config`, `gas-demodulify-plugin`, `qwiki` | A component identifies the repository and allows a per-repository board filter. |
| Roles | 4 members, 1 project admin | Limits workflow and scheme changes to one person. |

Scrum ceremonies cost more than they return at four people, so none are configured.

## 2. Issue types

| Type | Use | Commit prefix |
|---|---|---|
| Bug | Defect in shipped behavior | `fix:` |
| Story | New capability | `feat:` |
| Task | Chores, docs, refactors, CI | `chore:`, `docs:`, `refactor:`, `ci:` |
| Epic | Cross-repository initiative | none |

Sub-task and Spike types are omitted until needed.

A custom **Impact** field (`patch`, `minor`, `major`, `none`) is added to Story and Bug. The
auto-changeset script produces only patch releases. Minor and major bumps require a handwritten
changeset (`npx changeset`), so the field flags that need at creation time.

## 3. Workflow

```text
Backlog → Ready → In Progress → In Review → Done
```

| Status | Meaning | Git event |
|---|---|---|
| Ready | Scoped, with acceptance criteria | none |
| In Progress | A branch exists | Branch created |
| In Review | A pull request (PR) is open | PR opened |
| Done | Merged to `main` with CI green | PR merged (squash commit) |

"Done" means merged, not published. The release job runs after the merge, and a release
failure is filed as a separate Bug.

Board rules:

- **WIP limits:** In Progress ≤ 4, In Review ≤ 3. This is the main control against review
  stalls.
- **No Blocked status.** Blocked items carry a flag and a comment and stay in their column.

## 4. Git linkage conventions

The block below shows the branch and PR-title formats. The issue key goes at the **end** of the
PR title so the Conventional Commit prefix stays first, which is where the release script reads
it.

```text
Branch:    fix/DK-42-toc-heading-anchors
PR title:  fix(update-markdown-toc): handle headings after HTML blocks (DK-42)
```

A CI check on the PR title should require a valid Conventional Commit prefix and a `DK-\d+`
key. `chore:` and `docs:` PRs may be exempted from the key to reduce friction.

## 5. Integration

| Host | Integration |
|---|---|
| GitHub (`build-tools`, `gas-demodulify-plugin`) | The **GitHub for Jira** app links branches, commits and PRs by issue key. Install: <https://marketplace.atlassian.com/apps/1219592/github-for-jira> |
| Codeberg (`typescript-build-config`, which has `.woodpecker.yml`) | No native Jira integration is known for Codeberg or Forgejo. Verify before relying on one. The fallback is a Jira automation rule with an incoming webhook, called from Woodpecker or a Forgejo webhook. |

Automation rules are configured per project at
`https://<site>.atlassian.net/jira/software/projects/DK/settings/automate`:

1. PR opened referencing the key → transition to **In Review**.
2. PR merged → transition to **Done**.
3. Issue created with Impact `major` → comment reminding the author to add a handwritten
   changeset.

## 6. Fields, labels, versions

- **Fix Version** is not maintained by hand. Changesets owns versioning, and the `fixed` group
  in `build-tools` moves all five packages together, so a hand-kept Jira version would drift.
  The released version goes in a comment, or is set from the release job if automated.
- **Labels** come from a small controlled set: `docs`, `ci`, `release`, `dx`. Repositories are
  tracked as components, not labels.
- **Priority** keeps the Jira defaults. Highest is reserved for a broken release pipeline,
  because a failed release job blocks publishing in every consumer repository.

## 7. Working agreements

1. Every non-trivial change has an issue before its branch exists.
2. Each issue has one owner. Reviewers are not owners.
3. Reviews are completed within one working day.
4. A 15-minute weekly triage covers the Backlog, Ready ordering and stale Ready items. A daily
   standup is added only if the board shows blockers.
5. An automation rule archives Done items after 14 days.

## Caveats

- Jira Free allows up to 10 users, which covers four people. Current plan limits should be
  checked before depending on specific automation or storage quotas.
- Workflow transitions, integration behavior and the automation menu path reflect general Jira
  capability. They should be verified against Atlassian's current documentation before this
  page is treated as final.
- The GitHub for Jira marketplace URL should be confirmed when installing.
