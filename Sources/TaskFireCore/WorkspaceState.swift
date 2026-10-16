import Foundation

public struct WorkspaceState: Codable, Sendable {
    public var schemaVersion = 1
    public var tasks: [WorkTask]
    public var savedProjects: [String]? = nil
    public var journals: [String: String] = [:]
    public var documents: [KnowledgeDocument] = []
    public var settings = LarkSettings()
    public var lastSyncAt: Date?
    public init(tasks: [WorkTask] = []) { self.tasks = tasks }
    public var projects: [String] {
        Array(Set((savedProjects ?? []) + tasks.map(\.project)))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0 != "未分类" }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
    @discardableResult public mutating func addProject(_ rawName: String) throws -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw WorkspaceError("请输入项目名称。") }
        guard name != "未分类" else { throw WorkspaceError("“未分类”用于尚未选择项目的任务，请换一个项目名称。") }
        if let existing = projects.first(where: { $0.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
            if !(savedProjects ?? []).contains(existing) { savedProjects = (savedProjects ?? []) + [existing] }
            return existing
        }
        savedProjects = (savedProjects ?? []) + [name]
        return name
    }
    public mutating func saveTaskEdits(_ edited: WorkTask) {
        savedProjects = projects
        guard let index = tasks.firstIndex(where: { $0.id == edited.id }) else { tasks.append(edited); return }
        var current = tasks[index]
        current.planDate = edited.planDate; current.notes = edited.notes; current.project = edited.project
        current.isFocus = edited.isFocus; current.status = edited.status
        if current.source == .local { current.title = edited.title; current.description = edited.description; current.dueDate = edited.dueDate }
        tasks[index] = current
    }
    public mutating func mergeRemote(_ incoming: [WorkTask]) {
        for remote in incoming {
            if let index = tasks.firstIndex(where: { $0.source == .feishu && $0.remoteID == remote.remoteID }) {
                let personal = tasks[index]
                var merged = remote
                merged.id = personal.id; merged.planDate = personal.planDate; merged.notes = personal.notes
                merged.isFocus = personal.isFocus; merged.status = personal.status; merged.project = personal.project
                if merged.isCompleted && merged.completedAt == nil && personal.isCompleted { merged.completedAt = personal.completedAt }
                tasks[index] = merged
            } else { tasks.append(remote) }
        }
    }
}
