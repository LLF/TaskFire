import SwiftUI
import Charts
import TaskFireCore

struct DashboardView: View {
    @EnvironmentObject var store: WorkspaceStore
    var selectTask: (WorkTask) -> Void
    private var days: [Date] { (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0 - 6, to: Calendar.current.startOfDay(for: Date())) } }
    private var completedWeek: Int { store.state.tasks.filter { task in task.completedAt.map { $0 >= days[0] && $0 <= Date() } == true }.count }
    private var attention: [WorkTask] { store.pending.filter { $0.isOverdue || $0.status == .blocked } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                PageHeading(eyebrow: "最近 7 天 · " + Day.label(Date(), format: "yyyy 年 M 月"), title: "工作大盘", subtitle: "看见进展，也看见需要重新安排的事情。")
                HStack(spacing: 45) { metric(completedWeek, "近 7 天完成"); metric(store.pending.count, "未完成"); metric(store.pending.filter(\.isOverdue).count, "已逾期"); metric(store.pending.filter { $0.status == .blocked }.count, "阻塞中"); Spacer() }.padding(.vertical, 20).overlay(alignment: .top) { Divider() }.overlay(alignment: .bottom) { Divider() }
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeading(title: "每日完成趋势")
                    Chart(days, id: \.self) { day in
                        let count = store.state.tasks.filter { t in t.completedAt.map { Calendar.current.isDate($0, inSameDayAs: day) } == true }.count
                        BarMark(x: .value("日期", Day.label(day, format: "E d")), y: .value("完成数", count), width: .ratio(0.45)).foregroundStyle(Calendar.current.isDateInToday(day) ? Theme.accent : Theme.sage.opacity(0.45)).cornerRadius(4)
                    }.chartYScale(domain: 0...max(5, store.state.tasks.count)).frame(height: 220)
                    Text("按实际完成时间统计；飞书未提供完成时间的历史任务不计入每日趋势。").font(.system(size: 10)).foregroundStyle(.secondary)
                }.padding(24).background(Theme.note, in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 0) { SectionHeading(title: "需要关注", detail: "\(attention.count) 项"); TaskRows(tasks: attention, select: selectTask, emptyText: "目前没有逾期或阻塞任务。") }
            }.padding(32)
        }
    }
    private func metric(_ count: Int, _ title: String) -> some View { HStack(alignment: .firstTextBaseline, spacing: 9) { Text(count.description).font(.system(size: 28, weight: .medium)); Text(title).font(.system(size: 11)).foregroundStyle(.secondary) } }
}
