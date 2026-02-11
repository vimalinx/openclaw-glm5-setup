# OpenClaw 配置 GLM-5 完整教程

## 背景

OpenClaw 默认的 Z.AI provider 使用 `https://api.z.ai/api/coding/paas/v4`，但智谱 AI 官方 API 端点不同：

| 版本 | API 端点 |
|------|-----------|
| Z.AI 国际版 | `https://api.z.ai/api/paas/v4` |
| 智谱官方（国内） | `https://open.bigmodel.cn/api/paas/v4` |

GLM-5 目前未内置在 OpenClaw 的模型列表中，需要手动添加。

---

## 解决方案

### 方案 A：使用一键脚本（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/vimalinx/openclaw-glm5-setup/master/setup-glm5.sh | bash
```

脚本会自动：
1. 查找 `models.generated.js` 位置
2. 备份原文件
3. 添加 GLM-5 定义
4. 设置 `ZAI_API_KEY` 环境变量
5. 更新 `openclaw.json` 配置
6. 清除旧 session

### 方案 B：手动配置

#### 1. 找到 models.generated.js

```bash
# macOS
~/Library/Application\ Support/openclaw/node_modules/@mariozechner/pi-ai/dist/models.generated.js

# Linux (nvm)
~/.config/nvm/versions/node/v*/lib/node_modules/openclaw/node_modules/@mariozechner/pi-ai/dist/models.generated.js

# Linux (system)
/usr/local/lib/node_modules/openclaw/node_modules/@mariozechner/pi-ai/dist/models.generated.js
```

#### 2. 备份原文件

```bash
cp models.generated.js models.generated.js.bak
```

#### 3. 添加 GLM-5 定义

在 `models.generated.js` 中找到 `"zai": {` 部分，在 `glm-4.7-flash` 之后、关闭大括号之前添加：

```javascript
"glm-5": {
    id: "glm-5",
    name: "GLM-5",
    api: "openai-completions",
    provider: "zai",
    baseUrl: "https://api.z.ai/api/paas/v4",  // 国际版用这个
    // baseUrl: "https://open.bigmodel.cn/api/paas/v4",  // 国内用这个
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
```

#### 4. 设置 API Key 环境变量

```bash
# ~/.zshrc 或 ~/.bashrc
export ZAI_API_KEY="your-api-key-here"

# 重新加载
source ~/.zshrc
```

#### 5. 更新 openclaw.json

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "zai/glm-5"
      },
      "models": {
        "zai/glm-5": {}
      }
    }
  }
}
```

#### 6. 清除旧 session

```bash
rm -f ~/.openclaw/agents/main/sessions/sessions.json
```

#### 7. 重启 OpenClaw

```bash
openclaw tui
```

---

## 给 OpenClaw 提交 PR

如果想让 OpenClaw 官方支持 GLM-5，需要提交 PR：

### 1. Fork OpenClaw 仓库

访问 https://github.com/mariozechner/openclaw 点击 Fork

### 2. 修改文件

修改 `node_modules/@mariozechner/pi-ai/dist/models.generated.js` 的源文件。

实际上 GLM 模型定义应该在上游的 `pi-ai` 项目中：

https://github.com/mariozechner/pi-ai

### 3. 找到模型定义源码

```bash
git clone https://github.com/mariozechner/pi-ai.git
cd pi-ai
```

### 4. 添加 GLM-5 定义

在模型配置文件中添加（可能是 `src/models.ts` 或类似文件）：

```typescript
"glm-5": {
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
},
```

### 5. 提交 PR

```bash
git checkout -b add-glm-5-support
git commit -am "feat: add GLM-5 model support"
git push origin add-glm-5-support
```

然后在 GitHub 上创建 Pull Request。

---

## 验证配置

启动 OpenClaw 后，状态栏应显示：

```
agent main | session main (openclaw-tui) | zai/glm-5 | tokens ...
```

## 常见问题

### Q: 仍然显示 glm-4.7？
A: 删除 session 配置：
```bash
rm -f ~/.openclaw/agents/main/sessions/sessions.json
```

### Q: API 响应慢？
A: GLM-5 是推理模型，响应较慢。可以使用 `glm-4.7-flash` 更快：
```bash
# openclaw.json
"primary": "zai/glm-4.7-flash"
```

### Q: 配置不识别？
A: 确保 `models.generated.js` 中 GLM-5 在 `"zai": {` 对象内部，且 JSON 语法正确。

---

## 相关链接

- OpenClaw: https://github.com/mariozechner/openclaw
- pi-ai: https://github.com/mariozechner/pi-ai
- Z.AI: https://z.ai
- 智谱 AI: https://open.bigmodel.cn
- 一键脚本: https://github.com/vimalinx/openclaw-glm5-setup
