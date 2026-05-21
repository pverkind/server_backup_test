#!/usr/bin/env bash

set -euo pipefail

# ----------------------------
# Configuration
# ----------------------------

REPO="/c/Users/peter.verkinderen/Downloads/server_backup_test"
BRANCH="main"

# ----------------------------
# Exit silently if drive/repo unavailable
# ----------------------------

[ -d "$REPO" ] || exit 0

cd "$REPO" || exit 1

# ----------------------------
# Read GitHub token
# ----------------------------

if [ ! -f ".gh_token" ]; then
    echo "$(date '+%F %T') ERROR: .gh_token missing"
    exit 1
fi

TOKEN=$(< .gh_token)

AUTH=$(printf "x-access-token:%s" "$TOKEN" | base64 | tr -d '\n')

git \
    -c http.extraHeader="Authorization: Basic $AUTH" \
    pull origin "$BRANCH"

# ----------------------------
# Give a sign of life
# - if a user removes the ALIVE file on GitHub, the next run of Task Scheduler will re-create it and push it to GitHub
# ----------------------------

if [ ! -f "./ALIVE" ]; then
    date "+%Y-%m-%d %H:%M:%S" > ./ALIVE
    git add ./ALIVE
    git commit -m "still alive" 
    git \
        -c http.extraHeader="Authorization: Basic $AUTH" \
        push origin "$BRANCH"
fi

# ----------------------------
# Stage changed .log files only
# ----------------------------

while IFS= read -r -d '' file; do
    git add "$file"
done < <(find . -type f -path "./newserver/*.log" -o -path "./newserver/*.sh" -o -path "./*.sh" -print0)


# ----------------------------
# Commit/push only if needed
# ----------------------------

if git diff --cached --quiet; then
    exit 0
fi

COMMIT_MSG="Auto backup $(date '+%Y-%m-%d %H:%M:%S')"

git commit -m "$COMMIT_MSG" 

git \
    -c http.extraHeader="Authorization: Basic $AUTH" \
    push origin "$BRANCH"
