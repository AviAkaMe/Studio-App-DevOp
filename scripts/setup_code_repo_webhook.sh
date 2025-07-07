#!/bin/bash
# Script to create a GitHub webhook on the application repository
# Usage: ./setup_code_repo_webhook.sh <github-token> <owner> <repo> <jenkins-hook-url>
set -euo pipefail
TOKEN="$1"
OWNER="$2"
REPO="$3"
HOOK_URL="$4"

curl -H "Authorization: token ${TOKEN}" \
     -H "Content-Type: application/json" \
     -X POST "https://api.github.com/repos/${OWNER}/${REPO}/hooks" \
     -d '{"name":"web","active":true,"events":["push"],"config":{"url":"'${HOOK_URL}'","content_type":"json"}}'