//
//  ChatCardCell.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 08/11/25.
//

import UIKit

/// A simple reusable cell representing a chat preview.
/// Displays the username and the last message snippet in a rounded card.
final class ChatCardCell: UITableViewCell {

    // MARK: - Properties

    static let reuseID = "ChatCardCell"

    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var snippetLabel: UILabel!

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        usernameLabel.text = nil
        snippetLabel.text  = nil
    }

    // MARK: - Configuration

    /// Applies consistent style for the card and labels.
    private func configureUI() {
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = true
        selectionStyle = .default

        // Semi-transparent secondary text color
        snippetLabel.textColor = UIColor(named: "TextPrimary")?.withAlphaComponent(0.85)
    }

    /// Configures the cell with chat preview data.
    func configure(username: String, snippet: String) {
        usernameLabel.text = username
        snippetLabel.text  = snippet
    }
}
