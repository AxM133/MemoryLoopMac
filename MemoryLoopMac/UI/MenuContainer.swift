import SwiftUI

/// Контейнер меню-окна: фиксирует размер и даёт скролл/отступы.
struct MenuContainer<Content: View>: View {
    let content: Content
    init(@ViewBuilder _ content: () -> Content) { self.content = content() }

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: 600, alignment: .leading)   // ширина контента
        }
        // размеры самого окна — шире, чтобы ничего не резалось
        .frame(
            minWidth: 620, idealWidth: 660, maxWidth: 720,
            minHeight: 340, idealHeight: 440, maxHeight: 560
        )
    }
}
