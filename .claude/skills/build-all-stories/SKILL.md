---
name: build-all-stories
description: "Builds a range of stories end to end with no questions: for each one it runs the /dev-story flow, then the /story-done flow, taking every decision itself and logging it. Use when the user wants several stories built and closed in one go (\"build stories 1-3\"). Not for a single story with the user deciding: that is /dev-story."
argument-hint: "[epic-slug] [range, e.g. 1-3 or 4 or 2-7] [--commit]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, Bash(bash "*/.claude/skills/build-all-stories/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/story-facts.sh *), Bash(bash .claude/scripts/story-status.sh*), Bash(bash .claude/scripts/adr-status.sh *), Bash(bash .claude/scripts/md-section.sh *), Bash(bash .claude/scripts/session-state.sh *), Bash(bash .claude/scripts/review-receipts.sh *), Bash(godot *), Bash(mkdir -p production/qa/evidence/*), Bash(git status --porcelain*), Bash(git add -- *), Bash(git commit -m *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,automation_always_ask,workflow,qa.level,gate_level,review_mode,review_gate,engine_values,specialists,perf_budgets,system_overrides`

# Build all stories

For each story in a range: the whole `/dev-story` flow, then the whole `/story-done` flow,
with this skill taking every decision those skills would ask the person. Docs, run
results, evidence, criterion checks, fixes and status updates are all done as those
skills do them. Only the asking is removed, and everything decided is logged.

## 1. The epic, the range and the flags

Read the text typed after the skill name:
- **Epic:** a word that names a folder in `production/epics/`. With none, the only
  folder there. None or several and no slug: stop and list them.
- **Range:** `N-M` (stories N to M), `N` (that story only), or nothing (every open
  story). `1-3` means `story-001-*` to `story-003-*`. A range that names no story file:
  stop and list the story numbers that exist.
- **`--commit`:** commit each story after it closes. Without it, nothing is committed
  (the project's rule: no commits without the person's instruction).

Say in one line what will run: "Building stories 001-003 of shinobi-station: dev-story,
then story-done, for each."

## 2. The overrides (they hold for the whole run)

Run every phase of the two skills exactly as written, with only these changes:

1. **Automation is `autonomous` for this run, whatever the setting.** Where either skill
   would ask, take its recommended option (the first one, or the one it marks
   Recommended), and append the decision to `production/session-logs/decision-log.md`
   in the format of `.claude/docs/automation-modes.md`, naming the story.
2. **Always-ask categories are never decided here.** A decision in
   `automation_always_ask` (by default scope changes, file deletions, schema changes):
   do not make the change. Skip that part, log it as `skipped: <category>`, and list it
   in the report.
3. **Sign-off is the person's.** A Visual/Feel story's evidence doc gets its screenshot
   and this skill's own review notes, but its sign-off rows stay unticked: never mark
   `[x] Approved` for the person. `/story-done` then cannot close the story: leave it
   at the status `/story-done` gives it, and go on to the next story.
4. **Commits only with `--commit`.** Where `/story-done` asks "Commit this story?",
   commit as it describes when `--commit` was typed; otherwise do not, and log it.
5. **"Type `/dev-story …` / `/story-done …`" lines are this run's next steps,** not lines
   for the person: carry on with them yourself, story by story.
6. **The settings block above stands in for each skill's own.** Their `!` config lines do
   not render when read here; use the values above, with automation as in rule 1.
7. **The work goes where `/dev-story` sends it.** Its Phase 4 and 5 hand the code to the
   engine specialist in `project.yaml`'s `specialists` block (for GDScript,
   `godot-gdscript-specialist`, pinned to Sonnet in its agent file). Keep that hand-off:
   never write a story's code inline to save a step.

## 3. For each story, in number order

1. **Develop:** read `.claude/skills/dev-story/SKILL.md` and follow it from Phase 1 to
   Phase 7 for this story, with the files under `.claude/skills/dev-story/references/`
   when it says to read them.
2. **Close:** read `.claude/skills/story-done/SKILL.md` and follow it from Phase 1 to
   Phase 8, with its `references/` the same way.
3. **Readjust:** when `/story-done` finds a criterion unmet, a gap it can close (a
   missing doc, a missing screenshot) or a deviation it can fix, fix it the way
   `/dev-story` would, then run `/story-done` once more. At most two fix rounds per
   story. What is still open after that goes in the report, and the run goes on.
4. **Skip what is already closed:** a story whose Status is `Done` is not rebuilt; name it
   in the report.

A story whose Dependencies name a story that is not `Done` (outside the range, or left
open above) is still built on what exists; the report names the missing one.

## 4. Report

One block per story:

```
Story NNN: <title> — <final status from /story-done>
  Built: <files changed>
  Run: <dev-story's Run result>
  Evidence: <paths> | none needed
  Decided for you: <n> (production/session-logs/decision-log.md)
  Fix rounds: <0-2>; still open: <what, or none>
  Skipped (always-ask): <what, or none>
  Waiting on you: <sign-off in production/qa/evidence/<story>-evidence.md | nothing>
  Committed: <commit hash | no (--commit not given)>
```

Then the run's closing block:

```
Verdict: <ALL CLOSED | PARTLY CLOSED> — <n> of <m> stories Done (<range>)
Waiting on you: <each sign-off or skipped always-ask item, one per line | nothing>
Decision log: production/session-logs/decision-log.md (<n> entries this run)
```

A story that is not `Done` is never counted as closed, and a step that did not run says
so by name.
