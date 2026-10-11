import Carbon.HIToolbox

/// Switches the keyboard to a layout, so the person keeps typing in the layout the fixed text
/// is in. A layout that is not enabled on this Mac is left alone.
enum InputSourceSwitcher {
    /// `false` when no enabled input source has the ID.
    static func select(_ id: String) -> Bool {
        let filter = [kTISPropertyInputSourceID as String: id] as CFDictionary
        // For an ID that is not enabled TIS answers nil, not an empty list (measured).
        guard let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue(),
            let source = (list as? [TISInputSource])?.first
        else { return false }
        return TISSelectInputSource(source) == noErr
    }
}
