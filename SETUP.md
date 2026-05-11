# Setup — make a new client brochure in 2 minutes

This template lets you spin up a personalized one-page brochure for every prospect, hosted free on GitHub Pages. The whole flow runs inside Claude Code — you never need to touch the terminal directly.

---

## One-time setup

You'll do this once, ever. After that every new client takes 2 minutes.

1. **Install Claude Code** if you haven't already: <https://claude.com/claude-code>
2. **Clone this template** to your Mac. In Claude Code, point it at this repo and let it run:
   ```
   git clone https://github.com/don1989/tilletfilm-poc.git ~/Documents/tilletfilm-poc
   ```
   Then open Claude Code in `~/Documents/tilletfilm-poc/`.
3. **Run `/new-client` once.** The first time you run it, Claude will install everything it needs (Homebrew, GitHub CLI, etc.) for you. You'll be asked for two pieces of input — both unavoidable, both one-time:
   - **Your Mac password** when Homebrew installs itself. Type it into the terminal.
   - **A GitHub login code.** Claude will print an 8-character code; paste it into the browser tab that opens, click Authorize, come back.

You can quit out at any point during your first run. Setup is done.

### Studio showreel (also one-time)

Before your first real client, drop your studio showreel into this template repo as `assets/showreel.mp4` and commit it. From then on every brochure inherits it. Ask Claude to do it for you:

> "Add this file as the studio showreel: `~/Desktop/showreel.mp4`"

Claude will copy it into `assets/`, commit, and push. Same trick if you ever want to update the testimonial or work films — replace the file in `assets/`, commit, done.

---

## Every new client

In Claude Code, in the template folder:

```
/new-client
```

Claude asks you, one at a time:

1. **Prospect's full name** — e.g. *Sarah Johnson*
2. **Meeting day, date, time** — e.g. *Friday, 16 May 2026, 2:30 PM EST*
3. **Repo name** — Claude suggests `sarah-johnson-opening-scene`; accept or change.
4. **Intro video path** — wherever the 90-second personal video is on your Mac. Any filename. Any common format (`.mp4`, `.mov`, `.m4v`). For example `~/Desktop/sarah-intro.mov` straight off your phone via AirDrop. Or say *skip* and Claude leaves the placeholder.
5. **Anything custom?** — by default Claude uses your studio name, email, director, and brand colors. Only answer if you want to override.

Then Claude does the rest itself: copies the template, swaps every name and date in `index.html`, copies your intro video in, wires up scene 02, creates the GitHub repo, pushes, and turns on GitHub Pages. At the end it prints the live URL — something like `https://don1989.github.io/sarah-johnson-opening-scene/`.

Wait ~1 minute for GitHub to build the page the first time, then send the link.

> All brochure repos are created **public** — free GitHub Pages only serves public repos. The URL has no inbound links, so it's only discoverable by people you send it to.

---

## How assets work

Two layers:

- **Studio-wide** (testimonial, work films, showreel) — live in this template repo's `assets/`. Every new brochure inherits them. Update them once, here, and every future brochure picks up the new version on its next build.
- **Per-client** — just the intro video. The only file Claude asks you for.

So the only thing you wrangle per prospect is one 90-second video.

---

## Troubleshooting

**The `/new-client` slash command doesn't appear** — make sure you opened Claude Code in the template folder (`~/Documents/tilletfilm-poc/`), not the home folder. Claude looks for skills in `.claude/skills/` relative to where it was launched.

**The site shows 404 after Claude finishes** — GitHub Pages takes about a minute to build on first deploy. Refresh in 60 seconds. If still broken after 5 minutes, ask Claude to check: it can hit the Pages settings via `gh api repos/OWNER/REPO/pages` and tell you what's wrong.

**Intro video doesn't play on the client's site** — most likely the file path you gave Claude was wrong, or the file is in a format the browser doesn't support (rare for `.mp4`, `.mov`, `.m4v`). Ask Claude to re-run the intro-video step with a different file.

**The closing-scene reel is a black box** — you skipped the studio showreel setup above. Drop a `showreel.mp4` into the template's `assets/` folder, commit it, push. Future brochures will have it; this client's brochure can be fixed by asking Claude to copy the showreel into the already-created repo.

**The other videos (testimonial, work films) are stale** — those live in the template repo's `assets/`. Ask Claude to replace them and commit; every future brochure will use the new versions.
