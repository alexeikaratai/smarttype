import AppKit

/// Everything on a pasteboard, every item in every type, so it can be put back as it was.
struct PasteboardSnapshot {
    private let items: [[(type: NSPasteboard.PasteboardType, data: Data)]]

    /// `nil` when the pasteboard lists types it gives no data for, which is what a read looks
    /// like when macOS refuses SmartType the contents. Borrowing it then would lose them.
    init?(of pasteboard: NSPasteboard) {
        let items = (pasteboard.pasteboardItems ?? []).map { item in
            item.types.compactMap { type in item.data(forType: type).map { (type, $0) } }
        }
        let listsTypes = !(pasteboard.types ?? []).isEmpty
        guard !listsTypes || items.contains(where: { !$0.isEmpty }) else { return nil }
        self.items = items
    }

    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        let restored = items.map { item in
            let pasteboardItem = NSPasteboardItem()
            for (type, data) in item {
                pasteboardItem.setData(data, forType: type)
            }
            return pasteboardItem
        }
        pasteboard.writeObjects(restored)
    }
}
