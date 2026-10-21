import Foundation
import Testing

@testable import SmartTypeApp

@Suite struct FirstLaunchTests {
    /// Nobody has closed the welcome window yet, people updating from 0.2 included.
    @Test func theWelcomeIsDueUntilItIsClosed() {
        #expect(!FirstLaunch(defaults: .forTest(#function, part: "welcome")).isDone)
    }

    @Test func closingItIsRemembered() {
        let defaults = UserDefaults.forTest(#function, part: "welcome")
        FirstLaunch(defaults: defaults).isDone = true

        #expect(FirstLaunch(defaults: defaults).isDone)
        #expect(defaults.bool(forKey: "com.smarttype.welcome.done"))
    }
}
