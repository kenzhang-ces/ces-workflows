#!/bin/bash -eux

REPO_NAME=$1
SLACK_WEBHOOK_URL=$2

CUR_RELEASE_BRANCH=$(git branch -r| grep -Eo "origin/release_.*" | sort | tail -1)
PRE_RELEASE_BRANCH=$([ "$(git branch -r| grep -Eo "release_.*" | sort | tail -2 | wc -l)" -eq '2' ] &&
  git branch -r| grep -Eo "origin/release_.*" | sort | tail -2 | head -1 ||
  git rev-list --max-parents=0 HEAD)
VERSION=$(git describe --tags "$CUR_RELEASE_BRANCH")

COMMITS=$(git log --left-right --pretty=format:'%s (%ar) <%an>' --abbrev-commit --date=relative $PRE_RELEASE_BRANCH...$CUR_RELEASE_BRANCH)
COMMITS=${COMMITS//$'\n'/\\n\\n}
PAYLOAD="{
  \"blocks\": [
    {
      \"type\": \"header\",
      \"text\": {
        \"type\": \"plain_text\",
        \"text\": \"$REPO_NAME\",
        \"emoji\": true
      }
    },
    {
      \"type\": \"section\",
      \"text\": {
        \"type\": \"mrkdwn\",
        \"text\": \"<https://github.com/$REPO_NAME|$REPO_NAME>\"
      }
    },
    {
      \"type\": \"section\",
      \"fields\": [
        {
          \"type\": \"mrkdwn\",
          \"text\": \"*release branch:* <https://github.com/$REPO_NAME/tree/${CUR_RELEASE_BRANCH//origin\//}|$CUR_RELEASE_BRANCH>\"
        },
        {
          \"type\": \"mrkdwn\",
          \"text\": \"*deploy:* <https://github.com/$REPO_NAME/actions/workflows/deploy.yml|deploy>\"
        },
        {
          \"type\": \"mrkdwn\",
          \"text\": \"*currnet release version:* <https://github.com/$REPO_NAME/releases/tag/$VERSION|$VERSION>\"
        }
      ]
    },
    {
      \"type\": \"divider\"
    },
    {
      \"type\": \"section\",
      \"text\": {
          \"type\": \"mrkdwn\",
          \"text\": \"*Commits:*\n$COMMITS\"
        }
    }
  ]
 }"

curl -X POST -H 'Content-type: application/json' --data "$PAYLOAD" "$SLACK_WEBHOOK_URL"
