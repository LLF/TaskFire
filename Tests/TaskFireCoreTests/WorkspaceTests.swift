import XCTest
@testable import TaskFireCore
final class WorkspaceTests: XCTestCase {
    func testReschedulingDoesNotChangeDeadline() {
        let deadline = Date(timeIntervalSince1970: 1_900_000_000)
        var task = WorkTask(title: "交付", dueDate: deadline)
        task.planDate = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertEqual(task.dueDate, deadline)
    }
    func testRemoteMergeIsIdempotentAndPreservesPersonalFields() {
        var local = WorkTask(id: "feishu:guid", title: "旧标题", source: .feishu, remoteID: "guid")
        local.planDate = Date(timeIntervalSince1970: 1_800_000_000)
        local.notes = "等待反馈"; local.isFocus = true
        var state = WorkspaceState(tasks: [local, WorkTask(title: "自建")])
        let remote = WorkTask(id: "feishu:guid", title: "新标题", source: .feishu, remoteID: "guid")
        state.mergeRemote([remote]); state.mergeRemote([remote])
        XCTAssertEqual(state.tasks.count, 2)
        XCTAssertEqual(state.tasks[0].title, "新标题")
        XCTAssertEqual(state.tasks[0].planDate, local.planDate)
        XCTAssertEqual(state.tasks[0].notes, "等待反馈")
        XCTAssertTrue(state.tasks[0].isFocus)
    }
    func testSameTitleDoesNotCollapseDifferentSources() {
        var state = WorkspaceState(tasks: [WorkTask(title: "同名")])
        state.mergeRemote([WorkTask(id: "feishu:g", title: "同名", source: .feishu, remoteID: "g")])
        XCTAssertEqual(state.tasks.count, 2)
    }
    func testTaskPayloadParsesMillisecondsAndCompletion() throws {
        let json = Data(#"{"ok":true,"data":{"tasks":[{"guid":"g","summary":"任务","due":{"timestamp":"1800000000000"},"completed_at":"1800000001000"}]}}"#.utf8)
        let result = try LarkPayload.tasks(from: json)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, "feishu:g")
        XCTAssertEqual(result[0].dueDate?.timeIntervalSince1970, 1_800_000_000)
        XCTAssertNotNil(result[0].completedAt)
    }
    func testInvalidPayloadCannotLookLikeSuccessfulEmptySync() {
        for text in [#"{"ok":true,"data":{}}"#, #"{"ok":false,"error":{"message":"未登录"}}"#, #"{"ok":true,"data":{"tasks":[{"summary":"缺少 GUID"}]}}"#] {
            XCTAssertThrowsError(try LarkPayload.tasks(from: Data(text.utf8)))
        }
    }
    func testRepositoryRoundTripAndCorruptionProtection() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = WorkspaceRepository(url: root.appendingPathComponent("workspace.json"))
        var state = WorkspaceState(tasks: [WorkTask(title: "长期保留")])
        state.journals["2026-10-16"] = "今日心得"
        state.documents = [KnowledgeDocument(title: "经验", body: "内容")]
        try repository.save(state)
        let loaded = try repository.load()
        XCTAssertEqual(loaded.tasks[0].title, "长期保留")
        XCTAssertEqual(loaded.journals["2026-10-16"], "今日心得")
        XCTAssertEqual(loaded.documents[0].body, "内容")
        try Data("broken".utf8).write(to: repository.url)
        XCTAssertThrowsError(try repository.load())
    }
    func testProjectCanExistWithoutTasksAndSurvivesSaving() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = WorkspaceRepository(url: root.appendingPathComponent("workspace.json"))
        var state = WorkspaceState()
        XCTAssertEqual(try state.addProject("  TaskFire  "), "TaskFire")
        XCTAssertEqual(try state.addProject("taskfire"), "TaskFire")
        XCTAssertEqual(state.projects, ["TaskFire"])
        try repository.save(state)
        XCTAssertEqual(try repository.load().projects, ["TaskFire"])
        XCTAssertThrowsError(try state.addProject("   "))
        XCTAssertThrowsError(try state.addProject("未分类"))
    }
    func testLegacyWorkspaceWithoutProjectCatalogKeepsTaskProjects() throws {
        var local = WorkTask(title: "自建任务"); local.project = "产品迭代"
        var remote = WorkTask(id: "feishu:g", title: "飞书任务", source: .feishu, remoteID: "g"); remote.project = "产品迭代"
        let state = WorkspaceState(tasks: [local, remote])
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(state)) as? [String: Any])
        json.removeValue(forKey: "savedProjects")
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let legacy = try decoder.decode(WorkspaceState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(legacy.projects, ["产品迭代"])
        XCTAssertEqual(legacy.tasks.count, 2)
    }
    func testAssigningProjectsIncludesBothTaskSources() throws {
        var state = WorkspaceState(tasks: [WorkTask(title: "自建"), WorkTask(id: "feishu:g", title: "飞书", source: .feishu, remoteID: "g")])
        let project = try state.addProject("交付")
        for var task in state.tasks { task.project = project; state.saveTaskEdits(task) }
        XCTAssertEqual(state.tasks.filter { $0.project == project }.count, 2)
        XCTAssertEqual(state.tasks[1].remoteID, "g")
    }

    func testLegacyProjectRemainsWhenLastTaskMovesAway() throws {
        for explicitlyCreated in [false, true] {
            var task = WorkTask(title: "原有任务"); task.project = "旧项目"
            var state = WorkspaceState(tasks: [task])
            if explicitlyCreated { _ = try state.addProject("旧项目") }
            task.project = "新项目"; state.saveTaskEdits(task)
            XCTAssertTrue(state.projects.contains("旧项目"))
            XCTAssertTrue(state.projects.contains("新项目"))
        }
    }

}
