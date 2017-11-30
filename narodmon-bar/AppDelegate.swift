//
//  AppDelegate.swift
//  narodmon-bar
//
//  Created by Dmitriy Borovikov on 14.11.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusView: StatusItemView!

    var myPopover: NSPopover?
    var sensorsViewController: SensorsViewController!
    var detachedWindow: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusView = StatusItemView(statusItem: statusItem) {
            print("Action")
            self.showPopoverAction()
            }
        statusView.sizeToFit()
        
        Defaults.appStart()
        initPopover()

        
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

extension AppDelegate: NSPopoverDelegate {
    
    func initPopover() {
        sensorsViewController = NSStoryboard.main?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "SensorsViewController")) as! SensorsViewController
        
        let frame: NSRect = sensorsViewController.view.bounds
        let styleMask: NSWindow.StyleMask = [.titled, .closable]
        let rect = NSWindow.contentRect(forFrameRect: frame, styleMask: styleMask)
        detachedWindow = NSWindow(contentRect: rect, styleMask: styleMask, backing: .buffered, defer: true)
        detachedWindow?.contentViewController = sensorsViewController
        detachedWindow?.isReleasedWhenClosed = false

    }
    // -------------------------------------------------------------------------------
    //  createPopover
    // -------------------------------------------------------------------------------
    
    func createPopover() {
        if myPopover == nil {
            // create and setup our popover
            myPopover = NSPopover()
            // the popover retains us and we retain the popover,
            // we drop the popover whenever it is closed to avoid a cycle
            myPopover?.contentViewController = sensorsViewController
            switch 0 {
            case 0:
                myPopover?.appearance = NSAppearance(named: .vibrantLight)
            case 1:
                myPopover?.appearance = NSAppearance(named: .vibrantDark)
            default:
                myPopover?.appearance = NSAppearance(named: .aqua)
            }
            myPopover?.animates = true
            // AppKit will close the popover when the user interacts with a user interface element outside the popover.
            // note that interacting with menus or panels that become key only when needed will not cause a transient popover to close.
            myPopover?.behavior = .transient
            // so we can be notified when the popover appears or closes
            myPopover?.delegate = self
        }
    }
    
    // -------------------------------------------------------------------------------
    //  showPopoverAction:sender
    // -------------------------------------------------------------------------------
    
    func showPopoverAction() {
        if detachedWindow?.isVisible ?? false {
            // popover is already detached to a separate window, so select its window instead
            detachedWindow?.makeKeyAndOrderFront(self)
            return
        }
        
        createPopover()
        let targetButton = statusView.statusItem.button
        
        // configure the preferred position of the popover
        myPopover?.show(relativeTo: targetButton?.bounds ?? NSRect(), of: statusView, preferredEdge: .minY)
    }
    

    // MARK: - NSPopoverDelegate
    // -------------------------------------------------------------------------------
    // Invoked on the delegate when the NSPopoverWillShowNotification notification is sent.
    // This method will also be invoked on the popover.
    // -------------------------------------------------------------------------------
    func popoverWillShow(_ notification: Notification) {
        let popover = notification.object
        if popover != nil {
            //... operate on that popover
        }
    }
    
    // -------------------------------------------------------------------------------
    // Invoked on the delegate when the NSPopoverDidShowNotification notification is sent.
    // This method will also be invoked on the popover.
    // -------------------------------------------------------------------------------
    func popoverDidShow(_ notification: Notification) {
        // add new code here after the popover has been shown
    }
    
    // -------------------------------------------------------------------------------
    // Invoked on the delegate when the NSPopoverWillCloseNotification notification is sent.
    // This method will also be invoked on the popover.
    // -------------------------------------------------------------------------------
    
    func popoverWillClose(_ notification: Notification) {
        let closeReason = notification.userInfo![NSPopover.closeReasonUserInfoKey] as? NSPopover.CloseReason
        if closeReason != nil {
            // closeReason can be:
            //      NSPopoverCloseReasonStandard
            //      NSPopoverCloseReasonDetachToWindow
            //
            // add new code here if you want to respond "before" the popover closes
            //
        }
    }
    
    // -------------------------------------------------------------------------------
    // Invoked on the delegate when the NSPopoverDidCloseNotification notification is sent.
    // This method will also be invoked on the popover.
    // -------------------------------------------------------------------------------
    func popoverDidClose(_ notification: Notification) {
        let closeReason = notification.userInfo![NSPopover.closeReasonUserInfoKey] as? NSPopover.CloseReason
        if closeReason != nil {
            // closeReason can be:
            //      NSPopoverCloseReasonStandard
            //      NSPopoverCloseReasonDetachToWindow
            //
            // add new code here if you want to respond "after" the popover closes
            //
        }
        
        // release our popover since it closed
        myPopover = nil
    }
    
    // -------------------------------------------------------------------------------
    // Invoked on the delegate to give permission to detach popover as a separate window.
    // -------------------------------------------------------------------------------
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }
    
    // -------------------------------------------------------------------------------
    // Invoked on the delegate to when the popover was detached.
    // Note: Invoked only if AppKit provides the window for this popover.
    // -------------------------------------------------------------------------------
    func popoverDidDetach(_ popover: NSPopover) {
        print("popoverDidDetach")
    }
    

}

