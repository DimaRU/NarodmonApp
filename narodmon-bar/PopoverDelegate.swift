////
///  PopoverDelegate.swift
//

import Cocoa
import SwiftyUserDefaults

extension AppDelegate: NSPopoverDelegate {
    
    func createContentViewController() {
        sensorsViewController = (NSStoryboard.main?.instantiateController(withIdentifier: "PopupViewController") as! PopupViewController)
        sensorsViewController.dataStore = self.dataStore
        _ = sensorsViewController.view.bounds       // Early get bounds. !!! hack for proper size on first popup view
    }
    
    public func showPopover() {
        if let popover = popover {
            guard popover.isShown, popover.isDetached else { return }
            NSApp.activate(ignoringOtherApps: true)
            sensorsViewController.view.window?.makeKeyAndOrderFront(nil)
        } else {
            createPopover()
            statusView.highlighted = true
            popover?.show(relativeTo: NSRect.zero, of: proxyWindow!.contentView!, preferredEdge: .minY)
        }
    }
    
    func createPopover() {
        guard popover == nil else { return }
        // create and setup our popover
        popover = NSPopover()
        // the popover retains us and we retain the popover,
        // we drop the popover whenever it is closed to avoid a cycle
        popover?.contentViewController = sensorsViewController

        popover?.animates = true
        popover?.behavior = .transient
        popover?.delegate = self
        if proxyWindow == nil {
            proxyWindow = ProxyWindow(from: statusView.window!)
            proxyWindow?.display()
            proxyWindow?.makeKeyAndOrderFront(nil)
        }
    }

    // MARK: - NSPopoverDelegate

    // Invoked on the delegate when the NSPopoverWillShowNotification notification is sent.
    // This method will also be invoked on the popover.
    func popoverWillShow(_ notification: Notification) {
        if notification.object != nil {
            setPopoverState(showed: true)
            sensorsViewController.windowWillShow()
        }
    }
    
    // Invoked on the delegate when the NSPopoverDidShowNotification notification is sent.
    // This method will also be invoked on the popover.
    func popoverDidShow(_ notification: Notification) {
    }
    
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        return true
    }
    
    // Invoked on the delegate when the NSPopoverWillCloseNotification notification is sent.
    // This method will also be invoked on the popover.
    func popoverWillClose(_ notification: Notification) {
        guard let closeReason = notification.userInfo![NSPopover.closeReasonUserInfoKey] as? NSPopover.CloseReason else { return }
            // closeReason can be:
            //      NSPopoverCloseReasonStandard
            //      NSPopoverCloseReasonDetachToWindow
        if closeReason == NSPopover.CloseReason.detachToWindow {
        }
        if closeReason == NSPopover.CloseReason.standard {
            sensorsViewController.windowWillClose()
            setPopoverState(showed: false)
        }
        statusView.highlighted = false
    }
    
    // Invoked on the delegate when the NSPopoverDidCloseNotification notification is sent.
    // This method will also be invoked on the popover.
    func popoverDidClose(_ notification: Notification) {
        guard let closeReason = notification.userInfo![NSPopover.closeReasonUserInfoKey] as? NSPopover.CloseReason else { return }
        // closeReason can be:
        //      NSPopoverCloseReasonStandard
        //      NSPopoverCloseReasonDetachToWindow
        if closeReason == NSPopover.CloseReason.detachToWindow {
        }
        if closeReason == NSPopover.CloseReason.standard {
            proxyWindow?.close()
            proxyWindow = nil
            // release popover since it closed
            popover = nil
        }
    }
    
    // Invoked on the delegate to give permission to detach popover as a separate window.
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }

    // Invoked on the delegate to when the popover was detached.
    // Note: Invoked only if AppKit provides the window for this popover.
    func popoverDidDetach(_ popover: NSPopover) {
        proxyWindow?.level = Defaults[.AlwaysOnTop] ? NSWindow.Level.statusBar : .normal
        statusView.highlighted = false
    }
    
}
