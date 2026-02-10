import WidgetKit
import SwiftUI

@main
struct BookgolasWidgetBundle: WidgetBundle {
    var body: some Widget {
        BookgolasSmallWidget()
        BookgolasMediumWidget()
        BookgolasLockScreenCircularWidget()
        BookgolasLockScreenRectangularWidget()
        BookgolasLockScreenInlineWidget()
    }
}
