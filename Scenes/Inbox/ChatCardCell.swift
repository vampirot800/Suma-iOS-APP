//
//  ChatCardCell.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 08/11/25.
//

import UIKit

final class ChatCardCell: UITableViewCell {
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var snippetLabel: UILabel!
    static let reuseID = "ChatCardCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Visuals that match your theme
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = true
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectedBackgroundView = UIView()
    }

    func fill(name: String, snippet: String?) {
        usernameLabel.text = name
        snippetLabel.text  = snippet ?? ""
    }
}
