---
name: new-client
description: Spin up a personalized brochure GitHub repo for one client. Use when the user wants to create a new Opening Scene site for a prospect. Claude asks for the client details, generates the repo from the GitHub template, swaps the text + intro video, pushes, and enables GitHub Pages — all from any folder Claude Code is opened in. No local template clone required.
---

# new-client

You're creating a personalized brochure repo from the `don1989/tilletfilm-poc` GitHub **template repository**. The template is marked as a template on GitHub, so the GitHub API endpoint `POST /repos/{template_owner}/{template_repo}/generate` will create a fresh client repo with all the template files but no commit history.

This skill works from **any** folder the user has Claude Code opened in — it never relies on a local clone of the template.

Constants you can use throughout:
- Template source: `don1989/tilletfilm-poc`
- The operator's GitHub username: read from `gh api user --jq .login`. Brochure repos are always created under his own account — there's no org.
- Working directory for the new repo: `~/Documents/brochures/<repoName>`

## Step 0 — Determine the owner

```bash
OWNER=$(gh api user --jq .login)
```

That's where the new client repo will live (`$OWNER/$REPO_NAME`). If `gh api user` fails, `gh` isn't authenticated — tell the user to re-run the installer prompt and stop.

## Step 1 — Ask the per-client details

Use `AskUserQuestion`. Group sensibly:

**Q1 — Prospect's full name.** Free-text (e.g. "Sarah Johnson"). You split on the first space for first/last.

**Q2 — Meeting day, date, time.** One free-text question — e.g. `Friday, 16 May 2026, 2:30 PM EST`. Parse into the three sub-values.

**Q3 — Repo name.** Suggest `<firstname>-<lastname>-opening-scene` (lowercased, hyphenated). Confirm or override.

**Q4 — Intro video.** Path to the personal 90-second video on this Mac (e.g. `~/Desktop/sarah-intro.mov`). Accept any common format (`.mp4`, `.mov`, `.m4v`, `.webm`). Or "skip".

**Q5 — Studio / color overrides (optional).** Default to skip. Only follow up if the user wants non-default studio name, email, director, or brand colours.

Echo a one-line plan and wait for confirmation before doing anything destructive.

## Step 2 — Verify prerequisites (mostly a no-op after install)

```bash
command -v gh && command -v git && command -v perl && gh auth status
```

If any of these fail, the installer wasn't run. Tell the user to paste the installer prompt (see SETUP.md in the template repo). Stop.

## Step 3 — Generate the new repo from the template

```bash
gh api -X POST repos/don1989/tilletfilm-poc/generate \
  -f owner="$OWNER" \
  -f name="$REPO_NAME" \
  -f description="Opening Scene brochure for $CLIENT_FULL" \
  -F include_all_branches=false \
  -F private=false
```

This creates `$OWNER/$REPO_NAME` on GitHub with the template's files and a single initial commit. There's a brief moment where the repo exists but files aren't yet ready to clone — wait 3 seconds, then continue.

If this call returns `404`, the template flag isn't set on `don1989/tilletfilm-poc`. Tell the user to toggle it at `https://github.com/don1989/tilletfilm-poc/settings` and stop.

## Step 4 — Clone the generated repo locally for editing

```bash
mkdir -p ~/Documents/brochures
TARGET_DIR="$HOME/Documents/brochures/$REPO_NAME"
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
- Provide a showreel path for this brochure (one-off, copy as `assets/showreel.mp4`)
- Add it to the template repo for all future clients (commit to `don1989/tilletfilm-poc:main` — needs push permission)
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
- **Studio-wide** (testimonial, work films, showreel) — live in the template repo's `assets/` and are inherited by every generated brochure automatically. Update them once in `don1989/tilletfilm-poc` and every future client inherits the new version.
- **Per-client** — just the intro video. The only file you ask the user for.

## Don't

- Don't try to run this from a local template clone — there isn't one. Use the GitHub API.
- Don't push to `don1989/tilletfilm-poc` as part of a per-client run (template stays clean).
- Don't proceed past Step 2 if `gh auth status` fails — stop and tell the user to re-run the installer.
- Don't change the repo visibility to private — Pages only works on public repos with a free plan.
