////
///  PopoverDelegate.swift
//

import Cocoa
import SwiftyUserDefaults

extension AppDelegate: NSPopoverDelegate {
    
    public func initPopover() {
        sensorsViewController = NSStoryboard.main?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "SensorsViewController")) as! SensorsViewController
        sensorsViewController.dataStore = self.dataStore
        
        detachedWindow = DetachedWindow(frame: sensorsViewController.view.bounds)
    }
    
    public func showPopover() {
        if detachedWindow?.isVisible ?? false {
            // popover is already detached to a separate window, so select its window instead
            NSApp.activate(ignoringOtherApps: true)
            detachedWindow?.makeKeyAndOrderFront(self)
            return
        }
        
        createPopover()
        let targetButton = statusView.statusItem.button
        
        myPopover?.show(relativeTo: targetButton?.bounds ?? NSRect(), of: statusView, preferredEdge: .minY)
    }
    
    func createPopover() {
        guard myPopover == nil else { return }
        // create and setup our popover
        myPopover = NSPopover()
        // the popover retains us and we retain the popover,
        // we drop the popover whenever it is closed to avoid a cycle
        myPopover?.contentViewController = sensorsViewController
        myPopover?.appearance = NSAppearance(named: .vibrantLight)
        
        myPopover?.animates = true
        // AppKit will close the popover when the user interacts with a user interface element outside the popover.
        // note that interacting with menus or panels that become key only when needed will not cause a transient popover to close.
        myPopover?.behavior = .transient
        // so we can be notified when the popover appears or closes
        myPopover?.delegate = self
    }

    // MARK: - NSPopoverDelegate
    // -------------------------------------------------------------------------------
    // Invoked on the delegate when the NSPopoverWillShowNotification notification is sent.
    // This method will also be invoked on the popover.
    // -------------------------------------------------------------------------------
    func popoverWillShow(_ notification: Notification) {
        if notification.object != nil {
            setPopoverState(showed: true)
            self.sensorsViewController.setViewSizeOnContent()
        }
    }
    
    // -------------------------------------------------------------------------------
    // Invoked on the delegate when the NSPopoverDidShowNotification notification is sent.
    // This method will also be invoked on the popover.
    // -------------------------------------------------------------------------------
    func popoverDidShow(_ notification: Notification) {
        print("Did show")
    }
    
    // -------------------------------------------------------------------------------
    // Invoked on the delegate when the NSPopoverWillCloseNotification notification is sent.
    // This method will also be invoked on the popover.
    // -------------------------------------------------------------------------------
    
    func popoverWillClose(_ notification: Notification) {
        guard let closeReason = notification.userInfo![NSPopover.closeReasonUserInfoKey] as? NSPopover.CloseReason else { return }
        print("WillClose", closeReason)
            // closeReason can be:
            //      NSPopoverCloseReasonStandard
            //      NSPopoverCloseReasonDetachToWindow
        if closeReason == NSPopover.CloseReason.detachToWindow {
        }
        if closeReason == NSPopover.CloseReason.standard {
            setPopoverState(showed: false)
        }
    }
    
    // -------------------------------------------------------------------------------
    // Invoked on the delegate when the NSPopoverDidCloseNotification notification is sent.
    // This method will also be invoked on the popover.
    // -------------------------------------------------------------------------------
    func popoverDidClose(_ notification: Notification) {
        guard let closeReason = notification.userInfo![NSPopover.closeReasonUserInfoKey] as? NSPopover.CloseReason else { return }
        print("DidClose", closeReason)
        // closeReason can be:
        //      NSPopoverCloseReasonStandard
        //      NSPopoverCloseReasonDetachToWindow
        if closeReason == NSPopover.CloseReason.detachToWindow {
            detachedWindow?.contentViewController = sensorsViewController
            self.sensorsViewController.windowDidDetach()
        }
        // release our popover since it closed
        print("popoverDidClose")
        myPopover = nil
    }
    
    // -------------------------------------------------------------------------------
    // Invoked on the delegate to give permission to detach popover as a separate window.
    // -------------------------------------------------------------------------------
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        print("popoverShouldDetach")
        return true
    }
    
    // -------------------------------------------------------------------------------
    // Invoked on the delegate to when the popover was detached.
    // Note: Invoked only if AppKit provides the window for this popover.
    // -------------------------------------------------------------------------------
    func popoverDidDetach(_ popover: NSPopover) {
    }

    // -------------------------------------------------------------------------------
    // Invoked on the delegate asked for the detachable window for the popover.
    // -------------------------------------------------------------------------------
    func detachableWindow(for popover: NSPopover) -> NSWindow? {
        print("detachableWindow")
        return detachedWindow
    }

    
}
