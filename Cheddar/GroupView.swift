//
//  GroupView.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/28/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class GroupView: FrontPageView {
    class func instanceFromNib() -> GroupView {
        return UINib(nibName: "GroupView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! GroupView
    }
}