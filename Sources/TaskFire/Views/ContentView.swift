import SwiftUI
import AppKit
import TaskFireCore

enum Destination: Hashable { case today, plan, tasks, projects, records, dashboard
    var title: String { switch self { case .today: "今日"; case .plan: "计划"; case .tasks: "任务"; case .projects: "项目"; case .records: "记录"; case .dashboard: "大盘" } }
}
struct ContentView: View {
    @EnvironmentObject var store: WorkspaceStore
    @State private var selection: Destination? = .today
    @State private var newTask: WorkTask?
    @State private var selectedTask: WorkTask?
    @State private var selectedDocument: KnowledgeDocument?
    @State private var search = ""
    @State private var recordKnowledge = false
    @State private var projectSelection: String?
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) { Image(nsImage: NSApp.applicationIconImage).resizable().interpolation(.high).frame(width: 42, height: 42); Text("TaskFire").font(.system(size: 21, weight: .bold)).tracking(-0.6) }.padding(.horizontal, 19).padding(.top, 18).padding(.bottom, 22)
                List(selection: $selection) {
                    Section("工作空间") {
                        nav("今日", icon: "sun.max", value: .today, count: store.pending.filter { $0.isPlanned(on: Date()) }.count)
                        nav("计划", icon: "calendar", value: .plan, count: store.pending.filter { $0.isPlanned(on: Day.tomorrow) }.count)
                        nav("任务", icon: "checklist", value: .tasks, count: store.state.tasks.count)
                        nav("项目", icon: "square.stack.3d.up", value: .projects, count: store.projects.count)
                        nav("记录", icon: "book.closed", value: .records)
                        nav("大盘", icon: "chart.bar.xaxis", value: .dashboard)
                    }
                }.listStyle(.sidebar)
                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 6) { Circle().fill(store.state.lastSyncAt == nil ? Color.secondary : Theme.sage).frame(width: 5, height: 5); Text(store.state.lastSyncAt == nil ? "飞书尚未同步" : "飞书任务已同步").font(.system(size: 11)) }
                    Text(store.state.lastSyncAt.map { "上次同步 " + Day.label($0, format: "M/d HH:mm") } ?? "通过 lark-cli 连接个人任务").font(.system(size: 10)).foregroundStyle(.secondary)
                    Divider().padding(.vertical, 7)
                    HStack { Image(systemName: "person.crop.circle").font(.title3).foregroundStyle(.secondary); Text("我的工作台").font(.system(size: 12)); Spacer(); SettingsLink { Image(systemName: "gearshape") }.buttonStyle(.plain).help("设置") }
                }.padding(20)
            }.navigationSplitViewColumnWidth(min: 190, ideal: 215, max: 250)
        } detail: {
            VStack(spacing: 0) {
                Group {
                    switch selection ?? .today {
                    case .today: TodayView(newTask: createTask, selectTask: { selectedTask = $0 }, selectDocument: { selectedDocument = $0 }, showPlans: { selection = .plan }, showRecords: { recordKnowledge = $0; selection = .records })
                    case .plan: PlanView(newTask: { createTask(on: $0) }, selectTask: { selectedTask = $0 }, openLibrary: { selection = .tasks })
                    case .tasks: TaskLibraryView(search: search, project: nil, newTask: createTask, selectTask: { selectedTask = $0 })
                    case .projects: ProjectsView(selection: $projectSelection, newTask: { createTask(on: Date(), project: $0) }, selectTask: { selectedTask = $0 })
                    case .records: RecordsView(knowledge: $recordKnowledge, selectDocument: { selectedDocument = $0 })
                    case .dashboard: DashboardView(selectTask: { selectedTask = $0 })
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                Divider()
                HStack(spacing: 6) { Image(systemName: store.storageAvailable ? "checkmark.circle" : "exclamationmark.triangle").foregroundStyle(store.storageAvailable ? Theme.sage : Theme.accent); Text(store.notice ?? (store.storageAvailable ? "本机数据已保存" : "数据文件读取失败，已暂停写入")); Spacer(); Text("个人工作空间") }.font(.system(size: 10)).foregroundStyle(.secondary).padding(.horizontal, 20).frame(height: 28)
            }.navigationTitle(selection?.title ?? "今日")
            .toolbar {
                ToolbarItem(placement: .automatic) { HStack { Image(systemName: "magnifyingglass").foregroundStyle(.secondary); TextField("搜索任务", text: $search).textFieldStyle(.plain).frame(width: 145).onChange(of: search) { _, _ in if !search.isEmpty { selection = .tasks } } } }
                ToolbarItem(placement: .primaryAction) { Button { Task { await store.sync() } } label: { if store.syncing { ProgressView().controlSize(.small) } else { Label("同步飞书", systemImage: "arrow.triangle.2.circlepath") } }.disabled(store.syncing || !store.busyTaskIDs.isEmpty || !store.storageAvailable) }
            }
            .inspector(isPresented: Binding(get: { selectedTask != nil }, set: { if !$0 { selectedTask = nil } })) {
                if let task = selectedTask { TaskEditor(task: task, isNew: false, save: { store.upsert($0); selectedTask = nil }, close: { selectedTask = nil }, distill: { task in var doc = KnowledgeDocument(title: task.title, body: task.notes.isEmpty ? task.description : task.notes); doc.taskIDs = [task.id]; selectedDocument = doc }).id(task.id).inspectorColumnWidth(min: 310, ideal: 350, max: 420) }
            }
        }
        .frame(minWidth: 1050, minHeight: 720)
        .sheet(item: $newTask) { task in TaskEditor(task: task, isNew: true, save: { store.upsert($0); newTask = nil }, close: { newTask = nil }, distill: nil).frame(width: 460, height: 625) }
        .sheet(item: $selectedDocument) { doc in KnowledgeEditor(document: doc).environmentObject(store).frame(width: 720, height: 670) }
        .alert("需要处理", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) { Button("知道了") { store.errorMessage = nil } } message: { Text(store.errorMessage ?? "") }
        .onReceive(NotificationCenter.default.publisher(for: .taskFireNewTask)) { _ in createTask() }
        .onChange(of: selection) { _, _ in selectedTask = nil }
    }
    private func createTask() { createTask(on: selection == .plan ? Day.tomorrow : Date()) }
    private func createTask(on date: Date, project: String? = nil) {
        var task = WorkTask(title: ""); task.planDate = date
        if let project { task.project = project }
        else if selection == .projects { task.project = projectSelection ?? store.projects.first ?? "未分类" }
        newTask = task
    }
    private func nav(_ title: String, icon: String, value: Destination, count: Int? = nil) -> some View { HStack { Label(title, systemImage: icon); Spacer(); if let count { Text(count.description).font(.system(size: 10)).foregroundStyle(.secondary) } }.tag(value).padding(.vertical, 3) }
}
