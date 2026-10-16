import SwiftUI
import TaskFireCore

struct TaskEditor: View {
    @State var task: WorkTask
    var isNew: Bool
    var save: (WorkTask) -> Void
    var close: () -> Void
    var distill: ((WorkTask) -> Void)?
    @EnvironmentObject var store: WorkspaceStore
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack { Text(isNew ? "新建自建任务" : "任务详情").font(.system(size: 18, weight: .semibold)); Spacer(); Button(action: close) { Image(systemName: "xmark") }.buttonStyle(.plain).foregroundStyle(.secondary) }.padding(22)
            Divider()
            Form {
                Section("任务") {
                    TextField("任务名称", text: $task.title, axis: .vertical).lineLimit(1...4).disabled(task.source == .feishu)
                    HStack { Text("来源"); Spacer(); SourceBadge(source: task.source) }
                    ProjectPicker(selection: $task.project)
                    Picker("执行状态", selection: $task.status) { ForEach(ExecutionStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                    Toggle("设为今日重点", isOn: $task.isFocus)
                }
                Section("安排") {
                    Toggle("设置计划日期", isOn: Binding(get: { task.planDate != nil }, set: { task.planDate = $0 ? Date() : nil }))
                    if task.planDate != nil { DatePicker("计划日期", selection: Binding(get: { task.planDate ?? Date() }, set: { task.planDate = $0 }), displayedComponents: .date) }
                    if task.source == .local {
                        Toggle("设置截止日期", isOn: Binding(get: { task.dueDate != nil }, set: { task.dueDate = $0 ? Date() : nil }))
                        if task.dueDate != nil { DatePicker("截止日期", selection: Binding(get: { task.dueDate ?? Date() }, set: { task.dueDate = $0 })) }
                    } else { LabeledContent("飞书截止日期", value: task.dueDate.map { Day.label($0, format: "M/d HH:mm") } ?? "未设置") }
                }
                Section(task.source == .feishu ? "个人备注（仅本机）" : "描述与备注") { TextEditor(text: $task.notes).frame(minHeight: 100).font(.system(size: 12)) }
                if task.source == .feishu, let url = task.remoteURL.flatMap(URL.init(string:)) { Section { Link("在飞书查看原任务 ↗", destination: url) } }
                if let distill { Section { Button { distill(task) } label: { Label("将经验整理为知识文档", systemImage: "doc.text") }.disabled(task.notes.isEmpty && task.description.isEmpty) } }
            }.formStyle(.grouped)
            Divider()
            HStack { Button("取消", action: close).keyboardShortcut(.cancelAction); Spacer(); Button(isNew ? "创建任务" : "保存安排") { task.title = task.title.trimmingCharacters(in: .whitespacesAndNewlines); if task.project.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { task.project = "未分类" }; save(task) }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction).disabled(task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !store.storageAvailable) }.padding(18)
        }
    }
}
