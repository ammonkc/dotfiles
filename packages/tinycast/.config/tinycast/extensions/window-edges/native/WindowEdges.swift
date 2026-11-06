import AppKit
import ApplicationServices

// All geometry uses Accessibility coordinates: origin at the primary display's top left.
func destination(_ window: CGRect, in screen: CGRect, edge: String) -> CGPoint {
    switch edge {
    case "left": return CGPoint(x: screen.minX, y: window.minY)
    case "right": return CGPoint(x: screen.maxX - window.width, y: window.minY)
    case "top": return CGPoint(x: window.minX, y: screen.minY)
    default: return CGPoint(x: window.minX, y: screen.maxY - window.height)
    }
}

func hostScreen(_ window: CGRect, screens: [CGRect]) -> Int? {
    // Prefer the greatest overlap, then the nearest display for an offscreen window.
    screens.indices.max { a, b in
        func area(_ rect: CGRect) -> CGFloat {
            let overlap = window.intersection(rect)
            return overlap.isNull ? 0 : overlap.width * overlap.height
        }
        let aa = area(screens[a]), ab = area(screens[b])
        if aa != ab { return aa < ab }
        func distance(_ rect: CGRect) -> CGFloat {
            let dx = max(rect.minX - window.midX, 0, window.midX - rect.maxX)
            let dy = max(rect.minY - window.midY, 0, window.midY - rect.maxY)
            return dx * dx + dy * dy
        }
        return distance(screens[a]) > distance(screens[b])
    }
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
    return value
}

if CommandLine.arguments == [CommandLine.arguments[0], "--test"] {
    let screen = CGRect(x: -1440, y: -900, width: 1440, height: 875)
    let window = CGRect(x: -1000, y: -700, width: 600, height: 400)
    precondition(destination(window, in: screen, edge: "left") == CGPoint(x: -1440, y: -700))
    precondition(destination(window, in: screen, edge: "right") == CGPoint(x: -600, y: -700))
    precondition(destination(window, in: screen, edge: "top") == CGPoint(x: -1000, y: -900))
    precondition(destination(window, in: screen, edge: "bottom") == CGPoint(x: -1000, y: -425))
    let primary = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    precondition(hostScreen(window, screens: [primary, screen]) == 1)
    precondition(hostScreen(CGRect(x: 3000, y: 100, width: 100, height: 100), screens: [screen, primary]) == 1)
    precondition(hostScreen(CGRect(x: -100, y: 50, width: 600, height: 400), screens: [screen, primary]) == 1)
    let oversized = CGRect(x: 10, y: 20, width: 2200, height: 1200)
    precondition(destination(oversized, in: primary, edge: "right") == CGPoint(x: -280, y: 20))
    precondition(destination(oversized, in: primary, edge: "bottom") == CGPoint(x: 10, y: -120))
    print("Window edge geometry tests passed")
    exit(0)
}

guard CommandLine.arguments.count == 3,
      ["left", "right", "top", "bottom"].contains(CommandLine.arguments[1]) else {
    fail("Usage: window-edges <left|right|top|bottom> <application-bundle-id>")
}
guard AXIsProcessTrusted() else {
    fail("Allow Tinycast in System Settings > Privacy & Security > Accessibility, then try again.")
}
guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: CommandLine.arguments[2]).first else {
    fail("The focused application is no longer running.")
}
let application = AXUIElementCreateApplication(app.processIdentifier)
AXUIElementSetMessagingTimeout(application, 1)
guard let value = attribute(application, kAXFocusedWindowAttribute), CFGetTypeID(value) == AXUIElementGetTypeID() else {
    fail("The focused application has no focused window.")
}
let window = value as! AXUIElement
AXUIElementSetMessagingTimeout(window, 1)
if (attribute(window, "AXFullScreen") as? Bool) == true {
    fail("Leave fullscreen before moving the window to an edge.")
}
guard let position = attribute(window, kAXPositionAttribute),
      let size = attribute(window, kAXSizeAttribute),
      CFGetTypeID(position) == AXValueGetTypeID(), CFGetTypeID(size) == AXValueGetTypeID() else {
    fail("Could not read the focused window's geometry.")
}
var origin = CGPoint.zero
var dimensions = CGSize.zero
guard AXValueGetValue(position as! AXValue, .cgPoint, &origin),
      AXValueGetValue(size as! AXValue, .cgSize, &dimensions) else {
    fail("Could not decode the focused window's geometry.")
}
let screens = NSScreen.screens
let anchor = (screens.first { $0.frame.origin == .zero } ?? screens.first)?.frame.height ?? 0
func flip(_ rect: CGRect) -> CGRect {
    CGRect(x: rect.minX, y: anchor - rect.maxY, width: rect.width, height: rect.height)
}
let frame = CGRect(origin: origin, size: dimensions)
guard let index = hostScreen(frame, screens: screens.map { flip($0.frame) }) else {
    fail("No connected display found.")
}
var settable = DarwinBoolean(false)
guard AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &settable) == .success, settable.boolValue else {
    fail("This window does not support moving.")
}
var target = destination(frame, in: flip(screens[index].visibleFrame), edge: CommandLine.arguments[1])
guard let newPosition = AXValueCreate(.cgPoint, &target),
      AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, newPosition) == .success else {
    fail("The application refused to move its window.")
}
// Never write AXSize: fixed-size windows work too, and oversized windows stay oversized.
