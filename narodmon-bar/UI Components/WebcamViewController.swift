////
///  WebcamViewController.swift
//


import Cocoa
import ProgressKit
import PromiseKit
import Alamofire

class WebcamViewController: NSViewController {
    
    enum WebcamErrors: Error {
        case noData
    }
    
    // Mark: Data
    var webcam: WebcamImages!
    var imageUrl: [Date: String] = [:]
    var imageDateIndex: [Date] = []
    var currentDate: Date!
    var minSize: CGSize!
    
    // Mark: storyboard elements
    @IBOutlet weak var cameraName: NSTextField!
    @IBOutlet weak var cameraTime: NSTextField!
    @IBOutlet weak var cameraImageView: NSImageView!
    @IBOutlet weak var prevButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var spinner: Spinner!
    
    var errorMessageView: ErrorMessageView!

    
    public class func instance() -> WebcamViewController {
        return NSStoryboard.main?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "WebcamViewController")) as! WebcamViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nextButton.isEnabled = false
        prevButton.isEnabled = false
        cameraTime.stringValue = ""
        errorMessageView = ErrorMessageView.load(superView: view)

        minSize = cameraImageView.frame.size
        cameraName.stringValue = webcam.name
        spinner.animate = true
        let promise = self.loadImageList()
            .done {
                guard let date = self.imageDateIndex.max() else {
                    throw WebcamErrors.noData
                }
                self.currentDate = date
                if self.imageDateIndex.count > 1 {
                    self.prevButton.isEnabled = true
                }
        }
        fetchImage(promise)
    }
    
    @IBAction func prevButtonPress(_ sender: NSButton) {
        errorMessageView.clearError()
        guard let date = prevDate() else {
            self.prevButton.isEnabled = false
            let promise = loadImageList(latest: currentDate)
                .done {
                    guard let date = self.prevDate() else {
                        throw PMKError.cancelled
                    }
                    self.prevButton.isEnabled = true
                    self.nextButton.isEnabled = true
                    self.currentDate = date
            }
            fetchImage(promise)
            return
        }
        
        currentDate = date
        self.nextButton.isEnabled = true
        fetchImage(Promise.value(()))
        return
        
    }
    
    @IBAction func nextButtonPress(_ sender: NSButton) {
        errorMessageView.clearError()
        guard let date = nextDate() else { return }
        currentDate = date
        prevButton.isEnabled = true
        fetchImage(Promise.value(()))
        if nextDate() == nil {
            nextButton.isEnabled = false
        }
    }
    
    func setWebcamView(with image: NSImage?) {
        guard let image = image else {
            cameraImageView.image = nil
            cameraTime.stringValue = ""
            return
        }
        cameraTime.stringValue = smartDate(from: currentDate)
        guard let screenSize = NSScreen.main?.visibleFrame.size else {
            return
        }
        let maxSize = CGSize(width: screenSize.width / 3 * 2, height: screenSize.height / 3 * 2)
        
        var size = image.size
        if size.width < minSize.width {
            size.height = minSize.width / image.size.width * image.size.height
            size.width = minSize.width
        } else if size.height < minSize.height {
            size.height = minSize!.height
            size.width = minSize!.height / image.size.height * image.size.width
        }
        if size.height > maxSize.height {
            size.height = maxSize.height
            size.width = maxSize.height / image.size.height * image.size.width
        } else if size.width > maxSize.width {
            size.height = maxSize.width / image.size.width * image.size.height
            size.width = maxSize.width
        }
        size.height += 13 * 2
        self.preferredContentSize = size
        cameraImageView.image = image
    }
    
    
    func smartDate(from: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        
        if Calendar.current.isDateInToday(from) {
            // Today
            formatter.dateStyle = .none
        } else {
            // Not same day
            formatter.dateStyle = .short
        }
        
        return formatter.string(from: from)
    }
}




// Mark: Network I/O

extension WebcamViewController {
    func nextDate() -> Date? {
        return imageDateIndex.first(where: { $0 > currentDate })
    }
    
    func prevDate() -> Date? {
        return imageDateIndex.last(where: { $0 < currentDate })
    }
    
    func fetchImage(_ promise: Promise<Void>) {
        spinner.animate = true
        promise
            .then {
                self.loadImage()
            }.ensure {
                self.spinner.animate = false
            }.catch { error in
                var title: String
                var message: String
                
                switch(error) {
                case WebcamErrors.noData:
                    title = NSLocalizedString("Warning", comment: "WebcamView error title")
                    message = NSLocalizedString("No webcam data", comment: "WebcamView error message")
                case let error as NarodNetworkError:
                    title = error.localizedDescription
                    message = error.message()
                    print(error.message())
                case let AFError.responseValidationFailed(reason: reason):
                    title = NSLocalizedString("Error", comment: "WebcamView error title")
                    if case let .unacceptableStatusCode(statusCode) = reason {
                        switch statusCode {
                        case 400...499:
                            message = NSLocalizedString("Image not found", comment: "WebcamView error message")
                        case 500...599:
                            message = NSLocalizedString("Server error", comment: "WebcamView error message")
                        default:
                            message = NSLocalizedString("Network error", comment: "WebcamView error message")
                        }
                    } else {
                        return
                    }
                default:
                    title = NSLocalizedString("Network unreachable", comment: "WebcamView error title")
                    message = error.localizedDescription
                }
                self.errorMessageView.showError(title: title, message: message)
        }
    }
    
    func loadImage() -> Promise<Void> {
        let url = imageUrl[self.currentDate]!.replacingOccurrences(of: "http:", with: "https:")
        return Alamofire.request(url)
            .validate(statusCode: 200..<300)
            .responseData()
            .done { data, response in
                
                self.setWebcamView(with: NSImage(data: data))
        }
    }
    
    func loadImageList(latest: Date? = nil) -> Promise<Void> {
        return NarProvider.shared.request(.webcamImages(id: webcam.id!, limit: 10, latest: latest))
            .done { (webcamImages: WebcamImages) -> Void in
                webcamImages.images.forEach { self.imageUrl[$0.time] = $0.image }
                self.imageDateIndex = self.imageUrl.keys.sorted()   //  Recreate index
        }
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
