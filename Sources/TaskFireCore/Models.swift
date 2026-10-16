import Foundation

public enum TaskSource: String, Codable, CaseIterable, Sendable { case local, feishu
    public var title: String { self == .local ? "自建" : "飞书" }
}
public enum ExecutionStatus: String, Codable, CaseIterable, Sendable { case pending = "待开始", active = "进行中", blocked = "阻塞中" }
public struct WorkTask: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var source: TaskSource
    public var remoteID: String?
    public var remoteURL: String?
    public var description: String
    public var project: String
    public var planDate: Date?
    public var dueDate: Date?
    public var isFocus: Bool
    public var status: ExecutionStatus
    public var isCompleted: Bool
    public var completedAt: Date?
    public var notes: String
    public var createdAt: Date
    public init(id: String = UUID().uuidString, title: String, source: TaskSource = .local, remoteID: String? = nil, dueDate: Date? = nil) {
        self.id = id; self.title = title; self.source = source; self.remoteID = remoteID; self.dueDate = dueDate
        remoteURL = nil; description = ""; project = "未分类"; planDate = nil; isFocus = false; status = .pending
        isCompleted = false; completedAt = nil; notes = ""; createdAt = Date()
    }
    public func isPlanned(on date: Date) -> Bool { planDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false }
    public var isOverdue: Bool { !isCompleted && dueDate.map { $0 < Date() } == true }
}
public struct KnowledgeDocument: Identifiable, Codable, Equatable, Sendable {
    public var id: String = UUID().uuidString
    public var title: String
    public var body: String
    public var taskIDs: [String] = []
    public var journalDays: [String] = []
    public var remoteReference: String?
    public var remoteURL: String?
    public var publishedBody: String = ""
    public var updatedAt: Date = Date()
    public init(title: String = "未命名沉淀", body: String = "") { self.title = title; self.body = body }
    public mutating func recordPublication(reference: String, url: String?, sentBody: String, succeeded: Bool) {
        remoteReference = reference; remoteURL = url ?? remoteURL
        if succeeded { publishedBody = sentBody }
    }
}
public struct LarkSettings: Codable, Equatable, Sendable {
    public var executablePath = "/opt/homebrew/bin/lark-cli"
    public var parentToken = ""
    public init() {}
}
public enum Day {
    public static func key(_ date: Date) -> String { let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date) }
    public static func date(_ key: String) -> Date? { let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"; return f.date(from: key) }
    public static var tomorrow: Date { Calendar.current.date(byAdding: .day, value: 1, to: Date())! }
    public static func label(_ date: Date, format: String = "M 月 d 日，EEEE") -> String { let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); f.dateFormat = format; return f.string(from: date) }
}
