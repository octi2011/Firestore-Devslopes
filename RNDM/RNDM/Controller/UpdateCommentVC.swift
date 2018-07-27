//
//  UpdateCommentVC.swift
//  RNDM
//
//  Created by Octavian Duminica on 27/07/2018.
//  Copyright © 2018 Octavian Duminica. All rights reserved.
//

import UIKit
import Firebase

class UpdateCommentVC: UIViewController {

    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var updateButton: UIButton!
    
    var commentData: (comment: Comment, thought: Thought)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commentTextView.layer.cornerRadius = 10
        updateButton.layer.cornerRadius = 10
        commentTextView.text = commentData.comment.commentText
    }
    
    @IBAction func onUpdateTapped(_ sender: Any) {
        Firestore.firestore().collection(THOUGHTS_REF).document(commentData.thought.documentId)
        .collection(COMMENTS_REF).document(commentData.comment.documentId)
            .updateData([COMMENT_TEXT: commentTextView.text]) { [weak self] (error) in
                guard let weakSelf = self else { return }
                if let error = error {
                    debugPrint("Unable to update comment: \(error.localizedDescription)")
                } else {
                    weakSelf.navigationController?.popViewController(animated: true)
                }
        }
    }
}
