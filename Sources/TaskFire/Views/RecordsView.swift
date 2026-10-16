import SwiftUI
import TaskFireCore

struct RecordsView: View {
    @EnvironmentObject var store: WorkspaceStore
    @Binding var knowledge: Bool
    var selectDocument: (KnowledgeDocument) -> Void
    @State private var date = Date()
    private var days: [String] { Array(Set(store.state.journals.keys).union([Day.key(Date())])).sorted(by: >) }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageHeading(eyebrow: "记录当下，也积累以后", title: "记录", subtitle: "每天的心得，与值得长期保留的经验。", action: { selectDocument(KnowledgeDocument(title: "", body: "")) }, actionTitle: "新建沉淀")
            Picker("记录类型", selection: $knowledge) { Text("每日心得").tag(false); Text("知识沉淀").tag(true) }.pickerStyle(.segmented).labelsHidden().frame(width: 220).padding(.bottom, 24)
            Divider()
            if knowledge {
                ScrollView {
                    if store.state.documents.isEmpty { EmptyWorkspace(title: "留下值得复用的经验", detail: "从心得或任务中整理，也可以直接新建一篇知识沉淀。", symbol: "doc.text") }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 285), alignment: .top)], alignment: .leading, spacing: 20) {
                        ForEach(store.state.documents.sorted(by: { $0.updatedAt > $1.updatedAt })) { doc in
                            Button { selectDocument(doc) } label: {
                                VStack(alignment: .leading, spacing: 17) {
                                    Image(systemName: "doc.text").font(.system(size: 22, weight: .light)).foregroundStyle(Theme.sage)
                                    Text(doc.title.isEmpty ? "未命名沉淀" : doc.title).font(.system(size: 15, weight: .semibold)).lineLimit(2)
                                    Text(doc.body.isEmpty ? "继续整理你的想法…" : doc.body).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(3).lineSpacing(5).frame(maxWidth: .infinity, minHeight: 65, alignment: .topLeading)
                                    HStack { Text(doc.remoteReference == nil ? "本机草稿" : "已关联飞书"); Spacer(); Text(Day.label(doc.updatedAt, format: "M/d")) }.font(.system(size: 10)).foregroundStyle(.secondary)
                                }.padding(23).background(Theme.note, in: RoundedRectangle(cornerRadius: 8)).overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(Color.primary.opacity(0.07)) }
                            }.buttonStyle(.plain)
                        }
                    }.padding(.top, 22)
                }
            } else {
                HStack(alignment: .top, spacing: 28) {
                    ScrollView {
                        VStack(spacing: 7) { ForEach(days, id: \.self) { key in Button { if let day = Day.date(key) { date = day } } label: { VStack(alignment: .leading, spacing: 8) { Text(Day.date(key).map { Day.label($0) } ?? key).font(.system(size: 10)).foregroundStyle(.secondary); Text(store.state.journals[key]?.split(separator: "\n").first.map(String.init) ?? "给今天留一点记录").font(.system(size: 12, weight: .medium)).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading) }.padding(14).background(Day.key(date) == key ? Theme.note : .clear, in: RoundedRectangle(cornerRadius: 6)) }.buttonStyle(.plain) } }.padding(.top, 20)
                    }.frame(width: 205)
                    Divider()
                    VStack(alignment: .leading, spacing: 19) {
                        DateSelectionField(title: "记录日期", selection: $date, latestDate: Date(), hint: "选择日期以查看心得")
                        Text(Day.label(date, format: "yyyy 年 M 月 d 日 · EEEE")).font(.system(size: 21, weight: .semibold))
                        TextEditor(text: Binding(get: { store.journal(date) }, set: { store.saveJournal(date, text: $0) })).font(.system(size: 14)).lineSpacing(8).scrollContentBackground(.hidden).frame(maxHeight: .infinity)
                            .overlay(alignment: .topLeading) { if store.journal(date).isEmpty { Text("今天有什么收获？遇到了什么问题？\n把值得记住的想法写在这里。 ").font(.system(size: 13)).lineSpacing(8).foregroundStyle(.tertiary).padding(.top, 4).allowsHitTesting(false) } }
                        Divider()
                        HStack { Text("自动保存到本机 · 不自动生成飞书文档").font(.system(size: 10)).foregroundStyle(.secondary); Spacer(); Button("整理为知识文档 →") { var doc = KnowledgeDocument(title: "", body: store.journal(date)); doc.journalDays = [Day.key(date)]; selectDocument(doc) }.disabled(store.journal(date).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                    }.padding(.top, 25)
                }
            }
        }.padding(32)
    }
}
