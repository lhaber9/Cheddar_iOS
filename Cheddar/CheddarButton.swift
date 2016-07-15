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
    
    override func awakeFromNib() {
        tintColor = ColorConstants.textPrimary
        titleLabel?.font = UIFont(name: "Effra-Regular", size: 17)
        self.backgroundColor = ColorConstants.colorAccent
        
        layer.masksToBounds = false
        layer.cornerRadius = 3
        layer.shadowOpacity = 0.35
        layer.shadowColor = UIColor.blackColor().CGColor
        
        setStandardShadow()
        
        adjustsImageWhenHighlighted = false
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
    
    func setSecondaryButton() {
        backgroundColor = ColorConstants.solidGray
        setTitleColor(ColorConstants.textPrimary, forState: UIControlState.Normal)
    }
}