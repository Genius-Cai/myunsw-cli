# myunsw-cli

> 逆向工程 UNSW 学生门户 myUNSW，文档化所有 API 端点，支持 AI 辅助选课自动化。

**无爬虫。无密码。无浏览器自动化。** 仅需浏览器 Cookie + 已文档化的 API 端点。

[English Version](README.md)

---

## 这是什么？

[myUNSW](https://my.unsw.edu.au) 是 UNSW 悉尼的学生门户，基于老旧的 Java 框架 (BSDS) 运行，没有官方 API。

本项目通过逆向工程文档化了门户的所有端点，实现：

- **AI 辅助选课** — 让 Claude/Codex/Gemini 通过自然语言帮你选课
- **终端自动化** — 在终端查成绩、课表、学费、候补队列
- **程序化访问** — 发现隐藏的 JSON API，返回结构化数据

### 已验证功能

| 功能 | 状态 | 说明 |
|------|------|------|
| 查看选课状态 | ✅ | JSON API 返回完整课程数据 |
| 选课 | ✅ | 完整的选课流程 |
| 查看课表 | ✅ | JSON API 含教室/时间/周数 |
| 查看成绩（全学期） | ✅ | 基于 POST 的学期切换 |
| 下载成绩单 PDF | ✅ | PDF 自动下载 |
| 查看学费 | ✅ | 所有学期学费明细 |
| 搜索课程 | ✅ | 15+ 筛选参数 |
| 查看个人信息 | ✅ | 地址、电话、邮箱、紧急联系人 |
| 候补队列管理 | ✅ | 加入/退出/查看排名 |
| 确认选课 | ⚠️ | 可能需要浏览器（反自动化保护） |

## 快速开始

### 1. 获取 Cookie

#### 方法一：Chrome 插件（推荐）

1. 安装 [Get cookies.txt LOCALLY](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)（免费 Chrome 插件）
2. 登录 [myUNSW](https://my.unsw.edu.au)
3. 进入任意 `/active/` 页面（如选课、成绩页）
4. 点击插件图标 → "Export" → 保存为 `cookies.txt`
5. 移动到指定位置：

```bash
mv ~/Downloads/cookies.txt /tmp/myunsw_active.txt
```

#### 方法二：手动 DevTools

1. 登录 [myUNSW](https://my.unsw.edu.au)
2. 打开 DevTools (F12) → Application → Cookies → `my.unsw.edu.au`
3. 复制以下三个值：
   - `JSESSIONID`（路径必须是 `/active`，**不是** `/portal`）
   - `AWSALB`
   - `AWSALBCORS`
4. 创建 cookie 文件：

```bash
cat > /tmp/myunsw_active.txt << EOF
my.unsw.edu.au	FALSE	/active	FALSE	0	JSESSIONID	你的值
my.unsw.edu.au	FALSE	/	FALSE	0	AWSALB	你的值
my.unsw.edu.au	FALSE	/	FALSE	0	AWSALBCORS	你的值
EOF
```

#### 验证 Session

```bash
curl -s -b /tmp/myunsw_active.txt \
  'https://my.unsw.edu.au/active/studentClassEnrol/years.xml' | grep -c 'bsdsSequence'
# 1 = 有效, 0 = 已过期（需要重新登录）
```

> Session 约 30 分钟无操作后过期。

### 2. 选择你的平台

| 平台 | 安装方式 | 使用方式 |
|------|---------|---------|
| **Claude Code** | `cp skills/myunsw.md ~/.claude/commands/myunsw.md` | `/myunsw grades` |
| **Codex CLI** | `cp skills/AGENTS.md 项目目录/AGENTS.md` | `codex "查看我的成绩"` |
| **Gemini CLI** | `cp skills/GEMINI.md 项目目录/GEMINI.md` | `gemini "查看课表"` |
| **OpenClawd** | `cp skills/myunsw.md ~/.openclawd/skills/myunsw.md` | `openclawd --skill myunsw "选课"` |
| **Claude.ai** | 上传到 Project Knowledge | 直接对话 |
| **Cursor** | `cp skills/myunsw.md .cursor/rules/myunsw.md` | AI 辅助中自动加载 |
| **Windsurf** | `cp skills/myunsw.md .windsurfrules/myunsw.md` | AI 辅助中自动加载 |
| **Aider** | `aider --read skills/myunsw.md` | 作为上下文加载 |
| **原始 curl** | 无需安装 | 参考 `examples/` 目录 |

详细部署说明见 [docs/deployment.md](docs/deployment.md)。

## 架构

myUNSW 使用三层 Session 架构：

```
浏览器登录
  → CAS SSO (sso.unsw.edu.au)     ← TGC cookie (HttpOnly)
    → Portal (/portal)             ← JSESSIONID (path=/portal)  ← 不要用这个
    → Active (/active)             ← JSESSIONID (path=/active)  ← 用这个
```

所有表单使用 **BSDS 框架** — 服务端状态机：

```
1. GET 页面           → 从隐藏 input 提取 bsdsSequence
2. POST 到同一 URL    → bsdsSequence + bsdsSubmit-{操作} + 参数
3. 跟随 302 重定向    → 服务器重定向到下一个状态
4. 用新的 bsdsSequence 重复
```

> **核心规则**：`bsdsSequence` 每次页面加载都会递增。始终使用最新的值。

## 发现的端点

### 共 27 个端点，分 5 类：

| 类别 | 端点 | JSON API? |
|------|------|-----------|
| 选课 | years, courses, classes, timetable | ✅ `?data=classes` |
| 学术 | results, statement, timetable, exam, standing | PDF 下载 |
| 个人信息 | address, phone, email, name, emergency, SMS, stats | 读 + 写 |
| 财务 | fees, payment options | 只读 |
| 其他 | search, specialisation, Opal, T&C, IPT, graduation, disability | 混合 |

完整 API 文档见 [docs/api-reference.md](docs/api-reference.md)。

## 学期代码

| 代码 | 学期 | 代码 | 学期 |
|------|------|------|------|
| 5243 | T1 2024 | 5253 | T1 2025 |
| 5246 | T2 2024 | 5256 | T2 2025 |
| 5249 | T3 2024 | 5259 | T3 2025 |
| 5263 | T1 2026 | 5266 | T2 2026 |

规律：T1→T2→T3 代码差 3，跨年差 ~4。

## 项目结构

```
myunsw-cli/
├── README.md                    # 英文文档
├── README_CN.md                 # 本文件（中文文档）
├── LICENSE                      # MIT 开源协议
├── CONTRIBUTING.md              # 贡献指南
├── docs/
│   ├── api-reference.md         # 完整 API 文档
│   ├── bsds-framework.md        # BSDS 框架逆向笔记
│   └── deployment.md            # 各平台部署指南
├── skills/
│   ├── myunsw.md                # Claude Code 技能
│   ├── AGENTS.md                # Codex CLI 指令
│   └── GEMINI.md                # Gemini CLI 上下文
└── examples/
    ├── check-grades.sh          # 查询所有学期成绩
    ├── check-timetable.sh       # 获取课表 JSON
    └── search-classes.sh        # 搜索课程
```

## 限制

- **无法自动登录** — CAS SSO 需要浏览器；必须手动提取 Cookie
- **Session 约 30 分钟过期** — 过期后需要重新登录并更新 Cookie
- **最终选课确认**可能有反自动化保护
- **只能顺序请求** — BSDS 状态机在服务端，不能并行操作
- **`bsdsSubmit-drop-course` 没有确认步骤** — 立即退课，谨慎操作

## 贡献

欢迎贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md)。

待完成的方向：
- 开发 Python/Node 命令行工具
- 添加更多 AI 平台集成
- 测试研究生/博士生账号
- 开发浏览器插件自动提取 Cookie
- 自动刷新 Session

## 免责声明

本项目仅文档化 myUNSW 公开可访问的端点，供个人使用。**不会**存储或传输凭据、绕过认证、或访问其他学生的数据。请负责任地使用，遵守 UNSW IT 使用政策。

## 作者

**蔡明哲 (Steven Cai)** ([@Genius-Cai](https://github.com/Genius-Cai))

UNSW 悉尼 — 商科/计算机 双学位

## 开源协议

[MIT](LICENSE)
