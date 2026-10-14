/// Stands in for the panel's watch on clicks elsewhere: whether it runs, and a click for a test
/// to make.
final class ClickWatcherRecorder {
    var watching = 0
    var clickElsewhere: () -> Void = {}

    func watch(_ handler: @escaping () -> Void) -> () -> Void {
        watching += 1
        clickElsewhere = handler
        return { self.watching -= 1 }
    }
}
