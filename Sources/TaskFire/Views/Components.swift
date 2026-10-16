import SwiftUI
import TaskFireCore

enum Theme {
    static let accent = Color(red: 0.80, green: 0.39, blue: 0.24)
    static let sage = Color(red: 0.45, green: 0.56, blue: 0.42)
    static let note = Color.primary.opacity(0.035)
}
struct PageHeading: View {
    var eyebrow: String
    var title: String
    var subtitle: String
    var action: (() -> Void)? = nil
    var actionTitle = "新建任务"
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 10) {
                Text(eyebrow).font(.system(size: 11)).foregroundStyle(.secondary)
                Text(title).font(.system(size: 29, weight: .semibold)).tracking(-0.8)
                Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            if let action { Button(action: action) { Label(actionTitle, systemImage: "plus") }.buttonStyle(.borderedProminent).controlSize(.large) }
        }.padding(.bottom, 24)
    }
}
struct SectionHeading: View {
    var title: String
    var symbol: String? = nil
    var detail = ""
    var body: some View {
        HStack(spacing: 8) {
            if let symbol { Image(systemName: symbol).foregroundStyle(Theme.accent) }
            Text(title).font(.system(size: 13, weight: .semibold))
            if !detail.isEmpty { Text(detail).font(.system(size: 10)).foregroundStyle(.secondary) }
            Spacer()
        }.padding(.bottom, 10)
    }
}
struct SourceBadge: View {
    let source: TaskSource
    var body: some View { Text(source.title).font(.system(size: 9)).foregroundStyle(source == .feishu ? Color.blue : .secondary).padding(.horizontal, 5).padding(.vertical, 3).background(source == .feishu ? Color.blue.opacity(0.08) : Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 4)) }
}
struct TaskRow: View {
    @EnvironmentObject var store: WorkspaceStore
    let task: WorkTask
    let select: (WorkTask) -> Void
    var showsNotes = false
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button { Task { await store.toggle(task) } } label: {
                if store.busyTaskIDs.contains(task.id) { ProgressView().controlSize(.mini) }
                else { Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle").font(.system(size: 18, weight: .light)).foregroundStyle(task.isCompleted ? Theme.sage : Color.secondary.opacity(0.5)) }
            }.buttonStyle(.plain).disabled(store.syncing || store.busyTaskIDs.contains(task.id)).accessibilityLabel(task.isCompleted ? "重新打开任务" : "完成任务")
            Button { select(task) } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title).font(.system(size: 13, weight: .medium)).foregroundStyle(task.isCompleted ? .secondary : .primary).strikethrough(task.isCompleted).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 8) { SourceBadge(source: task.source); Text(task.project); Text("·"); Text(task.dueDate.map { Day.label($0, format: "M/d HH:mm") } ?? "无截止日期").foregroundStyle(task.isOverdue ? Theme.accent : .secondary) }.font(.system(size: 10)).foregroundStyle(.secondary)
                    if showsNotes {
                        let notes = task.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "note.text").font(.system(size: 11)).padding(.top, 2)
                            Text(notes.isEmpty ? "添加备注…" : notes)
                                .font(.system(size: 12)).lineSpacing(3)
                                .lineLimit(2).multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .foregroundStyle(notes.isEmpty ? Color.secondary.opacity(0.65) : Color.secondary)
                        .help(notes.isEmpty ? "点击任务添加备注" : notes)
                    }
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
            if !task.isCompleted && task.status != .pending { Text(task.status.rawValue).font(.system(size: 10)).foregroundStyle(task.status == .blocked ? Theme.accent : Theme.sage) }
            if task.isFocus { Image(systemName: "pin.fill").font(.system(size: 10)).foregroundStyle(Theme.accent.opacity(0.65)) }
        }.padding(.vertical, 17)
        .contextMenu {
            Button(task.isFocus ? "取消今日重点" : "设为今日重点") { var t = task; t.isFocus.toggle(); store.upsert(t) }
            Button("安排到今日") { var t = task; t.planDate = Date(); store.upsert(t) }
            Button("安排到明日") { var t = task; t.planDate = Day.tomorrow; store.upsert(t) }
            Button("暂不安排") { var t = task; t.planDate = nil; store.upsert(t) }
        }
    }
}
struct TaskRows: View {
    let tasks: [WorkTask]
    let select: (WorkTask) -> Void
    var emptyText = "还没有任务，给今天安排一件小事吧。"
    var showsNotes = false
    var body: some View {
        if tasks.isEmpty { Text(emptyText).font(.system(size: 12)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 25) }
        else { LazyVStack(spacing: 0) { ForEach(tasks) { task in TaskRow(task: task, select: select, showsNotes: showsNotes); if task.id != tasks.last?.id { Divider().opacity(0.6) } } } }
    }
}
struct EmptyWorkspace: View {
    var title: String
    var detail: String
    var symbol: String
    var body: some View { VStack(spacing: 14) { Image(systemName: symbol).font(.system(size: 30, weight: .light)).foregroundStyle(Theme.accent.opacity(0.7)); Text(title).font(.headline); Text(detail).font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center) }.padding(36).frame(maxWidth: .infinity) }
}
