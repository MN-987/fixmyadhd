import AppKit
import SwiftUI

struct TaskItem: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
}

enum NotePage {
    case tasks
    case later
    case done
}

private struct SavedState: Codable {
    var tasks: [TaskItem]
    var later: [TaskItem]
    var done: [TaskItem]?
    var doneCount: Int?
    var frameX: Double?
    var frameY: Double?
    var frameWidth: Double?
    var frameHeight: Double?
    var collapsed: Bool?
    var collapsedOnRight: Bool?
    var stripY: Double?
}

@MainActor
final class TaskStore: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var later: [TaskItem] = []
    @Published var done: [TaskItem] = []
    @Published var page: NotePage = .tasks
    @Published var isCollapsed = false
    @Published var collapsedOnRight = true

    var onCollapse: () -> Void = {}
    var onExpand: () -> Void = {}
    var onStripDragBegan: () -> Void = {}
    var onStripDrag: (CGFloat) -> Void = { _ in }
    var onStripDragEnded: (CGFloat) -> Void = { _ in }

    private(set) var savedFrame: NSRect?
    private(set) var savedStripY: CGFloat?
    private let fileURL: URL
    private var frame: NSRect?

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("FixMyADHD", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("tasks.json")
        load()
    }

    func add(_ raw: String) {
        let title = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        tasks.append(TaskItem(id: UUID(), title: title))
        save()
    }

    func addLater(_ raw: String) {
        let title = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        later.append(TaskItem(id: UUID(), title: title))
        save()
    }

    func complete(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        TrashSound.play()
        let item = tasks.remove(at: index)
        done.insert(item, at: 0)
        save()
    }

    func archive(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        let item = tasks.remove(at: index)
        later.insert(item, at: 0)
        save()
    }

    func rename(_ id: UUID, to raw: String) {
        let title = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            guard tasks[index].title != title else { return }
            tasks[index].title = title
        } else if let index = later.firstIndex(where: { $0.id == id }) {
            guard later[index].title != title else { return }
            later[index].title = title
        } else if let index = done.firstIndex(where: { $0.id == id }) {
            guard done[index].title != title else { return }
            done[index].title = title
        } else {
            return
        }
        save()
    }

    func moveTask(_ id: UUID, by slots: Int) {
        guard slots != 0, let from = tasks.firstIndex(where: { $0.id == id }) else { return }
        let to = min(max(from + slots, 0), tasks.count - 1)
        guard to != from else { return }
        let item = tasks.remove(at: from)
        tasks.insert(item, at: to)
        save()
    }

    func restore(_ id: UUID) {
        guard let index = later.firstIndex(where: { $0.id == id }) else { return }
        let item = later.remove(at: index)
        tasks.insert(item, at: 0)
        save()
    }

    func saveFrame(_ rect: NSRect) {
        frame = rect
        savedFrame = rect
        save()
    }

    func saveStripY(_ y: CGFloat) {
        savedStripY = y
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let state = try? JSONDecoder().decode(SavedState.self, from: data) else {
            return
        }
        tasks = state.tasks
        later = state.later
        done = state.done ?? []
        isCollapsed = state.collapsed ?? false
        collapsedOnRight = state.collapsedOnRight ?? true
        savedStripY = state.stripY.map { CGFloat($0) }
        if let x = state.frameX, let y = state.frameY,
           let width = state.frameWidth, let height = state.frameHeight {
            let rect = NSRect(x: x, y: y, width: width, height: height)
            frame = rect
            savedFrame = rect
        }
    }

    private func save() {
        let state = SavedState(
            tasks: tasks,
            later: later,
            done: done,
            doneCount: done.count,
            frameX: frame.map { Double($0.origin.x) },
            frameY: frame.map { Double($0.origin.y) },
            frameWidth: frame.map { Double($0.size.width) },
            frameHeight: frame.map { Double($0.size.height) },
            collapsed: isCollapsed,
            collapsedOnRight: collapsedOnRight,
            stripY: savedStripY.map { Double($0) }
        )
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

enum TrashSound {
    static let path = "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/finder/move to trash.aif"

    static func play() {
        NSSound(contentsOfFile: path, byReference: true)?.play()
    }
}
