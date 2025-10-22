//
//  ProfileHeaderView.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 21/10/25.
//

import UIKit

@IBDesignable
final class ProfileHeaderView: UIView {

    private let avatar = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let editButton = UIButton(type: .system)
    private let hStack = UIStackView()

    // Editable in Attributes Inspector for live IB preview
    @IBInspectable var name: String = "Your Name" { didSet { nameLabel.text = name } }
    @IBInspectable var role: String = "media creator" { didSet { roleLabel.text = role } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear

        avatar.image = UIImage(systemName: "person.crop.circle.fill")
        avatar.contentMode = .scaleAspectFit
        avatar.tintColor = .systemGray3
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 84).isActive = true
        avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor).isActive = true
        avatar.layer.cornerRadius = 42
        avatar.clipsToBounds = true

        nameLabel.font = UIFont.preferredFont(forTextStyle: .title2).bold()
        roleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        roleLabel.textColor = .secondaryLabel

        var cfg = UIButton.Configuration.plain()
        cfg.image = UIImage(systemName: "pencil.circle.fill")
        cfg.preferredSymbolConfigurationForImage = .init(pointSize: 24, weight: .regular)
        editButton.configuration = cfg
        editButton.tintColor = .systemBlue

        let textStack = UIStackView(arrangedSubviews: [nameLabel, roleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.addArrangedSubview(avatar)
        hStack.addArrangedSubview(textStack)
        hStack.addArrangedSubview(UIView()) // spacer
        hStack.addArrangedSubview(editButton)

        addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            hStack.topAnchor.constraint(equalTo: topAnchor),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // Gives the stack a natural height in IB and at runtime
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 110)
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        nameLabel.text = name
        roleLabel.text = role
    }
}

private extension UIFont {
    func bold() -> UIFont { UIFont.systemFont(ofSize: pointSize, weight: .semibold) }
}
