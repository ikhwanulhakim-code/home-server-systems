#!/usr/bin/env bash
set -euo pipefail

root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

build_page="$root/public/build/index.html"
systems_page="$root/public/systems/index.html"
systems_case_study="$root/public/systems/case-study/index.html"
systems_styles="$root/public/assets/css/systems.css"
systems_script="$root/public/assets/js/systems.js"
systems_image="$root/public/assets/images/home-server.jpg"
systems_icon="$root/public/assets/images/favicon.svg"
tokens="$root/public/assets/css/tokens.css"

test -f "$build_page"
test -f "$systems_page"
test -f "$systems_case_study"
test -f "$systems_styles"
test -f "$systems_script"
test -f "$systems_image"
test -f "$systems_icon"
test -f "$tokens"

grep -Fq 'I turn unclear problems into working software.' "$build_page"
grep -Fq 'Old laptop. New job.' "$systems_page"
grep -Fq 'Three problems. Three practical answers.' "$systems_page"
grep -Fq 'Want the engineering version?' "$systems_page"
grep -Fq 'href="./case-study/"' "$systems_page"
grep -Fq 'assets/css/systems.css' "$systems_page"
grep -Fq 'assets/js/systems.js' "$systems_page"
grep -Fq 'assets/images/home-server.jpg' "$systems_page"
grep -Fq 'assets/images/favicon.svg' "$systems_page"
grep -Fq 'assets/images/favicon.svg' "$systems_case_study"

for phrase in 'Home Server Lab' 'Hello Web' 'Build queue'; do
  grep -Fq "$phrase" "$build_page"
done

for phrase in 'Technical case study' 'Private administration path' 'Engineering decisions' 'Operational evidence'; do
  grep -Fq "$phrase" "$systems_case_study"
done

grep -Fq 'href="../"' "$systems_case_study"

for color in '#17120E' '#F2E8D6' '#FF5437' '#70CBEA' '#F5D84F' '#151413'; do
  grep -Fiq -- "$color" "$systems_styles"
done

for color in '#E8EFF2' '#101923' '#19324A' '#55C2C3' '#E05A47' '#7890A3'; do
  grep -Fiq -- "$color" "$tokens"
done

# The hero photograph ships at two widths, plus a social preview image.
for image in home-server.jpg home-server-800.jpg og-image.jpg; do
  test -f "$root/public/assets/images/$image" || {
    echo "Missing image: $image" >&2
    exit 1
  }
done
grep -Fq 'home-server.jpg' "$systems_page" || { echo 'Landing page does not use home-server.jpg' >&2; exit 1; }
grep -Fq 'srcset' "$systems_page" || { echo 'Landing page photo has no srcset' >&2; exit 1; }

# The site names no town or region.
if grep -riq 'south borneo' "$root" --exclude-dir=.git --exclude=smoke.sh; then
  echo 'Location detail found. The site names no town or region.' >&2
  exit 1
fi

# Search engines and link previews need these on both pages.
for page in "$systems_page" "$systems_case_study"; do
  for tag in 'rel="canonical"' 'property="og:title"' 'property="og:description"' \
             'property="og:image"' 'property="og:url"' 'name="twitter:card"' \
             'application/ld+json' 'https://systems.ikhwanulhakim.com'; do
    grep -Fq "$tag" "$page" || {
      echo "Missing $tag in $page" >&2
      exit 1
    }
  done
done

robots="$root/public/systems/robots.txt"
sitemap="$root/public/systems/sitemap.xml"
test -f "$robots"
test -f "$sitemap"
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
