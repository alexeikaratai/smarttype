/// Holds a wait until the test opens it.
final class Gate {
    private(set) var isHolding = false
    private var held: CheckedContinuation<Void, Never>?

    func hold() async {
        await withCheckedContinuation { continuation in
            held = continuation
            isHolding = true
        }
    }

    func open() {
        isHolding = false
        held?.resume()
        held = nil
    }
}
