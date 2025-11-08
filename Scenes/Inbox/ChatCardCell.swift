//
//  ChatCardCell.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 08/11/25.
//

import UIKit

final class ChatCardCell: UITableViewCell {
    static let reuseID = "ChatCardCell"

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var snippetLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = true
        selectionStyle = .default
        snippetLabel.textColor = UIColor(named: "TextPrimary")?.withAlphaComponent(0.85)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        usernameLabel.text = nil
        snippetLabel.text  = nil
    }
}
