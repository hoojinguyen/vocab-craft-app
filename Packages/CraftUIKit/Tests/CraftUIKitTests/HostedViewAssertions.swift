@testable import CraftUIKit
import SwiftUI
import XCTest
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Exercises SwiftUI's installed dynamic properties and appearance lifecycle.
/// Keep the native host alive through layout, then remove it to run disappearance cleanup.
@MainActor
@discardableResult
func assertHosted<Content: View>(
    _ content: Content,
    snapshot: Bool = false,
    file: StaticString = #filePath,
    line: UInt = #line
) -> Data? {
    var appeared = false
    let root = content.onAppear { appeared = true }
    #if canImport(UIKit)
    let host = UIHostingController(rootView: root)
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
    window.rootViewController = host
    window.isHidden = false
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
    defer {
        window.isHidden = true
        window.rootViewController = nil
    }
    #elseif canImport(AppKit)
    _ = NSApplication.shared
    let host = NSHostingView(rootView: root)
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 393, height: 852),
        styleMask: .borderless,
        backing: .buffered,
        defer: false
    )
    window.contentView = host
    host.layoutSubtreeIfNeeded()
    defer { window.contentView = nil }
    #endif
    XCTAssertTrue(appeared, "Mounted view must complete its appearance lifecycle", file: file, line: line)
    guard snapshot else { return nil }
    #if canImport(UIKit)
    return UIGraphicsImageRenderer(bounds: host.view.bounds).image { context in
        host.view.layer.render(in: context.cgContext)
    }.pngData()
    #elseif canImport(AppKit)
    guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return nil }
    host.cacheDisplay(in: host.bounds, to: bitmap)
    return bitmap.representation(using: .png, properties: [:])
    #else
    return nil
    #endif
}

// Test-only conformances let SwiftUI install nested dynamic properties before inspection.
extension CraftChoiceCard: DynamicProperty {}
extension CraftActionCard: DynamicProperty {}
extension CraftLessonNode: DynamicProperty {}
extension CraftPathNode: DynamicProperty {}

private struct HostedInspection<Subject: View & DynamicProperty>: View {
    var subject: Subject
    let inspect: (Subject) -> Void

    var body: some View {
        subject.body.onAppear { inspect(subject) }
    }
}

@MainActor
func assertHosted<Subject: View & DynamicProperty>(
    _ subject: Subject,
    file: StaticString = #filePath,
    line: UInt = #line,
    inspect: @escaping (Subject) -> Void
) {
    assertHosted(HostedInspection(subject: subject, inspect: inspect), file: file, line: line)
}
