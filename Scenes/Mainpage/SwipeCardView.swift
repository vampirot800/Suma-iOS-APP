//
//  SwipeCardView.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 23/10/25.
//

import UIKit

// Simple view model your VC feeds into the card
struct CandidateVM {
    let name: String
    let subtitle: String      // e.g. “Offers: travel • food” or role
    let tags: [String]        // full tag list to render as chips
    let image: UIImage?       // optional photo (placeholder OK)
}

final class SwipeCardView: UIView {

    // MARK: - Subviews
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let tagsStack = UIStackView()
    private let contentStack = UIStackView()

    // Layout constants so you can tweak quickly
    struct Layout {
        static let corner: CGFloat = 16
        static let shadow: Float = 0.18
        static let vPad: CGFloat = 14
        static let hPad: CGFloat = 16
        static let imageTop: CGFloat = 16
        static let imageSide: CGFloat = 24
        static let titleSpacing: CGFloat = 6
        static let chipSpacing: CGFloat = 8
        static let chipsTop: CGFloat = 10
        static let bottomPadding: CGFloat = 16
    }

    init(vm: CandidateVM) {
        super.init(frame: .zero)
        buildUI()
        apply(vm: vm)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildUI()
    }

    private func buildUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = Layout.corner
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Layout.shadow
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 6)

        // Image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.25)
        imageView.layer.cornerRadius = 12
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 2/3).isActive = true

        // Labels
        nameLabel.font = .preferredFont(forTextStyle: .title2).withWeight(.semibold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1

        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        // Tags
        tagsStack.axis = .horizontal
        tagsStack.spacing = Layout.chipSpacing
        tagsStack.alignment = .leading
        tagsStack.distribution = .fillProportionally

        // Content stack
        contentStack.axis = .vertical
        contentStack.spacing = Layout.titleSpacing

        // Assemble
        let container = UIStackView(arrangedSubviews: [imageView, contentStack])
        container.axis = .vertical
        container.spacing = Layout.vPad
        container.translatesAutoresizingMaskIntoConstraints = false

        addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.hPad),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.hPad),
            container.topAnchor.constraint(equalTo: topAnchor, constant: Layout.imageTop),
            container.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -Layout.bottomPadding)
        ])

        // Content
        contentStack.addArrangedSubview(nameLabel)
        contentStack.addArrangedSubview(subtitleLabel)

        let tagsWrapper = UIView()
        tagsWrapper.translatesAutoresizingMaskIntoConstraints = false
        tagsWrapper.addSubview(tagsStack)
        tagsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tagsStack.topAnchor.constraint(equalTo: tagsWrapper.topAnchor, constant: Layout.chipsTop),
            tagsStack.leadingAnchor.constraint(equalTo: tagsWrapper.leadingAnchor),
            tagsStack.trailingAnchor.constraint(lessThanOrEqualTo: tagsWrapper.trailingAnchor),
            tagsStack.bottomAnchor.constraint(equalTo: tagsWrapper.bottomAnchor)
        ])
        contentStack.addArrangedSubview(tagsWrapper)
    }

    func apply(vm: CandidateVM) {
        imageView.image = vm.image ?? UIImage(systemName: "photo")?
            .withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.systemGreen

        nameLabel.text = vm.name
        subtitleLabel.text = vm.subtitle

        // Tags → chips
        tagsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for tag in vm.tags.prefix(6) { // cap to keep it tidy
            tagsStack.addArrangedSubview(chip(tag))
        }
    }

    private func chip(_ text: String) -> UIView {
        let label = PaddingLabel(insets: .init(top: 4, left: 10, bottom: 4, right: 10))
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        label.backgroundColor = .tertiarySystemFill
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        return label
    }
}

// Helpers
private final class PaddingLabel: UILabel {
    private let insets: UIEdgeInsets
    init(insets: UIEdgeInsets) { self.insets = insets; super.init(frame: .zero) }
    required init?(coder: NSCoder) { self.insets = .zero; super.init(coder: coder) }
    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: insets)) }
    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        return CGSize(width: base.width + insets.left + insets.right,
                      height: base.height + insets.top + insets.bottom)
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let d = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: d, size: pointSize)
    }
}
