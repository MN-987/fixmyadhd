import AppKit
import SwiftUI

let appDelegate = AppDelegate()
let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.delegate = appDelegate
app.run()

final class StickyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var panel: StickyPanel?
    private let store = TaskStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let panel = StickyPanel(
            contentRect: defaultFrame(),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.minSize = cardMin
        panel.maxSize = cardMax
        panel.isRestorable = false
        panel.delegate = self
        store.onCollapse = { [weak self] in self?.collapse() }
        store.onExpand = { [weak self] in self?.expand() }

        let host = NSHostingView(rootView: StickyNoteView(store: store))
        host.sizingOptions = []
        host.translatesAutoresizingMaskIntoConstraints = true
        host.autoresizingMask = [.width, .height]
        host.wantsLayer = true
        host.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = host

        let frame = store.savedFrame.map(clamped) ?? defaultFrame()
        if store.isCollapsed {
            let screen = screen(for: frame)
            panel.minSize = stripSize
            panel.maxSize = stripSize
            panel.setFrame(stripFrame(onRight: store.collapsedOnRight, anchor: frame, screen: screen), display: true)
        } else {
            panel.setFrame(frame, display: true)
        }
        host.frame = panel.contentView?.bounds ?? panel.contentLayoutRect

        panel.orderFrontRegardless()
        panel.makeKey()
        self.panel = panel
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panel?.makeKeyAndOrderFront(nil)
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        guard let panel, !store.isCollapsed else { return }
        guard panel.frame.width >= cardMin.width, panel.frame.height >= cardMin.height else { return }
        store.saveFrame(panel.frame)
    }

    func windowDidMove(_ notification: Notification) {
        rememberCardFrame()
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        rememberCardFrame()
    }

    private func collapse() {
        guard let panel, !store.isCollapsed else { return }
        let current = panel.frame
        let screen = panel.screen ?? NSScreen.main
        let onRight = current.midX >= (screen?.visibleFrame.midX ?? current.midX)
        store.collapsedOnRight = onRight
        store.isCollapsed = true
        store.saveFrame(current)
        panel.minSize = stripSize
        panel.maxSize = stripSize
        panel.setFrame(stripFrame(onRight: onRight, anchor: current, screen: screen), display: true, animate: true)
    }

    private func expand() {
        guard let panel, store.isCollapsed else { return }
        let frame = store.savedFrame.map(clamped) ?? defaultFrame()
        panel.minSize = cardMin
        panel.maxSize = cardMax
        store.isCollapsed = false
        panel.setFrame(frame, display: true, animate: true)
        store.saveFrame(frame)
    }

    private func rememberCardFrame() {
        guard let panel, !store.isCollapsed else { return }
        guard panel.frame.width >= cardMin.width, panel.frame.height >= cardMin.height else { return }
        store.saveFrame(panel.frame)
    }

    private let cardMin = NSSize(width: 340, height: 360)
    private let cardMax = NSSize(width: 2400, height: 1600)
    private let stripSize = NSSize(width: 20, height: 128)

    private func stripFrame(onRight: Bool, anchor: NSRect, screen: NSScreen?) -> NSRect {
        let visible = screen?.visibleFrame ?? anchor
        var y = anchor.midY - stripSize.height / 2
        y = min(max(y, visible.minY + 12), visible.maxY - stripSize.height - 12)
        let x = onRight ? visible.maxX - stripSize.width : visible.minX
        return NSRect(x: x, y: y, width: stripSize.width, height: stripSize.height)
    }

    private func screen(for rect: NSRect) -> NSScreen? {
        NSScreen.screens.first { $0.frame.intersects(rect) } ?? NSScreen.main
    }

    private func defaultFrame() -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(x: 80, y: 80, width: 340, height: 480)
        }
        let visible = screen.visibleFrame
        let size = NSSize(width: 340, height: 480)
        return NSRect(
            x: visible.maxX - size.width - 28,
            y: visible.maxY - size.height - 28,
            width: size.width,
            height: size.height
        )
    }

    private func clamped(_ rect: NSRect) -> NSRect {
        guard let screen = NSScreen.screens.first(where: { $0.frame.intersects(rect) }) ?? NSScreen.main else {
            return rect
        }
        let visible = screen.visibleFrame
        var next = rect
        next.size.width = min(max(next.width, 340), visible.width)
        next.size.height = min(max(next.height, 360), visible.height)
        if next.maxX > visible.maxX { next.origin.x = visible.maxX - next.width }
        if next.minX < visible.minX { next.origin.x = visible.minX }
        if next.maxY > visible.maxY { next.origin.y = visible.maxY - next.height }
        if next.minY < visible.minY { next.origin.y = visible.minY }
        return next
    }
}
