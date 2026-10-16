# TaskFire 原生 macOS 实施计划

Goal: 将 design/index.html 已确认的五页设计制作成可运行的 SwiftUI 应用。
Architecture: WindowGroup 主窗口与独立 Settings；TaskFireCore 管理 Codable 模型、远端合并、JSON 原子保存；actor 封装 lark-cli Process，以参数数组调用，避免 shell 拼接。
Tech Stack: Swift 6、SwiftUI、SwiftPM、macOS 14+，无外部依赖。

约束：两类任务独立标识；个人计划日期独立于截止日期；心得自动本地保存，文档仅手动发布；发布后新增内容采用追加，避免覆盖云端修改；主线程不阻塞进程；同步失败不伪装成功。

- [x] 先在 Tests/TaskFireCoreTests/WorkspaceTests.swift 验证重排不改期限、GUID 幂等合并并保留个人字段、同名不同源不混淆、解析毫秒时间和错误拒绝、本地持久化与损坏保护。运行 rtk swift test 确认失败，再实现 Sources/TaskFireCore 下的模型、合并、解析和持久化。
- [x] Sources/TaskFire/Stores/WorkspaceStore.swift 负责主线程可观察状态和操作；Services/LarkClient.swift 负责带超时、stdout/stderr 排空的异步 CLI 调用。
- [x] Sources/TaskFire/Views 分别实现主窗口、今日、计划、任务库、记录、大盘、任务编辑器、知识编辑器和设置。空状态可直接创建或同步任务，日期可编辑。
- [x] 依据实际 CLI help 接入 +get-my-tasks、+complete、+reopen、docs +create 与 +update append。写入仅用户触发，不自动重试。
- [x] script/build_and_run.sh 构建 dist/TaskFire.app、启动并验证进程；.codex/environments/environment.toml 配置 Run。
- [x] 运行 rtk swift test 与构建，检查原生窗口和核心操作、重启后的保存结果，更新 README 记录限制。

## 验证记录

Swift 6 原生 .app 构建通过；portable core checks 10/10 通过。SwiftPM 在当前 CLT 中动态库加载失败，采用相同源码的 swiftc 测试入口。原生 QA 已验证新建/重点/完成、心得存储、读取3项真实飞书任务。正式远端写入未作为测试执行。主窗口最终收敛为单 Window，避免多窗口文档编辑冲突。

Xcode 27.1 安装就绪后，标准 swift test 编译完整应用并通过 6 项 XCTest（0 failures）。最终 .app 启动与进程检查通过，正式工作台成功读取3项飞书任务；原生窗口截图为 design/native-today.png。
