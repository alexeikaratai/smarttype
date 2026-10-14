@testable import SmartTypeApp

/// What an action did besides the keys and the panel: its beeps, the problems it explained and
/// the layouts it switched to. `onSwitch` runs as a layout is selected, for a test that checks
/// what the pasteboard held then.
final class ActionOutcome {
    var beeps = 0
    var explained: [Onboarding.Problem] = []
    var layouts: [String] = []
    var onSwitch: () -> Void = {}
}
