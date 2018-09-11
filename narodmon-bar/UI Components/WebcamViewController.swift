////
///  WebcamViewController.swift
//


import Cocoa

class WebcamViewController: NSViewController {

    weak var dataStore: AppDataStore!
    var webcam: UserFavorites.Webcam!
    
    @IBOutlet weak var cameraName: NSTextField!
    @IBOutlet weak var cameraImageView: NSImageView!
    
    public class func instance() -> WebcamViewController {
        return NSStoryboard.main?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "WebcamViewController")) as! WebcamViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraName.stringValue = webcam.name
        let imageURL = URL.init(string: webcam.image.replacingOccurrences(of: "http:", with: "https:"))!
        cameraImageView.image = NSImage.init(contentsOf: imageURL)
    }
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
