//
//  ProfileHeaderView.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 21/10/25.
//
//  Description:
//  Displays the user’s avatar, name, and role at the top of the profile.
//  Includes action buttons for editing the profile and viewing portfolios.
//

import UIKit

@IBDesignable
final class ProfileHeaderView: UIView {

    // MARK: - UI Components
    private let avatar = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let editButton = UIButton(type: .system)
    private let hStack = UIStackView()

    // MARK: - Callbacks
    /// Triggered when the edit (pencil) button is tapped.
    var onEditTapped: (() -> Void)?

    /// Triggered when the avatar image view is tapped.
    var onAvatarTapped: (() -> Void)?

    /// Triggered when the user wants to view their portfolio.
    var onPortfolioTapped: (() -> Void)?

    // MARK: - Inspectable IB Properties
    @IBInspectable var name: String = "Your Name" { didSet { nameLabel.text = name } }
    @IBInspectable var role: String = "media creator" { didSet { roleLabel.text = role } }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup
    /// Configures all layout and subviews.
    private func setup() {
        backgroundColor = .clear

        // Avatar
        avatar.image = UIImage(systemName: "person.crop.circle.fill")
        avatar.contentMode = .scaleAspectFill
        avatar.tintColor = .systemGray3
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 84).isActive = true
        avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor).isActive = true
        avatar.layer.cornerRadius = 42
        avatar.clipsToBounds = true
        avatar.isUserInteractionEnabled = true

        // Tap gesture on avatar
        let tap = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        avatar.addGestureRecognizer(tap)

        // Labels
        nameLabel.font = UIFont.preferredFont(forTextStyle: .title2).bold()
        roleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        roleLabel.textColor = .secondaryLabel

        // Edit button configuration
        var cfg = UIButton.Configuration.plain()
        cfg.image = UIImage(systemName: "pencil.circle.fill")
        cfg.preferredSymbolConfigurationForImage = .init(pointSize: 24, weight: .regular)
        editButton.configuration = cfg
        editButton.tintColor = .systemBlue
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)

        // Stack setup
        let textStack = UIStackView(arrangedSubviews: [nameLabel, roleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.addArrangedSubview(avatar)
        hStack.addArrangedSubview(textStack)
        hStack.addArrangedSubview(UIView()) // flexible spacer
        hStack.addArrangedSubview(editButton)

        addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            hStack.topAnchor.constraint(equalTo: topAnchor),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func editTapped() { onEditTapped?() }
    @objc private func avatarTapped() { onAvatarTapped?() }

    // MARK: - Public Methods
    /// Updates the displayed avatar image.
    func setAvatarImage(_ image: UIImage?) {
        avatar.image = image ?? UIImage(systemName: "person.crop.circle.fill")
    }

    // MARK: - Overrides
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 110)
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        nameLabel.text = name
        roleLabel.text = role
    }
}

// MARK: - UIFont Convenience
private extension UIFont {
    func bold() -> UIFont { UIFont.systemFont(ofSize: pointSize, weight: .semibold) }
}
