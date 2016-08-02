//
//  CheddarButton.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/29/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

@IBDesignable
class CheddarButton: UIButton {
    
    var spinner: UIActivityIndicatorView!
    var buttonIndex: Int!
    var shadowLayer:CALayer!
    
    class func newCheddarButton() -> CheddarButton {
        let newButton = CheddarButton(type: UIButtonType.Custom)
        newButton.setup()
        return newButton
    }
    
    override func awakeFromNib() {
        setup()
    }
    
    override func rounded(corners: UIRectCorner, radius: CGFloat) {
        layer.cornerRadius = 0
        super.rounded(corners, radius: radius)
    }
    
    func setup() {
        tintColor = ColorConstants.textPrimary
        titleLabel?.font = UIFont(name: "Effra-Regular", size: 17)
        self.backgroundColor = ColorConstants.colorAccent
        
        layer.masksToBounds = false
        layer.cornerRadius = 3
        layer.shadowOpacity = 0.35
        layer.shadowColor = UIColor.blackColor().CGColor
        
        setStandardShadow()
        
        adjustsImageWhenHighlighted = false
        
        spinner = UIActivityIndicatorView(forAutoLayout: ())
        spinner.alpha = 0
        addSubview(spinner)
        spinner.autoCenterInSuperview()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        setActiveShadow()
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        if (self.pointInside(touches.first!.locationInView(self), withEvent: nil)) {
            setActiveShadow()
        }
        else {
            setStandardShadow()
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        setStandardShadow()
    }
    
    func setStandardShadow() {
        layer.shadowOffset = CGSizeMake(1, 1);
        layer.shadowRadius = 1;
    }
    
    func setActiveShadow() {
        layer.shadowOffset = CGSizeMake(1, 2.5);
        layer.shadowRadius = 2.5;
    }
    
    func setPrimaryButton() {
        backgroundColor = ColorConstants.colorAccent
        setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
    }
    
    func setInversePrimaryButton() {
        backgroundColor = UIColor.whiteColor()
        setTitleColor(ColorConstants.colorAccent, forState: UIControlState.Normal)
    }
    
    func setSecondaryButton() {
        backgroundColor = ColorConstants.solidGray
        setTitleColor(ColorConstants.textPrimary, forState: UIControlState.Normal)
    }
    
    func displaySpinner() {
        enabled = false
        spinner.startAnimating()
    
        UIView.animateWithDuration(0.33) {
            self.spinner.alpha = 1
            self.titleLabel?.alpha = 0
            self.layoutIfNeeded()
        }
    }
    
    func removeSpinner() {
        enabled = true
        UIView.animateWithDuration(0.33) {
            self.spinner.alpha = 0
            self.titleLabel?.alpha = 1
            self.spinner.stopAnimating()
            self.layoutIfNeeded()
        }
    }
}