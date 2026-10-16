import SwiftUI
import TaskFireCore

struct ProjectPicker: View {
    @EnvironmentObject var store: WorkspaceStore
    @Binding var selection: String
    @State private var creatingProject = false
    private var names: [String] {
        Array(Set(store.projects + (selection == "未分类" ? [] : [selection]))).sorted()
    }
    var body: some View {
        HStack {
            Picker("所属项目", selection: $selection) {
                Text("未分类").tag("未分类")
                ForEach(names, id: \.self) { Text($0).tag($0) }
            }
            Button { creatingProject = true } label: { Image(systemName: "plus") }
                .buttonStyle(.borderless).help("新建项目").accessibilityLabel("新建项目")
        }
        .sheet(isPresented: $creatingProject) { NewProjectSheet { selection = $0 } }
    }
}

struct NewProjectSheet: View {
    @EnvironmentObject var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var validationMessage: String?
    @FocusState private var nameFocused: Bool
    var created: (String) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("新建项目").font(.system(size: 19, weight: .semibold))
            Text("把同一件事情的任务放在一起，也可以先建项目再添加任务。")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            TextField("项目名称", text: $name).textFieldStyle(.roundedBorder)
                .focused($nameFocused).onSubmit(create)
            if let validationMessage { Text(validationMessage).font(.caption).foregroundStyle(Theme.accent) }
            HStack {
                Button("取消") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("创建项目", action: create).buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !store.storageAvailable)
            }
        }.padding(26).frame(width: 420).onAppear { nameFocused = true }
    }
    private func create() {
        do { let project = try store.createProject(name); created(project); dismiss() }
        catch { validationMessage = error.localizedDescription }
    }
}
