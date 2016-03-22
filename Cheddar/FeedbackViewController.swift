//
//  FeedbackViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/21/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol FeedbackViewDelegate: class {
    func myAlias() -> Alias
    func shouldClose()
}

class FeedbackViewController: UIViewController {
    
    weak var delegate: FeedbackViewDelegate?
    
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        
        textView.layer.cornerRadius = 5;
        textView.layer.borderWidth = 1;
        textView.layer.borderColor = UIColor.grayColor().CGColor
        
    }
    
    @IBAction func sendFeedback() {
        Utilities.appDelegate().sendFeedback(textView.text, alias: (delegate?.myAlias())!)
        delegate?.shouldClose()
    }
}