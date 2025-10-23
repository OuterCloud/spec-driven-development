# Spec-Driven Development 脚手架

在 MacOS 上一键安装 [spec-kit](https://github.com/github/spec-kit) 开发环境的自动化工具。

## 系统要求

- MacOS
- Python ≥ 3.11
- Git

## 快速开始

```bash
# 1. 克隆并安装
git clone https://github.com/your-username/spec-driven-development.git
cd spec-driven-development
chmod +x setup-spec-kit.sh
./setup-spec-kit.sh

# 2. 验证
specify check

# 3. 创建项目
./create-project.sh my-project              # 默认桌面
./create-project.sh my-project ~/workspace  # 指定路径
./create-project.sh my-project --ai copilot # 使用 AI
```

## 开发流程

通过 vscode 打开项目。

```bash
code my-project
```

打开 Copilot Chat 插件, 开始撰写需求。

- 定义项目宪法，使用 `/speckit.constitution` 指令。详见 [speckit-constitution.md](docs/speckit-constitution.md)
- 撰写需求时，使用 `/speckit.specify` 指令。详见 [speckit-specify.md](docs/speckit-specify.md)
- 澄清需求时，使用 `/speckit.clarify` 指令。详见 [speckit-clarify.md](docs/speckit-clarify.md)
- 制定实施计划时，使用 `/speckit.plan` 指令。详见 [speckit-plan.md](docs/speckit-plan.md)
- 分解任务时，使用 `/speckit.tasks` 指令。详见 [speckit-tasks.md](docs/speckit-tasks.md)
- 实现任务时，使用 `/speckit.implement` 指令。详见 [speckit-implement.md](docs/speckit-implement.md)

## 常见问题

<details>
<summary>VS Code 命令行工具未找到</summary>

自动解决：重新运行 `./setup-spec-kit.sh`

手动解决：VS Code 中按 `Cmd+Shift+P` → "Shell Command: Install 'code' command in PATH"

</details>

<details>
<summary>Node.js 版本不兼容（需要 ≥ 22）</summary>

```bash
# NVM
nvm install --lts && nvm use --lts

# Homebrew
brew upgrade node
```

</details>

<details>
<summary>specify 命令未找到</summary>

```bash
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

</details>

---

💡 更多信息：[spec-kit 官方文档](https://github.com/github/spec-kit)
