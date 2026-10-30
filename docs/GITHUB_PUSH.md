# 推送到 GitHub

本仓库已在本地完成初始化与首次提交（分支 `main`，178 个文件，约 21 MB）。
`.env`、`.conda`、`pgdata`、`node_modules`、`dist`、`.artifacts` 等均已忽略。

## 方式一：一键脚本（推荐）

在项目根目录打开**普通 PowerShell**：

```powershell
cd "D:\edge download\vlunsleuth-main\vlunsleuth-main"

powershell -ExecutionPolicy Bypass -File .\push-to-github.ps1 `
  -RepoUrl "https://github.com/<你的用户名>/<仓库名>.git" `
  -UserName "你的名字" `
  -UserEmail "你的邮箱"
```

脚本会：修正提交作者 → 设置 origin → `git push -u origin main`，失败时打印排查提示。

## 方式二：手动命令

```powershell
cd "D:\edge download\vlunsleuth-main\vlunsleuth-main"

git config user.name "你的名字"
git config user.email "你的邮箱"
git commit --amend --reset-author --no-edit

git remote add origin https://github.com/<你的用户名>/<仓库名>.git
git push -u origin main
```

如果 `origin` 已存在，用 `git remote set-url origin <url>`。

## 认证说明

首次 push 会弹出 GitHub 登录（Git Credential Manager）。
如果没有弹窗，或提示认证失败：

1. GitHub → Settings → Developer settings → **Personal access tokens → Fine-grained tokens**
2. 选择该仓库，权限勾选 **Contents: Read and write**
3. push 时用户名填 GitHub 用户名，密码填这个 token

## 常见问题

| 现象 | 处理 |
|---|---|
| `Authentication failed` | 用 PAT 当密码，或重新触发 Git Credential Manager |
| `rejected ... fetch first` | 仓库已有提交：`git pull --rebase origin main` 后再 push |
| `refusing to merge unrelated histories` | `git pull origin main --allow-unrelated-histories` |
| 默认分支不是 main | push 后在 GitHub 仓库 Settings → Branches 改默认分支 |
| 想换提交作者 | 改完 `user.name/email` 后 `git commit --amend --reset-author --no-edit` |

## 推送内容

- ✅ 源码（backend / frontend / 模型子项目）、`samples/`、`docs/`、脚本、README
- ❌ `.env`（含 API Key）、`dataset/`（70 MB 知识库）、运行产物、依赖与本地环境

需要把 `dataset/` 也放进仓库的话，先告诉我，我调整 `.gitignore`（注意仓库体积会增大 70 MB）。
