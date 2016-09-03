//
//  FullPageScrollView.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/7/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class FullPageScrollView: UIViewController, UIScrollViewDelegate, FrontPageViewDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    var scrollViewWidthConstraint: NSLayoutConstraint!
    
    var pages: [UIView]! = []
    var currentPageIndex: Int = 0
    
    var isAnimatingPages = false
    
    override func viewDidLoad() {
        scrollView.delegate = self
    }
    
    func currentPage() -> UIView {
        return pages[currentPageIndex]
    }
    
    func addPage(_ pageContents: UIView) {
        if (scrollViewWidthConstraint != nil) {
            scrollView.removeConstraint(scrollViewWidthConstraint)
        }
        
        scrollViewWidthConstraint = nil
        scrollView.addSubview(pageContents)
        
        pageContents.autoSetDimension(ALDimension.width, toSize: UIScreen.main.bounds.size.width)
        
        if (pages.count > 0) {
            let lastPage = pages.last!
            pageContents.autoPinEdge(ALEdge.top, to: ALEdge.top, of: lastPage)
            pageContents.autoPinEdge(ALEdge.bottom, to: ALEdge.bottom, of: lastPage)
            pageContents.autoPinEdge(ALEdge.left, to: ALEdge.right, of: lastPage)
        }
        else {
            pageContents.autoPinEdge(toSuperviewEdge: ALEdge.left)
            pageContents.autoPinEdge(toSuperviewEdge: ALEdge.top)
            pageContents.autoPinEdge(toSuperviewEdge: ALEdge.bottom)
            pageContents.autoPinEdge(ALEdge.top, to: ALEdge.top, of: view, withOffset: -22)
            pageContents.autoPinEdge(ALEdge.bottom, to: ALEdge.bottom, of: view)
        }
        
        scrollViewWidthConstraint = NSLayoutConstraint(item: pageContents, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: scrollView, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0)
        scrollViewWidthConstraint.priority = 900
        
        scrollView.addConstraint(scrollViewWidthConstraint)
        
        pages.append(pageContents)
    }
    
    func didScrollToPage(_ page: Int) {
        // implemented by subclasses
    }
    
    @IBAction func goToNextPage() {
        if (isAnimatingPages) { return }
        scrollToPage(currentPageIndex + 1, animated: true)
    }
    
    @IBAction func goToPrevPage() {
        if (isAnimatingPages) { return }
        scrollToPage(currentPageIndex - 1, animated: true)
    }
    
    func goToLastPage() {
        scrollToPage(pages.count - 1, animated: true)
    }
    
    func goToLastPageNoAnimation() {
        scrollToPage(pages.count - 1, animated: false)
        didScrollToPage(pages.count - 1)
    }
    
    func goToFirstPage() {
        scrollToPage(0, animated: true)
    }
    
    func scrollToPage(_ pageIdx: Int, animated: Bool) {
        if (pageIdx < 0 || pageIdx >= pages.count) {
            return
        }
        isAnimatingPages = true
        
        currentPageIndex = pageIdx
        scrollView.setContentOffset(CGPoint(x: scrollView.frame.size.width * CGFloat(currentPageIndex),y: 0.0), animated:animated)
    }
    
    // MARK: FrontPageViewDelegate
    
//    func showChat() {
//        delegate.showChat()
//    }
//
//    func showLogin() {
//        delegate.showLogin()
//    }
  
    // MARK: UIScrollViewDelegate

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentPageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width);
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isAnimatingPages = false
        currentPageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width);
    }
    
//    func scrollViewDidScroll(scrollView: UIScrollView) {
//        delegate.scrollViewDidScroll(scrollView)
//    }
}
