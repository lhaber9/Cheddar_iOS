//
//  OptionsOverlayViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 4/14/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol OptionsOverlayViewDelegate: class {
    func selectedFeedback()
    func tryLeaveChatRoom()
    func shouldCloseOptions()
}

class OptionsOverlayViewController: UIViewController {
    
    weak var delegate:OptionsOverlayViewDelegate!
    
    @IBOutlet var cancelView: UIView!
    @IBOutlet var leaveChatView: UIView!
    @IBOutlet var sendFeedbackView: UIView!
    
    @IBOutlet var cancelLabel: UILabel!
    @IBOutlet var leaveChatLabel: UILabel!
    @IBOutlet var sendFeedbackLabel: UILabel!
    
    @IBOutlet var showingButtonsConstraint: NSLayoutConstraint!
    @IBOutlet var hiddenButtonsConstraint: NSLayoutConstraint!
    
    override func viewDidLayoutSubviews() {
        leaveChatView.rounded(unsafeBitCast(UIRectCorner.BottomLeft.rawValue | UIRectCorner.BottomRight.rawValue, UIRectCorner.self), radius: 5)
        sendFeedbackView.rounded(unsafeBitCast(UIRectCorner.TopRight.rawValue | UIRectCorner.TopLeft.rawValue, UIRectCorner.self), radius: 5)
        
        cancelView.layer.cornerRadius = 5
    }
    
    override func viewDidLoad() {
        cancelView.backgroundColor = ColorConstants.colorAccent
        leaveChatView.backgroundColor = UIColor.whiteColor()
        sendFeedbackView.backgroundColor = UIColor.whiteColor()
        
        cancelLabel.textColor = UIColor.whiteColor()
        leaveChatLabel.textColor = ColorConstants.colorAccent
        sendFeedbackLabel.textColor = ColorConstants.colorAccent
        
        showingButtonsConstraint.priority = 200
        hiddenButtonsConstraint.priority = 900
        view.layoutIfNeeded()
    }
    
    func willShow() {
        UIView.animateWithDuration(0.5) {
            self.showingButtonsConstraint.priority = 900
            self.hiddenButtonsConstraint.priority = 200
            self.view.layoutIfNeeded()
        }
    }
    
    func willHide() {
        UIView.animateWithDuration(0.5) {
            self.showingButtonsConstraint.priority = 200
            self.hiddenButtonsConstraint.priority = 900
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func cancelTap() {
        shouldClose()
    }
    
    @IBAction func leaveChatTap() {
        shouldClose()
        delegate.tryLeaveChatRoom()
    }
    
    @IBAction func sendFeedbackTap() {
        shouldClose()
        delegate.selectedFeedback()
    }
    
    @IBAction func shouldClose() {
        delegate.shouldCloseOptions()
    }
}