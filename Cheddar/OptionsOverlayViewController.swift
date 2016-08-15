//
//  OptionsOverlayViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 4/14/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol OptionsOverlayViewDelegate: class {
    func hideOverlayContents()
    func hideOverlay()
}

class OptionsOverlayViewController: UIViewController {
    
    weak var delegate:OptionsOverlayViewDelegate!
    
    @IBOutlet var showingCancelButtonConstraint: NSLayoutConstraint!
    @IBOutlet var hiddenCancelButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet var tapAwayView: UIView!
    
    @IBOutlet var cancelButton: CheddarButton!
    var optionButtons: [CheddarButton] = []
    
    var showingConstraints: [NSLayoutConstraint] = []
    var hiddenConstraints: [NSLayoutConstraint] = []
    
    var buttonHeight: CGFloat = 50
    var cancelButtonPad: CGFloat = 28
    var optionbuttonPad: CGFloat = 4
    
    var buttonNames: [String] = []
    var buttonData: [AnyObject!] = []
    var buttonActions: [(object: AnyObject!) -> Void] = []
    
//    override func viewDidLayoutSubviews() {
//        
//        // round only top and bottom corners stuff (not working with shadow)
////        if(optionButtons.count > 1) {
////            optionButtons.first!.rounded(unsafeBitCast(UIRectCorner.BottomLeft.rawValue | UIRectCorner.BottomRight.rawValue, UIRectCorner.self), radius: 5)
////            optionButtons.last!.rounded(unsafeBitCast(UIRectCorner.TopRight.rawValue | UIRectCorner.TopLeft.rawValue, UIRectCorner.self), radius: 5)
////        }
//        
//    }
    
    override func viewDidLoad() {
        setupButtons()
        
        cancelButton.setPrimaryButton()
        cancelButton.layer.shadowOpacity = 0.55
    
        showingCancelButtonConstraint.priority = 200
        hiddenCancelButtonConstraint.priority = 900
        
        hiddenCancelButtonConstraint.constant = -1 * ((CGFloat(optionButtons.count) * (buttonHeight + optionbuttonPad)) + cancelButtonPad)
        
        showingConstraints.append(showingCancelButtonConstraint)
        hiddenConstraints.append(hiddenCancelButtonConstraint)
        
        for (index, optionButton) in optionButtons.enumerate() {
            optionButton.setInversePrimaryButton()
            optionButton.layer.shadowOpacity = 0.55
            
            view.addSubview(optionButton)
            
            let hiddenConstraintConstant = (CGFloat(optionButtons.count - index - 1) * (buttonHeight + optionbuttonPad)) + optionbuttonPad
            
            let hiddenConstraint = NSLayoutConstraint(item: optionButton, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: hiddenConstraintConstant)
            hiddenConstraint.priority = 900
        
            let showingConstraintConstant = showingCancelButtonConstraint.constant + buttonHeight + cancelButtonPad + (CGFloat(index) * (buttonHeight + optionbuttonPad))
            
            let showingConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: optionButton, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: showingConstraintConstant)
            showingConstraint.priority = 200
            
            optionButton.autoPinEdge(ALEdge.Left, toEdge: ALEdge.Left, ofView: cancelButton)
            optionButton.autoPinEdge(ALEdge.Right, toEdge: ALEdge.Right, ofView: cancelButton)
            optionButton.autoSetDimension(ALDimension.Height, toSize: buttonHeight)
            
            view.addConstraint(hiddenConstraint)
            view.addConstraint(showingConstraint)
            
            showingConstraints.append(showingConstraint)
            hiddenConstraints.append(hiddenConstraint)
        }
        
        tapAwayView.autoPinEdge(ALEdge.Bottom, toEdge: ALEdge.Top, ofView: optionButtons.first!)
    
        view.layoutIfNeeded()
    }
    
    func setButtonNames(buttonNames: [String], andActions buttonActions: [(object: AnyObject!) -> Void], andButtonData buttonData:[AnyObject!]) {
        self.buttonNames = buttonNames
        self.buttonActions = buttonActions
    }
    
    func setupButtons() {
        for (index, name) in buttonNames.enumerate() {
            let button = CheddarButton.newCheddarButton()
            button.setTitle(name, forState: UIControlState.Normal)
            button.buttonIndex = index
            
            button.addTarget(self, action: #selector(OptionsOverlayViewController.tapOptionButton(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            
            optionButtons.append(button)
        }
    }
    
    func tapOptionButton(button: CheddarButton) {
        buttonActions[button.buttonIndex](object: buttonData[button.buttonIndex])
    }
    
    func willShow() {
        for (index, showingConstraint) in showingConstraints.reverse().enumerate() {
            dispatch_after(0, dispatch_get_main_queue()) {
                UIView.animateWithDuration(0.55, delay:Double(index) * 0.05, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                        showingConstraint.priority = 950
                        self.view.layoutIfNeeded()
                    }, completion: nil)
            }
        }
    }
    
    func willHide() {
        for showingConstraint in showingConstraints{
            dispatch_async(dispatch_get_main_queue(), {
                UIView.animateWithDuration(0.55, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                        showingConstraint.priority = 200
                        self.view.layoutIfNeeded()
                    }, completion: nil)
            })
        }
    }
    
    @IBAction func shouldClose() {
        willHide()
        delegate.hideOverlayContents()
        delegate.hideOverlay()
    }
}