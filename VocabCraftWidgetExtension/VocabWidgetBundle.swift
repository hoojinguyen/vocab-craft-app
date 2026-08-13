import SwiftUI
import WidgetKit

#if !SWIFT_PACKAGE
@main
#endif
struct VocabWidgetBundle: WidgetBundle {
    var body: some Widget {
        VocabWidget()
    }
}
