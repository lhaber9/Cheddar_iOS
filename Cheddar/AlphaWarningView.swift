//
//  AlphaWarningView.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/28/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class AlphaWarningView: FrontPageView {
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "AlphaWarningView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! AlphaWarningView
    }
}