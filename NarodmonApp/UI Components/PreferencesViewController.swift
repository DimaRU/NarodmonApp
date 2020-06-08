import Cocoa

// in the storyboard, ensure the view controller's transition checkboxes are all off, and the NSTabView's delegate is set to this controller object

class PreferencesViewController: NSTabViewController {
    
    lazy var originalSizes = [String : NSSize]()
    
    // MARK: - NSTabViewDelegate
    
    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, willSelect: tabViewItem)
        
        if self.originalSizes[tabViewItem!.label] == nil {
            self.originalSizes[tabViewItem!.label] = tabViewItem!.view!.frame.size
        }
    }
    
    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        guard let window = self.view.window else { return }

        window.title = tabViewItem!.label
        let size = (self.originalSizes[tabViewItem!.label])!
        let contentFrame = window.frameRect(forContentRect: NSMakeRect(0.0, 0.0, size.width, size.height))
        var frame = window.frame
        frame.origin.y = frame.origin.y + (frame.size.height - contentFrame.size.height)
        frame.size.height = contentFrame.size.height;
        frame.size.width = contentFrame.size.width;
        window.setFrame(frame, display: false, animate: true)
        
    }
}
