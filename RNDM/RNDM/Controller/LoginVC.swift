//
//  LoginVC.swift
//  RNDM
//
//  Created by Octavian Duminica on 26/07/2018.
//  Copyright © 2018 Octavian Duminica. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginVC: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var createUserButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.layer.cornerRadius = 10
        createUserButton.layer.cornerRadius = 10
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, let password = passwordTextField.text else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (user, error) in
            guard let weakSelf = self else { return }
            if let error = error {
                debugPrint("Error signing in: \(error)")
            } else {
                weakSelf.dismiss(animated: true, completion: nil)
            }
        }
    }
}
