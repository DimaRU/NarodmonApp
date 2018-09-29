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
    
    // Mark: storyboard elements
    @IBOutlet weak var cameraName: NSTextField!
    @IBOutlet weak var cameraTime: NSTextField!
    @IBOutlet weak var cameraImageView: NSImageView!
    @IBOutlet weak var prevButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var spinner: Spinner!
    @IBOutlet weak var webcamViewWidth: NSLayoutConstraint!
    @IBOutlet weak var webcamViewHeight: NSLayoutConstraint!
    
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
            self.cameraImageView.image = nil
            cameraTime.stringValue = ""
            return
        }
        cameraTime.stringValue = smartDate(from: currentDate)
        guard let screenSize = NSScreen.main?.visibleFrame.size else {
            return
        }
        let maxSize = CGSize(width: screenSize.width / 3 * 2, height: screenSize.height / 3 * 2)
        
        let size = image.size
        if size.height > maxSize.height {
            webcamViewHeight.constant = maxSize.height
            webcamViewWidth.constant = maxSize.height / size.height * size.width
        } else if size.width > maxSize.width {
            webcamViewWidth.constant = maxSize.width
            webcamViewHeight.constant = maxSize.width / size.width * size.height
        }
        self.cameraImageView.image = image
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
                    title = "Warning"
                    message = "No webcam data"
                case let error as NarodNetworkError:
                    title = error.localizedDescription
                    message = error.message()
                    print(error.message())
                case let AFError.responseValidationFailed(reason: reason):
                    title = "Error"
                    if case let .unacceptableStatusCode(statusCode) = reason {
                        print("statusCode:", statusCode)
                        switch statusCode {
                        case 400...499:
                            message = "Image not found"
                        case 500...599:
                            message = "Server error"
                        default:
                            message = "Network error"
                        }
                    } else {
                        return
                    }
                default:
                    title = "Network unreachable"
                    message = error.localizedDescription
                    print("Nerwork error:", error)
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
