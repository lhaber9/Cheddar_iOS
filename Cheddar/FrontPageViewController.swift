//
//  FrontPageViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/4/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol FrontPageViewControllerDelegate: class {
    func goToNextPageWithController(viewController: FrontPageViewController)
    func showChat()
    func raiseScrollView()
    func lowerScrollView()
}

class FrontPageViewController: UIViewController {
    
    weak var delegate: FrontPageViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}