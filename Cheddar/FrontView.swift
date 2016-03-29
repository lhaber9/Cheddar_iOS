//
//  FrontView.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/28/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol FrontPageViewDelegate: class {
    func goToNextPage()
    func goToPrevPage()
    func joinChat(isOneOnOne: Bool)
    //    func animateScrollViewToRaised()
    //    func animateScrollViewToDefault()
}

class FrontPageView: UIView {
    
    weak var delegate: FrontPageViewDelegate?
    
    func goToNextPageWithController(viewController: FrontPageView) {
        delegate?.goToNextPage()
    }
}
