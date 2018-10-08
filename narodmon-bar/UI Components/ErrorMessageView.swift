//
//  ErrorMessageView.swift
//  TestWebcamView
//
//  Created by Dmitriy Borovikov on 26/09/2018.
//  Copyright © 2018 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class ErrorMessageView: NSView {

    @IBOutlet weak var errorMessageTitle: NSTextField!
    @IBOutlet weak var errorMessageLabel: NSTextField!
    
    public class func load(superView: NSView) -> ErrorMessageView {
        guard let errorMessageView: ErrorMessageView = .fromNib() else {
            fatalError()
        }

        superView.addSubview(errorMessageView)
        errorMessageView.setConstraints(at: superView)
        return errorMessageView
    }
    
    private func setConstraints(at superView: NSView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.centerXAnchor.constraint(equalTo: superView.centerXAnchor).isActive = true
        self.centerYAnchor.constraint(equalTo: superView.centerYAnchor).isActive = true
        self.isHidden = true
    }
    
    public func showError(title: String, message: String) {
        errorMessageTitle.stringValue = title
        errorMessageLabel.stringValue = message
        
        self.isHidden = false
    }
    
    public func clearError() {
        self.isHidden = true
    }
}
