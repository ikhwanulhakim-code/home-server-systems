#!/usr/bin/env bash
set -euo pipefail

root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

landing="$root/public/index.html"
case_study="$root/public/case-study/index.html"
styles="$root/public/assets/css/systems.css"
script="$root/public/assets/js/systems.js"
photo="$root/public/assets/images/home-server.jpg"
icon="$root/public/assets/images/favicon.svg"
robots="$root/public/robots.txt"
sitemap="$root/public/sitemap.xml"

for file in "$landing" "$case_study" "$styles" "$script" "$photo" "$icon" "$robots" "$sitemap"; do
  test -f "$file" || { echo "Missing file: $file" >&2; exit 1; }
done

# The document root holds the Systems view alone. The Build view is deferred.
if [ -e "$root/public/build" ]; then
  echo 'The deferred Build view is inside the served directory.' >&2
  exit 1
fi

grep -Fq 'Old laptop. New job.' "$landing"
grep -Fq 'Three problems. Three practical answers.' "$landing"
grep -Fq 'Want the engineering version?' "$landing"
grep -Fq 'href="./case-study/"' "$landing"
grep -Fq 'assets/css/systems.css' "$landing"
grep -Fq 'assets/js/systems.js' "$landing"
grep -Fq 'assets/images/favicon.svg' "$landing"

for phrase in 'Technical case study' 'Private administration path' 'Engineering decisions' 'Operational evidence'; do
  grep -Fq "$phrase" "$case_study"
done
grep -Fq 'href="../"' "$case_study"
grep -Fq 'assets/images/favicon.svg' "$case_study"

for color in '#17120E' '#F2E8D6' '#FF5437' '#70CBEA' '#F5D84F' '#151413'; do
  grep -Fiq -- "$color" "$styles"
done

# The hero photograph ships at two widths, plus a social preview image.
for image in home-server.jpg home-server-800.jpg og-image.jpg; do
  test -f "$root/public/assets/images/$image" || {
    echo "Missing image: $image" >&2
    exit 1
  }
done
grep -Fq 'home-server.jpg' "$landing" || { echo 'Landing page does not use home-server.jpg' >&2; exit 1; }
grep -Fq 'srcset' "$landing" || { echo 'Landing page photo has no srcset' >&2; exit 1; }

# Scroll reveals fade in. The hidden state is applied by the script rather than
# by a stylesheet, so a JavaScript failure leaves every section readable.
grep -Fq 'is-armed' "$script" || { echo 'The reveal script does not arm sections before observing them' >&2; exit 1; }
grep -Fq '.reveal.is-armed' "$styles" || { echo 'No armed reveal rule in the stylesheet' >&2; exit 1; }
grep -A4 '\.reveal\.is-armed' "$styles" | grep -q 'opacity' || { echo 'The armed reveal rule does not fade' >&2; exit 1; }

# The site names no town or region.
if grep -riq 'south borneo' "$root" --exclude-dir=.git --exclude=smoke.sh; then
  echo 'Location detail found. The site names no town or region.' >&2
  exit 1
fi

# Search engines and link previews need these on both pages.
for page in "$landing" "$case_study"; do
  for tag in 'rel="canonical"' 'property="og:title"' 'property="og:description"' \
             'property="og:image"' 'property="og:url"' 'name="twitter:card"' \
             'application/ld+json' 'https://systems.ikhwanulhakim.com'; do
    grep -Fq "$tag" "$page" || {
      echo "Missing $tag in $page" >&2
      exit 1
    }
  done
done

grep -Fq 'Sitemap: https://systems.ikhwanulhakim.com/sitemap.xml' "$robots"
grep -Fq 'https://systems.ikhwanulhakim.com/' "$sitemap"
grep -Fq 'https://systems.ikhwanulhakim.com/case-study/' "$sitemap"

# This repository is published. Every tracked file, not only the HTML, must stay
# free of private addresses, hardware identifiers, account names, and secrets.
private_pattern='192\.168\.[0-9]|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]|\b10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b'
private_pattern="$private_pattern"'|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]'
private_pattern="$private_pattern"'|([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}|serveradmin|ikhwanulhakim-code'
private_pattern="$private_pattern"'|BEGIN [A-Z ]*PRIVATE KEY'
private_pattern="$private_pattern"'|(PASSWORD|SECRET|API_KEY|ACCESS_KEY|AUTH_TOKEN)[[:space:]]*=[[:space:]]*[^[:space:]]'

# The GitHub account name matches the server hostname, so the repository's own
# clone URL is not a leak.
allowed='github\.com/ikhwanulhakim-code'

leaks="$(
  find "$root" \
    -path "$root/.git" -prune -o \
    -path "$root/tests/smoke.sh" -prune -o \
    -type f -print |
  xargs grep -nIE "$private_pattern" 2>/dev/null |
  grep -vE "$allowed" || true
)"
if [ -n "$leaks" ]; then
  echo 'Sensitive infrastructure detail found in published files:' >&2
  echo "$leaks" >&2
  exit 1
fi

echo 'Local portfolio source checks passed.'
