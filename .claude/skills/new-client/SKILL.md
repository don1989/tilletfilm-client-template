---
name: new-client
description: Spin up a personalized brochure GitHub repo for one client. Use when the user wants to create a new Opening Scene site for a prospect — Claude asks for the client details, makes the repo, swaps the text + assets, pushes to GitHub, and enables GitHub Pages. No config file needed.
---

# new-client

You are creating a personalized brochure repo from this template, end to end, by asking the user a few questions and then doing all the work yourself with tool calls. No JSON config, no separate script — just a conversation.

The template is a single-page site (`index.html` + `assets/`) currently filled in for one specific prospect ("Lee Liasi" of Tillett Film). Your job: produce a fresh repo with everything swapped for a new prospect, pushed to GitHub, with Pages enabled.

## Step 1 — Ask the details

Use the `AskUserQuestion` tool. Group sensibly; don't ask 10 questions in a row. Suggested flow:

**Q1 — Client name.** "What's the prospect's full name?" (free-text via Other; you'll split on the space for first/last).

**Q2 — Meeting details.** "When is the meeting? Day, date, time — e.g. `Friday, 16 May 2026, 2:30 PM EST`" (free-text).

**Q3 — Repo name.** Suggest a default like `firstname-lastname-opening-scene` (lowercase, dashes) and ask if that's OK or they want a different one.

> Repos are **always public** — GitHub Pages on free accounts only serves public repos. The brochure URL is technically discoverable, but in practice it's just `github.io/some-slug` with no inbound links. Don't ask about visibility.

**Q4 — Assets.** "Where are the client's videos/images? Either give me a folder path on this machine, or say 'use template assets'."

**Q5 — Studio / color overrides (optional).** Default is to skip. Only ask follow-ups if the user says they want non-default studio name, email, director, or brand colors.

After collecting, **echo a one-line plan** back ("Creating sarah-johnson-opening-scene for Sarah Johnson, meeting Friday 16 May 2:30 PM EST, public, template assets — OK?") and wait for confirmation.

## Step 2 — Install prerequisites (first run only)

Most of the time this step is a no-op. But if anything is missing, the skill installs it for the user. Don't ask the user to open another terminal — do it here.

Run this single check first to see what's missing:

```bash
for c in brew git gh rsync; do printf "%s: " "$c"; command -v "$c" >/dev/null && echo OK || echo MISSING; done
gh auth status 2>&1 | head -3 || true
```

Then handle each missing piece **in order**:

### 2a. Homebrew (Mac only)
If `brew` is missing and the platform is macOS (`uname -s` returns `Darwin`):

> Tell the user: "I need to install Homebrew first. It'll ask for your Mac password — type it in this terminal and press Enter."

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

This is interactive (sudo password) — let it run, don't background it. After it finishes, Homebrew may print a line about adding itself to PATH (`eval "$(/opt/homebrew/bin/brew shellenv)"`). Run that line so the current shell sees `brew`.

On Linux, use the system package manager (`sudo apt-get install -y gh git rsync` or similar) instead of brew. Tell the user what command you're about to run and let them approve.

### 2b. gh, git, rsync
For anything still missing:

```bash
brew install gh git rsync       # Mac
# or
sudo apt-get update && sudo apt-get install -y gh git rsync   # Debian/Ubuntu
```

### 2c. GitHub authentication
If `gh auth status` fails:

> Tell the user: "I need to log you in to GitHub. A browser tab will open — copy the 8-character code I show you, paste it into the page, and click Authorize. Come back here when done."

```bash
gh auth login --web --git-protocol https
```

Wait for it to finish. Verify with `gh auth status` before continuing.

### 2d. Determine the GitHub owner
Once authenticated:

```bash
gh api user --jq .login
```

Use that as `<owner>`. If the user mentioned wanting to push under an organization, ask which one.

## Step 3 — Build the new repo locally

The template lives at the current working directory. Create a sibling folder.

```bash
TEMPLATE_DIR="$(pwd)"
TARGET_DIR="$(dirname "$(pwd)")/<repoName>"
mkdir "$TARGET_DIR"
rsync -a --exclude='.git/' --exclude='scripts/' --exclude='.claude/' \
         --exclude='client.config*.json' --exclude='SETUP.md' \
         "$TEMPLATE_DIR/" "$TARGET_DIR/"
```

If the user supplied an assets folder, copy its contents into `$TARGET_DIR/assets/` (overwriting matching filenames):

```bash
rsync -a "<userAssetsDir>/" "$TARGET_DIR/assets/"
```

## Step 4 — Swap the strings in index.html

Use `Edit` with `replace_all: true` on `$TARGET_DIR/index.html`. **Order matters** — longest/most-specific patterns first so they don't get eaten by shorter ones:

1. `Lee Liasi` → `<CLIENT_FULL>`
2. `Liasi` → `<CLIENT_LAST>`
3. `Charlie Tillett` → `<DIRECTOR_FULL>` (only if studio overridden)
4. `charlie@tillettfilm.com` → `<STUDIO_EMAIL>` (only if studio overridden)
5. `tillettfilm.com` → `<STUDIO_DOMAIN>` (only if studio overridden)
6. `Tillett Film` → `<STUDIO_NAME>` (only if studio overridden)
7. `Charlie` → `<DIRECTOR_FIRST>` (only if studio overridden)
8. `Lee` → `<CLIENT_FIRST>`
9. `12 May 2026` → `<MEETING_DATE>`
10. `10:00 AM GMT` → `<MEETING_TIME>`
11. `Tuesday` → `<MEETING_DAY>`

Skip steps 3–7 if the user didn't override studio defaults.

For optional color overrides, also edit the `:root` block:
- `--bg: #ffffff;` → `--bg: <hex>;`
- `--bg-alt: #f5f4f1;` → `--bg-alt: <hex>;`
- `--bg-invert: #0a0a0a;` → `--bg-invert: <hex>;`
- `--ink: #0a0a0a;` → `--ink: <hex>;`

## Step 5 — Create the GitHub repo and push

```bash
cd "$TARGET_DIR"
git init -b main
git add .
git commit -m "Initial brochure for <CLIENT_FULL>"
gh repo create "<owner>/<repoName>" --public
gh repo set-default "<owner>/<repoName>"
git remote add origin "https://github.com/<owner>/<repoName>.git"
git push -u origin main
```

If `gh repo create` supports `--source=. --push` in one call, prefer that.

## Step 6 — Enable GitHub Pages

```bash
gh api -X POST "repos/<owner>/<repoName>/pages" \
  -f "source[branch]=main" -f "source[path]=/" \
  || gh api -X PUT "repos/<owner>/<repoName>/pages" \
       -f "source[branch]=main" -f "source[path]=/"
```

(The first call fails if Pages was already enabled; the PUT fallback updates it.)

## Step 7 — Report back

Tell the user:
- Live URL: `https://<owner>.github.io/<repoName>/` (allow ~1 minute for first build)
- Repo URL: `https://github.com/<owner>/<repoName>`
- Local folder path of the new repo

## Asset filenames the template expects

If the user provides a folder, the videos/images inside must be named exactly:

- `testimonial.mp4`, `testimonial-thumbnail.jpg`
- `work-brand-film.mp4`, `work-brand-film.jpg`
- `work-event-film.mp4`, `work-event-film.jpg`
- `work-founder-film.mp4`, `work-founder-film.jpg`
- `intro.mp4` (90-second personal note — optional but referenced)
- `showreel.mp4` (closing reel — optional but referenced)

If their folder is missing some, offer to rename theirs to match, or to leave the template defaults in place.

## Don't

- Don't modify the template `index.html` directly — always edit the copy in `$TARGET_DIR`.
- Don't commit anything to this template repo as part of the skill.
- Don't push to a repo the user didn't approve in Step 1.
- Don't proceed if `gh auth status` fails — stop and ask the user to authenticate first.
