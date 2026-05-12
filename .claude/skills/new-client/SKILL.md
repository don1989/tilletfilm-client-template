---
name: new-client
description: Spin up a personalized client site GitHub repo for one prospect. Use when the user wants to create a new Opening Scene site for a prospect. Claude asks for the client details, generates the repo from the operator's own template, swaps the text + intro video, pushes, and enables GitHub Pages — all from any folder Claude Code is opened in.
---

# new-client

You're creating a personalized client site from the operator's own GitHub **template repository** at `<their-username>/tilletfilm-client-template`. That template is a copy of `don1989/tilletfilm-client-template` that the operator made during install — they own it, can customize the studio-wide assets (showreel, work films, testimonials, brand text/colours) however they like, and every new client site is generated fresh from it.

The GitHub API endpoint `POST /repos/{template_owner}/{template_repo}/generate` creates a fresh client repo with all the template files but no commit history. The template must be marked as a template on GitHub (the installer does this).

This skill works from **any** folder Claude Code is opened in — it never relies on a local clone of the template.

Constants you can use throughout:
- The operator's GitHub username: read from `gh api user --jq .login`.
- Template source: `$OWNER/tilletfilm-client-template` — *the operator's* template, not the upstream one. Convention-based: the installer always creates it with this name.
- Working directory for new client sites: `~/Documents/client-sites/<repoName>`
- Operator's local template clone (for context): `~/Documents/tilletfilm-client-template/` — they edit studio assets there.

## Step 0 — Determine the owner and template source

```bash
OWNER=$(gh api user --jq .login)
TEMPLATE_REPO="$OWNER/tilletfilm-client-template"
```

If `gh api user` fails, `gh` isn't authenticated — tell the user to re-run the installer prompt and stop.

Verify the operator's template exists and is marked as a template:

```bash
gh api "repos/$TEMPLATE_REPO" --jq '.is_template' 2>/dev/null
```

If this returns `false` or the call 404s, the install didn't complete properly. Tell the user to re-run the installer or manually toggle the Template Repository flag at `https://github.com/$TEMPLATE_REPO/settings`. Stop.

## Step 1 — Ask the per-client details

Most of these are free-text (names, dates, file paths), so **do NOT use `AskUserQuestion`** — that tool is designed for multiple-choice and forces the user through an "Other → type text" detour for every answer. Instead, just write the question list as a plain assistant message and let the user reply with all the answers at once. A single message like this is ideal:

> "To generate the client site, I need:
> 1. **Prospect's full name** — e.g. "Sarah Johnson"
> 2. **Meeting day, date, time** — e.g. "Friday, 16 May 2026, 2:30 PM EST"
> 3. **Repo name** — I'll suggest `<firstname>-<lastname>-precall-brochure` based on the name; confirm or override.
> 4. **Intro video path** on this Mac — e.g. `~/Desktop/sarah-intro.mov`, or say "skip"
> 5. **Studio/color overrides** — default is to keep the template's defaults. Say "skip" or list what to change."

Parse the reply, then echo a one-line plan back and wait for confirmation before doing anything destructive:

> "Plan: generate `<owner>/<repo-name>` for `<full-name>`, meeting `<day, date, time>`, intro from `<path>`, defaults elsewhere. Proceed?"

## Step 2 — Verify prerequisites (mostly a no-op after install)

```bash
command -v gh && command -v git && command -v perl && gh auth status
```

If any of these fail, the installer wasn't run. Tell the user to paste the installer prompt (see SETUP.md in the template repo). Stop.

## Step 3 — Generate the new repo from the operator's template

```bash
gh api -X POST "repos/$TEMPLATE_REPO/generate" \
  -f owner="$OWNER" \
  -f name="$REPO_NAME" \
  -f description="Opening Scene client site for $CLIENT_FULL" \
  -F include_all_branches=false \
  -F private=false
```

This creates `$OWNER/$REPO_NAME` on GitHub with the template's files and a single initial commit. There's a brief moment where the repo exists but files aren't yet ready to clone — wait 3 seconds, then continue.

If this call returns `404`, the template flag isn't set on `$TEMPLATE_REPO` (Step 0 should have caught this — re-check).

## Step 4 — Clone the generated repo locally for editing

```bash
mkdir -p ~/Documents/client-sites
TARGET_DIR="$HOME/Documents/client-sites/$REPO_NAME"
gh repo clone "$OWNER/$REPO_NAME" "$TARGET_DIR"
cd "$TARGET_DIR"
```

The clone gives us a working copy on disk for the edits. We push back when done.

## Step 5 — Swap the per-client strings in index.html

Use `Edit` with `replace_all: true` on `$TARGET_DIR/index.html`. **Order matters** — longest first so shorter patterns don't eat them:

1. `Lee Liasi` → `<CLIENT_FULL>`
2. `Liasi` → `<CLIENT_LAST>`
3. `Charlie Tillett` → `<DIRECTOR_FULL>` *(only if studio overridden)*
4. `charlie@tillettfilm.com` → `<STUDIO_EMAIL>` *(only if overridden)*
5. `tillettfilm.com` → `<STUDIO_DOMAIN>` *(only if overridden)*
6. `Tillett Film` → `<STUDIO_NAME>` *(only if overridden)*
7. `Charlie` → `<DIRECTOR_FIRST>` *(only if overridden)*
8. `Lee` → `<CLIENT_FIRST>`
9. `12 May 2026` → `<MEETING_DATE>`
10. `10:00 AM GMT` → `<MEETING_TIME>`
11. `Tuesday` → `<MEETING_DAY>`

For colour overrides, also edit the `:root` block:
- `--bg: #ffffff;` → `--bg: <hex>;`
- `--bg-alt: #f5f4f1;` → `--bg-alt: <hex>;`
- `--bg-invert: #0a0a0a;` → `--bg-invert: <hex>;`
- `--ink: #0a0a0a;` → `--ink: <hex>;`

## Step 6 — Wire up the intro video (if provided)

If the user gave a path in Q4:

```bash
[ -f "$INTRO_PATH" ] || { echo "Intro file not found, skipping"; }
EXT="${INTRO_PATH##*.}"
EXT="$(printf '%s' "$EXT" | tr '[:upper:]' '[:lower:]')"
cp "$INTRO_PATH" "$TARGET_DIR/assets/intro.$EXT"
```

Then run this perl one-liner to swap the scene-02 placeholder for a real `<video>` tag and remove the dead alert handler:

```bash
INTRO_EXT="$EXT" perl -i -0777 -pe '
  my $ext = $ENV{INTRO_EXT};
  my $replacement =
    qq{<video src="assets/intro.$ext" controls playsinline preload="metadata" } .
    qq{id="introVideo" style="width:100%; aspect-ratio:16/9; background:#000; } .
    qq{border-radius:12px; display:block;">Your browser does not support embedded video.</video>};
  s~<div class="video-placeholder" id="introVideo">\s*<div class="play-button"></div>\s*<div class="video-caption">[^<]*</div>\s*</div>~$replacement~;
  s~\s*// Video placeholder click\s*\n\s*document\.getElementById\(.introVideo.\)\?\.addEventListener\(.click., \(\) => \{[^}]*\}\);~~;
' "$TARGET_DIR/index.html"
```

## Step 7 — Check the studio showreel

```bash
[ -f "$TARGET_DIR/assets/showreel.mp4" ] || echo "WARNING: closing scene reel missing"
```

If missing, tell the user the closing scene will be a black box and offer:
- Provide a showreel path for this client site only (one-off, copy as `assets/showreel.mp4` in this new repo)
- Add it to *the operator's own template* (`$TEMPLATE_REPO`) so every future client site inherits it. The local clone is at `~/Documents/tilletfilm-client-template/`. Drop the file in `assets/showreel.mp4` there, `git add/commit/push`. Then also copy into `$TARGET_DIR/assets/` for this client.
- Skip

## Step 8 — Commit and push

```bash
cd "$TARGET_DIR"
git add -A
git commit -m "Personalize for $CLIENT_FULL"
git push
```

## Step 9 — Enable GitHub Pages

```bash
gh api -X POST "repos/$OWNER/$REPO_NAME/pages" \
  -f "source[branch]=main" -f "source[path]=/" \
  || gh api -X PUT "repos/$OWNER/$REPO_NAME/pages" \
       -f "source[branch]=main" -f "source[path]=/"
```

## Step 10 — Report back

Tell the user:
- Live URL: `https://$OWNER.github.io/$REPO_NAME/` (allow ~1 minute for first build)
- Repo URL: `https://github.com/$OWNER/$REPO_NAME`
- Local working folder: `$TARGET_DIR`

## How assets work (for context if user asks)

Two layers:
- **Studio-wide** (testimonial, work films, showreel) — live in the template repo's `assets/` and are inherited by every generated client site automatically. Update them once in `don1989/tilletfilm-client-template` and every future client inherits the new version.
- **Per-client** — just the intro video. The only file you ask the user for.

## Don't

- Don't try to run this from a local template clone — there isn't one. Use the GitHub API.
- Don't push to `don1989/tilletfilm-client-template` as part of a per-client run (template stays clean).
- Don't proceed past Step 2 if `gh auth status` fails — stop and tell the user to re-run the installer.
- Don't change the repo visibility to private — Pages only works on public repos with a free plan.
