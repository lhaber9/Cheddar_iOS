//
//  FeedbackViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/21/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol FeedbackViewDelegate: class {
    func myAlias() -> Alias!
    func shouldCloseAll()
}

class FeedbackViewController: UIViewController {
    
    weak var delegate: FeedbackViewDelegate?
    
    @IBOutlet var textView: UITextView!
    @IBOutlet var sendButton: CheddarButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var errorLabel: UILabel!
    
    var errorLabelTimer:NSTimer!
    
    override func viewDidLoad() {
        textView.layer.cornerRadius = 5
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.grayColor().CGColor
        sendButton.setPrimaryButton()
        errorLabel.textColor = ColorConstants.colorAccent
        titleLabel.textColor = ColorConstants.colorAccent
    }
    
    @IBAction func sendFeedback() {
        let feedbackString = textView.text
        if (feedbackString.isEmpty) {
            displayError("Feedback cannot be blank")
            return
        }
        
        sendButton.displaySpinner()
        
        CheddarRequest.sendFeedback(feedbackString, alias: (delegate?.myAlias()), successCallback: { (object) in
                self.sendButton.removeSpinner()
                self.delegate?.shouldCloseAll()
            }) { (error) in
                self.sendButton.removeSpinner()
                self.displayError("Error sending feedback")
        }
    }
    
    func displayError(text: String) {
        errorLabel.text = text
        UIView.animateWithDuration(0.333) {
            self.errorLabel.alpha = 1
            self.view.layoutIfNeeded()
        }
        
        if (errorLabelTimer != nil) {
            errorLabelTimer.invalidate()
            errorLabelTimer = nil
        }
        
        errorLabelTimer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(FeedbackViewController.hideError), userInfo: nil, repeats: false)
    }
    
    func hideError() {
        UIView.animateWithDuration(0.333) {
            self.errorLabel.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
}