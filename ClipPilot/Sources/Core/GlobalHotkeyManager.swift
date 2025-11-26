import Foundation
import Carbon
import AppKit

class GlobalHotkeyManager {
    private struct HotkeyRegistration {
        let eventHotkey: EventHotKeyRef
        let hotkeyID: EventHotKeyID
        let callback: () -> Void
    }

    private var registrations: [HotkeyRegistration] = []
    private var eventHandler: EventHandlerRef?
    private var nextHotkeyID: UInt32 = 1

    deinit {
        unregisterAllHotkeys()
    }

    func registerHotkey(
        keyCode: UInt32,
        modifiers: NSEvent.ModifierFlags,
        callback: @escaping () -> Void
    ) {

        // Convert NSEvent modifiers to Carbon modifiers
        var carbonModifiers: UInt32 = 0

        if modifiers.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if modifiers.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if modifiers.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        if modifiers.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }

        // Install event handler only once
        if eventHandler == nil {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )

            let handler: EventHandlerUPP = { _, event, userData in
                guard let userData = userData else {
                    return OSStatus(eventNotHandledErr)
                }

                let manager = Unmanaged<GlobalHotkeyManager>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                // Get the hotkey ID from the event
                var hotkeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    UInt32(kEventParamDirectObject),
                    UInt32(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotkeyID
                )

                // Find and call the corresponding callback
                DispatchQueue.main.async {
                    manager.handleHotkeyPressed(hotkeyID: hotkeyID)
                }

                return noErr
            }

            let selfPtr = Unmanaged.passUnretained(self).toOpaque()

            InstallEventHandler(
                GetApplicationEventTarget(),
                handler,
                1,
                &eventType,
                selfPtr,
                &eventHandler
            )
        }

        // Register the hotkey
        let hotkeyID = EventHotKeyID(signature: OSType(0x4B455931), id: nextHotkeyID)
        nextHotkeyID += 1

        var eventHotkey: EventHotKeyRef?
        RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &eventHotkey
        )

        if let eventHotkey = eventHotkey {
            let registration = HotkeyRegistration(
                eventHotkey: eventHotkey,
                hotkeyID: hotkeyID,
                callback: callback
            )
            registrations.append(registration)
        }
    }

    private func handleHotkeyPressed(hotkeyID: EventHotKeyID) {
        for registration in registrations {
            if registration.hotkeyID.id == hotkeyID.id &&
               registration.hotkeyID.signature == hotkeyID.signature {
                registration.callback()
                break
            }
        }
    }

    func unregisterHotkey() {
        unregisterAllHotkeys()
    }

    private func unregisterAllHotkeys() {
        for registration in registrations {
            UnregisterEventHotKey(registration.eventHotkey)
        }
        registrations.removeAll()

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}
