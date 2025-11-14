import SwiftUI

struct MenuContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
                .padding(20)
                .frame(maxWidth: 380)
        }
        .frame(
            minWidth: 420, idealWidth: 420, maxWidth: 420,
            minHeight: 480, idealHeight: 520, maxHeight: 560
        )
    }
}
