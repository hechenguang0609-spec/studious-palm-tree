import Cocoa
import Foundation

// Ctrl+Option+Command+S → correct-or-connect (never Settings UI)
let script = NSHomeDirectory() + "/Scripts/sidecar/bin/connect-wired-main.sh"

func runConnect() {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    task.arguments = [script]
    task.standardOutput = FileHandle.nullDevice
    task.standardError = FileHandle.nullDevice
    do {
        try task.run()
    } catch {
        NSLog("sidecar-hotkey launch failed: \(error)")
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var monitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(opts)
        NSLog("sidecar-hotkey trusted=\(trusted) target=\(script)")

        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let want: NSEvent.ModifierFlags = [.control, .option, .command]
            guard flags == want else { return }
            if event.keyCode == 1 {
                NSLog("sidecar-hotkey fired S")
                runConnect()
            }
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let want: NSEvent.ModifierFlags = [.control, .option, .command]
            if flags == want && event.keyCode == 1 {
                runConnect()
                return nil
            }
            return event
        }
    }
}

let app = NSApplication.shared
let del = AppDelegate()
app.delegate = del
app.setActivationPolicy(.accessory)
app.run()
