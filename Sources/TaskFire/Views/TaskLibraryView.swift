import SwiftUI
import TaskFireCore

struct TaskLibraryView: View {
    @EnvironmentObject var store: WorkspaceStore
    var search: String
    var project: String?
    var newTask: () -> Void
    var selectTask: (WorkTask) -> Void
    @State private var source: TaskSource?
    @State private var onlyPending = false
    private var filtered: [WorkTask] {
        store.state.tasks.filter { t in (source == nil || t.source == source) && (project == nil || t.project == project) && (!onlyPending || !t.isCompleted) && (search.isEmpty || t.title.localizedCaseInsensitiveContains(search) || t.notes.localizedCaseInsensitiveContains(search)) }.sorted { a, b in if a.isCompleted != b.isCompleted { return !a.isCompleted }; return (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture) }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PageHeading(eyebrow: "所有事情，都有落点", title: project ?? "任务", subtitle: "飞书与自建任务，统一查看、独立维护。", action: newTask)
                HStack { Picker("来源", selection: $source) { Text("全部任务").tag(nil as TaskSource?); Text("飞书任务").tag(TaskSource.feishu as TaskSource?); Text("自建任务").tag(TaskSource.local as TaskSource?) }.pickerStyle(.segmented).frame(width: 300); Spacer(); Toggle("仅未完成", isOn: $onlyPending).toggleStyle(.checkbox); Text("\(filtered.count) 项").font(.system(size: 11)).foregroundStyle(.secondary) }.padding(.bottom, 18)
                Divider()
                TaskRows(tasks: filtered, select: selectTask, emptyText: search.isEmpty ? "还没有任务。创建自建任务，或点击工具栏同步飞书。" : "没有找到匹配的任务。")
            }.padding(32)
        }
    }
}
struct PlanView: View {
    @EnvironmentObject var store: WorkspaceStore
    var newTask: (Date) -> Void
    var selectTask: (WorkTask) -> Void
    var openLibrary: () -> Void
    @State private var date = Day.tomorrow
    private var scheduled: [WorkTask] { store.state.tasks.filter { $0.isPlanned(on: date) } }
    private var unscheduled: [WorkTask] { store.pending.filter { $0.planDate == nil } }
    private var carryover: [WorkTask] { store.pending.filter { t in t.planDate.map { Calendar.current.startOfDay(for: $0) < Calendar.current.startOfDay(for: Date()) } == true } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PageHeading(eyebrow: "给接下来的工作，留一点余地", title: "计划", subtitle: "明日、未来和未完成的事情，都可以重新安排。", action: { newTask(date) })
                HStack(alignment: .top, spacing: 35) {
                    VStack(alignment: .leading, spacing: 14) {
                        DateSelectionField(title: "查看日期", selection: $date)
                        SectionHeading(title: Calendar.current.isDate(date, inSameDayAs: Day.tomorrow) ? "明日计划" : Day.label(date, format: "M 月 d 日计划"), detail: "\(scheduled.count) 项")
                        Divider().overlay(Theme.accent.opacity(0.5))
                        TaskRows(tasks: scheduled, select: selectTask, emptyText: "这一天还没有安排。点击任务修改计划日期。")
                        Button(action: openLibrary) { Label("从任务中选择", systemImage: "plus") }.buttonStyle(.plain).foregroundStyle(Theme.accent)
                        Text("安排日期只决定哪天做，不改变交付期限。").font(.system(size: 11)).foregroundStyle(.secondary).padding(16).frame(maxWidth: .infinity, alignment: .leading).background(Theme.note, in: RoundedRectangle(cornerRadius: 7))
                    }.frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeading(title: "待安排", detail: "\(unscheduled.count) 项")
                        Divider(); TaskRows(tasks: unscheduled, select: selectTask, emptyText: "所有任务都有了安排。")
                        if !carryover.isEmpty { SectionHeading(title: "此前未完成", detail: "\(carryover.count) 项").padding(.top, 20); TaskRows(tasks: carryover, select: selectTask) }
                        Text("点击任务查看详情，或右键快速安排到今日 / 明日。").font(.system(size: 10)).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity)
                }
            }.padding(32)
        }
    }
}
