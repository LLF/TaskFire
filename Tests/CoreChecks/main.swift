import Foundation
import TaskFireCore

struct CheckFailure: Error { let text: String }
func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws { if !condition() { throw CheckFailure(text: message) } }
var failures = 0
@MainActor func check(_ name: String, _ test: () throws -> Void) { do { try test(); print("PASS " + name) } catch { failures += 1; print("FAIL " + name + ": " + String(describing: error)) } }
check("rescheduling leaves deadline unchanged") {
    let due = Date(timeIntervalSince1970: 1_900_000_000)
    var t = WorkTask(title: "任务", dueDate: due); t.planDate = Date()
    try expect(t.dueDate == due, "deadline changed")
}
check("GUID merge preserves personal schedule and notes") {
    var t = WorkTask(id: "feishu:g", title: "旧", source: .feishu, remoteID: "g")
    t.planDate = Date(timeIntervalSince1970: 1_800_000_000); t.notes = "笔记"; t.isFocus = true; t.status = .blocked
    var s = WorkspaceState(tasks: [t])
    let remote = WorkTask(id: "feishu:g", title: "新", source: .feishu, remoteID: "g")
    s.mergeRemote([remote]); s.mergeRemote([remote])
    try expect(s.tasks.count == 1, "duplicate tasks")
    try expect(s.tasks[0].title == "新" && s.tasks[0].notes == "笔记", "lost note or stale title")
    try expect(s.tasks[0].planDate == t.planDate && s.tasks[0].isFocus && s.tasks[0].status == .blocked, "lost personal fields")
}
check("same title from different sources remains separate") {
    var s = WorkspaceState(tasks: [WorkTask(title: "同名")]); s.mergeRemote([WorkTask(id: "feishu:g", title: "同名", source: .feishu, remoteID: "g")])
    try expect(s.tasks.count == 2, "merged unrelated tasks")
}
check("CLI items format and completed boolean") {
    let bytes = Data(#"{"ok":true,"data":{"has_more":false,"items":[{"guid":"g","summary":"任务","due_at":"1800000000000","completed":true,"url":"https://example.com/task"}]}}"#.utf8)
    let tasks = try LarkPayload.tasks(from: bytes)
    try expect(tasks.count == 1 && tasks[0].id == "feishu:g", "missing remote task")
    try expect(tasks[0].dueDate?.timeIntervalSince1970 == 1_800_000_000, "milliseconds parsed incorrectly")
    try expect(tasks[0].isCompleted && tasks[0].completedAt == nil, "invented historical completion date")
}
check("malformed, failed and truncated syncs are rejected") {
    for raw in [#"{"ok":true,"data":{}}"#, #"{"ok":false,"error":{"message":"未授权"}}"#, #"{"ok":true,"data":{"items":[{"summary":"无 GUID"}]}}"#, #"{"ok":true,"data":{"has_more":true,"items":[]}}"#] {
        var rejected = false; do { _ = try LarkPayload.tasks(from: Data(raw.utf8)) } catch { rejected = true }
        try expect(rejected, "invalid response looked successful")
    }
}
check("empty successful sync is allowed") {
    let tasks = try LarkPayload.tasks(from: Data(#"{"ok":true,"data":{"items":[],"has_more":false}}"#.utf8))
    try expect(tasks.isEmpty, "empty sync rejected")
}
check("journal, task and document survive persistence") {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let r = WorkspaceRepository(url: root.appendingPathComponent("workspace.json"))
    var s = WorkspaceState(tasks: [WorkTask(title: "保留任务")]); s.journals["2026-10-16"] = "心得"; s.documents = [KnowledgeDocument(title: "知识", body: "经验")]
    try r.save(s); let loaded = try r.load()
    try expect(loaded.tasks[0].title == "保留任务" && loaded.journals["2026-10-16"] == "心得" && loaded.documents[0].body == "经验", "lost stored data")
    try Data("broken".utf8).write(to: r.url)
    var rejected = false; do { _ = try r.load() } catch { rejected = true }
    try expect(rejected, "corruption silently reset")
}
check("known completion timestamp survives later limited payload") {
    var old = WorkTask(id: "feishu:g", title: "任务", source: .feishu, remoteID: "g"); old.isCompleted = true; old.completedAt = Date(timeIntervalSince1970: 1_800_000_000)
    var incoming = old; incoming.completedAt = nil
    var s = WorkspaceState(tasks: [old]); s.mergeRemote([incoming]); try expect(s.tasks[0].completedAt == old.completedAt, "lost completion history")
}
check("saving stale task editor preserves latest completion and remote fields") {
    var old = WorkTask(id: "feishu:g", title: "旧标题", source: .feishu, remoteID: "g")
    var current = old; current.title = "远端新标题"; current.isCompleted = true; current.completedAt = Date(); current.dueDate = Date(timeIntervalSince1970: 1_900_000_000)
    old.notes = "本机备注"; old.planDate = Date(timeIntervalSince1970: 1_800_000_000)
    var state = WorkspaceState(tasks: [current]); state.saveTaskEdits(old)
    try expect(state.tasks[0].isCompleted && state.tasks[0].title == current.title && state.tasks[0].dueDate == current.dueDate, "stale editor reverted remote state")
    try expect(state.tasks[0].notes == old.notes && state.tasks[0].planDate == old.planDate, "edits lost")
}
check("partial publication keeps reference without claiming full success") {
    var doc = KnowledgeDocument(title: "知识", body: "新正文"); doc.publishedBody = "旧正文"
    doc.recordPublication(reference: "remote", url: nil, sentBody: doc.body, succeeded: false)
    try expect(doc.remoteReference == "remote" && doc.publishedBody == "旧正文", "partial publish marked complete")
    doc.recordPublication(reference: "remote", url: nil, sentBody: doc.body, succeeded: true)
    try expect(doc.publishedBody == "新正文", "complete publication not tracked")
}
print("\(10 - failures)/10 checks passed")
exit(failures == 0 ? 0 : 1)
