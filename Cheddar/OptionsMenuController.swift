//
//  OptionsMenuController.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/20/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol OptionsMenuControllerDelegate: class {
    func selectedFeedback()
}


class OptionsMenuController: UIViewController {
    
    weak var delegate: OptionsMenuControllerDelegate?
    
    @IBAction func tappedFeedback() {
        delegate!.selectedFeedback()
    }
}