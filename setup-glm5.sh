#!/bin/bash

set -e

API_KEY="YOUR_API_KEY_HERE"
GLM5_CONFIG='        "glm-5": {
            id: "glm-5",
            name: "GLM-5",
            api: "openai-completions",
            provider: "zai",
            baseUrl: "https://api.z.ai/api/paas/v4",
            compat: { "supportsDeveloperRole": false },
            reasoning: false,
            input: ["text"],
            cost: {
                input: 0,
                output: 0,
                cacheRead: 0,
                cacheWrite: 0,
            },
            contextWindow: 131072,
            maxTokens: 8192,
        },'

echo "🔍 查找 models.generated.js..."

# 查找文件
MODELS_FILE=""
for dir in \
  "$HOME/.config/nvm/versions/node"*/lib/node_modules/openclaw/node_modules/@mariozechner/pi-ai/dist/models.generated.js" \
  "$HOME/.nvm/versions/node"*/lib/node_modules/openclaw/node_modules/@mariozechner/pi-ai/dist/models.generated.js" \
  "/usr/local/lib/node_modules/openclaw/node_modules/@mariozechner/pi-ai/dist/models.generated.js" \
  "/opt/homebrew/lib/node_modules/openclaw/node_modules/@mariozechner/pi-ai/dist/models.generated.js"; do
  if [ -f "$dir" ]; then
    MODELS_FILE=$(echo $dir | head -1)
    break
  fi
done

if [ -z "$MODELS_FILE" ]; then
  echo "❌ 未找到 models.generated.js"
  exit 1
fi

echo "✅ 找到文件: $MODELS_FILE"

# 检查是否已配置
if grep -q '"glm-5":' "$MODELS_FILE" 2>/dev/null; then
  echo "⚠️  GLM-5 已存在，跳过添加"
else
  # 备份
  cp "$MODELS_FILE" "${MODELS_FILE}.bak.$(date +%s)"
  echo "💾 已备份原文件"

  # 添加 GLM-5 定义（在 glm-4.7-flash 之后）
  if grep -q '"glm-4.7-flash":' "$MODELS_FILE"; then
    # 在 glm-4.7-flash 后添加
    sed -i.bak '/"glm-4.7-flash": {/,/^[[:space:]]*},[[:space:]]*$/ s/^\([[:space:]]*\)},[[:space:]]*$/\1},\
'"$GLM5_CONFIG"'/' "$MODELS_FILE" 2>/dev/null || \
    perl -i.bak -pe 's/("glm-4\.7-flash":.*?\n)(\s+},)/$1\n$2\n'"$GLM5_CONFIG"'/' "$MODELS_FILE"
    echo "✅ 已添加 GLM-5 定义"
  else
    echo "❌ 未找到 glm-4.7-flash，请手动添加"
  fi
fi

# 设置环境变量
SHELL_RC="$HOME/.zshrc"
if [ ! -f "$SHELL_RC" ]; then
  SHELL_RC="$HOME/.bashrc"
fi

if ! grep -q "ZAI_API_KEY" "$SHELL_RC" 2>/dev/null; then
  echo "" >> "$SHELL_RC"
  echo "# Z.AI API Key" >> "$SHELL_RC"
  echo "export ZAI_API_KEY=\"$API_KEY\"" >> "$SHELL_RC"
  echo "✅ 已添加 API Key 到 $SHELL_RC"
else
  echo "⚠️  ZAI_API_KEY 已存在，跳过"
  # 更新现有值
  sed -i "s/export ZAI_API_KEY=.*/export ZAI_API_KEY=\"$API_KEY\"/" "$SHELL_RC"
  echo "✅ 已更新 API Key"
fi

# 更新 openclaw.json
OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"
if [ -f "$OPENCLAW_CONFIG" ]; then
  # 使用 jq 更新配置
  if command -v jq >/dev/null 2>&1; then
    jq --arg model "zai/glm-5" '.agents.defaults.model.primary = $model' "$OPENCLAW_CONFIG" > tmp.json && mv tmp.json "$OPENCLAW_CONFIG"
    if ! jq -e '.agents.defaults.models["zai/glm-5"]' "$OPENCLAW_CONFIG" >/dev/null 2>&1; then
      jq '.agents.defaults.models["zai/glm-5"] = {}' "$OPENCLAW_CONFIG" > tmp.json && mv tmp.json "$OPENCLAW_CONFIG"
    fi
    echo "✅ 已更新 openclaw.json"
  else
    echo "⚠️  未安装 jq，请手动设置 primary 为 zai/glm-5"
  fi
fi

# 清除 session
rm -f "$HOME/.openclaw/agents/main/sessions/sessions.json"
echo "🗑️  已清除旧 session"

echo ""
echo "✨ 配置完成！"
echo ""
echo "📋 接下来的步骤："
echo "   1. 重新加载环境变量: source $SHELL_RC"
echo "   2. 启动 openclaw: openclaw tui"
echo ""
