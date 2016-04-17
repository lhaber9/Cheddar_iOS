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
    func shouldClose()
}

class OptionsOverlayViewController: UIViewController {
    
    weak var delegate:OptionsOverlayViewDelegate!
    
    @IBOutlet var cancelView: UIView!
    @IBOutlet var leaveChatView: UIView!
    @IBOutlet var sendFeedbackView: UIView!
    
    @IBOutlet var cancelLabel: UILabel!
    @IBOutlet var leaveChatLabel: UILabel!
    @IBOutlet var sendFeedbackLabel: UILabel!
    
    @IBOutlet var showingCancelButtonConstraint: NSLayoutConstraint!
    @IBOutlet var showingLeaveButtonConstraint: NSLayoutConstraint!
    @IBOutlet var showingFeedbackButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet var hiddenCancelButtonConstraint: NSLayoutConstraint!
    @IBOutlet var hiddenLeaveButtonConstraint: NSLayoutConstraint!
    @IBOutlet var hiddenFeedbackButtonConstraint: NSLayoutConstraint!
    
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
        
        hideAllButtons()
        view.layoutIfNeeded()
    }
    
    func hideAllButtons() {
        showingCancelButtonConstraint.priority = 200
        showingLeaveButtonConstraint.priority = 200
        showingFeedbackButtonConstraint.priority = 200
        
        hiddenCancelButtonConstraint.priority = 900
        hiddenLeaveButtonConstraint.priority = 900
        hiddenFeedbackButtonConstraint.priority = 900
    }
    
    func willShow() {
        dispatch_async(dispatch_get_main_queue(), {
            UIView.animateWithDuration(0.55, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                self.showingFeedbackButtonConstraint.priority = 900
                self.hiddenFeedbackButtonConstraint.priority = 200
                self.view.layoutIfNeeded()
            }, completion: nil)
        })
        dispatch_async(dispatch_get_main_queue(), {
            UIView.animateWithDuration(0.55, delay: 0.05, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                self.showingLeaveButtonConstraint.priority = 900
                self.hiddenLeaveButtonConstraint.priority = 200
                self.view.layoutIfNeeded()
            }, completion: nil)
        })
        dispatch_async(dispatch_get_main_queue(), {
            UIView.animateWithDuration(0.55, delay: 0.1, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                self.showingCancelButtonConstraint.priority = 900
                self.hiddenCancelButtonConstraint.priority = 200
                self.view.layoutIfNeeded()
            }, completion: nil)
        })
    }
    
    func willHide() {
        UIView.animateWithDuration(0.65, delay: 0, usingSpringWithDamping: 0.55, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.hideAllButtons()
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @IBAction func cancelTap() {
        shouldClose()
    }
    
    @IBAction func leaveChatTap() {
        shouldClose()
        delegate.tryLeaveChatRoom()
    }
    
    @IBAction func sendFeedbackTap() {
        delegate.shouldCloseOptions()
        delegate.selectedFeedback()
    }
    
    @IBAction func shouldClose() {
        delegate.shouldClose()
    }
}