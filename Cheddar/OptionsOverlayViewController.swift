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
    var buttonData: [AnyObject?] = []
    var buttonActions: [(_ object: AnyObject?) -> Void] = []
    
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
        
        for (index, optionButton) in optionButtons.enumerated() {
            optionButton.setInversePrimaryButton()
            optionButton.layer.shadowOpacity = 0.55
            
            view.addSubview(optionButton)
            
            let hiddenConstraintConstant = (CGFloat(optionButtons.count - index - 1) * (buttonHeight + optionbuttonPad)) + optionbuttonPad
            
            let hiddenConstraint = NSLayoutConstraint(item: optionButton, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: hiddenConstraintConstant)
            hiddenConstraint.priority = 900
        
            let showingConstraintConstant = showingCancelButtonConstraint.constant + buttonHeight + cancelButtonPad + (CGFloat(index) * (buttonHeight + optionbuttonPad))
            
            let showingConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: optionButton, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: showingConstraintConstant)
            showingConstraint.priority = 200
            
            optionButton.autoPinEdge(ALEdge.left, to: ALEdge.left, of: cancelButton)
            optionButton.autoPinEdge(ALEdge.right, to: ALEdge.right, of: cancelButton)
            optionButton.autoSetDimension(ALDimension.height, toSize: buttonHeight)
            
            view.addConstraint(hiddenConstraint)
            view.addConstraint(showingConstraint)
            
            showingConstraints.append(showingConstraint)
            hiddenConstraints.append(hiddenConstraint)
        }
        
        tapAwayView.autoPinEdge(ALEdge.bottom, to: ALEdge.top, of: optionButtons.first!)
    
        view.layoutIfNeeded()
    }
    
    func setButtonNames(_ buttonNames: [String], andActions buttonActions: [(_ object: AnyObject?) -> Void], andButtonData buttonData:[AnyObject?]) {
        self.buttonNames = buttonNames
        self.buttonActions = buttonActions
    }
    
    func setupButtons() {
        for (index, name) in buttonNames.enumerated() {
            let button = CheddarButton.newCheddarButton()
            button.setTitle(name, for: UIControlState.normal)
            button.buttonIndex = index
            
            button.addTarget(self, action: #selector(OptionsOverlayViewController.tapOptionButton(_:)), for: UIControlEvents.touchUpInside)
            
            optionButtons.append(button)
        }
    }
    
    func tapOptionButton(_ button: CheddarButton) {
        buttonActions[button.buttonIndex](buttonData[button.buttonIndex])
    }
    
    func willShow() {
        for (index, showingConstraint) in showingConstraints.reversed().enumerated() {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.55, delay:Double(index) * 0.05, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                        showingConstraint.priority = 950
                        self.view.layoutIfNeeded()
                    }, completion: nil)
            }
        }
    }
    
    func willHide() {
        for showingConstraint in showingConstraints{
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.55, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                        showingConstraint.priority = 200
                        self.view.layoutIfNeeded()
                    }, completion: nil)
            }
        }
    }
    
    @IBAction func shouldClose() {
        willHide()
        delegate.hideOverlayContents()
        delegate.hideOverlay()
    }
}
