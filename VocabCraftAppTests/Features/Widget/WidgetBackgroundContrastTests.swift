#if os(iOS)
import CraftUIKit
import SwiftUI
import Testing
import UIKit
@testable import VocabCraftApp
import WidgetKit

/// The widget's text is white (`textInverse`), so every row that can hold text must stay readable on the background.
@MainActor
@Suite("WidgetBackgroundContrast")
struct WidgetBackgroundContrastTests {
    private static let minimumRatio = 4.5

    private let entry = VocabWidgetEntry(
        date: Date(),
        card: WidgetCard(
            wordId: 1, lemma: "serendipity", ipa: "/ˌser.ənˈdɪp.ə.ti/", definitionVi: "sự tình cờ may mắn",
            exampleEn: "Finding that café was pure serendipity.", source: .upcoming, partOfSpeech: "noun"
        ),
        mode: .flashcardFront,
        dueCount: 2,
        practicedToday: 3
    )

    private func luminance(_ red: Double, _ green: Double, _ blue: Double) -> Double {
        func linear(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    private func pixel(_ image: UIImage, x: Int, y: Int) -> (red: Double, green: Double, blue: Double) {
        guard let cgImage = image.cgImage else { return (0, 0, 0) }
        var data = [UInt8](repeating: 0, count: 4)
        let context = CGContext(
            data: &data, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        context?.draw(cgImage, in: CGRect(x: -x, y: -(cgImage.height - 1 - y), width: cgImage.width, height: cgImage.height))
        return (Double(data[0]) / 255, Double(data[1]) / 255, Double(data[2]) / 255)
    }

    private func lowestRatio(family: WidgetFamily, size: CGSize, scheme: ColorScheme) throws -> Double {
        let theme = CraftDefaultTheme()
        let background = WidgetBackground(entry: entry, family: family)
            .frame(width: size.width, height: size.height)
            .environment(\.widgetRenderingMode, .fullColor)
            .environment(\.craftTheme, theme)
            .environment(\.colorScheme, scheme)
        let renderer = ImageRenderer(content: background)
        renderer.scale = 3
        let image = try #require(renderer.uiImage)

        let white = UIColor(theme.colors.textInverse)
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        white.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let foreground = luminance(Double(red), Double(green), Double(blue))

        var lowest = Double.infinity
        // Text starts below the 16 pt content margin; sample down the whole widget at three x positions.
        for yFraction in [0.12, 0.2, 0.3, 0.5, 0.7, 0.85] {
            for xFraction in [0.15, 0.5, 0.85] {
                let sample = pixel(
                    image,
                    x: Int(size.width * xFraction * 3),
                    y: Int(size.height * yFraction * 3)
                )
                let backgroundLuminance = luminance(sample.red, sample.green, sample.blue)
                let ratio = (max(foreground, backgroundLuminance) + 0.05) / (min(foreground, backgroundLuminance) + 0.05)
                lowest = min(lowest, ratio)
            }
        }
        return lowest
    }

    @Test func smallBackgroundKeepsWhiteTextReadableInBothAppearances() throws {
        let size = CGSize(width: 158, height: 158)
        for scheme in [ColorScheme.light, .dark] {
            let ratio = try lowestRatio(family: .systemSmall, size: size, scheme: scheme)
            #expect(ratio >= Self.minimumRatio, "small \(scheme) lowest contrast \(ratio)")
        }
    }

    @Test func mediumBackgroundKeepsWhiteTextReadableInBothAppearances() throws {
        let size = CGSize(width: 338, height: 158)
        for scheme in [ColorScheme.light, .dark] {
            let ratio = try lowestRatio(family: .systemMedium, size: size, scheme: scheme)
            #expect(ratio >= Self.minimumRatio, "medium \(scheme) lowest contrast \(ratio)")
        }
    }
}
#endif
