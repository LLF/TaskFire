import SwiftUI
import TaskFireCore

struct ProjectsView: View {
    @EnvironmentObject var store: WorkspaceStore
    @Binding var selection: String?
    var newTask: (String) -> Void
    var selectTask: (WorkTask) -> Void
    @State private var creatingProject = false
    @State private var source: TaskSource?
    @State private var onlyPending = false
    private var current: String { selection ?? store.projects.first ?? "未分类" }
    private var projectTasks: [WorkTask] { store.state.tasks.filter { $0.project == current } }
    private var visibleTasks: [WorkTask] {
        projectTasks.filter { (source == nil || $0.source == source) && (!onlyPending || !$0.isCompleted) }
            .sorted { a, b in
                if a.isCompleted != b.isCompleted { return !a.isCompleted }
                return (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture)
            }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageHeading(eyebrow: "让相关的事情，聚在一起", title: "项目", subtitle: "按项目查看任务，飞书与自建任务都可以归类。", action: { creatingProject = true }, actionTitle: "新建项目")
            Divider()
            HStack(alignment: .top, spacing: 26) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("我的项目 · \(store.projects.count)").font(.system(size: 11)).foregroundStyle(.secondary).padding(.horizontal, 12).padding(.bottom, 8)
                        ForEach(store.projects, id: \.self) { project in projectRow(project, symbol: "folder") }
                        if store.projects.isEmpty {
                            Text("先建一个项目，或在任务详情中为任务选择项目。")
                                .font(.system(size: 11)).foregroundStyle(.secondary).lineSpacing(5).padding(12)
                        }
                        Divider().padding(.vertical, 10)
                        projectRow("未分类", symbol: "tray")
                    }.padding(.vertical, 22)
                }.frame(width: 210)
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 9) {
                                Text(current).font(.system(size: 23, weight: .semibold)).lineLimit(2)
                                Text("\(projectTasks.count) 项任务 · \(projectTasks.filter { !$0.isCompleted }.count) 项未完成 · \(projectTasks.filter(\.isCompleted).count) 项已完成")
                                    .font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button { newTask(current) } label: { Label("新建任务", systemImage: "plus") }
                                .buttonStyle(.borderedProminent)
                        }.padding(.bottom, 23)
                        HStack {
                            Picker("任务来源", selection: $source) {
                                Text("全部").tag(nil as TaskSource?)
                                Text("飞书任务").tag(TaskSource.feishu as TaskSource?)
                                Text("自建任务").tag(TaskSource.local as TaskSource?)
                            }.pickerStyle(.segmented).labelsHidden().frame(maxWidth: 260)
                            Spacer()
                            Toggle("仅未完成", isOn: $onlyPending).toggleStyle(.checkbox).font(.system(size: 11))
                        }.padding(.bottom, 15)
                        Divider()
                        TaskRows(tasks: visibleTasks, select: selectTask, emptyText: projectTasks.isEmpty ? "这个项目还没有任务。新建任务会自动选中当前项目，也可以从任务详情中归类已有任务。" : "当前筛选下没有任务。")
                    }.padding(.top, 25)
                }
            }
        }
        .padding(32)
        .sheet(isPresented: $creatingProject) { NewProjectSheet { selection = $0 } }
    }
    private func projectRow(_ project: String, symbol: String) -> some View {
        let count = store.state.tasks.filter { $0.project == project && !$0.isCompleted }.count
        return Button { selection = project } label: {
            HStack(spacing: 9) {
                Image(systemName: symbol).foregroundStyle(current == project ? Theme.accent : .secondary)
                Text(project).font(.system(size: 12, weight: current == project ? .semibold : .regular)).lineLimit(2)
                Spacer()
                Text(count.description).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(current == project ? Theme.note : .clear, in: RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(project + "，" + count.description + " 项未完成")
        .accessibilityAddTraits(current == project ? [.isSelected] : [])
    }
}
