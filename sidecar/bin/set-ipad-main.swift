import Foundation
import CoreGraphics

let dry = CommandLine.arguments.contains("--list")

var displayCount: UInt32 = 0
var displays = [CGDirectDisplayID](repeating: 0, count: 16)
let err = CGGetActiveDisplayList(16, &displays, &displayCount)
if err != .success {
    fputs("CGGetActiveDisplayList failed: \(err.rawValue)\n", stderr)
    exit(1)
}

struct Info {
    let id: CGDirectDisplayID
    let w: Int
    let h: Int
    let main: Bool
    let builtin: Bool
    let inMirror: Bool
}

let ipadExact: Set<String> = [
    "3024x2384", "2732x2048", "2388x1668", "2360x1640", "2224x1668", "2048x1536",
    "1668x2388", "1640x2360", "1536x2048", "2384x3024",
    "1512x1192", "1192x1512", "1366x1024", "1024x1366"
]

var infos: [Info] = []
for i in 0..<Int(displayCount) {
    let id = displays[i]
    let w = Int(CGDisplayPixelsWide(id))
    let h = Int(CGDisplayPixelsHigh(id))
    let main = CGDisplayIsMain(id) != 0
    let builtin = CGDisplayIsBuiltin(id) != 0
    let inMirror = CGDisplayIsInMirrorSet(id) != 0
    infos.append(Info(id: id, w: w, h: h, main: main, builtin: builtin, inMirror: inMirror))
    print("display id=\(id) \(w)x\(h) main=\(main) builtin=\(builtin) inMirrorSet=\(inMirror)")
}

if dry { exit(0) }

func exactIPad(_ x: Info) -> Bool {
    !x.builtin && ipadExact.contains("\(x.w)x\(x.h)")
}

// Prefer native Sidecar UI sizes over Yam full-panel sizes when both present
let sidecarPrefer: Set<String> = ["1512x1192", "1192x1512", "1366x1024", "1024x1366"]
var sidecar = infos.first(where: { exactIPad($0) && sidecarPrefer.contains("\($0.w)x\($0.h)") })
if sidecar == nil {
    sidecar = infos.first(where: { exactIPad($0) })
}
if sidecar == nil {
    let externals = infos.filter { !$0.builtin }
    let nonVirtual = externals.filter { !($0.w == 1920 && $0.h == 1440) && !($0.w == 3840 && $0.h == 2880) && !($0.w == 2732 && $0.h == 2048) }
    if let x = nonVirtual.first {
        sidecar = x
    } else if externals.count == 1 {
        sidecar = externals[0]
    }
}

guard let target = sidecar else {
    fputs("找不到 Sidecar/iPad 显示器。请先完成有线随航连接。\n", stderr)
    exit(2)
}

print("chosen sidecar id=\(target.id) \(target.w)x\(target.h)")

var config: CGDisplayConfigRef?
guard CGBeginDisplayConfiguration(&config) == .success, let cfg = config else {
    fputs("CGBeginDisplayConfiguration failed\n", stderr)
    exit(3)
}

// Sidecar as main at origin
if CGConfigureDisplayOrigin(cfg, target.id, 0, 0) != .success {
    fputs("set sidecar origin failed\n", stderr)
    CGCancelDisplayConfiguration(cfg)
    exit(4)
}

// Mirror every other display onto Sidecar (sole usable screen)
for info in infos where info.id != target.id {
    let mr = CGConfigureDisplayMirrorOfDisplay(cfg, info.id, target.id)
    if mr != .success {
        fputs("mirror \(info.id) -> \(target.id) failed \(mr.rawValue)\n", stderr)
    } else {
        print("mirrored id=\(info.id) onto sidecar")
    }
}

let done = CGCompleteDisplayConfiguration(cfg, .permanently)
if done != .success {
    fputs("CGCompleteDisplayConfiguration failed \(done.rawValue)\n", stderr)
    exit(5)
}

print("ok: Sidecar is main + mirrored (sole display)")
