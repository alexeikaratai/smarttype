import AppKit

/// Process lifecycle. The object graph is built once, after launch has finished.
package final class AppDelegate: NSObject, NSApplicationDelegate {
    private var composition: AppComposition?

    package func applicationDidFinishLaunching(_ notification: Notification) {
        let composition = AppComposition()
        composition.start()
        self.composition = composition
    }
}
