#!/bin/bash

set -e

API_KEY="23a3699c8fdf4ca3a4ca15fa5a298ffc.vqjkmbpyXDHRy85i"

echo "🍎 macOS OpenClaw GLM-5 配置脚本"
echo "=================================="
echo ""

# 查找 models.generated.js
echo "🔍 查找 models.generated.js..."

MODELS_FILE=""
for dir in \
  "$HOME/.nvm/versions/node"/v*/lib/node_modules/openclaw/node_modules/@mariozechner/pi-ai/dist/models.generated.js \
  "$HOME/Library/Application Support/openclaw/node_modules/@mariozechner/pi-ai/dist/models.generated.js" \
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

  # 创建临时 Python 脚本
  echo "📝 添加 GLM-5 定义..."

  cat > /tmp/add_glm5.py << 'EOF'
import sys
import re

if len(sys.argv) < 2:
    print("❌ 错误: 缺少文件路径参数", file=sys.stderr)
    sys.exit(1)

file_path = sys.argv[1]

try:
    with open(file_path, 'r') as f:
        content = f.read()
except Exception as e:
    print(f"❌ 无法读取文件: {e}", file=sys.stderr)
    sys.exit(1)

# 检查是否已存在
if '"glm-5":' in content:
    print("⚠️  GLM-5 已存在")
    sys.exit(0)

# GLM-5 定义
glm5_def = '''        "glm-5": {
            id: "glm-5",
            name: "GLM-5",
            api: "openai-completions"",
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
        },'''

# 在 glm-4.7-flash 后插入
pattern = r'("glm-4\.7-flash": \{[^}]+\},\s*)(\n\s+\},)'
replacement = r'\1\n' + glm5_def + r'\2'

if re.search(pattern, content, re.DOTALL):
    new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    with open(file_path, 'w') as f:
        f.write(new_content)
    print("✅ 已添加 GLM-5")
else:
    print("⚠️  未找到 glm-4.7-flash，尝试在 zai provider 末尾添加")
    # 备选方案：在 zai 的最后一个模型后添加
    zai_pattern = r'("glm-4\.7-flash": \{[^}]+\},)(\s+\},\s*\n)'
    if re.search(zai_pattern, content, re.DOTALL):
        new_content = re.sub(zai_pattern, r'\1\n' + glm5_def + r'\2', content, flags=re.DOTALL)
        with open(file_path, 'w') as f:
            f.write(new_content)
        print("✅ 已添加 GLM-5")
    else:
        print("❌ 无法自动添加，请手动编辑")
        sys.exit(1)
EOF

  # 运行 Python 脚本
  python3 /tmp/add_glm5.py "$MODELS_FILE"
  PY_EXIT=$?

  # 清理
  rm -f /tmp/add_glm5.py

  if [ $PY_EXIT -ne 0 ]; then
    echo ""
    echo "❌ 添加失败，请手动添加"
    echo ""
    echo "编辑文件: vim $MODELS_FILE"
    echo "在 \"zai\": { 部分的最后添加："
    cat << 'GLM5_EOF'
        "glm-5": {
            id: "glm-5",
            name: "GLM-5",
            api: "openai-completions"",
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
        },
GLM5_EOF
    exit 1
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
  sed -i '' "s/export ZAI_API_KEY=.*/export ZAI_API_KEY=\"$API_KEY\"/" "$SHELL_RC"
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
