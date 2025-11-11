//
//  SwipeCardView.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 11/11/25.
//
//  Description:
//  A reusable profile card view designed for swipe-style interfaces.
//  Displays a candidate’s image, name, role, metadata, bio, and tags,
//  with an optional “View CV” button when a CV URL is available.
//

import UIKit

// MARK: - Candidate View Model

/// Represents the data model for a candidate card displayed in the swipe interface.
public struct CandidateVM {
    public let userId: String
    public let name: String
    public let subtitle: String
    public let tags: [String]
    public let imageURL: URL?
    public let image: UIImage?
    public let role: String?
    public let bio: String?
    public let cvURL: URL?
    public let website: String?
    public let location: String?

    public init(
        userId: String,
        name: String,
        subtitle: String,
        tags: [String],
        imageURL: URL?,
        role: String?,
        bio: String?,
        cvURL: URL?,
        website: String? = nil,
        location: String? = nil,
        placeholder: UIImage? = nil
    ) {
        self.userId = userId
        self.name = name
        self.subtitle = subtitle
        self.tags = tags
        self.imageURL = imageURL
        self.role = role
        self.bio = bio
        self.cvURL = cvURL
        self.website = website
        self.location = location
        self.image = placeholder
    }
}

// MARK: - Font Utility

/// Utility enum to safely load the Inter font family or fallback to system fonts.
private enum InterFont {
    static func regular(_ size: CGFloat) -> UIFont {
        UIFont(name: "Inter-Regular", size: size) ?? .systemFont(ofSize: size)
    }
    static func semibold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Inter-SemiBold", size: size) ?? .systemFont(ofSize: size, weight: .semibold)
    }
    static func bold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Inter-Bold", size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }
}

// MARK: - Swipe Card View

/// Displays a candidate’s profile in a Figma-like 16:9 card layout.
/// Includes header image, metadata, bio, tags, and CV button.
public final class SwipeCardView: UIView {

    // MARK: - Layout Constants

    private struct Layout {
        static let corner: CGFloat = 20
        static let shadowOpacity: Float = 0.16
        static let shadowRadius: CGFloat = 12
        static let shadowOffset = CGSize(width: 0, height: 8)
        static let hPad: CGFloat = 16
        static let vPad: CGFloat = 14
        static let imageCorner: CGFloat = 12
        static let titleSpacing: CGFloat = 6
        static let metaSpacing: CGFloat = 10
        static let chipSpacing: CGFloat = 8
        static let bottomPadding: CGFloat = 16
        static let tagLineSpacing: CGFloat = 8
        static let cvHeight: CGFloat = 46
    }

    private static let imageCache = NSCache<NSURL, UIImage>()

    // MARK: - UI Components

    private let container = UIStackView()
    private let imageView = UIImageView()
    private let contentStack = UIStackView()

    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let metaRow = UIStackView()
    private let locationRow = UIStackView()
    private let locationIcon = UIImageView(image: UIImage(systemName: "mappin.and.ellipse"))
    private let locationLabel = UILabel()

    private let websiteRow = UIStackView()
    private let websiteIcon = UIImageView(image: UIImage(systemName: "globe"))
    private let websiteButton = UIButton(type: .system)

    private let bioLabel = UILabel()

    // Tags and CV button
    private let tagsBlock = UIStackView()
    private let firstLine = UIStackView()
    private let firstLineTags = UIStackView()
    private let lineSpacer = UIView()
    private let cvButton = UIButton(type: .system)

    private var extraTagLines: [UIStackView] = []
    private var allChipViews: [ChipLabel] = []

    private var currentVM: CandidateVM?
    private var lastWidth: CGFloat = 0

    // MARK: - Initialization

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

    // MARK: - UI Construction

    /// Builds and arranges all subviews for the card layout.
    private func buildUI() {
        backgroundColor = UIColor(named: "sumaWhite")
        layer.cornerRadius = Layout.corner
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Layout.shadowOpacity
        layer.shadowRadius = Layout.shadowRadius
        layer.shadowOffset = Layout.shadowOffset

        // Header image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.imageCorner
        imageView.backgroundColor = UIColor(named: "Header")?.withAlphaComponent(0.15)
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 9.0 / 16.0).isActive = true

        // Title and subtitle
        nameLabel.font = InterFont.bold(24)
        nameLabel.textColor = UIColor(named: "Surface")
        subtitleLabel.font = InterFont.regular(16)
        subtitleLabel.textColor = UIColor(named: "TextSecondary")
        subtitleLabel.numberOfLines = 2

        // Meta rows (location + website)
        setupMetaRows()

        // Bio
        bioLabel.font = InterFont.regular(16)
        bioLabel.textColor = UIColor(named: "Surface")
        bioLabel.numberOfLines = 4

        // Tags and CV button
        setupTagsBlock()

        // Container stack
        container.axis = .vertical
        container.alignment = .fill
        container.spacing = Layout.vPad
        container.translatesAutoresizingMaskIntoConstraints = false

        addSubview(container)
        container.addArrangedSubview(imageView)
        container.addArrangedSubview(contentStack)

        // Main content
        contentStack.axis = .vertical
        contentStack.spacing = Layout.titleSpacing
        contentStack.addArrangedSubview(nameLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.addArrangedSubview(metaRow)
        contentStack.addArrangedSubview(bioLabel)
        contentStack.addArrangedSubview(tagsBlock)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.hPad),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.hPad),
            container.topAnchor.constraint(equalTo: topAnchor, constant: Layout.vPad),
            container.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -Layout.bottomPadding)
        ])
    }

    /// Configures the meta row stack views for location and website.
    private func setupMetaRows() {
        locationIcon.tintColor = UIColor(named: "TextSecondary")
        locationIcon.contentMode = .scaleAspectFit
        locationLabel.font = InterFont.regular(14)
        locationLabel.textColor = UIColor(named: "TextSecondary")

        locationRow.axis = .horizontal
        locationRow.alignment = .center
        locationRow.spacing = 6
        locationRow.addArrangedSubview(locationIcon)
        locationRow.addArrangedSubview(locationLabel)

        websiteIcon.tintColor = UIColor(named: "TextSecondary")
        websiteIcon.contentMode = .scaleAspectFit
        websiteButton.setTitleColor(UIColor(named: "TextSecondary"), for: .normal)
        websiteButton.titleLabel?.font = InterFont.regular(14)
        websiteButton.contentHorizontalAlignment = .leading
        websiteButton.addTarget(self, action: #selector(openWebsite), for: .touchUpInside)

        websiteRow.axis = .horizontal
        websiteRow.alignment = .center
        websiteRow.spacing = 6
        websiteRow.addArrangedSubview(websiteIcon)
        websiteRow.addArrangedSubview(websiteButton)

        metaRow.axis = .horizontal
        metaRow.alignment = .center
        metaRow.spacing = Layout.metaSpacing
        metaRow.addArrangedSubview(locationRow)
        metaRow.addArrangedSubview(websiteRow)
    }

    /// Configures the layout for tags and the “View CV” button.
    private func setupTagsBlock() {
        tagsBlock.axis = .vertical
        tagsBlock.spacing = Layout.tagLineSpacing

        firstLine.axis = .horizontal
        firstLine.alignment = .center
        firstLine.spacing = Layout.chipSpacing

        firstLineTags.axis = .horizontal
        firstLineTags.alignment = .leading
        firstLineTags.spacing = Layout.chipSpacing
        firstLine.addArrangedSubview(firstLineTags)
        firstLine.addArrangedSubview(lineSpacer)

        // CV button setup
        cvButton.setTitle("View CV", for: .normal)
        cvButton.titleLabel?.font = InterFont.semibold(16)
        cvButton.setTitleColor(UIColor(named: "Background2"), for: .normal)
        cvButton.backgroundColor = UIColor(named: "Surface")
        cvButton.layer.cornerRadius = 14
        cvButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
        cvButton.heightAnchor.constraint(equalToConstant: Layout.cvHeight).isActive = true
        cvButton.addTarget(self, action: #selector(openCV), for: .touchUpInside)

        firstLine.addArrangedSubview(cvButton)
        tagsBlock.addArrangedSubview(firstLine)
    }

    // MARK: - View Model Application

    /// Applies a candidate view model to update the card UI.
    public func apply(vm: CandidateVM) {
        currentVM = vm
        nameLabel.text = vm.name
        subtitleLabel.text = vm.subtitle

        locationLabel.text = vm.location
        locationRow.isHidden = vm.location?.isEmpty ?? true

        websiteButton.setTitle(vm.website, for: .normal)
        websiteRow.isHidden = vm.website?.isEmpty ?? true

        bioLabel.text = vm.bio
        bioLabel.isHidden = (vm.bio ?? "").isEmpty

        // Build chip labels for tags
        allChipViews = vm.tags.map { ChipLabel(text: $0) }
        rebuildTagLines(availableWidth: bounds.width)

        cvButton.isHidden = (vm.cvURL == nil)

        if let img = vm.image {
            imageView.image = img
        } else if let url = vm.imageURL {
            setImage(from: url)
        } else {
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = UIColor(named: "Accent2")
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    // MARK: - Tag Layout Logic

    public override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        if abs(width - lastWidth) > 1 {
            lastWidth = width
            rebuildTagLines(availableWidth: width)
        }
    }

    /// Dynamically wraps tag chips into multiple lines based on width.
    private func rebuildTagLines(availableWidth: CGFloat) {
        firstLineTags.arrangedSubviews.forEach { $0.removeFromSuperview() }
        extraTagLines.forEach { tagsBlock.removeArrangedSubview($0); $0.removeFromSuperview() }
        extraTagLines.removeAll()

        guard !allChipViews.isEmpty else { return }

        layoutIfNeeded()
        let cvWidth = cvButton.isHidden ? 0 : (cvButton.intrinsicContentSize.width + Layout.chipSpacing)
        let padding: CGFloat = Layout.hPad * 2
        let usableFirstLine = max(0, availableWidth - padding - cvWidth)

        var currentWidth: CGFloat = 0
        var remainingChips = allChipViews

        // Fill first line beside CV button
        while let chip = remainingChips.first {
            let chipWidth = chip.intrinsicContentSize.width
            if currentWidth == 0 || currentWidth + Layout.chipSpacing + chipWidth <= usableFirstLine {
                firstLineTags.addArrangedSubview(chip)
                currentWidth += (currentWidth == 0 ? chipWidth : Layout.chipSpacing + chipWidth)
                remainingChips.removeFirst()
            } else {
                break
            }
        }

        // Additional lines
        while !remainingChips.isEmpty {
            let line = UIStackView()
            line.axis = .horizontal
            line.alignment = .leading
            line.spacing = Layout.chipSpacing

            var lineWidth: CGFloat = 0
            while let chip = remainingChips.first {
                let chipWidth = chip.intrinsicContentSize.width
                if lineWidth == 0 || lineWidth + Layout.chipSpacing + chipWidth <= (availableWidth - padding) {
                    line.addArrangedSubview(chip)
                    lineWidth += (lineWidth == 0 ? chipWidth : Layout.chipSpacing + chipWidth)
                    remainingChips.removeFirst()
                } else {
                    break
                }
            }
            extraTagLines.append(line)
            tagsBlock.addArrangedSubview(line)
        }
    }

    // MARK: - Image Loading

    private func setImage(from url: URL) {
        if let cached = SwipeCardView.imageCache.object(forKey: url as NSURL) {
            imageView.image = cached
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let img = UIImage(data: data) else { return }
            SwipeCardView.imageCache.setObject(img, forKey: url as NSURL)
            DispatchQueue.main.async { self.imageView.image = img }
        }.resume()
    }

    // MARK: - Actions

    @objc private func openCV() {
        guard let url = currentVM?.cvURL else { return }
        UIApplication.shared.open(url)
    }

    @objc private func openWebsite() {
        guard let site = currentVM?.website,
              let url = URL(string: site),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Chip Label

/// Rounded label used as a tag chip within the card.
private final class ChipLabel: UILabel {
    private let insets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

    init(text: String) {
        super.init(frame: .zero)
        self.text = text
        font = InterFont.semibold(14)
        textColor = UIColor(named: "Surface")
        backgroundColor = UIColor(named: "Accent2")
        layer.cornerRadius = 12
        layer.masksToBounds = true
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        return CGSize(
            width: base.width + insets.left + insets.right,
            height: base.height + insets.top + insets.bottom
        )
    }
}
