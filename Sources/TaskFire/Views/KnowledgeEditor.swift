import SwiftUI
import TaskFireCore

struct KnowledgeEditor: View {
    @EnvironmentObject var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss
    @State var document: KnowledgeDocument
    @State private var linkExisting = false
    @State private var existingReference = ""
    private var busy: Bool { store.publishingIDs.contains(document.id) }
    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack { Label("知识沉淀", systemImage: "doc.text").font(.system(size: 14, weight: .semibold)); Spacer(); Text(document.remoteReference == nil ? "本机草稿" : "已关联飞书文档").font(.system(size: 10)).foregroundStyle(.secondary) }
            TextField("给这篇沉淀起个名字", text: $document.title).textFieldStyle(.plain).font(.system(size: 23, weight: .semibold))
            HStack {
                if !document.journalDays.isEmpty { Label(document.journalDays.joined(separator: "、"), systemImage: "book.closed").font(.system(size: 10)).foregroundStyle(.secondary) }
                Menu {
                    if store.state.tasks.isEmpty { Text("创建任务后可以在此关联") }
                    ForEach(store.state.tasks) { task in Button { if document.taskIDs.contains(task.id) { document.taskIDs.removeAll { $0 == task.id } } else { document.taskIDs.append(task.id) }; persist() } label: { Label(task.title, systemImage: document.taskIDs.contains(task.id) ? "checkmark.circle.fill" : "circle") } }
                } label: { Label("关联任务（\(document.taskIDs.count)）", systemImage: "link") }.menuStyle(.borderlessButton).fixedSize()
                Spacer()
            }
            Divider()
            TextEditor(text: $document.body).font(.system(size: 14)).lineSpacing(7).scrollContentBackground(.hidden).frame(maxHeight: .infinity).overlay(alignment: .topLeading) { if document.body.isEmpty { Text("记录问题、方法和收获，支持 Markdown。 ").foregroundStyle(.tertiary).padding(.top, 3).allowsHitTesting(false) } }
            if document.remoteReference == nil { Toggle("关联已有飞书文档", isOn: $linkExisting).font(.system(size: 11)) }
            if linkExisting || document.remoteReference != nil {
                HStack {
                    TextField("飞书文档 URL 或 token（可修改）", text: $existingReference).textFieldStyle(.roundedBorder)
                    if document.remoteReference != nil { Button("解除关联") { document.remoteReference = nil; document.remoteURL = nil; document.publishedBody = ""; existingReference = ""; linkExisting = false; persist() }.font(.system(size: 11)) }
                }
            }
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4) { Text("草稿自动保存到本机").font(.system(size: 10)); Text(document.remoteReference != nil || linkExisting ? "追加当前版本到文末，保留云端已有内容。" : "仅在点击发布后创建飞书文档。").font(.system(size: 10)) }.foregroundStyle(.secondary)
                Spacer()
                if let url = document.remoteURL.flatMap(URL.init(string:)) { Link("打开飞书 ↗", destination: url).font(.system(size: 11)) }
                Button("完成") { persist(); dismiss() }.keyboardShortcut(.cancelAction)
                Button {
                    if linkExisting || document.remoteReference != nil {
                        let target = existingReference.trimmingCharacters(in: .whitespacesAndNewlines)
                        if target != document.remoteReference { document.publishedBody = ""; document.remoteURL = nil }
                        document.remoteReference = target
                    }
                    persist()
                    Task { await store.publish(document.id); refreshRemoteFields() }
                } label: { if busy { ProgressView().controlSize(.small) } else { Text(document.remoteReference != nil || linkExisting ? "追加到飞书" : "发布到飞书") } }.buttonStyle(.borderedProminent).disabled(busy || document.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || document.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || ((linkExisting || document.remoteReference != nil) && existingReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) || !store.storageAvailable)
            }
        }.padding(28).disabled(busy)
        .onChange(of: document.title) { _, _ in persist() }
        .onChange(of: document.body) { _, _ in persist() }
        .onAppear { if let ref = document.remoteReference { existingReference = ref }; persist() }
    }
    private func persist() { if !document.title.isEmpty || !document.body.isEmpty || store.state.documents.contains(where: { $0.id == document.id }) { store.saveDocument(document) } }
    private func refreshRemoteFields() { if let saved = store.state.documents.first(where: { $0.id == document.id }) { document.remoteReference = saved.remoteReference; document.remoteURL = saved.remoteURL; document.publishedBody = saved.publishedBody } }
}
