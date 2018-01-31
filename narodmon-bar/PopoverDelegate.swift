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
        if detachedWindow?.isVisible ?? false {
            // popover is already detached to a separate window, so select its window instead
            NSApp.activate(ignoringOtherApps: true)
            detachedWindow?.makeKeyAndOrderFront(self)
            return
        }
        
        createPopover()
        myPopover?.show(relativeTo: statusView.bounds, of: statusView, preferredEdge: .minY)
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
        myPopover?.behavior = .transient
        myPopover?.delegate = self
        if detachedWindow == nil {
            detachedWindow = DetachedWindow(frame: sensorsViewController.view.bounds)
        }
    }

    // MARK: - NSPopoverDelegate

    // Invoked on the delegate when the NSPopoverWillShowNotification notification is sent.
    // This method will also be invoked on the popover.
    func popoverWillShow(_ notification: Notification) {
        if notification.object != nil {
            setPopoverState(showed: true)
            self.sensorsViewController.setViewSizeOnContent()
        }
    }
    
    // Invoked on the delegate when the NSPopoverDidShowNotification notification is sent.
    // This method will also be invoked on the popover.
    func popoverDidShow(_ notification: Notification) {
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
            setPopoverState(showed: false)
        }
    }
    
    // Invoked on the delegate when the NSPopoverDidCloseNotification notification is sent.
    // This method will also be invoked on the popover.
    func popoverDidClose(_ notification: Notification) {
        guard let closeReason = notification.userInfo![NSPopover.closeReasonUserInfoKey] as? NSPopover.CloseReason else { return }
        // closeReason can be:
        //      NSPopoverCloseReasonStandard
        //      NSPopoverCloseReasonDetachToWindow
        if closeReason == NSPopover.CloseReason.detachToWindow {
            detachedWindow?.contentViewController = sensorsViewController
            detachedWindow?.invalidateShadow()
            self.sensorsViewController.windowDidDetach()
        }
        // release popover since it closed
        myPopover = nil
    }
    
    // Invoked on the delegate to give permission to detach popover as a separate window.
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }

    // Invoked on the delegate asked for the detachable window for the popover.
    func detachableWindow(for popover: NSPopover) -> NSWindow? {
        return detachedWindow
    }

    
}
