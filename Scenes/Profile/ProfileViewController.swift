//
//  ProfileViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import UIKit

final class ProfileViewController: ScrollingStackViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"

        // HEADER (avatar + name + role + edit button)
        let header = makeProfileHeader()
        stackView.addArrangedSubview(header)

        // ABOUT / DESCRIPTION
        let about = makeSection(title: "About", text: "Short bio / description goes here.")
        stackView.addArrangedSubview(about)

        // “Sumas” / achievements placeholder grid
        let gridPlaceholder = makePlaceholder(height: 300, title: "Sumas / Achievements")
        stackView.addArrangedSubview(gridPlaceholder)
    }

    private func makeProfileHeader() -> UIView {
        let container = UIView()

        let avatar = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        avatar.contentMode = .scaleAspectFit
        avatar.tintColor = .systemGray3
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 84).isActive = true
        avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor).isActive = true
        avatar.layer.cornerRadius = 42
        avatar.clipsToBounds = true

        let nameLabel = UILabel()
        nameLabel.font = UIFont.preferredFont(forTextStyle: .title2).bold()
        nameLabel.text = "Your Name"

        let roleLabel = UILabel()
        roleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        roleLabel.textColor = .secondaryLabel
        roleLabel.text = "media creator"

        let textStack = UIStackView(arrangedSubviews: [nameLabel, roleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let editButton = UIButton(type: .system)
        editButton.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
        editButton.setPreferredSymbolConfiguration(.init(pointSize: 24, weight: .regular), forImageIn: .normal)
        editButton.tintColor = .systemBlue

        let h = UIStackView(arrangedSubviews: [avatar, textStack, UIView(), editButton])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12

        h.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(h)
        NSLayoutConstraint.activate([
            h.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            h.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            h.topAnchor.constraint(equalTo: container.topAnchor),
            h.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }


    private func makeSection(title: String, text: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)

        let bodyLabel = UILabel()
        bodyLabel.text = text
        bodyLabel.numberOfLines = 0
        bodyLabel.font = UIFont.preferredFont(forTextStyle: .body)

        let v = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        v.axis = .vertical
        v.spacing = 8
        return v
    }

    private func makePlaceholder(height: CGFloat, title: String) -> UIView {
        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.textColor = .secondaryLabel

        let box = UIView()
        box.backgroundColor = .secondarySystemBackground
        box.layer.cornerRadius = 12
        box.translatesAutoresizingMaskIntoConstraints = false
        box.heightAnchor.constraint(equalToConstant: height).isActive = true
        box.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: box.centerYAnchor)
        ])
        return box
    }
}

// Small convenience so labels can be bolded easily
private extension UIFont {
    func bold() -> UIFont { UIFont(descriptor: fontDescriptor.withSymbolicTraits(.traitBold)!, size: pointSize) }
}
