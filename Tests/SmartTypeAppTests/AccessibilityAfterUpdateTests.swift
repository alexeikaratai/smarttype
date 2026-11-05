import Testing

@testable import SmartTypeApp

/// Every release is signed anew, and macOS keeps a grant for the code it was given to: the next
/// release reads as not trusted while the old entry stays (measured with a probe). So a release
/// without the permission, after one that had it, lost it to the update.
@Suite struct AccessibilityAfterUpdateTests {
    @Test func aGrantIsRememberedWithTheReleaseThatHadIt() {
        #expect(PermissionRecorder.afterAnUpdateThatTookIt().permission().wasTakenByAnUpdate())
    }

    /// Told once, so Settings opens at the first launch after the update, not at every one.
    @Test func theUpdateIsToldOnce() {
        let macOS = PermissionRecorder.afterAnUpdateThatTookIt()

        #expect(macOS.permission().wasTakenByAnUpdate())
        #expect(!macOS.permission().wasTakenByAnUpdate())
    }

    /// Switched off by the person in the release that had it: no update's doing.
    @Test func aPermissionSwitchedOffInTheSameReleaseIsNoUpdate() {
        let macOS = PermissionRecorder.trusted()
        #expect(macOS.permission().isGranted)

        macOS.isTrusted = false

        #expect(!macOS.permission().wasTakenByAnUpdate())
    }

    /// A release that kept the permission is the one remembered from then on, so switching it off
    /// there is the person's doing too.
    @Test func aReleaseThatKeptThePermissionIsRememberedInstead() {
        let macOS = PermissionRecorder.trusted()
        #expect(macOS.permission().isGranted)
        macOS.release = "0.3.5 (13)"
        #expect(!macOS.permission().wasTakenByAnUpdate())

        macOS.isTrusted = false

        #expect(!macOS.permission().wasTakenByAnUpdate())
    }

    /// Nothing to tell when no release had it: one never granted, or 0.3.3, which kept no record.
    @Test func aReleaseWithoutThePermissionLeavesNothingToTell() {
        let macOS = PermissionRecorder()
        #expect(!macOS.permission().isGranted)

        macOS.release = "0.3.5 (13)"

        #expect(!macOS.permission().wasTakenByAnUpdate())
    }
}
