#!/usr/bin/env bash
set -euo pipefail

# Checks the running portfolio-viewer container on the loopback address.
# The container serves the Systems view only. The Build view is deferred.

base="${BASE_URL:-http://127.0.0.1:8084}"
host="${SYSTEMS_HOST:-systems.home.internal}"
port="${PORT:-8084}"

fail() {
  echo "Container check failed: $1" >&2
  exit 1
}

fetch_status() {
  curl -s -o /dev/null -w '%{http_code}' --max-time 5 -H "Host: $2" "$base$1"
}

fetch_body() {
  curl -s --max-time 5 -H "Host: $2" "$base$1"
}

# The Systems hostname serves the landing page at the container root.
[ "$(fetch_status / "$host")" = '200' ] || fail "$host / did not return 200"
grep -Fq 'Old laptop. New job.' <<<"$(fetch_body / "$host")" ||
  fail "$host / did not return the Systems landing page"

# The technical case study is reachable as a directory route.
[ "$(fetch_status /case-study/ "$host")" = '200' ] || fail "$host /case-study/ did not return 200"
grep -Fq 'Technical case study' <<<"$(fetch_body /case-study/ "$host")" ||
  fail "$host /case-study/ did not return the case study"

# Shared assets live outside the document root and need their own location.
for asset in /assets/css/systems.css /assets/js/systems.js /assets/images/inbook-server.jpg; do
  [ "$(fetch_status "$asset" "$host")" = '200' ] || fail "$asset did not return 200"
done

# The deferred Build view must not be reachable through this container.
[ "$(fetch_status /build/ "$host")" = '404' ] || fail '/build/ is reachable'

# An unknown hostname gets no content.
[ "$(fetch_status / unknown.invalid)" = '404' ] || fail 'unknown hostname returned content'

# The health endpoint backs the Compose health check.
[ "$(fetch_status /healthz unknown.invalid)" = '200' ] || fail '/healthz did not return 200'

# The published port stays on the loopback address.
listeners=''
if command -v ss >/dev/null 2>&1; then
  listeners="$(ss -ltnH "sport = :$port" | awk '{print $4}')"
elif command -v lsof >/dev/null 2>&1; then
  listeners="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN | awk 'NR>1 {print $9}')"
fi
if [ -n "$listeners" ]; then
  grep -Ev '^(127\.0\.0\.1|\[::1\]|localhost)[.:]' <<<"$listeners" |
    grep -q . && fail "port $port listens outside the loopback address"
fi

echo 'Local container checks passed.'
