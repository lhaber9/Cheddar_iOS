//
//  RegisterViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/4/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class RegisterViewController: FrontPageViewController {
    
    @IBOutlet var emailTextField: UITextField!
    
    @IBAction func goToNext() {
        tapOut()
        if (isEmailVaildated()) {
            delegate?.goToNextPageWithController(SelectionViewController())
        }
        else {
            delegate?.goToNextPageWithController(EmailValidateViewController())
        }
    }
    
    func isEmailVaildated() -> Bool {
        return false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLoad() {
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapOut"))
    }
    
    func tapOut() {
        emailTextField.resignFirstResponder()
    }
    
    func keyboardWillShow() {
        delegate?.raiseScrollView()
    }
    
    func keyboardWillHide() {
        delegate?.lowerScrollView()
    }
    
}