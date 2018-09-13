////
///  WebcamCellView.swift
//


import Cocoa

class WebcamCellView: NSTableCellView {

    var webcamId: Int!
    
    @IBOutlet weak var webcamNameLabel: NSTextField?
    @IBOutlet weak var webcamIdLabel: NSTextField?
    
    func setContent(webcam: WebcamImages) {
        webcamNameLabel?.stringValue = webcam.name
        webcamIdLabel?.stringValue = String(webcam.id!)
        webcamId = webcam.id
    }
    
    @IBAction func viewWebcamInMapAction(_ sender: NSMenuItem) {
        let baseUrl = NSLocalizedString("https://narodmon.com", comment: "Open map URL")
        NSWorkspace.shared.open(URL(string: baseUrl + "/-" + String(webcamId))!)
    }

}
