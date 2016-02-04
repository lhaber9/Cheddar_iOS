//
//  ViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/1/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import UIKit


class ViewController: UIViewController, FrontPageViewControllerDelegate {

    @IBOutlet var shadowBackgroundView: UIView!
    @IBOutlet var container0: UIView!
    
    @IBOutlet var emailView: UIView!
    @IBOutlet var confirmView: UIView!
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewWidthConstraint: NSLayoutConstraint!
    
    var containers: [UIView]!
    var currentPage: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setShawdowForView(shadowBackgroundView)
        shadowBackgroundView.layer.shadowRadius = 5;
        shadowBackgroundView.layer.shadowOpacity = 0.8;
        
        containers = [container0]
        let introViewController = IntroViewController()
        addViewControllerPageToLastContainer(introViewController)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func goToNext() {
        scrollToPage(currentPage + 1)
    }
    
    func scrollToPage(pageIdx: Int) {
        scrollView.setContentOffset(CGPointMake(scrollView.frame.size.width * CGFloat(pageIdx), 0.0), animated:true)
        currentPage = pageIdx
    }
    
    func addContainer() {
        containers.last!.removeConstraint(scrollViewWidthConstraint)
        let containerView = UIView()
        scrollView.addSubview(containerView)
        
        containerView.autoMatchDimension(ALDimension.Width, toDimension:ALDimension.Width, ofView: containers.last!)
        containerView.autoPinEdgeToSuperviewEdge(ALEdge.Top, withInset: 5)
        containerView.autoPinEdgeToSuperviewEdge(ALEdge.Bottom, withInset: 5)
        containerView.autoPinEdge(ALEdge.Left, toEdge: ALEdge.Right, ofView: containers.last!)
        scrollViewWidthConstraint = containerView.autoPinEdgeToSuperviewEdge(ALEdge.Trailing)

        containers.append(containerView)
    }
    
    func addViewControllerPageToLastContainer(viewController: FrontPageViewController) {
        
        viewController.delegate = self
        addChildViewController(viewController)
        let view = viewController.view
        
        let containerView = containers.last!
        containerView.addSubview(view)
        
        view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
        view.autoPinEdgeToSuperviewEdge(ALEdge.Top)
        view.autoSetDimension(ALDimension.Width, toSize: 320)
        view.autoAlignAxisToSuperviewAxis(ALAxis.Vertical)
        
        setShawdowForView(view)
    }
    
    func setShawdowForView(view: UIView) {
        view.layer.masksToBounds = false;
        view.layer.shadowOffset = CGSizeMake(0, 0);
        view.layer.shadowRadius = 3;
        view.layer.shadowOpacity = 0.5;
    }
    
    func goToNextPageWithController(viewController: FrontPageViewController) {
        addContainer()
        addViewControllerPageToLastContainer(viewController)
        goToNext()
    }
}

