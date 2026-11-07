import Foundation
import Network
import Observation

/// Watches the connection and tells the person, calmly, when it drops and when
/// it's back. Nothing they've saved disappears while offline.
@Observable
final class ConnectivityMonitor {
    static let shared = ConnectivityMonitor()

    private(set) var isOnline = true

    private let monitor = NWPathMonitor()
    private var started = false
    private var hasReported = false

    func start() {
        guard !started else { return }
        started = true
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.update(online: online) }
        }
        monitor.start(queue: DispatchQueue(label: "picartdo.connectivity", qos: .utility))

        #if DEBUG
        // `--simulate-offline`: drop the connection after 4 s, restore it after 12 s.
        if ProcessInfo.processInfo.arguments.contains("--simulate-offline") {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                self.update(online: false)
                try? await Task.sleep(for: .seconds(8))
                self.update(online: true)
            }
        }
        #endif
    }

    private func update(online: Bool) {
        let firstReading = !hasReported
        hasReported = true
        guard online != isOnline || (firstReading && !online) else { return }
        isOnline = online

        if online {
            // Only say "back" if we told them it was gone.
            guard !firstReading else { return }
            PicartdoToast.show("You\u{2019}re back online", icon: "wifi")
        } else {
            PicartdoToast.show(
                "You\u{2019}re offline. Your saved pieces and tickets are still here.",
                icon: "wifi.slash",
                duration: .seconds(6)
            )
        }
    }
}
