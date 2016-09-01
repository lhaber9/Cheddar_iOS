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
    
    var colorHighlightChange: CGFloat = 0.04
    var buttonHighlighted = false
    
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
        titleLabel?.font = UIFont(name: "Effra-Medium", size: 18)
        self.backgroundColor = ColorConstants.colorAccent
        
        layer.masksToBounds = false
        layer.cornerRadius = 3
        layer.shadowOpacity = 0.35
        layer.shadowColor = UIColor.blackColor().CGColor
        
        adjustsImageWhenHighlighted = false
        
        spinner = UIActivityIndicatorView(forAutoLayout: ())
        spinner.alpha = 0
        addSubview(spinner)
        spinner.autoCenterInSuperview()
        
        setStandardShadow()
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
    
    func alterBackgroundColor(change: CGFloat) {
        let components = CGColorGetComponents(backgroundColor?.CGColor)
        let red = components[0]
        let green = components[1]
        let blue = components[2]
        
        backgroundColor = UIColor(red: red + change,
                                  green: green + change,
                                  blue: blue + change,
                                  alpha: 1)
    }
    
    func setStandardShadow() {
        layer.shadowOffset = CGSizeMake(1, 1);
        layer.shadowRadius = 1;
        
        if (buttonHighlighted) {
            alterBackgroundColor(colorHighlightChange)
            buttonHighlighted = false
        }
    }
    
    func setActiveShadow() {
        layer.shadowOffset = CGSizeMake(1, 2.5);
        layer.shadowRadius = 2.5;
        
        if (!buttonHighlighted) {
            alterBackgroundColor(-1 * colorHighlightChange)
            buttonHighlighted = true
        }
    }
    
    func setPrimaryButton() {
        backgroundColor = ColorConstants.colorAccent
        setTitleColor(ColorConstants.whiteColor, forState: UIControlState.Normal)
    }
    
    func setInversePrimaryButton() {
        backgroundColor = ColorConstants.whiteColor
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