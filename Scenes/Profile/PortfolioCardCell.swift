//
//  PortfolioCardCell.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 10/11/25.
//
//  Description:
//  Reusable UICollectionViewCell representing a portfolio "card" inside the
//  user’s profile. Displays title, role/date, and key skills.
//

import UIKit

final class PortfolioCardCell: UICollectionViewCell {

    // MARK: - Reuse Identifier
    static let reuseID = "PortfolioCardCell"

    // MARK: - UI Elements
    private let card = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let footerLabel = UILabel()

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup
    /// Configures the cell’s layout and visual style.
    private func setupView() {
        contentView.backgroundColor = .clear

        // Card styling
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(named: "BrandSecondary") ?? .secondarySystemBackground
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        contentView.addSubview(card)

        // Labels
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 2

        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1

        footerLabel.font = .systemFont(ofSize: 12, weight: .medium)
        footerLabel.textColor = .tertiaryLabel
        footerLabel.numberOfLines = 1

        // Add labels to card
        [titleLabel, subtitleLabel, footerLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }

        // Layout constraints
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

    // MARK: - Configuration
    /// Populates the cell with a given `PortfolioItem`'s data.
    func configure(with item: PortfolioItem) {
        titleLabel.text = item.title.isEmpty ? "Untitled Project" : item.title

        // Combine role and date range
        let roleText = item.role.isEmpty ? nil : item.role
        let dateText = Self.makeDateRange(start: item.startDate, end: item.endDate)
        subtitleLabel.text = [roleText, dateText].compactMap { $0 }.joined(separator: " · ")

        // Footer preview — show first two skills
        if item.skills.isEmpty {
            footerLabel.text = nil
        } else {
            footerLabel.text = item.skills.prefix(2).joined(separator: " • ")
        }
    }

    // MARK: - Date Formatting Helper
    /// Returns a formatted date range (e.g., “Mar 2023 – Sep 2024”).
    private static func makeDateRange(start: Date?, end: Date?) -> String? {
        guard start != nil || end != nil else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"

        switch (start, end) {
        case let (s?, e?):
            return "\(formatter.string(from: s)) – \(formatter.string(from: e))"
        case let (s?, nil):
            return "\(formatter.string(from: s)) – Present"
        case let (nil, e?):
            return "Until \(formatter.string(from: e))"
        default:
            return nil
        }
    }
}
