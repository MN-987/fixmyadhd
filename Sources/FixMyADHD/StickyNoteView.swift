import SwiftUI

struct StickyNoteView: View {
    @ObservedObject var store: TaskStore
    @State private var draft = ""

    private let paper = Color(red: 1.0, green: 0.91, blue: 0.40)
    private let ink = Color.black.opacity(0.88)

    var body: some View {
        Group {
            if store.isCollapsed {
                collapsedStrip
            } else {
                card
            }
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            header
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 1)
            list
            if store.page == .tasks {
                addBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var collapsedStrip: some View {
        Button(action: store.onExpand) {
            Image(systemName: store.collapsedOnRight ? "chevron.left" : "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Open tasks")
        .background(paper)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: store.collapsedOnRight ? 12 : 0,
                bottomLeadingRadius: store.collapsedOnRight ? 12 : 0,
                bottomTrailingRadius: store.collapsedOnRight ? 0 : 12,
                topTrailingRadius: store.collapsedOnRight ? 0 : 12,
                style: .continuous
            )
        )
    }

    private var header: some View {
        ZStack {
            DragHeader()
            HStack(spacing: 8) {
                Button(store.page == .tasks ? "Later" : "Tasks") {
                    store.page = store.page == .tasks ? .later : .tasks
                }
                .buttonStyle(NoteChipStyle())

                Spacer(minLength: 8)

                Button {
                    store.page = store.page == .done ? .tasks : .done
                } label: {
                    Text("Done \(store.done.count)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(store.page == .done ? 0.85 : 0.45))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Finished tasks")

                Button(action: store.onCollapse) {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(ink)
                        .frame(width: 26, height: 26)
                        .background(Color.black.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Collapse")

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(ink)
                        .frame(width: 26, height: 26)
                        .background(Color.black.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Quit")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .frame(height: 56)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                switch store.page {
                case .later:
                    laterRows
                case .done:
                    doneRows
                case .tasks:
                    taskRows
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var taskRows: some View {
        if store.tasks.isEmpty {
            emptyLine("Type a task below.")
        } else {
            ForEach(store.tasks) { item in
                HStack(alignment: .center, spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)

                    Button {
                        store.complete(item.id)
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(red: 0.08, green: 0.38, blue: 0.16))
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.62))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Done")

                    Button("Later") {
                        store.archive(item.id)
                    }
                    .buttonStyle(NoteChipStyle())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                rowLine
            }
        }
    }

    @ViewBuilder
    private var laterRows: some View {
        if store.later.isEmpty {
            emptyLine("Nothing parked.")
        } else {
            ForEach(store.later) { item in
                HStack(alignment: .center, spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)

                    Button("To tasks") {
                        store.restore(item.id)
                    }
                    .buttonStyle(NoteChipStyle())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                rowLine
            }
        }
    }

    @ViewBuilder
    private var doneRows: some View {
        if store.done.isEmpty {
            emptyLine("Nothing finished yet.")
        } else {
            ForEach(store.done) { item in
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.08, green: 0.38, blue: 0.16))
                    Text(item.title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                rowLine
            }
        }
    }

    private var rowLine: some View {
        Rectangle()
            .fill(Color.black.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 14)
    }

    private func emptyLine(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(Color.black.opacity(0.45))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
    }

    private var addBar: some View {
        HStack(spacing: 8) {
            TextField("New task", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(ink)
                .onSubmit(commit)

            Button(action: park) {
                Image(systemName: "clock")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(ink)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Add to Later")

            Button(action: commit) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.black.opacity(0.82))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Add task")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.06))
    }

    private func commit() {
        store.add(draft)
        draft = ""
    }

    private func park() {
        store.addLater(draft)
        draft = ""
    }
}

private struct NoteChipStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.black.opacity(0.88))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(configuration.isPressed ? 0.16 : 0.08))
            .clipShape(Capsule())
    }
}

struct DragHeader: NSViewRepresentable {
    func makeNSView(context: Context) -> DragView {
        DragView()
    }

    func updateNSView(_ nsView: DragView, context: Context) {}

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: DragView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 340, height: proposal.height ?? 56)
    }
}

final class DragView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
