import AppKit

extension NSMenuItem {
    /// Where the words start, from the icon's left edge: room for the widest symbol and a gap.
    private static let textColumn: CGFloat = 26
    /// The height every icon is drawn at; its width follows its own proportions.
    private static let iconHeight: CGFloat = 14

    /// The title with an SF Symbol in front of it, inside the attributed title, as SmartDock
    /// draws its menu: macOS 26 draws no `image` in a status menu, while an attachment draws,
    /// whitens under the highlight and greys out with a disabled item (all measured there).
    ///
    /// The attributed title goes first: setting it rewrites `title` to its own characters, the
    /// attachment and the tab included, while setting `title` after it keeps it and puts the
    /// plain words back (both measured), which is what VoiceOver and the tests read.
    func setTitle(_ title: String, symbol: String) {
        attributedTitle = Self.titled(title, symbol: symbol)
        self.title = title
    }

    /// The icon, a tab, then the words. The symbol goes in as it is, a template, or it would
    /// follow neither the highlight nor the theme (SmartDock), so a tab stop aligns the words.
    private static func titled(_ title: String, symbol: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 14, weight: .regular))
        {
            image.isTemplate = true
            let width = image.size.height > 0 ? image.size.width * iconHeight / image.size.height : iconHeight
            let attachment = NSTextAttachment()
            attachment.image = image
            // The glyph sits low against the menu's text otherwise (SmartDock).
            attachment.bounds = CGRect(x: 0, y: -3, width: width, height: iconHeight)
            result.append(NSAttributedString(attachment: attachment))
            result.append(NSAttributedString(string: "\t"))
        }
        result.append(NSAttributedString(string: title))
        let style = NSMutableParagraphStyle()
        style.tabStops = [NSTextTab(textAlignment: .left, location: textColumn)]
        result.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: result.length))
        return result
    }
}
