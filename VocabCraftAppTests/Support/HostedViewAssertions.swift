import CraftUIKit
import SwiftUI
import Testing
@testable import VocabCraftApp
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
    let suiteName = "HostedViewTests.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
        if Test.current != nil {
            Issue.record("Cannot create isolated hosted-view defaults")
        } else {
            XCTFail("Cannot create isolated hosted-view defaults", file: file, line: line)
        }
        return nil
    }
    let container = AppContainer(
        useMockData: true,
        useSampleData: true,
        vocabularyDataSource: MockVocabularyDataSource(),
        refreshWidgetDeckUseCase: HostedViewRefreshWidgetDeckUseCase(),
        ttsService: MockTextToSpeechService(),
        userSettingsStore: UserSettingsStore(defaults: defaults)
    )
    let content = content
        .environment(\.appContainer, container)
        .environment(\.appRouter, container.appRouter)
        .craftTheme(CraftDefaultTheme())
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
        defaults.removePersistentDomain(forName: suiteName)
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
    defer {
        window.contentView = nil
        defaults.removePersistentDomain(forName: suiteName)
    }
    #endif
    if Test.current != nil {
        #expect(appeared, "Mounted view must complete its appearance lifecycle")
    } else {
        XCTAssertTrue(appeared, "Mounted view must complete its appearance lifecycle", file: file, line: line)
    }
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

private struct HostedViewRefreshWidgetDeckUseCase: RefreshWidgetDeckUseCaseProtocol {
    func execute() async {}
}

// SwiftPM owns these types in this package; the Xcode test target imports them.
// Explicit retroactive conformances are confined to that separate test target.
#if SWIFT_PACKAGE
extension ReflexHeaderBarView: DynamicProperty {}
extension ReflexBlitzSummaryView: DynamicProperty {}
extension ReflexBlitzView: DynamicProperty {}
extension MixedReflexSummaryView: DynamicProperty {}
#else
extension ReflexHeaderBarView: @retroactive DynamicProperty {}
extension ReflexBlitzSummaryView: @retroactive DynamicProperty {}
extension ReflexBlitzView: @retroactive DynamicProperty {}
extension MixedReflexSummaryView: @retroactive DynamicProperty {}
#endif

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
