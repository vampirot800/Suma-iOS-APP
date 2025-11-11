//
//  IdeaArticleCell.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 11/11/25.
//

import UIKit

/// Custom table view cell that displays a single `IdeaArticle` as a large card.
final class IdeaArticleCell: UITableViewCell {

    // MARK: - Reuse Identifier
    static let reuseID = "IdeaArticleCell"

    // MARK: - UI Elements

    private let card = UIView()
    private let stack = UIStackView()

    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let urlLabel = UILabel()

    // MARK: - Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildUI()
    }

    // MARK: - UI Setup

    /// Configures the card-style layout and labels.
    private func buildUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Card background
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(named: "Surface") ?? .secondarySystemBackground
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
        card.layer.masksToBounds = false

        contentView.addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])

        // Stack layout inside the card
        stack.axis = .vertical
        stack.spacing = 8
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        // Configure labels
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.numberOfLines = 0
        titleLabel.textColor = UIColor(named: "Background2") ?? .label

        metaLabel.font = .systemFont(ofSize: 14)
        metaLabel.textColor = (UIColor(named: "Background2") ?? .label).withAlphaComponent(0.7)
        metaLabel.numberOfLines = 1

        urlLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        urlLabel.textColor = (UIColor(named: "Background2") ?? .label).withAlphaComponent(0.9)
        urlLabel.numberOfLines = 1
        urlLabel.lineBreakMode = .byTruncatingMiddle

        // Add arranged views
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(metaLabel)
        stack.addArrangedSubview(urlLabel)
    }

    // MARK: - Configuration

    /// Configures the cell with article data.
    /// - Parameter a: The `IdeaArticle` object to display.
    func configure(with a: IdeaArticle) {
        titleLabel.text = a.title

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short

        metaLabel.text = "\(a.points) points • \(a.author) • \(df.string(from: a.date))"
        urlLabel.text = a.url?.host ?? a.urlString
    }
}
