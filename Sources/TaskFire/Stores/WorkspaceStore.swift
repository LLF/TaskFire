import SwiftUI
import TaskFireCore

@MainActor final class WorkspaceStore: ObservableObject {
    @Published private(set) var state: WorkspaceState
    @Published var errorMessage: String?
    @Published var notice: String?
    @Published private(set) var syncing = false
    @Published private(set) var busyTaskIDs: Set<String> = []
    @Published private(set) var publishingIDs: Set<String> = []
    @Published private(set) var storageAvailable = true
    let repository: WorkspaceRepository
    let lark = LarkClient()
    init(repository: WorkspaceRepository = .standard) {
        self.repository = repository
        do { state = try repository.load() }
        catch { state = WorkspaceState(); storageAvailable = false; errorMessage = "本地数据无法读取，已保留原文件，暂停写入以免覆盖。请先备份并检查：\n" + repository.url.path + "\n" + error.localizedDescription }
    }
    var projects: [String] { state.projects }
    func createProject(_ name: String) throws -> String {
        guard storageAvailable else { throw WorkspaceError("本地数据不可写，暂时无法创建项目。") }
        let project = try state.addProject(name)
        commit()
        return project
    }
    var pending: [WorkTask] { state.tasks.filter { !$0.isCompleted } }
    func commit() {
        guard storageAvailable else { errorMessage = "本地数据文件读取失败，当前暂停保存。请先备份并修复原文件。"; return }
        do { try repository.save(state) } catch { errorMessage = "保存失败：" + error.localizedDescription }
    }
    func upsert(_ task: WorkTask) {
        guard storageAvailable else { commit(); return }
        state.saveTaskEdits(task)
        commit()
    }
    func toggle(_ task: WorkTask) async {
        guard storageAvailable, !busyTaskIDs.contains(task.id) else { return }
        busyTaskIDs.insert(task.id); defer { busyTaskIDs.remove(task.id) }
        do {
            if task.source == .feishu { try await lark.complete(task, settings: state.settings) }
            guard let index = state.tasks.firstIndex(where: { $0.id == task.id }) else { return }
            state.tasks[index].isCompleted = !task.isCompleted
            state.tasks[index].completedAt = task.isCompleted ? nil : Date()
            commit()
            notice = task.source == .feishu ? "飞书任务状态已同步" : "任务状态已保存"
        } catch { errorMessage = error.localizedDescription }
    }
    func sync() async {
        guard !syncing, storageAvailable, busyTaskIDs.isEmpty else { return }
        syncing = true; defer { syncing = false }
        do {
            let tasks = try await lark.fetchTasks(settings: state.settings)
            state.mergeRemote(tasks); state.lastSyncAt = Date(); commit(); notice = "已获取 \(tasks.count) 项飞书任务"
        } catch { errorMessage = error.localizedDescription }
    }
    func journal(_ day: Date) -> String { state.journals[Day.key(day)] ?? "" }
    func saveJournal(_ day: Date, text: String) { guard storageAvailable else { return }; let key = Day.key(day); if text.isEmpty { state.journals.removeValue(forKey: key) } else { state.journals[key] = text }; commit() }
    func saveDocument(_ document: KnowledgeDocument) {
        guard storageAvailable else { commit(); return }
        var document = document; document.updatedAt = Date()
        if let i = state.documents.firstIndex(where: { $0.id == document.id }) { state.documents[i] = document } else { state.documents.insert(document, at: 0) }
        commit()
    }
    func publish(_ id: String) async {
        guard storageAvailable, !publishingIDs.contains(id), let doc = state.documents.first(where: { $0.id == id }) else { return }
        guard doc.body != doc.publishedBody || doc.remoteReference == nil else { notice = "内容没有变化，无需重复发布"; return }
        publishingIDs.insert(id); defer { publishingIDs.remove(id) }
        do {
            let receipt = try await lark.publish(doc, settings: state.settings)
            guard let i = state.documents.firstIndex(where: { $0.id == id }) else { return }
            state.documents[i].recordPublication(reference: receipt.reference, url: receipt.url, sentBody: doc.body, succeeded: receipt.succeeded)
            commit()
            if receipt.succeeded { notice = receipt.warning ?? "已保存到飞书文档" }
            else { errorMessage = receipt.warning ?? "飞书未完整写入内容，请先打开文档核对，再决定是否重试。" }
        } catch { errorMessage = error.localizedDescription + "\n写入结果若不确定，请先在飞书检查，避免重复提交。" }
    }
    func saveSettings(_ settings: LarkSettings) { state.settings = settings; commit() }
    func exportBackup() {
        let panel = NSSavePanel(); panel.nameFieldStringValue = "TaskFire-" + Day.key(Date()) + ".json"
        if panel.runModal() == .OK, let url = panel.url { do { let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; encoder.outputFormatting = [.prettyPrinted]; try encoder.encode(state).write(to: url, options: .atomic) } catch { errorMessage = error.localizedDescription } }
    }
}
