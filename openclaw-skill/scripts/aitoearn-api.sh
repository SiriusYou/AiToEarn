#!/usr/bin/env bash
# aitoearn-api.sh — Helper for OpenClaw to call AiToEarn REST API
# Usage: ./aitoearn-api.sh <command> [args...]
#
# Environment variables:
#   AITOEARN_BASE_URL  — Gateway URL (default: http://localhost:8080)
#   AITOEARN_TOKEN     — JWT authentication token (required)

set -euo pipefail

BASE="${AITOEARN_BASE_URL:-http://localhost:8080}/api"
TOKEN="${AITOEARN_TOKEN:?Error: AITOEARN_TOKEN is not set. Run login first.}"

auth_headers() {
  echo -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json"
}

api_get() {
  curl -sf -X GET "$1" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" | jq .
}

api_post() {
  curl -sf -X POST "$1" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$2" | jq .
}

api_delete() {
  curl -sf -X DELETE "$1" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" | jq .
}

api_stream() {
  curl -sN -X POST "$1" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

# ── Commands ──────────────────────────────────────────────────────────────────

cmd_login_email() {
  local email="${1:?Usage: aitoearn-api.sh login-email <email>}"
  api_post "${BASE}/login/mail" "{\"mail\":\"${email}\"}"
}

cmd_verify_email() {
  local email="${1:?Usage: aitoearn-api.sh verify-email <email> <code>}"
  local code="${2:?Usage: aitoearn-api.sh verify-email <email> <code>}"
  curl -sf -X POST "${BASE}/login/mail/verify" \
    -H "Content-Type: application/json" \
    -d "{\"mail\":\"${email}\",\"code\":\"${code}\"}" | jq .
}

cmd_me() {
  api_get "${BASE}/user/mine"
}

cmd_accounts() {
  api_get "${BASE}/account/list/all"
}

cmd_account_stats() {
  api_get "${BASE}/account/statistics"
}

cmd_chat() {
  local prompt="${1:?Usage: aitoearn-api.sh chat <prompt> [model]}"
  local model="${2:-gpt-4o}"
  api_post "${BASE}/ai/chat" \
    "{\"messages\":[{\"role\":\"user\",\"content\":$(echo "$prompt" | jq -Rs .)}],\"model\":\"${model}\"}"
}

cmd_chat_stream() {
  local prompt="${1:?Usage: aitoearn-api.sh chat-stream <prompt> [model]}"
  local model="${2:-gpt-4o}"
  api_stream "${BASE}/ai/chat/stream" \
    "{\"messages\":[{\"role\":\"user\",\"content\":$(echo "$prompt" | jq -Rs .)}],\"model\":\"${model}\"}"
}

cmd_image() {
  local prompt="${1:?Usage: aitoearn-api.sh image <prompt> [model]}"
  local model="${2:-flux}"
  api_post "${BASE}/ai/image/generate" \
    "{\"prompt\":$(echo "$prompt" | jq -Rs .),\"model\":\"${model}\"}"
}

cmd_image_async() {
  local prompt="${1:?Usage: aitoearn-api.sh image-async <prompt> [model]}"
  local model="${2:-dall-e-3}"
  api_post "${BASE}/ai/image/generate/async" \
    "{\"prompt\":$(echo "$prompt" | jq -Rs .),\"model\":\"${model}\"}"
}

cmd_image_status() {
  local log_id="${1:?Usage: aitoearn-api.sh image-status <logId>}"
  api_get "${BASE}/ai/image/task/${log_id}"
}

cmd_video() {
  local prompt="${1:?Usage: aitoearn-api.sh video <prompt> [model]}"
  local model="${2:-sora}"
  api_post "${BASE}/ai/video/generations" \
    "{\"prompt\":$(echo "$prompt" | jq -Rs .),\"model\":\"${model}\"}"
}

cmd_video_status() {
  local task_id="${1:?Usage: aitoearn-api.sh video-status <taskId>}"
  api_get "${BASE}/ai/video/generations/${task_id}"
}

cmd_publish() {
  local data="${1:?Usage: aitoearn-api.sh publish <json-body>}"
  api_post "${BASE}/plat/publish/create" "$data"
}

cmd_publish_now() {
  local task_id="${1:?Usage: aitoearn-api.sh publish-now <taskId>}"
  api_post "${BASE}/plat/publish/nowPubTask/${task_id}" "{}"
}

cmd_publish_list() {
  local page="${1:-1}"
  local size="${2:-10}"
  api_post "${BASE}/plat/publish/getList" \
    "{\"pageNo\":${page},\"pageSize\":${size}}"
}

cmd_publish_queued() {
  local page="${1:-1}"
  local size="${2:-10}"
  api_post "${BASE}/plat/publish/statuses/queued/posts" \
    "{\"pageNo\":${page},\"pageSize\":${size}}"
}

cmd_publish_published() {
  local page="${1:-1}"
  local size="${2:-10}"
  api_post "${BASE}/plat/publish/statuses/published/posts" \
    "{\"pageNo\":${page},\"pageSize\":${size}}"
}

cmd_publish_delete() {
  local task_id="${1:?Usage: aitoearn-api.sh publish-delete <taskId>}"
  api_delete "${BASE}/plat/publish/delete/${task_id}"
}

cmd_publish_overview() {
  api_get "${BASE}/plat/publish/publishInfo/data"
}

cmd_adapt() {
  local data="${1:?Usage: aitoearn-api.sh adapt <json-body>}"
  api_post "${BASE}/ai/material-adaptation/" "$data"
}

cmd_adapt_get() {
  local material_id="${1:?Usage: aitoearn-api.sh adapt-get <materialId> [platform]}"
  local platform="${2:-}"
  if [ -n "$platform" ]; then
    api_get "${BASE}/ai/material-adaptation/${material_id}/${platform}"
  else
    api_get "${BASE}/ai/material-adaptation/${material_id}"
  fi
}

cmd_draft() {
  local data="${1:?Usage: aitoearn-api.sh draft <json-body>}"
  api_post "${BASE}/ai/draft-generation/" "$data"
}

cmd_draft_status() {
  local task_id="${1:?Usage: aitoearn-api.sh draft-status <taskId>}"
  api_get "${BASE}/ai/draft-generation/${task_id}"
}

cmd_analytics() {
  local account_id="${1:?Usage: aitoearn-api.sh analytics <accountId>}"
  api_get "${BASE}/channel/dataCube/accountDataCube/${account_id}"
}

cmd_comments() {
  local data="${1:?Usage: aitoearn-api.sh comments <json-body>}"
  api_post "${BASE}/channel/engagement/post/comments" "$data"
}

cmd_ai_comment() {
  local data="${1:?Usage: aitoearn-api.sh ai-comment <json-body>}"
  api_post "${BASE}/channel/engagement/comment/ai-generate" "$data"
}

cmd_models_chat() {
  api_get "${BASE}/ai/models/chat"
}

cmd_models_image() {
  api_get "${BASE}/ai/models/image/generation"
}

cmd_models_video() {
  api_get "${BASE}/ai/models/video/generation"
}

cmd_help() {
  cat <<'HELP'
AiToEarn API Helper — Commands:

  Auth:
    login-email <email>             Send login verification code
    verify-email <email> <code>     Verify code and get token
    me                              Get current user profile

  Accounts:
    accounts                        List all connected social accounts
    account-stats                   Get account statistics

  AI Generation:
    chat <prompt> [model]           AI chat (default: gpt-4o)
    chat-stream <prompt> [model]    AI chat with streaming
    image <prompt> [model]          Generate image (default: flux)
    image-async <prompt> [model]    Generate image async (default: dall-e-3)
    image-status <logId>            Check image task status
    video <prompt> [model]          Generate video (default: sora)
    video-status <taskId>           Check video task status

  Publishing:
    publish <json>                  Create publish task
    publish-now <taskId>            Publish immediately
    publish-list [page] [size]      List publish records
    publish-queued [page] [size]    List queued tasks
    publish-published [page] [size] List published posts
    publish-delete <taskId>         Delete queued task
    publish-overview                Publishing stats overview

  Content Adaptation:
    adapt <json>                    Adapt material to platforms
    adapt-get <materialId> [plat]   Get adaptation(s)

  Drafts:
    draft <json>                    Generate content drafts
    draft-status <taskId>           Check draft generation status

  Analytics & Engagement:
    analytics <accountId>           Get account analytics
    comments <json>                 Fetch post comments
    ai-comment <json>               Generate AI comment

  Models:
    models-chat                     List available chat models
    models-image                    List available image models
    models-video                    List available video models

  help                              Show this help
HELP
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

command="${1:-help}"
shift || true

case "$command" in
  login-email)      cmd_login_email "$@" ;;
  verify-email)     cmd_verify_email "$@" ;;
  me)               cmd_me ;;
  accounts)         cmd_accounts ;;
  account-stats)    cmd_account_stats ;;
  chat)             cmd_chat "$@" ;;
  chat-stream)      cmd_chat_stream "$@" ;;
  image)            cmd_image "$@" ;;
  image-async)      cmd_image_async "$@" ;;
  image-status)     cmd_image_status "$@" ;;
  video)            cmd_video "$@" ;;
  video-status)     cmd_video_status "$@" ;;
  publish)          cmd_publish "$@" ;;
  publish-now)      cmd_publish_now "$@" ;;
  publish-list)     cmd_publish_list "$@" ;;
  publish-queued)   cmd_publish_queued "$@" ;;
  publish-published) cmd_publish_published "$@" ;;
  publish-delete)   cmd_publish_delete "$@" ;;
  publish-overview) cmd_publish_overview ;;
  adapt)            cmd_adapt "$@" ;;
  adapt-get)        cmd_adapt_get "$@" ;;
  draft)            cmd_draft "$@" ;;
  draft-status)     cmd_draft_status "$@" ;;
  analytics)        cmd_analytics "$@" ;;
  comments)         cmd_comments "$@" ;;
  ai-comment)       cmd_ai_comment "$@" ;;
  models-chat)      cmd_models_chat ;;
  models-image)     cmd_models_image ;;
  models-video)     cmd_models_video ;;
  help|--help|-h)   cmd_help ;;
  *)
    echo "Unknown command: $command" >&2
    echo "Run '$0 help' for usage." >&2
    exit 1
    ;;
esac
