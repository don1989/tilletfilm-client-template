#!/usr/bin/env bash
#
# new-client.sh — spin up a personalized brochure repo for one client.
#
# Usage:
#   ./scripts/new-client.sh path/to/client.config.json
#
# What it does:
#   1. Reads the JSON config
#   2. Copies the template (index.html + assets/) into ../<repoName>
#   3. Swaps every per-client string (name, meeting day/date/time, etc.)
#      and any studio/color overrides
#   4. Copies the client's video/image files from assetsDir into assets/
#      (filenames must match the template — see README.md)
#   5. Creates a new public/private GitHub repo via gh
#   6. Pushes the site to main
#   7. Enables GitHub Pages (main branch, root)
#   8. Prints the live URL
#
# Requirements:
#   - gh (GitHub CLI) installed and authenticated:  gh auth login
#   - jq installed
#   - rsync installed

set -euo pipefail

# ---------- args ----------
if [ $# -lt 1 ]; then
  echo "Usage: $0 path/to/client.config.json" >&2
  exit 1
fi

CONFIG_PATH="$1"
if [ ! -f "$CONFIG_PATH" ]; then
  echo "Config file not found: $CONFIG_PATH" >&2
  exit 1
fi

# ---------- prerequisite checks ----------
for cmd in gh jq rsync git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    echo "Install instructions in SETUP.md" >&2
    exit 1
  fi
done

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run: gh auth login" >&2
  exit 1
fi

# ---------- repo paths ----------
TEMPLATE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# ---------- read config ----------
read_cfg() { jq -r "$1" "$CONFIG_PATH"; }

CLIENT_FIRST=$(read_cfg '.client.firstName')
CLIENT_LAST=$(read_cfg '.client.lastName')
CLIENT_FULL="${CLIENT_FIRST} ${CLIENT_LAST}"
MEETING_DAY=$(read_cfg '.client.meetingDay')
MEETING_DATE=$(read_cfg '.client.meetingDate')
MEETING_TIME=$(read_cfg '.client.meetingTime')

STUDIO_NAME=$(read_cfg '.studio.name')
DIRECTOR_FIRST=$(read_cfg '.studio.directorFirstName')
DIRECTOR_FULL=$(read_cfg '.studio.directorFullName')
STUDIO_DOMAIN=$(read_cfg '.studio.domain')
STUDIO_EMAIL=$(read_cfg '.studio.email')

COLOR_BG=$(read_cfg '.colors.bg // "#ffffff"')
COLOR_BG_ALT=$(read_cfg '.colors.bgAlt // "#f5f4f1"')
COLOR_BG_INVERT=$(read_cfg '.colors.bgInvert // "#0a0a0a"')
COLOR_INK=$(read_cfg '.colors.ink // "#0a0a0a"')

GH_OWNER=$(read_cfg '.github.owner')
REPO_NAME=$(read_cfg '.github.repoName')
# Always public — GitHub Pages on free accounts requires a public repo.

INTRO_VIDEO=$(read_cfg '.introVideo // ""')

# ---------- validate ----------
for v in CLIENT_FIRST CLIENT_LAST MEETING_DAY MEETING_DATE MEETING_TIME \
         STUDIO_NAME DIRECTOR_FIRST DIRECTOR_FULL STUDIO_DOMAIN STUDIO_EMAIL \
         GH_OWNER REPO_NAME; do
  if [ -z "${!v}" ] || [ "${!v}" = "null" ]; then
    echo "Missing required config field: $v" >&2
    exit 1
  fi
done

# ---------- target dir ----------
TARGET_DIR="$( cd "$TEMPLATE_DIR/.." && pwd )/$REPO_NAME"
if [ -e "$TARGET_DIR" ]; then
  echo "Target directory already exists: $TARGET_DIR" >&2
  echo "Delete it or choose a different repoName." >&2
  exit 1
fi

echo "==> Creating $TARGET_DIR"
mkdir -p "$TARGET_DIR"

# ---------- copy template (excluding git + scripts + .claude + configs) ----------
rsync -a \
  --exclude='.git/' \
  --exclude='scripts/' \
  --exclude='.claude/' \
  --exclude='client.config*.json' \
  --exclude='client-assets/' \
  --exclude='SETUP.md' \
  "$TEMPLATE_DIR/" "$TARGET_DIR/"

# ---------- copy per-client intro video (if provided) ----------
# Studio-wide assets (testimonial, work films, showreel) were already
# included in the rsync above. The only per-client asset is intro.<ext>.
INTRO_EXT=""
if [ -n "$INTRO_VIDEO" ]; then
  if [ ! -f "$INTRO_VIDEO" ]; then
    echo "WARNING: introVideo path '$INTRO_VIDEO' not found; scene 02 will keep its placeholder." >&2
    INTRO_VIDEO=""
  else
    # Lowercase extension
    INTRO_EXT="${INTRO_VIDEO##*.}"
    INTRO_EXT="$(printf '%s' "$INTRO_EXT" | tr '[:upper:]' '[:lower:]')"
    echo "==> Copying intro video to assets/intro.${INTRO_EXT}"
    cp "$INTRO_VIDEO" "$TARGET_DIR/assets/intro.${INTRO_EXT}"
  fi
fi

# ---------- showreel check ----------
if [ ! -f "$TARGET_DIR/assets/showreel.mp4" ]; then
  echo ""
  echo "WARNING: assets/showreel.mp4 is not in the template — the closing scene"
  echo "         of every brochure (including this one) will show a black box."
  echo "         To fix once for all future clients, drop a showreel.mp4 into"
  echo "         the template repo's assets/ folder and commit it."
  echo ""
fi

# ---------- text replacements in index.html ----------
# Order matters: longest/most-specific patterns FIRST so they don't get
# eaten by shorter replacements.
INDEX="$TARGET_DIR/index.html"

# Cross-platform sed in-place (BSD on macOS, GNU on Linux)
sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    sed -i -e "$1" "$INDEX"
  else
    sed -i '' -e "$1" "$INDEX"
  fi
}

# Escape replacement value for sed (escapes & / \)
esc() { printf '%s' "$1" | sed -e 's/[&/\\]/\\&/g'; }

echo "==> Replacing per-client strings"

# 1. Client full name first (so "Lee" doesn't break "Lee Liasi")
sed_inplace "s/Lee Liasi/$(esc "$CLIENT_FULL")/g"
sed_inplace "s/Liasi/$(esc "$CLIENT_LAST")/g"

# 2. Director full name before studio name (so "Charlie Tillett" stays atomic)
sed_inplace "s/Charlie Tillett/$(esc "$DIRECTOR_FULL")/g"

# 3. Email before domain (email contains the domain)
sed_inplace "s/charlie@tillettfilm\.com/$(esc "$STUDIO_EMAIL")/g"

# 4. Studio domain
sed_inplace "s/tillettfilm\.com/$(esc "$STUDIO_DOMAIN")/g"

# 5. Studio name
sed_inplace "s/Tillett Film/$(esc "$STUDIO_NAME")/g"

# 6. Standalone director first name
sed_inplace "s/Charlie/$(esc "$DIRECTOR_FIRST")/g"

# 7. Client first name (after full name already replaced)
sed_inplace "s/Lee/$(esc "$CLIENT_FIRST")/g"

# 8. Meeting date/time (specific strings)
sed_inplace "s/12 May 2026/$(esc "$MEETING_DATE")/g"
sed_inplace "s/10:00 AM GMT/$(esc "$MEETING_TIME")/g"

# 9. Meeting day (do last — "Tuesday" appears many places)
sed_inplace "s/Tuesday/$(esc "$MEETING_DAY")/g"

# 10. CSS color tokens (only the :root defaults)
sed_inplace "s/--bg: #ffffff;/--bg: $(esc "$COLOR_BG");/"
sed_inplace "s/--bg-alt: #f5f4f1;/--bg-alt: $(esc "$COLOR_BG_ALT");/"
sed_inplace "s/--bg-invert: #0a0a0a;/--bg-invert: $(esc "$COLOR_BG_INVERT");/"
sed_inplace "s/--ink: #0a0a0a;/--ink: $(esc "$COLOR_INK");/"

echo "==> Text replacements complete"

# ---------- swap scene-02 placeholder for a real <video> tag ----------
# Only if the user supplied an intro video. Uses perl in slurp mode so
# the multi-line block can be matched without any extra dependencies
# (perl ships on macOS and most Linux distros).
if [ -n "$INTRO_VIDEO" ] && [ -n "$INTRO_EXT" ]; then
  echo "==> Wiring up scene 02 intro video"
  INDEX_PATH="$INDEX" INTRO_EXT="$INTRO_EXT" perl -i -0777 -pe '
    my $ext = $ENV{INTRO_EXT};
    my $replacement =
      qq{<video src="assets/intro.$ext" controls playsinline preload="metadata" } .
      qq{id="introVideo" style="width:100%; aspect-ratio:16/9; background:#000; } .
      qq{border-radius:12px; display:block;">Your browser does not support embedded video.</video>};
    s~<div class="video-placeholder" id="introVideo">\s*<div class="play-button"></div>\s*<div class="video-caption">[^<]*</div>\s*</div>~$replacement~;
    # Remove the dead click-handler alert too (use ~ as delimiter to avoid {} clash).
    s~\s*// Video placeholder click\s*\n\s*document\.getElementById\(.introVideo.\)\?\.addEventListener\(.click., \(\) => \{[^}]*\}\);~~;
  ' "$INDEX"
fi

# ---------- init git + create GH repo ----------
cd "$TARGET_DIR"
git init -b main >/dev/null
git add .
git -c user.email="${DIRECTOR_FULL// /.}@${STUDIO_DOMAIN}" \
    -c user.name="$DIRECTOR_FULL" \
    commit -m "Initial brochure for ${CLIENT_FULL}" >/dev/null

echo "==> Creating GitHub repo $GH_OWNER/$REPO_NAME (public — required for free GitHub Pages)"
gh repo create "$GH_OWNER/$REPO_NAME" --public \
  --source=. --remote=origin --push \
  --description "Opening Scene brochure for ${CLIENT_FULL}"

# ---------- enable GitHub Pages ----------
echo "==> Enabling GitHub Pages (main / root)"
# Try to create the pages site; if it already exists, update the source.
if ! gh api -X POST "repos/$GH_OWNER/$REPO_NAME/pages" \
      -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1; then
  gh api -X PUT "repos/$GH_OWNER/$REPO_NAME/pages" \
      -f "source[branch]=main" -f "source[path]=/" >/dev/null
fi

PAGES_URL="https://${GH_OWNER}.github.io/${REPO_NAME}/"

echo ""
echo "Done."
echo "  Local copy: $TARGET_DIR"
echo "  Repo:       https://github.com/$GH_OWNER/$REPO_NAME"
echo "  Live site:  $PAGES_URL  (allow ~1 minute for first build)"
