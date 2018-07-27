//
//  MainVC.swift
//  RNDM
//
//  Created by Octavian Duminica on 26/07/2018.
//  Copyright © 2018 Octavian Duminica. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

enum ThoughtCategory: String {
    case serious = "serious"
    case funny = "funny"
    case crazy = "crazy"
    case popular = "popular"
}

class MainVC: UIViewController {

    @IBOutlet private weak var segmentControl: UISegmentedControl!
    @IBOutlet private weak var tableView: UITableView!
    
    private var thoughts = [Thought]()
    private var thoughtsCollectionRef: CollectionReference!
    private var thoughtsListener: ListenerRegistration!
    private var selectedCategory = ThoughtCategory.funny.rawValue
    private var handle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        thoughtsCollectionRef = Firestore.firestore().collection(THOUGHTS_REF)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        handle = Auth.auth().addStateDidChangeListener({ [weak self] (auth, user) in
            guard let weakSelf = self else { return }
            if user == nil {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let loginVC = storyboard.instantiateViewController(withIdentifier: "loginVC")
                weakSelf.present(loginVC, animated: true, completion: nil)
            } else {
                weakSelf.setListener()
            }
        })
        
        // one time only
//        thoughtsCollectionRef.getDocuments { [weak self] (snapshot, error) in
//            guard let weakSelf = self else { return }
//            if let error = error {
//                debugPrint("Error fetching docs: \(error)")
//            } else {
//                guard let snap = snapshot else { return }
//
//                for document in snap.documents {
//                    let data = document.data()
//                    let username = data[USERNAME] as? String ?? "Anonymous"
//                    let timestamp = data[TIMESTAMP] as? Date ?? Date()
//                    let thoughtText = data[THOUGHT_TEXT] as? String ?? ""
//                    let numLikes = data[NUM_LIKES] as? Int ?? 0
//                    let numComments = data[NUM_COMMENTS] as? Int ?? 0
//                    let documentId = document.documentID
//
//                    let newThought = Thought(username: username, timestamp: timestamp, thoughtText: thoughtText, numLikes: numLikes, numComments: numComments, documentId: documentId)
//                    weakSelf.thoughts.append(newThought)
//                }
//                weakSelf.tableView.reloadData()
//            }
//        }
    }
    
    func setListener() {
        
        if selectedCategory == ThoughtCategory.popular.rawValue {
            thoughtsListener = thoughtsCollectionRef
                .order(by: NUM_LIKES, descending: true)
                .addSnapshotListener { [weak self] (snapshot, error) in
                    guard let weakSelf = self else { return }
                    if let error = error {
                        debugPrint("Error fetching docs: \(error)")
                    } else {
                        weakSelf.thoughts.removeAll()
                        weakSelf.thoughts = Thought.parseData(snapshot: snapshot)
                        weakSelf.tableView.reloadData()
                    }
            }
            
        } else {
        
            thoughtsListener = thoughtsCollectionRef
                .whereField(CATEGORY, isEqualTo: selectedCategory)
                .order(by: TIMESTAMP, descending: true)
                .addSnapshotListener { [weak self] (snapshot, error) in
                    guard let weakSelf = self else { return }
                    if let error = error {
                        debugPrint("Error fetching docs: \(error)")
                    } else {
                        weakSelf.thoughts.removeAll()
                        weakSelf.thoughts = Thought.parseData(snapshot: snapshot)
                        weakSelf.tableView.reloadData()
                    }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if thoughtsListener != nil {
            thoughtsListener.remove()
        }
    }
    
    @IBAction func categoryChanged(_ sender: Any) {
        switch segmentControl.selectedSegmentIndex {
        case 0:
            selectedCategory = ThoughtCategory.funny.rawValue
        case 1:
            selectedCategory = ThoughtCategory.serious.rawValue
        case 2:
            selectedCategory = ThoughtCategory.crazy.rawValue
        default:
            selectedCategory = ThoughtCategory.popular.rawValue
        }
        
        thoughtsListener.remove()
        setListener()
    }
    
    @IBAction func onLogoutTapped(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signoutError as NSError {
            debugPrint("Error signing out: \(signoutError)")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toComments" {
            if let destinationVC = segue.destination as? CommentsVC {
                if let thought = sender as? Thought {
                    destinationVC.thought = thought
                }
            }
        }
    }
}

extension MainVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return thoughts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "thoughtCell", for: indexPath) as? ThoughtCell {
            cell.configureCell(thought: thoughts[indexPath.row])
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toComments", sender: thoughts[indexPath.row])
    }
}

