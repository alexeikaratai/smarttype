import Carbon.HIToolbox
import OSLog

/// Carbon's `RegisterEventHotKey`: system-wide, needs no Accessibility permission and costs
/// nothing while idle. Several apps may share a combination; macOS reports no conflict.
final class CarbonHotKeyRegistrar: HotKeyRegistering {
    var onPress: ((UInt32) -> Void)?

    // nonisolated(unsafe): `deinit` is nonisolated and must read both to tear them down.
    nonisolated(unsafe) private var hotKeys: [EventHotKeyRef] = []
    nonisolated(unsafe) private var eventHandler: EventHandlerRef?

    init() {}

    deinit {
        for hotKey in hotKeys {
            UnregisterEventHotKey(hotKey)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    func register(_ combo: KeyCombo, id: UInt32) -> Bool {
        guard installEventHandler() else { return false }
        var hotKey: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(combo.key.code),
            combo.modifiers.carbonFlags,
            EventHotKeyID(signature: hotKeySignature, id: id),
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
        guard status == noErr, let hotKey else {
            Log.hotKeys.error("Not registered: \(combo.displayString, privacy: .public), OSStatus \(status)")
            return false
        }
        hotKeys.append(hotKey)
        Log.hotKeys.notice("Registered \(combo.displayString, privacy: .public)")
        return true
    }

    func unregisterAll() {
        for hotKey in hotKeys {
            UnregisterEventHotKey(hotKey)
        }
        hotKeys.removeAll()
    }

    // MARK: - Private

    fileprivate func deliver(_ id: UInt32) {
        onPress?(id)
    }

    private func installEventHandler() -> Bool {
        guard eventHandler == nil else { return true }
        var pressed = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyPressed,
            1,
            &pressed,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        if status != noErr {
            Log.hotKeys.error("Hotkey handler not installed, OSStatus \(status)")
        }
        return status == noErr
    }
}

// MARK: - Carbon callback

/// "SMTY" — tags our hotkeys, so an event registered by anything else is never taken for one.
private nonisolated let hotKeySignature: OSType = "SMTY".utf8.reduce(0) { $0 << 8 | OSType($1) }

/// Carbon calls this on the main thread. It must be a plain C function, so it cannot be
/// actor-isolated itself; it hands the identifier straight back to the main actor.
private nonisolated func hotKeyPressed(
    _ call: EventHandlerCallRef?,
    _ event: EventRef?,
    _ registrar: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let registrar else { return OSStatus(eventNotHandledErr) }
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr, hotKeyID.signature == hotKeySignature else { return OSStatus(eventNotHandledErr) }
    let target = Unmanaged<CarbonHotKeyRegistrar>.fromOpaque(registrar).takeUnretainedValue()
    MainActor.assumeIsolated {
        target.deliver(hotKeyID.id)
    }
    return noErr
}
