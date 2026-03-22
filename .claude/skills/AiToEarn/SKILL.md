---
name: aitoearn
description: >
  AiToEarn content marketing platform: AI chat, image/video generation,
  multi-platform publishing (TikTok, YouTube, Instagram, Twitter, Douyin,
  Xiaohongshu, Bilibili, etc.), analytics, and engagement — all via REST API.
  Use when the user wants to create content, publish posts, check publishing
  status, generate media, or view social-media analytics.
metadata:
  openclaw:
    emoji: "\U0001F680"
    requires:
      bins: [curl, jq]
---

## When to use

- User asks to **create or generate** social media content (text, image, video)
- User asks to **publish** content to one or more platforms
- User asks to **check status** of a publish task or AI generation task
- User asks to view **analytics** or **engagement** data for their accounts
- User asks to **adapt** content for different platforms
- User asks to **manage accounts** (list, add, remove social accounts)

## When NOT to use

- General web browsing or non-AiToEarn queries
- Direct platform interactions that bypass AiToEarn (use platform skills instead)
- File system operations unrelated to AiToEarn content

## Setup

AiToEarn must be running (locally via Docker or on a remote server).
Set these environment variables before using:

```bash
# Required
export AITOEARN_BASE_URL="http://localhost:8080"   # Nginx gateway
export AITOEARN_TOKEN=""                            # JWT auth token

# Optional — override individual service URLs
# export AITOEARN_API_URL="http://localhost:3002"   # Backend API
# export AITOEARN_AI_URL="http://localhost:3010"     # AI service
```

### Getting a token

```bash
# 1. Request email verification code
curl -s -X POST "${AITOEARN_BASE_URL}/api/login/mail" \
  -H "Content-Type: application/json" \
  -d '{"mail":"you@example.com"}' | jq .

# 2. Verify code and get JWT
curl -s -X POST "${AITOEARN_BASE_URL}/api/login/mail/verify" \
  -H "Content-Type: application/json" \
  -d '{"mail":"you@example.com","code":"123456"}' | jq -r '.data.token'
```

Store the returned token in `AITOEARN_TOKEN`.

---

## Common headers

Every authenticated request needs:

```
Authorization: Bearer $AITOEARN_TOKEN
Content-Type: application/json
```

Shorthand used below:

```bash
AUTH='-H "Authorization: Bearer ${AITOEARN_TOKEN}" -H "Content-Type: application/json"'
BASE="${AITOEARN_BASE_URL}/api"
```

---

## AI Chat (content generation)

Generate marketing copy, captions, hashtags, or any text content.

```bash
# Streaming chat (SSE) — preferred for long responses
curl -s -N -X POST "${BASE}/ai/chat/stream" \
  $AUTH \
  -d '{
    "messages": [{"role":"user","content":"Write a TikTok caption about summer travel with hashtags"}],
    "model": "gpt-4o"
  }'

# Non-streaming chat
curl -s -X POST "${BASE}/ai/chat" \
  $AUTH \
  -d '{
    "messages": [{"role":"user","content":"Write 3 Instagram captions for a coffee brand"}],
    "model": "gpt-4o"
  }' | jq .
```

## AI Image Generation

```bash
# Generate image (sync)
curl -s -X POST "${BASE}/ai/image/generate" \
  $AUTH \
  -d '{
    "prompt": "A vibrant flat-lay of summer accessories on a beach towel",
    "model": "flux"
  }' | jq .

# Generate image (async — for large/slow models)
curl -s -X POST "${BASE}/ai/image/generate/async" \
  $AUTH \
  -d '{
    "prompt": "Professional product photo of a leather bag",
    "model": "dall-e-3"
  }' | jq .

# Check async task status
curl -s -X GET "${BASE}/ai/image/task/{logId}" $AUTH | jq .
```

## AI Video Generation

```bash
# Generate video
curl -s -X POST "${BASE}/ai/video/generations" \
  $AUTH \
  -d '{
    "prompt": "A sunset timelapse over the ocean with calming music",
    "model": "sora"
  }' | jq .

# Check video task status
curl -s -X GET "${BASE}/ai/video/generations/{taskId}" $AUTH | jq .

# List video tasks
curl -s -X GET "${BASE}/ai/video/generations?pageNo=1&pageSize=10" $AUTH | jq .
```

## Publishing Content

### Create a publish task

```bash
curl -s -X POST "${BASE}/plat/publish/create" \
  $AUTH \
  -d '{
    "accountIds": ["acc_id_1", "acc_id_2"],
    "content": {
      "title": "Summer Travel Guide 2026",
      "desc": "Top 10 destinations you must visit this summer!",
      "mediaUrls": ["https://your-storage.com/video.mp4"]
    },
    "publishTime": "2026-03-25T10:00:00Z"
  }' | jq .
```

### Publish immediately

```bash
curl -s -X POST "${BASE}/plat/publish/nowPubTask/{taskId}" $AUTH | jq .
```

### Check publish status

```bash
# List publish records
curl -s -X POST "${BASE}/plat/publish/getList" \
  $AUTH \
  -d '{"pageNo":1,"pageSize":10}' | jq .

# Get records for a specific flow
curl -s -X GET "${BASE}/plat/publish/records/{flowId}" $AUTH | jq .

# Get queued tasks
curl -s -X POST "${BASE}/plat/publish/statuses/queued/posts" \
  $AUTH \
  -d '{"pageNo":1,"pageSize":10}' | jq .

# Get published posts
curl -s -X POST "${BASE}/plat/publish/statuses/published/posts" \
  $AUTH \
  -d '{"pageNo":1,"pageSize":10}' | jq .
```

### Delete a queued task

```bash
curl -s -X DELETE "${BASE}/plat/publish/delete/{taskId}" $AUTH | jq .
```

## Account Management

```bash
# List all connected social accounts
curl -s -X GET "${BASE}/account/list/all" $AUTH | jq .

# Get account details
curl -s -X GET "${BASE}/account/{accountId}" $AUTH | jq .

# Get account statistics (fans, reads, likes)
curl -s -X GET "${BASE}/account/statistics" $AUTH | jq .

# Get current user profile
curl -s -X GET "${BASE}/user/mine" $AUTH | jq .
```

## Content Adaptation (multi-platform)

Automatically adapt a piece of content for different social platforms.

```bash
# Adapt material to multiple platforms
curl -s -X POST "${BASE}/ai/material-adaptation/" \
  $AUTH \
  -d '{
    "materialId": "mat_123",
    "platforms": ["tiktok", "instagram", "xiaohongshu", "twitter"]
  }' | jq .

# Get adaptation for specific platform
curl -s -X GET "${BASE}/ai/material-adaptation/{materialId}/{platform}" $AUTH | jq .

# List all adaptations for a material
curl -s -X GET "${BASE}/ai/material-adaptation/{materialId}" $AUTH | jq .
```

## Draft Generation (AI-powered content creation)

```bash
# Generate brand content drafts
curl -s -X POST "${BASE}/ai/draft-generation/" \
  $AUTH \
  -d '{
    "brandName": "CoolBrand",
    "topic": "Summer collection launch",
    "platforms": ["tiktok", "instagram"]
  }' | jq .

# Generate image-text drafts
curl -s -X POST "${BASE}/ai/draft-generation/image-text" \
  $AUTH \
  -d '{
    "topic": "Morning coffee routine",
    "style": "minimalist"
  }' | jq .

# Check draft generation status
curl -s -X GET "${BASE}/ai/draft-generation/{taskId}" $AUTH | jq .
```

## Engagement & Analytics

```bash
# Get account analytics (data cube)
curl -s -X GET "${BASE}/channel/dataCube/accountDataCube/{accountId}" $AUTH | jq .

# Get bulk account data
curl -s -X GET "${BASE}/channel/dataCube/getAccountDataBulk/{accountId}" $AUTH | jq .

# Fetch post comments
curl -s -X POST "${BASE}/channel/engagement/post/comments" \
  $AUTH \
  -d '{"accountId":"acc_123","postId":"post_456"}' | jq .

# Generate AI comment
curl -s -X POST "${BASE}/channel/engagement/comment/ai-generate" \
  $AUTH \
  -d '{"accountId":"acc_123","postId":"post_456","prompt":"friendly and engaging"}' | jq .

# Publish a comment
curl -s -X POST "${BASE}/channel/engagement/comment/publish" \
  $AUTH \
  -d '{"accountId":"acc_123","postId":"post_456","content":"Great post!"}' | jq .
```

## Publishing Overview

```bash
# Get publishing overview statistics
curl -s -X GET "${BASE}/plat/publish/publishInfo/data" $AUTH | jq .

# Get daily publishing info
curl -s -X GET "${BASE}/plat/publish/publishDayInfo/list/1/10" $AUTH | jq .
```

## Quick Recipes

**Generate + publish a TikTok post:**
1. Use `/ai/chat/stream` to generate caption
2. Use `/ai/image/generate` or `/ai/video/generations` to create media
3. Use `/plat/publish/create` with the TikTok account ID and media URL
4. Optionally use `/plat/publish/nowPubTask/{id}` to publish immediately

**Adapt content for all platforms:**
1. Use `/ai/draft-generation/` to generate base content
2. Use `/ai/material-adaptation/` to adapt for each target platform
3. Use `/plat/publish/create` with multiple account IDs

## Notes

- All API paths are prefixed with `/api` when accessed through the Nginx gateway (port 8080)
- AI service endpoints use the `/api/ai` prefix through the gateway
- Rate limiting is applied to login and verification endpoints
- File uploads for media go through RustFS (S3-compatible) at port 9000
- Supported platforms: TikTok, YouTube, Instagram, Twitter/X, Facebook, Pinterest, LinkedIn, Douyin, Xiaohongshu, WeChat, Bilibili, Kwai
