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
        let newButton = CheddarButton(type: UIButtonType.custom)
        newButton.setup()
        return newButton
    }
    
    override func awakeFromNib() {
        setup()
    }
    
    override func rounded(_ corners: UIRectCorner, radius: CGFloat) {
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
        layer.shadowColor = UIColor.black.cgColor
        
        adjustsImageWhenHighlighted = false
        
        spinner = UIActivityIndicatorView(forAutoLayout: ())
        spinner.alpha = 0
        addSubview(spinner)
        spinner.autoCenterInSuperview()
        
        setStandardShadow()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        setActiveShadow()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if (self.point(inside: touches.first!.location(in: self), with: nil)) {
            setActiveShadow()
        }
        else {
            setStandardShadow()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        setStandardShadow()
    }
    
    func alterBackgroundColor(_ change: CGFloat) {
        let components = (backgroundColor?.cgColor)?.components
        let red = components?[0]
        let green = components?[1]
        let blue = components?[2]
        
        backgroundColor = UIColor(red: red! + change,
                                  green: green! + change,
                                  blue: blue! + change,
                                  alpha: 1)
    }
    
    func setStandardShadow() {
        layer.shadowOffset = CGSize(width: 1,height: 1)
        layer.shadowRadius = 1
        
        if (buttonHighlighted) {
            alterBackgroundColor(colorHighlightChange)
            buttonHighlighted = false
        }
    }
    
    func setActiveShadow() {
        layer.shadowOffset = CGSize(width: 1,height: 2.5)
        layer.shadowRadius = 2.5
        
        if (!buttonHighlighted) {
            alterBackgroundColor(-1 * colorHighlightChange)
            buttonHighlighted = true
        }
    }
    
    func setPrimaryButton() {
        backgroundColor = ColorConstants.colorAccent
        setTitleColor(ColorConstants.whiteColor, for: UIControlState.normal)
    }
    
    func setInversePrimaryButton() {
        backgroundColor = ColorConstants.whiteColor
        setTitleColor(ColorConstants.colorAccent, for: UIControlState.normal)
    }
    
    func setSecondaryButton() {
        backgroundColor = ColorConstants.solidGray
        setTitleColor(ColorConstants.textPrimary, for: UIControlState.normal)
    }
    
    func displaySpinner() {
        isEnabled = false
        spinner.startAnimating()
    
        UIView.animate(withDuration: 0.33) {
            self.spinner.alpha = 1
            self.titleLabel?.alpha = 0
            self.layoutIfNeeded()
        }
    }
    
    func removeSpinner() {
        isEnabled = true
        UIView.animate(withDuration: 0.33) {
            self.spinner.alpha = 0
            self.titleLabel?.alpha = 1
            self.spinner.stopAnimating()
            self.layoutIfNeeded()
        }
    }
}
