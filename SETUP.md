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

### Every new client

**1. Make a folder for the client's videos** (anywhere on your Mac):

```
~/Documents/clients/sarah-johnson/
├── testimonial.mp4
├── testimonial-thumbnail.jpg
├── work-brand-film.mp4
├── work-brand-film.jpg
├── work-event-film.mp4
├── work-event-film.jpg
├── work-founder-film.mp4
├── work-founder-film.jpg
├── intro.mp4          (the 90-second personal note)
└── showreel.mp4       (the closing reel)
```

**The filenames must match exactly** — that's how the brochure finds them.

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
    "repoName": "sarah-johnson-opening-scene",
    "private": false
  },
  "assetsDir": "/Users/YOUR-USERNAME/Documents/clients/sarah-johnson"
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

## Option B — Through Claude Code

If you're using Claude Code, just type `/new-client` and answer the questions Claude asks you. It builds the config and runs the script for you. (You still need the one-time setup from Option A.)

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

**Videos don't play on the client's site** — the filenames in your assets folder must match exactly. See the list under "Make a folder for the client's videos" above.
