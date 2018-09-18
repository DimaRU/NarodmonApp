////
///  WebcamViewController.swift
//


import Cocoa
import ProgressKit

class WebcamViewController: NSViewController {
    
    // Mark: Data
    var webcam: WebcamImages!
    var imageUrl: [Date: String] = [:]
    var imageDateIndex: [Date] = []
    var index = 0
    
    // Mark: storyboard elements
    @IBOutlet weak var cameraName: NSTextField!
    @IBOutlet weak var cameraTime: NSTextField!
    @IBOutlet weak var cameraImageView: NSImageView!
    @IBOutlet weak var prevButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var spinner: Spinner!
    
    
    
    public class func instance() -> WebcamViewController {
        return NSStoryboard.main?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "WebcamViewController")) as! WebcamViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.animate = true
        
        cameraName.stringValue = webcam.name
        let imageURL = URL.init(string: webcam.images[0].image.replacingOccurrences(of: "http:", with: "https:"))!
        print(webcam.images[0].image)
        cameraImageView.image = NSImage.init(contentsOf: imageURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5)  { [weak self] in
            print("Stop animation")
            self?.spinner.animate = false
        }
    }
    
    @IBAction func prevButtonPress(_ sender: NSButton) {
    }
    
    @IBAction func nextButtonPress(_ sender: NSButton) {
    }
    
}




// Mark: Network I/O

extension WebcamViewController {
}

extension WebcamViewController: NSPopoverDelegate {
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        return true
    }
    
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }
    
    func popoverDidDetach(_ popover: NSPopover) {
    }
    
    func popoverWillShow(_ notification: Notification) {
    }
    
    func popoverDidShow(_ notification: Notification) {
    }
    
    func popoverWillClose(_ notification: Notification) {
    }
    
    func popoverDidClose(_ notification: Notification) {
    }
}
