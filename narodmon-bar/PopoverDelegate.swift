////
///  PopoverDelegate.swift
//

import Cocoa
import SwiftyUserDefaults

extension AppDelegate: NSPopoverDelegate {
    
    public func initPopover() {
        sensorsViewController = NSStoryboard.main?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "SensorsViewController")) as! SensorsViewController
        sensorsViewController.dataStore = self.dataStore
        _ = sensorsViewController.view.bounds       // Early get bounds. !!! hack for proper size on first popup view
    }
    
    public func showPopover() {
        if let myPopover = popover {
            guard myPopover.isShown, myPopover.isDetached else { return }
            print("showed and detached")
            NSApp.activate(ignoringOtherApps: true)
            sensorsViewController.view.window?.makeKeyAndOrderFront(nil)
        } else {
            createPopover()
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
            self.sensorsViewController.setViewSizeOnContent()
            print("Will show")
        }
    }
    
    // Invoked on the delegate when the NSPopoverDidShowNotification notification is sent.
    // This method will also be invoked on the popover.
    func popoverDidShow(_ notification: Notification) {
        print("Did show")
    }
    
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        print("popoverShouldClose")
        return true
    }
    
    // Invoked on the delegate when the NSPopoverWillCloseNotification notification is sent.
    // This method will also be invoked on the popover.
    func popoverWillClose(_ notification: Notification) {
        guard let closeReason = notification.userInfo![NSPopover.closeReasonUserInfoKey] as? NSPopover.CloseReason else { return }
        print("popoverWillClose", closeReason)
            // closeReason can be:
            //      NSPopoverCloseReasonStandard
            //      NSPopoverCloseReasonDetachToWindow
        if closeReason == NSPopover.CloseReason.detachToWindow {
        }
        if closeReason == NSPopover.CloseReason.standard {
            setPopoverState(showed: false)
        }
    }
    
    // Invoked on the delegate when the NSPopoverDidCloseNotification notification is sent.
    // This method will also be invoked on the popover.
    func popoverDidClose(_ notification: Notification) {
        guard let closeReason = notification.userInfo![NSPopover.closeReasonUserInfoKey] as? NSPopover.CloseReason else { return }
        print("popoverDidClose", closeReason)
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
        print("popoverDidDetach")
        proxyWindow?.level = .normal
    }

    // Invoked on the delegate asked for the detachable window for the popover.
//    func detachableWindow(for popover: NSPopover) -> NSWindow? {
//        return detachedWindow
//    }

    
}
