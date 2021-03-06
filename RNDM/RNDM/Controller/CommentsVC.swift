//
//  CommentsVC.swift
//  RNDM
//
//  Created by Octavian Duminica on 27/07/2018.
//  Copyright © 2018 Octavian Duminica. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class CommentsVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addCommentTextField: UITextField!
    @IBOutlet weak var keyboardView: UIView!
    
    var thought: Thought!
    var comments = [Comment]()
    var thoughtRef: DocumentReference!
    let firestore = Firestore.firestore()
    var username: String!
    var commentListener: ListenerRegistration!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        thoughtRef = firestore.collection(THOUGHTS_REF).document(thought.documentId)
        if let name = Auth.auth().currentUser?.displayName {
            username = name
        }
        self.view.bindToKeyboard()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        commentListener = firestore.collection(THOUGHTS_REF).document(thought.documentId).collection(COMMENTS_REF)
            .order(by: TIMESTAMP, descending: false)
            .addSnapshotListener({ [weak self] (snapshot, error) in
            guard let weakSelf = self else { return }
            
            guard let snapshot = snapshot else {
                debugPrint("Error fetching comments: \(error!)")
                return
            }
            
            weakSelf.comments.removeAll()
            weakSelf.comments = Comment.parseData(snapshot: snapshot)
            weakSelf.tableView.reloadData()
            
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        commentListener.remove()
    }
    
    // FOR TRANSACTIONS - READ OPERATIONS MUST COME BEFORE WRITE OPERATIONS
    // NEVER APPLY PARTIAL WRITES
    @IBAction func addCommentTapped(_ sender: Any) {
        guard let commentText = addCommentTextField.text else { return }
        
        firestore.runTransaction({ [weak self] (transaction, errorPointer) -> Any? in
            guard let weakSelf = self else { return nil }
            
            let thoughtDocument: DocumentSnapshot
            do {
                try thoughtDocument = transaction.getDocument(Firestore.firestore().collection(THOUGHTS_REF).document(weakSelf.thought.documentId))
            } catch let error as NSError {
                debugPrint("Fetch error: \(error.localizedDescription)")
                return nil
            }
            
            guard let oldNumComments = thoughtDocument.data()![NUM_COMMENTS] as? Int else { return nil }
            
            transaction.updateData([NUM_COMMENTS: oldNumComments + 1], forDocument: weakSelf.thoughtRef)
            
            let newCommentRef = weakSelf.firestore.collection(THOUGHTS_REF).document(weakSelf.thought.documentId).collection(COMMENTS_REF).document()
            
            transaction.setData([
                COMMENT_TEXT: commentText,
                TIMESTAMP: FieldValue.serverTimestamp(),
                USERNAME: weakSelf.username,
                USER_ID: Auth.auth().currentUser?.uid ?? ""
                ], forDocument: newCommentRef)
            
            return nil
        }) { [weak self] (object, error) in
            guard let weakSelf = self else { return }
            if let error = error {
                debugPrint("Transaction failed: \(error)")
            } else {
                weakSelf.addCommentTextField.text = ""
                weakSelf.addCommentTextField.resignFirstResponder()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? UpdateCommentVC {
            if let commentData = sender as? (comment: Comment, thought: Thought) {
                destination.commentData = commentData
            }
        }
    }
}

extension CommentsVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as? CommentCell {
            cell.configureCell(comment: comments[indexPath.row], delegate: self)
            return cell
        } else {
            return UITableViewCell()
        }
    }
}

extension CommentsVC: CommentDelegate {
    func commentOptionsTapped(comment: Comment) {
        let alert = UIAlertController(title: "Edit Comment", message: "You can delete or edit", preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete Comment", style: .default) { [weak self] (action) in
            guard let weakSelf = self else { return }
            
//            weakSelf.firestore.collection(THOUGHTS_REF).document(weakSelf.thought.documentId)
//            .collection(COMMENTS_REF)
//            .document(comment.documentId).delete(completion: { (error) in
//                if let error = error {
//                    debugPrint("Unable to delete comment: \(error.localizedDescription)")
//                } else {
//                    alert.dismiss(animated: true, completion: nil)
//                }
//            })
            
            weakSelf.firestore.runTransaction({ [weak self] (transaction, errorPointer) -> Any? in
                guard let weakSelf = self else { return nil }
                
                let thoughtDocument: DocumentSnapshot
                do {
                    try thoughtDocument = transaction.getDocument(Firestore.firestore().collection(THOUGHTS_REF).document(weakSelf.thought.documentId))
                } catch let error as NSError {
                    debugPrint("Fetch error: \(error.localizedDescription)")
                    return nil
                }
                
                guard let oldNumComments = thoughtDocument.data()![NUM_COMMENTS] as? Int else { return nil }
                
                transaction.updateData([NUM_COMMENTS: oldNumComments - 1], forDocument: weakSelf.thoughtRef)
           
                let commentRef = weakSelf.firestore.collection(THOUGHTS_REF)
                    .document(weakSelf.thought.documentId)
                    .collection(COMMENTS_REF)
                    .document(comment.documentId)
                
                transaction.deleteDocument(commentRef)
                
                return nil
            }) { [weak self] (object, error) in
                guard let _ = self else { return }
                if let error = error {
                    debugPrint("Transaction failed: \(error)")
                } else {
                    alert.dismiss(animated: true, completion: nil)
                }
            }
        }
        
        let editAction = UIAlertAction(title: "Edit Comment", style: .default) { [weak self] (action) in
            guard let weakSelf = self else { return }
            weakSelf.performSegue(withIdentifier: "toEditComment", sender: (comment, weakSelf.thought))
            alert.dismiss(animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        alert.addAction(deleteAction)
        alert.addAction(editAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
}
