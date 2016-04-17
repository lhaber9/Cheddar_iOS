//
//  FeedbackViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/21/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol FeedbackViewDelegate: class {
    func currentAlias() -> Alias!
    func shouldClose()
}

class FeedbackViewController: UIViewController {
    
    weak var delegate: FeedbackViewDelegate?
    
    @IBOutlet var textView: UITextView!
    @IBOutlet var buttonView: UIView!
    @IBOutlet var sendLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    
    override func viewDidLoad() {
        textView.layer.cornerRadius = 5
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.grayColor().CGColor
        buttonView.layer.cornerRadius = 5
        buttonView.backgroundColor = ColorConstants.chatNavBackground
        sendLabel.textColor = ColorConstants.textPrimary
        titleLabel.textColor = ColorConstants.colorAccent
    }
    
    @IBAction func sendFeedback() {
        Utilities.appDelegate().sendFeedback(textView.text, alias: (delegate?.currentAlias())!)
        delegate?.shouldClose()
    }
}