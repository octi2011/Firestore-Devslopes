//
//  CreateUserVC.swift
//  RNDM
//
//  Created by Octavian Duminica on 26/07/2018.
//  Copyright © 2018 Octavian Duminica. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase

class CreateUserVC: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createButton.layer.cornerRadius = 10
        cancelButton.layer.cornerRadius = 10
    }
    
    @IBAction func onCreateTapped(_ sender: Any) {
        guard let email = emailTextField.text,
            let password = passwordTextField.text,
            let username = usernameTextField.text else { return }
        
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if let error = error {
                debugPrint("Error creating user: \(error.localizedDescription)")
            }
            
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = username
            changeRequest?.commitChanges(completion: { (error) in
                if let error = error {
                    debugPrint(error.localizedDescription)
                }
            })
            
            guard let userId = Auth.auth().currentUser?.uid else { return }
            Firestore.firestore().collection(USERS_REF).document(userId).setData([
                USERNAME: username,
                DATE_CREATED: FieldValue.serverTimestamp()
                ], completion: { [weak self] (error) in
                    guard let weakSelf = self else { return }
                    if let error = error {
                        debugPrint(error.localizedDescription)
                    } else {
                        weakSelf.dismiss(animated: true, completion: nil)
                    }
            })
        }
    }
    
    @IBAction func onCancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
