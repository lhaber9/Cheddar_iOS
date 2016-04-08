//
//  AlphaWarningView.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/28/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class AlphaWarningView: FrontPageView {
    
    @IBOutlet var joinButton: CheddarButton!
    @IBOutlet var joinButtonView: UIView!
    
    class func instanceFromNib() -> AlphaWarningView {
        return UINib(nibName: "AlphaWarningView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! AlphaWarningView
    }
    
    override func awakeFromNib() {
        joinButtonView.layer.masksToBounds = false;
        setStandardShadow()
    }
    
    func setStandardShadow() {
        joinButtonView.layer.shadowOffset = CGSizeMake(0, 1);
        joinButtonView.layer.shadowRadius = 1;
        joinButtonView.layer.shadowOpacity = 0.45;
        joinButtonView.layer.shadowColor = UIColor.blackColor().CGColor
        joinButtonView.layer.shadowPath = UIBezierPath(rect: joinButtonView.bounds).CGPath;
    }
    
    func setActiveShadow() {
        joinButtonView.layer.shadowOffset = CGSizeMake(0, 5);
        joinButtonView.layer.shadowRadius = 2;
        joinButtonView.layer.shadowOpacity = 0.55;
        joinButtonView.layer.shadowColor = UIColor.blackColor().CGColor
        joinButtonView.layer.shadowPath = UIBezierPath(rect: joinButtonView.bounds).CGPath;
    }
    
    @IBAction func tapDownButton() {
        setActiveShadow()
    }
    
    @IBAction func tapUpButton() {
        setStandardShadow()
        joinChat()
    }
    
    func joinChat() {
        delegate?.showChat()
    }
}