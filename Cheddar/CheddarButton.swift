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
        
        layer.shadowOffset = CGSizeMake(0.5, 0.5)
        layer.shadowRadius = 0.5
        
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
//        
//        let shadowOffset = CABasicAnimation.init(keyPath: "shadowOffset")
//        shadowOffset.fromValue = NSValue(CGSize: CGSizeMake(0.5, 2.5))
//        shadowOffset.toValue = NSValue(CGSize: CGSizeMake(0.5, 0.5))
//        shadowOffset.duration = 1.0;
//        
//        
//        let shadowRadius = CABasicAnimation.init(keyPath: "shadowRadius")
//        shadowOffset.fromValue = 1.5
//        shadowOffset.toValue = 0.5
//        shadowOffset.duration = 0.1;
//        
//        layer.addAnimation(shadowRadius, forKey: "shadowRadius")
//        layer.addAnimation(shadowOffset, forKey: "shadowOffset")
        
        layer.shadowOffset = CGSizeMake(0.5, 0.5);
        layer.shadowRadius = 0.5;
    }
    
    func setActiveShadow() {
        
//        let shadowOffset = CABasicAnimation.init(keyPath: "shadowOffset")
//        shadowOffset.fromValue = NSValue(CGSize: CGSizeMake(0.5, 0.5))
//        shadowOffset.toValue = NSValue(CGSize: CGSizeMake(0.5, 2.5))
//        shadowOffset.duration = 0.1;
//        
//        let shadowRadius = CABasicAnimation.init(keyPath: "shadowRadius")
//        shadowOffset.fromValue = 0.5
//        shadowOffset.toValue = 1.5
//        shadowOffset.duration = 1.0;
//        
//        layer.addAnimation(shadowRadius, forKey: "shadowRadius")
//        layer.addAnimation(shadowOffset, forKey: "shadowOffset")
        
        layer.shadowOffset = CGSizeMake(0.5, 2.5);
        layer.shadowRadius = 1.5;

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