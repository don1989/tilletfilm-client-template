# Setup — make a new client brochure in 2 minutes

This template lets you spin up a personalized one-page brochure for every prospect, hosted free on GitHub Pages. No coding required.

There are **two ways** to use it. Pick whichever feels easier.

---

## Option A — One command (recommended)

You run a single command per client. Best if you're comfortable opening Terminal once a week.

### One-time setup

Open Terminal (Mac: ⌘+Space → "Terminal" → Enter). Paste each block, press Enter, wait for it to finish before the next.

**1. Install Homebrew** (if you don't already have it):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**2. Install the tools the script needs:**

```bash
brew install gh jq rsync git
```

**3. Log in to GitHub** (this opens your browser):

```bash
gh auth login
```

Choose: GitHub.com → HTTPS → Login with a web browser. Copy the code it shows, paste it in the browser tab that opens, click Authorize.

**4. Get the template:**

```bash
cd ~/Documents
git clone https://github.com/don1989/tilletfilm-poc.git
cd tilletfilm-poc
```

You only do steps 1–4 once. Done.

### One-time studio setup: showreel

Before your first client, drop your studio showreel into the template repo as `assets/showreel.mp4`, then commit it. From now on every brochure inherits it.

```bash
cd ~/Documents/tilletfilm-poc
cp /path/to/your/showreel.mp4 assets/showreel.mp4
git add assets/showreel.mp4
git commit -m "Add studio showreel"
git push
```

Same goes for the studio testimonials and work films — they're already in `assets/` from the template, but you can swap them once and every future brochure will use the new versions.

### Every new client

The only file that changes per client is the **personal intro video** — the 90-second note you record for that specific prospect. Everything else (testimonial, work films, showreel) is shared across all clients and lives in the template.

**1. Have the intro video on your Mac somewhere.** Any filename, any common format works (.mp4, .mov, .m4v). For example `~/Desktop/sarah-intro.mov` straight off your phone via AirDrop.

**2. Copy the example config and fill it in:**

```bash
cd ~/Documents/tilletfilm-poc
cp client.config.example.json clients/sarah-johnson.json
open clients/sarah-johnson.json
```

Edit the fields:

```json
{
  "client": {
    "firstName": "Sarah",
    "lastName": "Johnson",
    "meetingDay": "Friday",
    "meetingDate": "16 May 2026",
    "meetingTime": "2:30 PM EST"
  },
  "studio": {
    "name": "Tillett Film",
    "directorFirstName": "Charlie",
    "directorFullName": "Charlie Tillett",
    "domain": "tillettfilm.com",
    "email": "charlie@tillettfilm.com"
  },
  "github": {
    "owner": "don1989",
    "repoName": "sarah-johnson-opening-scene"
  },
  "introVideo": "/Users/YOUR-USERNAME/Desktop/sarah-intro.mov"
}
```

Save and close.

**3. Run the script:**

```bash
bash scripts/new-client.sh clients/sarah-johnson.json
```

That's it. The script will print the live URL at the end — something like `https://don1989.github.io/sarah-johnson-opening-scene/`. Wait ~1 minute for GitHub to build the page the first time, then send the link to your client.

### Customizing colors (optional)

Add a `colors` block to the config to override the four brand tokens:

```json
"colors": {
  "bg": "#ffffff",
  "bgAlt": "#f5f4f1",
  "bgInvert": "#0a0a0a",
  "ink": "#0a0a0a"
}
```

Omit it to keep the Tillett Film defaults.

---

## Option B — Through Claude Code (simplest)

If you're using Claude Code in this folder, just type:

```
/new-client
```

The very first time you run it, Claude will install everything it needs (Homebrew, the GitHub CLI, etc.) and log you in to GitHub. You'll be asked twice for input you can't avoid:

1. **Mac password** — when Homebrew installs itself. Type it into the terminal.
2. **GitHub login** — Claude will print an 8-character code and open `github.com/login/device` in your browser. Paste the code, click Authorize, come back.

Both of those happen once, ever. Every run after that, Claude jumps straight to the questions.

Then Claude asks you the per-client details (name, meeting day/date/time, repo name, where the videos are) one at a time, and does everything itself: copy the template, swap the names, copy your videos in, create the GitHub repo, push, and turn on Pages. **No config file. No commands to remember.**

> All brochure repos are created **public** because free GitHub Pages only serves public repos. The URL is `https://your-username.github.io/some-slug/` with no inbound links — only people you send the link to will find it.

---

## What does the script actually do?

1. Reads your config.
2. Makes a fresh copy of this template in a sibling folder (e.g. `~/Documents/sarah-johnson-opening-scene/`).
3. Find-and-replaces every "Lee Liasi", "Tuesday", "12 May 2026", etc. with your client's values.
4. Copies your client's video/image files into the `assets/` folder.
5. Creates a brand new GitHub repo under your account.
6. Pushes the site.
7. Turns on GitHub Pages, so the site is live at `https://YOUR-USERNAME.github.io/REPO-NAME/`.

The original template repo is **never touched** — every client gets their own clean repo.

---

## Troubleshooting

**"command not found: gh"** — you skipped step 2 above. Run `brew install gh jq rsync git`.

**"GitHub CLI is not authenticated"** — run `gh auth login` and follow the browser flow.

**"Target directory already exists"** — you tried to use the same `repoName` twice. Either delete the old folder (`rm -rf ../sarah-johnson-opening-scene`) or pick a different name.

**The site shows 404 after the script finishes** — GitHub Pages takes about a minute to build on first deploy. Refresh in 60 seconds. If still broken after 5 minutes, go to `https://github.com/YOUR-USERNAME/REPO-NAME/settings/pages` and check the Source is set to "Deploy from a branch → main → / (root)".

**Intro video doesn't play on the client's site** — make sure your `introVideo` path in the config actually exists and points at a video file. Common formats (.mp4, .mov, .m4v) all work. If the closing-scene reel is broken, you skipped the one-time studio setup above — drop a `showreel.mp4` into the template's `assets/` folder and commit it.

**The other videos (testimonial, work films) are stale** — those live in the template repo's `assets/`. Replace them there once and commit; every future brochure will use the new versions.
