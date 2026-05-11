---
name: new-client
description: Spin up a personalized brochure GitHub repo for one client. Use when the user wants to create a new Opening Scene site for a prospect — collects the client details (name, meeting day/date/time), studio overrides, color overrides, and assets folder; then creates the repo and enables GitHub Pages.
---

# new-client

You are creating a new personalized brochure repo from this template. The template is a one-page site (`index.html` + `assets/`) pre-filled with placeholder values for one specific client (currently "Lee Liasi" of Tillett Film). Your job is to produce a fresh repo with all those values swapped for a new prospect, push it to GitHub, and enable GitHub Pages.

## How to run

1. **Ask the user** for the per-client values using the `AskUserQuestion` tool. Group them sensibly — don't ask 12 questions in a row. A good flow:

   **Question 1 — client identity:** first name, last name (single free-text via "Other" — phrase it as "What's the client's full name? e.g. Sarah Johnson")

   **Question 2 — meeting details:** day of week, date, time (one free-text question, ask for all three: "When is the meeting? Format: day, date, time — e.g. Friday, 16 May 2026, 2:30 PM EST")

   **Question 3 — repo name:** "What should the GitHub repo be called?" (suggest a default like `<firstname>-<lastname>-opening-scene`, all lowercase, dashes)

   **Question 4 — visibility:** public or private GitHub repo

   **Question 5 — assets:** "Where are the client's video/image files?" Offer options:
   - "I have a folder ready" (then ask for the path)
   - "Use the template assets for now, I'll swap them later"

   **Question 6 — studio/color overrides (optional):** "Any non-default studio name, email, or brand colors?" Default to skipping; only ask follow-ups if they say yes.

2. **Confirm the plan** in a short summary (client name, meeting, repo name, asset source). Wait for user OK before proceeding.

3. **Build a config JSON** at `/tmp/new-client-<repoName>.json` matching `client.config.example.json` in the repo root. Fill the studio block with the existing values from the template unless the user overrode them. Defaults:
   - `studio.name`: "Tillett Film"
   - `studio.directorFirstName`: "Charlie"
   - `studio.directorFullName`: "Charlie Tillett"
   - `studio.domain`: "tillettfilm.com"
   - `studio.email`: "charlie@tillettfilm.com"
   - `colors`: omit (script falls back to template defaults)
   - `github.owner`: read from `git remote get-url origin` on the template repo, or ask if unclear

4. **Run the script:**
   ```bash
   bash scripts/new-client.sh /tmp/new-client-<repoName>.json
   ```

5. **Report results** to the user: the live URL, the repo URL, and a reminder that GitHub Pages may take ~1 minute to build on first deploy.

## What gets replaced

The script does ordered text substitutions in `index.html`. You don't need to do these by hand — but here's what changes so you can answer questions:

- Per-client: `Lee Liasi`, `Lee`, `Liasi`, `Tuesday`, `12 May 2026`, `10:00 AM GMT`
- Studio (only if overridden): `Tillett Film`, `Charlie Tillett`, `Charlie`, `tillettfilm.com`, `charlie@tillettfilm.com`
- Colors (only if overridden): the four `:root` CSS variables — `--bg`, `--bg-alt`, `--bg-invert`, `--ink`

## What the script needs installed

If any of these are missing, tell the user before running:
- `gh` (GitHub CLI), authenticated with `gh auth login`
- `jq`
- `rsync`
- `git`

## Asset filenames

If the user provides their own assets folder, the files inside must use these exact names (otherwise the page won't find them):

- `testimonial.mp4`, `testimonial-thumbnail.jpg`
- `work-brand-film.mp4`, `work-brand-film.jpg`
- `work-event-film.mp4`, `work-event-film.jpg`
- `work-founder-film.mp4`, `work-founder-film.jpg`
- `intro.mp4` (the 90-second personal video — referenced by the brochure but optional)
- `showreel.mp4` (closing reel — referenced by the brochure but optional)

Warn the user if their folder is missing these names and offer to either rename for them or proceed with the template defaults.

## Don't

- Don't modify the template `index.html` directly. The script always operates on a copy in a sibling directory.
- Don't commit anything to this template repo as part of the skill — only the new client repo gets a commit.
- Don't push to a different repo than the one the user specified.
