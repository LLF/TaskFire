import SwiftUI
import AppKit
import TaskFireCore

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) { NSApp.setActivationPolicy(.regular); NSApp.activate(ignoringOtherApps: true) }
}
extension Notification.Name { static let taskFireNewTask = Notification.Name("TaskFire.newTask") }
@main struct TaskFireApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store: WorkspaceStore
    init() {
        let arguments = ProcessInfo.processInfo.arguments
        var repository = WorkspaceRepository.standard
        if let index = arguments.firstIndex(of: "--data-file"), arguments.indices.contains(index + 1), arguments[index + 1].hasPrefix("/") { repository = WorkspaceRepository(url: URL(fileURLWithPath: arguments[index + 1])) }
        _store = StateObject(wrappedValue: WorkspaceStore(repository: repository))
    }
    var body: some Scene {
        Window("TaskFire", id: "main") {
            ContentView().environmentObject(store).tint(Theme.accent).environment(\.locale, Locale(identifier: "zh_CN"))
        }
        .defaultSize(width: 1380, height: 920)
        .commands {
            CommandGroup(after: .newItem) { Button("新建自建任务") { NotificationCenter.default.post(name: .taskFireNewTask, object: nil) }.keyboardShortcut("n") }
            CommandMenu("工作台") { Button("同步飞书任务") { Task { await store.sync() } }.keyboardShortcut("r", modifiers: [.command, .shift]); Button("导出本地备份…") { store.exportBackup() } }
        }
        Settings { SettingsView().environmentObject(store).tint(Theme.accent).environment(\.locale, Locale(identifier: "zh_CN")) }
    }
}
