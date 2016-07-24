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
    
    override func viewDidLoad() {
        textView.layer.cornerRadius = 5
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.grayColor().CGColor
        sendButton.setPrimaryButton()
        errorLabel.textColor = ColorConstants.colorAccent
        titleLabel.textColor = ColorConstants.colorAccent
    }
    
    @IBAction func sendFeedback() {
        sendButton.displaySpinner()
        
        CheddarRequest.sendFeedback(textView.text, alias: (delegate?.myAlias())!, successCallback: { (object) in
                self.sendButton.removeSpinner()
                self.delegate?.shouldCloseAll()
            }) { (error) in
                self.sendButton.removeSpinner()
                self.displayError()
        }
    }
    
    func displayError() {
        UIView.animateWithDuration(0.333) {
            self.errorLabel.alpha = 1
            self.view.layoutIfNeeded()
        }
        
        NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(FeedbackViewController.hideError), userInfo: nil, repeats: false)
    }
    
    func hideError() {
        UIView.animateWithDuration(0.333) {
            self.errorLabel.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
}