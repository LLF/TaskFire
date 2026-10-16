import Foundation

public struct WorkspaceRepository: Sendable {
    public let url: URL
    public init(url: URL) { self.url = url }
    public static var standard: WorkspaceRepository {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("TaskFire", isDirectory: true)
        return WorkspaceRepository(url: directory.appendingPathComponent("workspace.json"))
    }
    public func load() throws -> WorkspaceState {
        guard FileManager.default.fileExists(atPath: url.path) else { return WorkspaceState() }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let state = try decoder.decode(WorkspaceState.self, from: Data(contentsOf: url))
        guard state.schemaVersion == 1 else { throw WorkspaceError("数据版本不受支持，已保留原文件。") }
        return state
    }
    public func save(_ state: WorkspaceState) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(state).write(to: url, options: .atomic)
    }
}
public struct WorkspaceError: LocalizedError, Sendable {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}
