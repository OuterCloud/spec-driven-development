# Projects Directory

这个目录用于存放通过 spec-kit 创建的项目。

## 使用说明

### 自动创建项目

使用根目录下的便捷脚本：

```bash
# 回到脚手架根目录
cd ..

# 创建新项目（会自动创建到此目录下）
./create-project.sh my-awesome-project --ai copilot
```

### 手动创建项目

您也可以手动在此目录下创建项目：

```bash
# 进入此目录
cd projects

# 创建项目
specify init my-project --ai copilot
```

## 推荐的项目命名规范

- 使用小写字母和连字符：`user-auth-system`
- 避免空格和特殊字符
- 使用描述性名称：`e-commerce-backend`、`mobile-app-frontend`

## .gitignore 说明

默认情况下，`projects/` 目录下的所有项目都会被 git 忽略（除了这个 README），这样可以：

1. 保持脚手架仓库的整洁
2. 避免意外提交项目代码到脚手架仓库
3. 让每个项目都可以有自己独立的 git 仓库

如果您想要跟踪某个特定项目，可以：

1. 为该项目单独初始化 git 仓库
2. 或者修改根目录的 `.gitignore` 文件
