# 部署指南

如何在不同 AI 编程平台上配置 myunsw-cli。

## 前置条件

### 获取 Cookie（两种方式）

#### 方式一：Chrome 插件（推荐）

1. 安装 [Get cookies.txt LOCALLY](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)（免费 Chrome 插件）
2. 登录 [myUNSW](https://my.unsw.edu.au)
3. 进入任意 `/active/` 页面（如选课、成绩页）
4. 点击插件图标 → "Export" → 保存为 `cookies.txt`
5. 导出的文件已是 Netscape 格式，可直接使用！

```bash
# 移动到指定位置
mv ~/Downloads/cookies.txt /tmp/myunsw_active.txt
```

> **提示**：导出的文件包含该域名下的所有 Cookie。直接使用即可，但实际只需要 `/active` 路径下的 JSESSIONID、AWSALB 和 AWSALBCORS。

#### 方式二：手动 DevTools

1. 登录 [myUNSW](https://my.unsw.edu.au)
2. 打开 DevTools (F12) → Application → Cookies → `my.unsw.edu.au`
3. 找到并复制以下三个值：
   - `JSESSIONID`（路径必须是 `/active`，**不是** `/portal`）
   - `AWSALB`
   - `AWSALBCORS`
4. 手动创建 cookie 文件：

```bash
cat > /tmp/myunsw_active.txt << EOF
my.unsw.edu.au	FALSE	/active	FALSE	0	JSESSIONID	YOUR_VALUE
my.unsw.edu.au	FALSE	/	FALSE	0	AWSALB	YOUR_VALUE
my.unsw.edu.au	FALSE	/	FALSE	0	AWSALBCORS	YOUR_VALUE
EOF
```

### 验证 Session

```bash
curl -s -b /tmp/myunsw_active.txt \
  'https://my.unsw.edu.au/active/studentClassEnrol/years.xml' | grep -c 'bsdsSequence'
# 1 = 有效, 0 = 已过期（需要重新登录）
```

Session 约 30 分钟无操作后过期。

---

## 各平台配置

### Claude Code

Claude Code 通过 `~/.claude/commands/` 中的斜杠命令工作。

```bash
# 克隆仓库
git clone https://github.com/Genius-Cai/myunsw-cli.git
cd myunsw-cli

# 安装技能
cp skills/myunsw.md ~/.claude/commands/myunsw.md

# 在 Claude Code 中使用：
# /myunsw setup        ← 首次使用，粘贴 cookie
# /myunsw grades       ← 查看成绩
# /myunsw status       ← 选课状态
# /myunsw timetable    ← 获取课表 JSON
```

技能支持传参：`/myunsw grades T3 2025`、`/myunsw search COMP` 等。

### Codex CLI (OpenAI)

Codex 从项目根目录读取 `AGENTS.md`。

```bash
# 克隆并进入项目
git clone https://github.com/Genius-Cai/myunsw-cli.git
cd myunsw-cli

# 复制 agent 指令到你的工作目录
cp skills/AGENTS.md /path/to/your/project/AGENTS.md

# 或者创建符号链接
ln -s $(pwd)/skills/AGENTS.md /path/to/your/project/AGENTS.md

# 在 Codex 中使用
codex "check my UNSW enrollment status"
codex "what are my grades for T3 2025?"
codex "search for COMP1511 classes in T2 2026"
```

### Gemini CLI (Google)

```bash
# 复制上下文文件
cp skills/GEMINI.md /path/to/your/project/GEMINI.md

# 在 Gemini CLI 中使用
gemini "show my UNSW timetable"
gemini "check my UNSW fees"
```

### OpenClawd

```bash
# 复制技能到 OpenClawd
mkdir -p ~/.openclawd/skills
cp skills/myunsw.md ~/.openclawd/skills/myunsw.md

# 使用
openclawd --skill myunsw "check enrollment status"
openclawd --skill myunsw "show grades for all terms"
```

### Claude.ai（网页版）

1. 打开 [claude.ai](https://claude.ai) → 创建新项目
2. 点击 "Add to Project Knowledge"
3. 上传 `skills/myunsw.md`
4. 开始对话：
   > "我需要管理 UNSW 选课。我的 cookie 是：JSESSIONID=xxx, AWSALB=yyy, AWSALBCORS=zzz"

Claude 会创建 cookie 文件并通过 Artifacts 或工具执行 curl 命令。

### Cursor

```bash
# 添加为 Cursor 规则
mkdir -p .cursor/rules
cp skills/myunsw.md .cursor/rules/myunsw.md

# Cursor 会将其作为 AI 辅助的上下文自动加载
```

### Windsurf

```bash
cp skills/myunsw.md .windsurfrules/myunsw.md
```

### Aider

```bash
# 作为上下文文件添加
aider --read skills/myunsw.md

# 或者添加到 .aider.conf.yml
# read:
#   - skills/myunsw.md
```

---

## Cookie 使用技巧

### 用插件自动刷新

由于 Session 约 30 分钟过期，你可能需要频繁重新导出：

1. 保持 myUNSW 标签页在浏览器中打开
2. Session 过期时，刷新页面（通过 CAS SSO 自动重新认证）
3. 用插件重新导出
4. `mv ~/Downloads/cookies.txt /tmp/myunsw_active.txt`

### 过滤 Cookie（可选）

插件会导出所有 Cookie。如果只想保留必需的：

```bash
grep -E '(JSESSIONID|AWSALB)' ~/Downloads/cookies.txt > /tmp/myunsw_active.txt
```

### Cookie 文件格式

Netscape cookie 格式（Tab 分隔）：
```
domain	subdomains	path	secure	expiry	name	value
```

示例：
```
my.unsw.edu.au	FALSE	/active	FALSE	0	JSESSIONID	ABC123DEF456
my.unsw.edu.au	FALSE	/	FALSE	1739648000	AWSALB	xyz789
my.unsw.edu.au	FALSE	/	FALSE	1739648000	AWSALBCORS	xyz789
```
