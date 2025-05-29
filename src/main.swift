import Cocoa

@main
struct EbookConverterApp {
    static func main() {
        let appDelegate = AppDelegate()
        NSApplication.shared.delegate = appDelegate
        NSApplication.shared.run()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let mainViewController = MainViewController()
        window = NSWindow(contentViewController: mainViewController)
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}