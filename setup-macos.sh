#!/bin/bash

set -e

API_KEY="23a3699c8fdf4ca3a4ca15fa5a298ffc.vqjkmbpyXDHRy85i"
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

echo "🍎 macOS OpenClaw GLM-5 配置脚本"
echo "=================================="
echo ""

# 查找 models.generated.js
echo "🔍 查找 models.generated.js..."

MODELS_FILE=""
for dir in \
  "$HOME/Library/Application Support/openclaw/node_modules/@mariozechner/pi-ai/dist/models.generated.js" \
  "$HOME/.nvm/versions/node"/v*/lib/node_modules/openclaw/node_modules/@mariozechner/pi-ai/dist/models.generated.js \
  "/usr/local/lib/node_modules/openclaw/node_modules/@mariozechner/pi-ai/dist/models.generated.js" \
  "/opt/homebrew/lib/node_modules/openclaw/node_modules/@mariozechner/pi-ai/dist/models.generated.js"; do
  if [ -f "$dir" ]; then
    MODELS_FILE="$dir"
    break
  fi
done

if [ -z "$MODELS_FILE" ]; then
  echo "❌ 未找到 models.generated.js"
  echo ""
  echo "请确认 OpenClaw 已安装："
  echo "  npm list -g openclaw"
  exit 1
fi

echo "✅ 找到: $MODELS_FILE"

# 检查是否已配置
if grep -q '"glm-5":' "$MODELS_FILE" 2>/dev/null; then
  echo "⚠️  GLM-5 已存在，跳过添加"
else
  # 备份
  BACKUP="${MODELS_FILE}.bak.$(date +%s)"
  cp "$MODELS_FILE" "$BACKUP"
  echo "💾 已备份: $BACKUP"

  # 添加 GLM-5 定义
  echo "📝 添加 GLM-5 定义..."

  if grep -q '"glm-4.7-flash":' "$MODELS_FILE"; then
    # 使用 perl 在 glm-4.7-flash 后插入
    perl -i -pe 's/("glm-4\.7-flash":.*?\n)(\s+},)/$1$2\n'"$GLM5_CONFIG"'/' "$MODELS_FILE"
    echo "✅ 已添加 GLM-5"
  else
    echo "⚠️  未找到 glm-4.7-flash"
    echo "请手动在 zai provider 的最后添加 GLM-5 定义"
  fi
fi

# 检测默认 shell
SHELL_RC=""
if [ -n "$ZSH_VERSION" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
  SHELL_RC="$HOME/.bash_profile"
else
  SHELL_RC="$HOME/.zshrc"
fi

echo ""
echo "🐢 检测到 Shell 配置: $SHELL_RC"

# 设置环境变量
if ! grep -q "ZAI_API_KEY" "$SHELL_RC" 2>/dev/null; then
  echo "" >> "$SHELL_RC"
  echo "# Z.AI API Key (GLM-5)" >> "$SHELL_RC"
  echo "export ZAI_API_KEY=\"$API_KEY\"" >> "$SHELL_RC"
  echo "✅ 已添加 API Key 到 $SHELL_RC"
else
  echo "⚠️  ZAI_API_KEY 已存在"
  # macOS sed 用法不同
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/export ZAI_API_KEY=.*/export ZAI_API_KEY=\"$API_KEY\"/" "$SHELL_RC"
  else
    sed -i "s/export ZAI_API_KEY=.*/export ZAI_API_KEY=\"$API_KEY\"/" "$SHELL_RC"
  fi
  echo "✅ 已更新 API Key"
fi

# 更新 openclaw.json
OPENCLAW_DIR="$HOME/.openclaw"
OPENCLAW_CONFIG="$OPENCLAW_DIR/openclaw.json"

if [ -f "$OPENCLAW_CONFIG" ]; then
  echo ""
  echo "📝 更新 openclaw.json..."

  # 检查 jq
  if command -v jq >/dev/null 2>&1; then
    # 备份
    cp "$OPENCLAW_CONFIG" "${OPENCLAW_CONFIG}.bak"

    # 更新 primary 模型
    jq --arg model "zai/glm-5" \
      '.agents.defaults.model.primary = $model' \
      "$OPENCLAW_CONFIG" > /tmp/openclaw.json && mv /tmp/openclaw.json "$OPENCLAW_CONFIG"

    # 添加 glm-5 到 models 列表
    if ! jq -e '.agents.defaults.models["zai/glm-5"]' "$OPENCLAW_CONFIG" >/dev/null 2>&1; then
      jq '.agents.defaults.models["zai/glm-5"] = {}' \
        "$OPENCLAW_CONFIG" > /tmp/openclaw.json && mv /tmp/openclaw.json "$OPENCLAW_CONFIG"
    fi

    echo "✅ 已更新 openclaw.json"
  else
    echo "⚠️  未安装 jq，跳过配置更新"
    echo "   安装: brew install jq"
    echo "   或手动设置 primary 为 zai/glm-5"
  fi
else
  echo "⚠️  未找到 openclaw.json"
fi

# 清除 session
SESSIONS_DIR="$OPENCLAW_DIR/agents/main/sessions"
if [ -f "$SESSIONS_DIR/sessions.json" ]; then
  rm -f "$SESSIONS_DIR/sessions.json"
  echo ""
  echo "🗑️  已清除旧 session"
fi

# 显示验证信息
echo ""
echo "✨ 配置完成！"
echo ""
echo "📋 下一步："
echo "   1. 打开新终端窗口（或运行: source $SHELL_RC）"
echo "   2. 验证: echo \$ZAI_API_KEY"
echo "   3. 启动: openclaw tui"
echo ""
echo "📌 预期状态栏显示:"
echo "   agent main | session main (openclaw-tui) | zai/glm-5 | tokens ..."
echo ""
echo "❓ 遇到问题？"
echo "   - 检查: cat $MODELS_FILE | grep -A 5 glm-5"
echo "   - 清除: rm $SESSIONS_DIR/sessions.json"
echo ""
