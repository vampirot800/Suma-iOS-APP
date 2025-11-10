//
//  PortfolioCardCell.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 10/11/25.
//
//  Renders a portfolio "card" for the profile grid.
//  Works with ProfileViewController's registration & reuseID.
//

import UIKit

final class PortfolioCardCell: UICollectionViewCell {

    // Expose a reuseID so ProfileViewController can register + dequeue
    static let reuseID = "PortfolioCardCell"

    // UI
    private let card = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let footerLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }

    private func build() {
        // Card styling (rounded rectangle like your mockups)
        contentView.backgroundColor = .clear

        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(named: "BrandSecondary") ?? .secondarySystemBackground
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        card.layer.borderWidth = 0.0
        contentView.addSubview(card)

        // Labels
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 2

        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1

        footerLabel.font = .systemFont(ofSize: 12, weight: .medium)
        footerLabel.textColor = .tertiaryLabel
        footerLabel.numberOfLines = 1

        [titleLabel, subtitleLabel, footerLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }

        // Layout
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),

            footerLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            footerLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            footerLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])
    }

    // Public configure
    func configure(with item: PortfolioItem) {
        titleLabel.text = item.title.isEmpty ? "Untitled Project" : item.title

        // e.g., "Art Director · Mar 2023 – Sep 2024"
        let roleText = item.role.isEmpty ? nil : item.role
        let dateText = Self.makeDateRange(start: item.startDate, end: item.endDate)
        subtitleLabel.text = [roleText, dateText].compactMap { $0 }.joined(separator: " · ")

        // Optional footer: show first 1–2 skills
        if item.skills.isEmpty {
            footerLabel.text = nil
        } else {
            let preview = item.skills.prefix(2).joined(separator: " • ")
            footerLabel.text = preview
        }
    }

    private static func makeDateRange(start: Date?, end: Date?) -> String? {
        guard start != nil || end != nil else { return nil }
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        switch (start, end) {
        case let (s?, e?):
            return "\(f.string(from: s)) – \(f.string(from: e))"
        case let (s?, nil):
            return "\(f.string(from: s)) – Present"
        case let (nil, e?):
            return "Until \(f.string(from: e))"
        default:
            return nil
        }
    }
}
