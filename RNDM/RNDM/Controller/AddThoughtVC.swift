//
//  AddThoughtVC.swift
//  RNDM
//
//  Created by Octavian Duminica on 26/07/2018.
//  Copyright © 2018 Octavian Duminica. All rights reserved.
//

import UIKit
import Firebase

class AddThoughtVC: UIViewController {
    
    @IBOutlet weak var categorySegment: UISegmentedControl!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var thoughtTextView: UITextView!
    @IBOutlet weak var postButton: UIButton!
    
    private var selectedCategory = ThoughtCategory.funny.rawValue
    
    override func viewDidLoad() {
        super.viewDidLoad()
        postButton.layer.cornerRadius = 4
        thoughtTextView.layer.cornerRadius = 4
        thoughtTextView.text = "My random thought..."
        thoughtTextView.textColor = UIColor.lightGray
        thoughtTextView.delegate = self
    }
    
    @IBAction func postButtonTapped(_ sender: Any) {
        guard let username = usernameTextField.text else { return }
        
        Firestore.firestore().collection(THOUGHTS_REF).addDocument(data: [
            CATEGORY: selectedCategory,
            NUM_COMMENTS: 0,
            NUM_LIKES: 0,
            THOUGHT_TEXT: thoughtTextView.text,
            TIMESTAMP: FieldValue.serverTimestamp(),
            USERNAME: username
        ]) { (error) in
            if let error = error {
                debugPrint("Error adding document: \(error)")
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func categoryChanged(_ sender: Any) {
        switch categorySegment.selectedSegmentIndex {
        case 0:
            selectedCategory = ThoughtCategory.funny.rawValue
        case 1:
            selectedCategory = ThoughtCategory.serious.rawValue
        default:
            selectedCategory = ThoughtCategory.crazy.rawValue
        }
    }
}

extension AddThoughtVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.text = ""
        textView.textColor = UIColor.darkGray
    }
}