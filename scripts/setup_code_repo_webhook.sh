# ---------------------------------------------
# Helper script to configure a GitHub webhook
# ---------------------------------------------
# Arguments:
#   1 - Personal access token with repo permissions
#   2 - GitHub repository owner
#   3 - Repository name
#   4 - Jenkins webhook URL (usually https://jenkins.example.com/github-webhook/)

# Exit immediately on errors and treat unset vars as errors
set -euo pipefail
# Read the supplied arguments for clarity
TOKEN="$1"    # authentication token
OWNER="$2"    # organization or user that owns the repo
REPO="$3"     # repository to configure
HOOK_URL="$4" # full URL Jenkins listens on

curl -H "Authorization: token ${TOKEN}" \ 
     -H "Content-Type: application/json" \ 
     -X POST "https://api.github.com/repos/${OWNER}/${REPO}/hooks" \ 
     -d '{"name":"web","active":true,"events":["push"],"config":{"url":"${HOOK_URL}","content_type":"json"}}'
