import SwiftUI
import TaskFireCore

/// Shared date field for plan browsing and daily journals.
struct DateSelectionField: View {
    let title: String
    @Binding var selection: Date
    var latestDate: Date? = nil
    var hint = "选择日期以查看计划"
    @State private var showingCalendar = false

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
            Button { showingCalendar.toggle() } label: {
                HStack(spacing: 9) {
                    Text(Day.label(selection, format: "yyyy/M/d")).monospacedDigit()
                    Image(systemName: "calendar").foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(title + "，" + Day.label(selection, format: "yyyy 年 M 月 d 日"))
            .popover(isPresented: $showingCalendar, arrowEdge: .bottom) {
                DateCalendarPopover(selection: $selection, latestDate: latestDate, hint: hint) { showingCalendar = false }
            }
            Spacer()
        }
    }
}

/// A roomier date popover with readable type and 36-point day targets.
struct DateCalendarPopover: View {
    @Binding var selection: Date
    let latestDate: Date?
    let hint: String
    let didSelect: () -> Void
    @State private var displayedMonth: Date
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    init(selection: Binding<Date>, latestDate: Date? = nil, hint: String = "选择日期以查看计划", didSelect: @escaping () -> Void) {
        _selection = selection
        self.latestDate = latestDate
        self.hint = hint
        self.didSelect = didSelect
        _displayedMonth = State(initialValue: Calendar.current.dateInterval(of: .month, for: selection.wrappedValue)?.start ?? selection.wrappedValue)
    }

    private var weekdays: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        let symbols = formatter.veryShortStandaloneWeekdaySymbols!
        let offset = calendar.firstWeekday - 1
        return Array(symbols[offset...] + symbols[..<offset])
    }

    private var dates: [Date] {
        let weekday = calendar.component(.weekday, from: displayedMonth)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0 - offset, to: displayedMonth) }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(Day.label(displayedMonth, format: "yyyy 年 M 月"))
                    .font(.system(size: 16, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                monthButton("上个月", symbol: "chevron.left", offset: -1)
                monthButton("下个月", symbol: "chevron.right", offset: 1)
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, day in
                    Text(day).font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary).frame(height: 24)
                }
                ForEach(dates, id: \.self) { day in
                    let selected = calendar.isDate(day, inSameDayAs: selection)
                    let enabled = isSelectable(day)
                    let inMonth = calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month)
                    Button {
                        selection = day
                        didSelect()
                    } label: {
                        Text(calendar.component(.day, from: day).description)
                            .font(.system(size: 14, weight: selected ? .semibold : .regular))
                            .monospacedDigit()
                            .foregroundStyle(selected ? Color.white : (enabled && inMonth ? Color.primary : Color.secondary.opacity(0.35)))
                            .frame(maxWidth: .infinity).frame(height: 36)
                            .background(selected ? Theme.accent : Color.clear, in: RoundedRectangle(cornerRadius: 7))
                            .overlay(alignment: .bottom) {
                                if calendar.isDateInToday(day) {
                                    Circle().fill(selected ? .white : Theme.accent)
                                        .frame(width: 3, height: 3).padding(.bottom, 3)
                                }
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!enabled)
                    .accessibilityLabel(Day.label(day, format: "yyyy 年 M 月 d 日"))
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }
            Divider()
            HStack {
                Text(hint).font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Button("今天") { selection = calendar.startOfDay(for: Date()); didSelect() }
                    .buttonStyle(.bordered).controlSize(.small)
                    .disabled(!isSelectable(Date()))
            }
        }
        .padding(18)
        .frame(width: 330)
    }

    private func isSelectable(_ date: Date) -> Bool {
        latestDate.map { calendar.compare(date, to: $0, toGranularity: .day) != .orderedDescending } ?? true
    }

    private func monthButton(_ title: String, symbol: String, offset: Int) -> some View {
        Button {
            if let month = calendar.date(byAdding: .month, value: offset, to: displayedMonth) { displayedMonth = month }
        } label: {
            Image(systemName: symbol).font(.system(size: 12, weight: .medium)).frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .disabled(calendar.date(byAdding: .month, value: offset, to: displayedMonth).map { !isSelectable($0) } ?? true)
        .accessibilityLabel(title)
        .help(title)
    }
}
