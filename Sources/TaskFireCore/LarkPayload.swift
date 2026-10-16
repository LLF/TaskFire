import Foundation

public enum LarkPayload {
    public static func envelope(_ bytes: Data) throws -> [String: Any] {
        guard let json = try JSONSerialization.jsonObject(with: bytes) as? [String: Any] else { throw WorkspaceError("飞书返回了无法识别的数据。") }
        guard json["ok"] as? Bool == true else {
            let error = json["error"] as? [String: Any]
            throw WorkspaceError((error?["message"] as? String ?? "飞书操作失败") + "\n" + (error?["hint"] as? String ?? "请在设置中检查 lark-cli 登录与权限。"))
        }
        guard let data = json["data"] as? [String: Any] else { throw WorkspaceError("飞书响应缺少 data，未变更本地数据。") }
        return data
    }
    public static func tasks(from bytes: Data) throws -> [WorkTask] {
        let data = try envelope(bytes)
        guard let items = (data["items"] ?? data["tasks"]) as? [[String: Any]] else { throw WorkspaceError("任务响应格式发生变化，未变更本地数据。") }
        guard data["has_more"] as? Bool != true else { throw WorkspaceError("任务数量超出 CLI 分页上限，本次未标记同步成功。") }
        var seen = Set<String>()
        return try items.compactMap { item in
            guard let guid = item["guid"] as? String, !guid.isEmpty, let title = item["summary"] as? String else { throw WorkspaceError("飞书任务缺少 GUID 或标题，已停止同步。") }
            guard seen.insert(guid).inserted else { return nil }
            let dueObject = item["due"] as? [String: Any]
            var task = WorkTask(id: "feishu:" + guid, title: title, source: .feishu, remoteID: guid, dueDate: timestamp(item["due_at"] ?? dueObject?["timestamp"]))
            task.remoteURL = item["url"] as? String; task.description = item["description"] as? String ?? ""
            task.completedAt = timestamp(item["completed_at"])
            task.isCompleted = item["completed"] as? Bool ?? (task.completedAt != nil)
            task.createdAt = timestamp(item["created_at"]) ?? Date()
            return task
        }
    }
    public static func timestamp(_ value: Any?) -> Date? {
        guard let value else { return nil }
        if let string = value as? String {
            if let number = Double(string) { return numericDate(number) }
            let iso = ISO8601DateFormatter()
            if let d = iso.date(from: string) { return d }
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = iso.date(from: string) { return d }
            for format in ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"] { let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = format; if let d = f.date(from: string) { return d } }
        }
        if let n = value as? NSNumber { return numericDate(n.doubleValue) }
        return nil
    }
    private static func numericDate(_ number: Double) -> Date? { guard number > 0 else { return nil }; return Date(timeIntervalSince1970: number > 100_000_000_000 ? number / 1000 : number) }
}
