//
//  SwipeCardView.swift
//  FIT3178-App
//
//  - Bigger corner radius
//  - Softer, larger shadow
//  - 16:9 image
//  - Rounded "chip" tags
//

import UIKit

// View model VC feeds into the card
public struct CandidateVM {
    public let name: String
    public let subtitle: String      // e.g. “Offers: travel • food” or role
    public let tags: [String]        // tag chips
    public let image: UIImage?       // optional photo
    public init(name: String, subtitle: String, tags: [String], image: UIImage?) {
        self.name = name; self.subtitle = subtitle; self.tags = tags; self.image = image
    }
}

public final class SwipeCardView: UIView {

    // MARK: - Layout constants
    private struct Layout {
        static let corner: CGFloat = 20
        static let shadowOpacity: Float = 0.16
        static let shadowRadius: CGFloat = 12
        static let shadowOffset = CGSize(width: 0, height: 8)
        static let hPad: CGFloat = 16
        static let vPad: CGFloat = 14
        static let imageCorner: CGFloat = 12
        static let titleSpacing: CGFloat = 6
        static let chipsTop: CGFloat = 10
        static let chipSpacing: CGFloat = 8
        static let bottomPadding: CGFloat = 16
    }

    // MARK: - Subviews
    private let container = UIStackView()
    private let imageView = UIImageView()
    private let contentStack = UIStackView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let tagsStack = UIStackView()

    // MARK: - Init
    public convenience init(vm: CandidateVM) {
        self.init(frame: .zero)
        apply(vm: vm)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildUI()
    }

    // MARK: - Build
    private func buildUI() {
        backgroundColor = .systemBackground
        layer.cornerRadius = Layout.corner
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Layout.shadowOpacity
        layer.shadowRadius = Layout.shadowRadius
        layer.shadowOffset = Layout.shadowOffset

        // Image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.imageCorner
        imageView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.20)
        // 16:9 aspect
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 9.0/16.0).isActive = true

        // Labels
        nameLabel.font = .preferredFont(forTextStyle: .title2).withWeight(.semibold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1

        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        // Content stack (title + subtitle + chips wrapper)
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Layout.titleSpacing

        // Tags
        tagsStack.axis = .horizontal
        tagsStack.alignment = .leading
        tagsStack.distribution = .fillProportionally
        tagsStack.spacing = Layout.chipSpacing

        // Container
        container.axis = .vertical
        container.alignment = .fill
        container.spacing = Layout.vPad
        container.translatesAutoresizingMaskIntoConstraints = false

        // Assemble
        addSubview(container)
        container.addArrangedSubview(imageView)
        container.addArrangedSubview(contentStack)

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

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.hPad),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.hPad),
            container.topAnchor.constraint(equalTo: topAnchor, constant: Layout.vPad),
            container.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -Layout.bottomPadding)
        ])
    }

    // MARK: - Apply content
    public func apply(vm: CandidateVM) {
        imageView.image = vm.image ?? UIImage(systemName: "photo")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.systemGreen

        nameLabel.text = vm.name
        subtitleLabel.text = vm.subtitle

        // Rebuild tags
        tagsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for tag in vm.tags {
            let chip = ChipLabel(text: tag)
            tagsStack.addArrangedSubview(chip)
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    // Perf: stable shadow path
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: Layout.corner).cgPath
    }
}

// MARK: - Chip Label (rounded tag)
private final class ChipLabel: UILabel {
    private let insets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
    init(text: String) {
        super.init(frame: .zero)
        self.text = text
        font = .preferredFont(forTextStyle: .footnote)
        textColor = .label
        backgroundColor = .tertiarySystemFill
        layer.cornerRadius = 12
        layer.masksToBounds = true
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .horizontal)
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }
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
