import SwiftUI
import TaskFireCore

struct TodayView: View {
    @EnvironmentObject var store: WorkspaceStore
    var newTask: () -> Void
    var selectTask: (WorkTask) -> Void
    var selectDocument: (KnowledgeDocument) -> Void
    var showPlans: () -> Void
    var showRecords: (Bool) -> Void
    @State private var source: TaskSource?
    private var today: [WorkTask] { store.state.tasks.filter { $0.isPlanned(on: Date()) } }
    private var focus: [WorkTask] { today.filter { $0.isFocus && !$0.isCompleted } }
    private var remaining: [WorkTask] { today.filter { !( $0.isFocus && !$0.isCompleted ) && (source == nil || $0.source == source) }.sorted { !$0.isCompleted && $1.isCompleted } }
    private var done: Int { today.filter(\.isCompleted).count }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PageHeading(eyebrow: Day.label(Date()), title: "今天，专注重要的事。", subtitle: "安排好节奏，一件一件完成。", action: newTask)
                HStack(spacing: 25) {
                    metric(today.count, "今日任务"); Divider().frame(height: 27); metric(done, "已完成"); Divider().frame(height: 27); metric(today.filter { $0.status == .active && !$0.isCompleted }.count, "进行中")
                    Spacer()
                    VStack(alignment: .leading, spacing: 8) { HStack { Text("今日进度"); Spacer(); Text(today.isEmpty ? "0%" : "\(done * 100 / today.count)%").foregroundStyle(Theme.sage) }.font(.system(size: 10)).foregroundStyle(.secondary); ProgressView(value: Double(done), total: Double(max(today.count, 1))).tint(Theme.sage) }.frame(width: 150)
                }.padding(.vertical, 20).overlay(alignment: .top) { Divider() }.overlay(alignment: .bottom) { Divider() }.padding(.bottom, 30)
                HStack(alignment: .top, spacing: 28) {
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeading(title: "今日重点", symbol: "pin", detail: focus.isEmpty ? "在任务详情中设置重点" : "把精力留给重要的事")
                        TaskRows(tasks: focus, select: selectTask, emptyText: "还没有重点任务。选一件今天最想完成的事。", showsNotes: true)
                            .padding(.horizontal, 16).background(Theme.accent.opacity(0.035), in: RoundedRectangle(cornerRadius: 9)).overlay { RoundedRectangle(cornerRadius: 9).strokeBorder(Theme.accent.opacity(0.15)) }.padding(.bottom, 28)
                        SectionHeading(title: "任务清单", detail: "\(today.count - focus.count)")
                        Picker("任务来源", selection: $source) { Text("全部").tag(nil as TaskSource?); Text("飞书任务").tag(TaskSource.feishu as TaskSource?); Text("自建任务").tag(TaskSource.local as TaskSource?) }.pickerStyle(.segmented).labelsHidden().frame(maxWidth: 300).padding(.bottom, 9)
                        TaskRows(tasks: remaining, select: selectTask, showsNotes: true)
                        Button(action: newTask) { Label("添加一项任务", systemImage: "plus").font(.system(size: 12)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 15) }.buttonStyle(.plain)
                        if today.isEmpty { Button("从任务中安排已有任务") { showPlans() }.buttonStyle(.link) }
                    }.frame(maxWidth: .infinity)
                    Divider()
                    VStack(alignment: .leading, spacing: 27) {
                        VStack(alignment: .leading, spacing: 9) {
                            HStack { SectionHeading(title: "每日心得"); Button("查看全部 ↗") { showRecords(false) }.font(.system(size: 10)).buttonStyle(.plain).foregroundStyle(.secondary) }
                            Text(Day.label(Date(), format: "yyyy.MM.dd · EEEE")).font(.system(size: 10)).foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("给今天留一点记录。").font(.system(size: 13, weight: .semibold))
                                TextEditor(text: Binding(get: { store.journal(Date()) }, set: { store.saveJournal(Date(), text: $0) })).font(.system(size: 12)).lineSpacing(6).scrollContentBackground(.hidden).frame(height: 160).overlay(alignment: .topLeading) { if store.journal(Date()).isEmpty { Text("今天有什么收获、想法或感受？").font(.system(size: 12)).foregroundStyle(.tertiary).padding(.top, 2).padding(.leading, 4).allowsHitTesting(false) } }
                                HStack { Text("自动保存到本机").font(.system(size: 9)).foregroundStyle(.tertiary); Spacer(); Button("沉淀为文档 →") { var doc = KnowledgeDocument(title: "", body: store.journal(Date())); doc.journalDays = [Day.key(Date())]; selectDocument(doc) }.font(.system(size: 10)).buttonStyle(.plain).foregroundStyle(Theme.accent).disabled(store.journal(Date()).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                            }.padding(16).background(Theme.note, in: RoundedRectangle(cornerRadius: 8))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack { SectionHeading(title: "明日计划"); Button(action: showPlans) { Image(systemName: "arrow.right") }.buttonStyle(.plain).foregroundStyle(Theme.accent) }
                            let tomorrow = store.pending.filter { $0.isPlanned(on: Day.tomorrow) }
                            if tomorrow.isEmpty { Text("给明天留一点空白。随时安排新任务。").font(.system(size: 11)).foregroundStyle(.secondary).lineSpacing(5) }
                            ForEach(tomorrow.prefix(3)) { task in Button { selectTask(task) } label: { Label(task.title, systemImage: "calendar").font(.system(size: 11)).lineLimit(1).padding(.vertical, 5) }.buttonStyle(.plain).foregroundStyle(.secondary) }
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            HStack { SectionHeading(title: "最近沉淀"); Button("查看全部 ↗") { showRecords(true) }.font(.system(size: 10)).buttonStyle(.plain).foregroundStyle(.secondary) }
                            if let doc = store.state.documents.sorted(by: { $0.updatedAt > $1.updatedAt }).first {
                                Button { selectDocument(doc) } label: { HStack(alignment: .top, spacing: 10) { Image(systemName: "doc.text").foregroundStyle(Theme.sage); VStack(alignment: .leading, spacing: 6) { Text(doc.title).font(.system(size: 11, weight: .medium)).lineLimit(2); Text(doc.remoteReference == nil ? "本地草稿" : "已关联飞书文档").font(.system(size: 9)).foregroundStyle(.secondary) } } }.buttonStyle(.plain)
                            }
                            Text("有值得留下的经验，再整理成文档。").font(.system(size: 10)).foregroundStyle(.secondary).lineSpacing(5)
                        }
                    }.frame(width: 265)
                }
                Label("计划日期只影响个人安排，不改变飞书任务的截止日期。", systemImage: "checkmark").font(.system(size: 10)).foregroundStyle(.tertiary).padding(.top, 27)
            }.padding(32)
        }
    }
    private func metric(_ number: Int, _ label: String) -> some View { HStack(alignment: .firstTextBaseline, spacing: 8) { Text(number.description).font(.system(size: 25, weight: .medium)).monospacedDigit(); Text(label).font(.system(size: 11)).foregroundStyle(.secondary) } }
}
