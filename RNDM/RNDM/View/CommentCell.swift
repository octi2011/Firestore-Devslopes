//
//  CommentCell.swift
//  RNDM
//
//  Created by Octavian Duminica on 27/07/2018.
//  Copyright © 2018 Octavian Duminica. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {

    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    func configureCell(comment: Comment) {
        usernameLabel.text = comment.username
        commentLabel.text = comment.commentText
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, hh:mm"
        let timestamp = formatter.string(from: comment.timestamp)
        timestampLabel.text = timestamp
    }
}
