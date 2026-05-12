# Setup — make a new client site in 2 minutes

This is the operator's guide. You'll never need to open Terminal — everything runs inside Claude Code, which you already have.

---

## One-time install (~5 minutes, once ever)

Open Claude Code. Paste this single prompt and let it run:

````
Install the Tillett Film client-site maker for me. You should:

1. If `brew` (Homebrew) isn't installed on this Mac, install it from https://brew.sh/. This step needs my Mac password — you'll be prompted in the terminal pane, and I'll type it in.

2. Use brew to install `gh` and `git` if they're not already present.

3. Run `gh auth login --web --git-protocol https` so I'm logged in to GitHub. Show me the 8-character device code and the URL — I'll paste the code into the browser and authorize.

4. Create the directory `~/.claude/skills/new-client/` (mkdir -p).

5. Download the skill file from
   https://raw.githubusercontent.com/don1989/tilletfilm-client-template/main/.claude/skills/new-client/SKILL.md
   and save it as `~/.claude/skills/new-client/SKILL.md`. (Use `curl -fsSL <url> -o <path>`.)

6. Pre-approve the Bash commands the skill will need so I don't have to click Allow on every run. In `~/.claude/settings.json`, merge in this `permissions.allow` block (preserve any existing rules):

   ```json
   {
     "permissions": {
       "allow": [
         "Bash(gh:*)",
         "Bash(git:*)",
         "Bash(brew install:*)",
         "Bash(perl -i:*)",
         "Bash(cp:*)",
         "Bash(mkdir:*)",
         "Bash(rsync:*)",
         "Bash(test:*)",
         "Bash([:*)",
         "Bash(curl -fsSL:*)"
       ]
     }
   }
   ```

7. Verify everything by running `gh auth status` and listing `~/.claude/skills/new-client/`. Tell me when `/new-client` is ready to use.
````

You'll be asked twice during this run, both one-time:
- **Your Mac password** when Homebrew installs itself
- **An 8-character GitHub code** that you paste into the browser tab Claude opens

After this completes, restart Claude Code (quit and re-open) so it picks up the new skill.

---

## Every new client (~2 minutes)

Open Claude Code from anywhere — your home folder is fine, you don't need to be in any particular project.

Type:

```
/new-client
```

Claude asks you, one at a time:

1. **Prospect's full name** — e.g. *Sarah Johnson*
2. **Meeting day, date, time** — e.g. *Friday, 16 May 2026, 2:30 PM EST*
3. **Repo name** — Claude suggests `sarah-johnson-opening-scene`; accept or change.
4. **Intro video path** — wherever the 90-second personal video is on your Mac. Any filename, any common format (`.mp4`, `.mov`, `.m4v`). For example `~/Desktop/sarah-intro.mov` straight off your phone via AirDrop. Or say *skip* to leave the placeholder.
5. **Anything custom?** — by default Claude uses the studio's standard name, email, director, and brand colours. Only answer if you want to override.

Then Claude:
- Generates a fresh repo under your GitHub account via the template-generate API
- Clones it locally to `~/Documents/client-sites/<repo-name>/` for editing
- Swaps every name and date in `index.html`
- Copies your intro video in and wires up scene 02
- Commits + pushes
- Turns on GitHub Pages
- Prints the live URL

Send the URL to your prospect. Allow ~1 minute on first deploy.

> All client-site repos are created **public** — free GitHub Pages only serves public repos. The URL has no inbound links, so it's only discoverable by people you send it to.

---

## How assets work

Two layers:

- **Studio-wide** (testimonial, work films, showreel) — live in the template repo and every new client site inherits them automatically.
- **Per-client** — just the intro video. The only file Claude asks you for.

If you ever need to update the studio testimonial, a work film, or the showreel, ask Claude in any session:

> "Update the studio showreel in the template — use this file: `~/Desktop/new-showreel.mp4`"

Claude will commit the change to the template repo. Every future client site inherits it.

---

## Troubleshooting

**`/new-client` doesn't appear** — quit Claude Code and re-open. Skills are picked up on launch. If still missing, paste the installer prompt above again.

**The site shows 404 after Claude finishes** — Pages takes about a minute to build on first deploy. Refresh in 60 seconds. If still broken after 5 minutes, ask Claude: *"Check the Pages status on this repo."*

**Intro video doesn't play on the client's site** — most likely the file path you gave Claude was wrong, or the file is in an obscure format. Ask Claude to re-run with a different file.

**Closing-scene reel is a black box** — the template is missing `assets/showreel.mp4`. Ask Claude: *"Add this file as the studio showreel: `~/Desktop/showreel.mp4`"* — it'll commit to the template and every future client site will have it.

**404 from the generate API** — the template repo isn't marked as a template on GitHub. Toggle it at <https://github.com/don1989/tilletfilm-client-template/settings> → check "Template repository".
