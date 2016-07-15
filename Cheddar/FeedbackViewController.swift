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
    
    override func viewDidLoad() {
        textView.layer.cornerRadius = 5
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.grayColor().CGColor
        sendButton.setPrimaryButton()
        titleLabel.textColor = ColorConstants.colorAccent
    }
    
    @IBAction func sendFeedback() {
        CheddarRequest.sendFeedback(textView.text, alias: (delegate?.myAlias())!, successCallback: { (object) in
            }) { (error) in
        }
        
        delegate?.shouldCloseAll()
    }
}