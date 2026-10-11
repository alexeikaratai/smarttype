/// Fixed text, and the layout to switch to so the person can keep typing in it.
package struct Correction: Equatable, Sendable {
    package let text: String
    /// The layout of the last converted word, where the caret ends up.
    package let targetLayoutID: String

    package init(text: String, targetLayoutID: String) {
        self.text = text
        self.targetLayoutID = targetLayoutID
    }
}
