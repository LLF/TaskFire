import Foundation
import TaskFireCore

struct DocumentReceipt: Sendable { var reference: String; var url: String?; var warning: String?; var succeeded: Bool }
actor LarkClient {
    func fetchTasks(settings: LarkSettings) async throws -> [WorkTask] {
        let bytes = try await CLIProcess.run(path: settings.executablePath, arguments: ["task", "+get-my-tasks", "--as", "user", "--page-all", "--format", "json"])
        return try LarkPayload.tasks(from: bytes)
    }
    func complete(_ task: WorkTask, settings: LarkSettings) async throws {
        guard let guid = task.remoteID else { throw WorkspaceError("任务没有飞书 GUID。") }
        let bytes = try await CLIProcess.run(path: settings.executablePath, arguments: ["task", task.isCompleted ? "+reopen" : "+complete", "--task-id", guid, "--as", "user", "--format", "json"])
        _ = try LarkPayload.envelope(bytes)
    }
    func publish(_ document: KnowledgeDocument, settings: LarkSettings) async throws -> DocumentReceipt {
        var arguments: [String]
        let content: String
        if let reference = document.remoteReference {
            arguments = ["docs", "+update", "--doc", reference, "--command", "append", "--doc-format", "markdown", "--content", "-", "--as", "user"]
            let stamp = Day.label(Date(), format: "yyyy-MM-dd HH:mm")
            content = "\n\n## 补充记录 · " + stamp + "\n\n" + document.body
        } else {
            arguments = ["docs", "+create", "--title", document.title, "--doc-format", "markdown", "--content", "-", "--as", "user"]
            if !settings.parentToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { arguments += ["--parent-token", settings.parentToken] }
            content = document.body
        }
        let bytes = try await CLIProcess.run(path: settings.executablePath, arguments: arguments, input: content)
        let data = try LarkPayload.envelope(bytes)
        let remote = data["document"] as? [String: Any] ?? [:]
        let reference = remote["document_id"] as? String ?? document.remoteReference
        guard let reference, !reference.isEmpty else { throw WorkspaceError("飞书可能已创建文档，但没有返回文档标识。请先在飞书检查，避免重复创建。") }
        let warnings = data["warnings"] as? [String] ?? []
        let result = data["result"] as? String
        let warning = !warnings.isEmpty ? warnings.joined(separator: "\n") : (result == "partial_success" || result == "failed" ? "飞书报告内容未完全写入，请打开文档核对后再操作。" : nil)
        return DocumentReceipt(reference: reference, url: remote["url"] as? String ?? document.remoteURL, warning: warning, succeeded: result != "partial_success" && result != "failed" && warnings.isEmpty)
    }
    func version(path: String) async throws -> String {
        let bytes = try await CLIProcess.run(path: path, arguments: ["--version"])
        return String(decoding: bytes, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum CLIProcess {
    static func run(path: String, arguments: [String], input: String? = nil) async throws -> Data {
        try await Task.detached(priority: .userInitiated) { try blockingRun(path: path, arguments: arguments, input: input) }.value
    }
    private static func blockingRun(path: String, arguments: [String], input: String?) throws -> Data {
            guard path.hasPrefix("/"), FileManager.default.isExecutableFile(atPath: path) else { throw WorkspaceError("找不到可执行的 lark-cli。请在设置中指定绝对路径，例如 /opt/homebrew/bin/lark-cli。") }
            let root = FileManager.default.temporaryDirectory.appendingPathComponent("TaskFire-" + UUID().uuidString)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            defer { try? FileManager.default.removeItem(at: root) }
            let outURL = root.appendingPathComponent("stdout"), errURL = root.appendingPathComponent("stderr"), inputURL = root.appendingPathComponent("stdin")
            FileManager.default.createFile(atPath: outURL.path, contents: nil, attributes: [.posixPermissions: 0o600])
            FileManager.default.createFile(atPath: errURL.path, contents: nil, attributes: [.posixPermissions: 0o600])
            try Data((input ?? "").utf8).write(to: inputURL)
            let out = try FileHandle(forWritingTo: outURL), err = try FileHandle(forWritingTo: errURL), stdin = try FileHandle(forReadingFrom: inputURL)
            defer { try? out.close(); try? err.close(); try? stdin.close() }
            let process = Process(); process.executableURL = URL(fileURLWithPath: path); process.arguments = arguments
            process.standardOutput = out; process.standardError = err; process.standardInput = stdin
            var environment = ProcessInfo.processInfo.environment
            environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
            environment["LARKSUITE_CLI_NO_UPDATE_NOTIFIER"] = "1"; environment["LARKSUITE_CLI_NO_SKILLS_NOTIFIER"] = "1"
            process.environment = environment
            let finished = DispatchSemaphore(value: 0)
            process.terminationHandler = { _ in finished.signal() }
            try process.run()
            if finished.wait(timeout: .now() + 90) == .timedOut {
                process.terminate()
                if finished.wait(timeout: .now() + 2) == .timedOut { kill(process.processIdentifier, SIGKILL); process.waitUntilExit() }
                throw WorkspaceError("飞书操作超过 90 秒。若正在写入，请先在飞书检查结果，再决定是否重试。")
            }
            let stdout = try Data(contentsOf: outURL), stderr = try Data(contentsOf: errURL)
            guard process.terminationStatus == 0 else {
                let bytes = stderr.isEmpty ? stdout : stderr
                if let error = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any], let info = error["error"] as? [String: Any] {
                    let message = info["message"] as? String ?? "飞书操作失败"
                    let hint = info["hint"] as? String ?? "请检查 lark-cli 的登录和权限。"
                    if process.terminationStatus == 10 { throw WorkspaceError("CLI 要求额外确认，本次操作没有自动确认。请在终端检查该操作。\n" + message) }
                    throw WorkspaceError(message + "\n" + hint)
                }
                throw WorkspaceError("lark-cli 执行失败（退出码 \(process.terminationStatus)）。请在终端检查 CLI 配置；本次未标记操作成功。")
            }
            return stdout
    }
}
