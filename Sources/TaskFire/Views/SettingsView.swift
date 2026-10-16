import SwiftUI
import AppKit
import TaskFireCore

struct SettingsView: View {
    @EnvironmentObject var store: WorkspaceStore
    @State private var settings = LarkSettings()
    @State private var version = ""
    @State private var checking = false
    var body: some View {
        Form {
            Section("飞书 CLI") {
                TextField("lark-cli 路径", text: $settings.executablePath)
                HStack { Button("选择可执行文件…") { let panel = NSOpenPanel(); panel.canChooseDirectories = false; panel.allowsMultipleSelection = false; if panel.runModal() == .OK, let url = panel.url { settings.executablePath = url.path } }; Button("检查 CLI") { checking = true; Task { do { version = try await store.lark.version(path: settings.executablePath) } catch { version = error.localizedDescription }; checking = false } }.disabled(checking); if checking { ProgressView().controlSize(.small) } }
                if !version.isEmpty { Text(version).font(.caption).textSelection(.enabled) }
                Text("复用本机 lark-cli 的用户身份。首次使用请先在终端完成配置与授权；本应用不保存账号密钥。").font(.caption).foregroundStyle(.secondary)
                Text("lark-cli auth login --domain task --domain docs --domain drive").font(.system(.caption, design: .monospaced)).textSelection(.enabled)
            }
            Section("知识文档") {
                TextField("保存位置 token（可选）", text: $settings.parentToken)
                Text("留空时由飞书使用默认位置。心得不会自动发布；知识文档仅在手动操作时写入。更新采用追加方式。").font(.caption).foregroundStyle(.secondary)
            }
            Section("本机数据") {
                Text(store.repository.url.path).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                HStack { Button("在 Finder 中显示") { NSWorkspace.shared.activateFileViewerSelecting([store.repository.url]) }; Button("导出备份…") { store.exportBackup() } }
            }
            HStack { Spacer(); Button("保存设置") { store.saveSettings(settings); version = "设置已保存" }.buttonStyle(.borderedProminent) }
        }.formStyle(.grouped).frame(width: 580, height: 560).onAppear { settings = store.state.settings }
    }
}
