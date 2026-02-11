# OpenClaw GLM-5 一键配置脚本

自动配置 OpenClaw 使用 GLM-5 模型（Z.AI 国际版）

## 功能

- 自动查找并修改 `models.generated.js`
- 添加 GLM-5 模型定义（Z.AI 国际版 API）
- 配置 API Key 环境变量
- 更新 `openclaw.json` 主模型
- 清除旧 session

## 使用方法

```bash
# 下载脚本
curl -O https://github.com/vimalinx/openclaw-glm5-setup/raw/main/setup-glm5.sh

# 添加执行权限
chmod +x setup-glm5.sh

# 运行配置
./setup-glm5.sh

# 重新加载环境变量
source ~/.zshrc  # 或 ~/.bashrc

# 启动 OpenClaw
openclaw tui
```

## API 端点

- **国内（智谱官方）**: `https://open.bigmodel.cn/api/paas/v4`
- **国外（Z.AI）**: `https://api.z.ai/api/paas/v4`

本脚本使用 Z.AI 国际版 API。

## 系统支持

- macOS (Homebrew/npm)
- Linux (nvm/system npm)

## 注意事项

- 会自动备份原文件
- 如已有 GLM-5 配置会跳过添加
- 需要 `jq` 命令（可选）

## License

MIT
