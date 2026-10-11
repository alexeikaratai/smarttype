import Testing

@testable import SmartTypeApp

@Suite struct InputSourceSwitcherTests {
    /// The real TIS call, on an ID no Mac has: nothing is switched. TIS answers `nil` rather
    /// than an empty list for it (measured), and that must read as "not selected".
    @Test func aLayoutThatIsNotEnabledIsNotSelected() {
        #expect(!InputSourceSwitcher.select("com.smarttype.tests.no-such-layout"))
    }
}
