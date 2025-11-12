#!/usr/bin/env bash
# set-github-branch-protection.sh
# Creates/updates branch protection for a GitHub repo using the REST API.
# Usage:
#   GITHUB_TOKEN=ghp_xxx REPO_OWNER=owner REPO_NAME=repo BRANCH=main ./set-github-branch-protection.sh
# Environment variables:
#   GITHUB_TOKEN (required) - a token with "repo" scope (or appropriate org repo scope)
#   REPO_OWNER (required)
#   REPO_NAME (required)
#   BRANCH (optional, default: main)
#   REQUIRED_STATUS_CONTEXTS (optional, comma-separated CI contexts e.g. "ci/test,ci/lint")
#   REQUIRED_APPROVALS (optional, default: 1)
#   ENFORCE_ADMINS (optional, default: true)
#   RESTRICT_PUSH_USERS (optional, comma-separated usernames)
#   RESTRICT_PUSH_TEAMS (optional, comma-separated team slugs)

set -euo pipefail

: "${GITHUB_TOKEN:?GITHUB_TOKEN is required (set environment variable)}"
: "${REPO_OWNER:?REPO_OWNER is required}"
: "${REPO_NAME:?REPO_NAME is required}"
BRANCH=${BRANCH:-main}
REQUIRED_STATUS_CONTEXTS=${REQUIRED_STATUS_CONTEXTS:-}
REQUIRED_APPROVALS=${REQUIRED_APPROVALS:-1}
ENFORCE_ADMINS=${ENFORCE_ADMINS:-true}
RESTRICT_PUSH_USERS=${RESTRICT_PUSH_USERS:-}
RESTRICT_PUSH_TEAMS=${RESTRICT_PUSH_TEAMS:-}

API="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/branches/${BRANCH}/protection"

# Build JSON body safely (avoid complex nested quoting)
# required_status_checks: either null or object with contexts
if [ -n "${REQUIRED_STATUS_CONTEXTS}" ]; then
  IFS=',' read -r -a ctx <<< "${REQUIRED_STATUS_CONTEXTS}"
  contexts_items=""
  for c in "${ctx[@]}"; do
    # escape any double quotes in the context string
    c_escaped=$(printf '%s' "$c" | sed 's/"/\\"/g')
    if [ -z "$contexts_items" ]; then
      contexts_items="\"${c_escaped}\""
    else
      contexts_items="$contexts_items,\"${c_escaped}\""
    fi
  done
  contexts_json="[${contexts_items}]"
  required_status_checks_json="{ \"strict\": true, \"contexts\": ${contexts_json} }"
else
  required_status_checks_json="null"
fi

# restrictions: null or object
if [ -n "${RESTRICT_PUSH_USERS}" ] || [ -n "${RESTRICT_PUSH_TEAMS}" ]; then
  users_items=""
  teams_items=""

  if [ -n "${RESTRICT_PUSH_USERS}" ]; then
    IFS=',' read -r -a us <<< "${RESTRICT_PUSH_USERS}"
    for u in "${us[@]}"; do
      u_escaped=$(printf '%s' "$u" | sed 's/"/\\"/g')
      if [ -z "$users_items" ]; then
        users_items="\"${u_escaped}\""
      else
        users_items="$users_items,\"${u_escaped}\""
      fi
    done
    users_json="[${users_items}]"
  else
    users_json="[]"
  fi

  if [ -n "${RESTRICT_PUSH_TEAMS}" ]; then
    IFS=',' read -r -a ts <<< "${RESTRICT_PUSH_TEAMS}"
    for t in "${ts[@]}"; do
      t_escaped=$(printf '%s' "$t" | sed 's/"/\\"/g')
      if [ -z "$teams_items" ]; then
        teams_items="\"${t_escaped}\""
      else
        teams_items="$teams_items,\"${t_escaped}\""
      fi
    done
    teams_json="[${teams_items}]"
  else
    teams_json="[]"
  fi

  restrictions_json="{ \"users\": ${users_json}, \"teams\": ${teams_json} }"
else
  restrictions_json="null"
fi

# Build request body
read -r -d '' BODY <<EOF || true
{
  "required_status_checks": ${required_status_checks_json},
  "enforce_admins": ${ENFORCE_ADMINS},
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": ${REQUIRED_APPROVALS}
  },
  "restrictions": ${restrictions_json}
}
EOF

# Make the request and capture body + HTTP code
resp_body_file=$(mktemp)
http_code=$(curl -sS -o "$resp_body_file" -w "%{http_code}" -X PUT \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "Content-Type: application/json" \
  --data "$BODY" \
  "$API")

if (( http_code >= 200 && http_code < 300 )); then
  echo "Branch protection set for ${REPO_OWNER}/${REPO_NAME}:${BRANCH}"
  rm -f "$resp_body_file"
  exit 0
else
  echo "Failed to set branch protection (HTTP ${http_code})" >&2
  if [ -s "$resp_body_file" ]; then
    echo "Response body:" >&2
    sed -n '1,200p' "$resp_body_file" >&2
  fi
  rm -f "$resp_body_file"
  exit 2
fi
