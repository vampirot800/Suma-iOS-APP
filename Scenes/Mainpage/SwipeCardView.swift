//
//  SwipeCardView.swift
//  FIT3178-App
//
//  Figma-ready profile card:
//  - 16:9 header image
//  - Name + role
//  - Meta row: location + website
//  - Bio (multiline)
//  - Tag chips
//  - Bottom-right "View CV" button (only if cvURL present)

import UIKit

// MARK: - View model
public struct CandidateVM {
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

    public init(name: String,
                subtitle: String,
                tags: [String],
                imageURL: URL?,
                role: String?,
                bio: String?,
                cvURL: URL?,
                website: String? = nil,
                location: String? = nil,
                placeholder: UIImage? = nil) {
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

// MARK: - Inter font utility
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
        static let metaSpacing: CGFloat = 10
        static let chipsTop: CGFloat = 10
        static let chipSpacing: CGFloat = 8
        static let bottomPadding: CGFloat = 16
        static let tagLineSpacing: CGFloat = 8
        static let cvHeight: CGFloat = 46 // 8pt smaller than the 54 you had
    }

    private static let imageCache = NSCache<NSURL, UIImage>()

    // MARK: - Views
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

    // Tags + CV
    private let tagsBlock = UIStackView()            // vertical: multiple lines
    private let firstLine = UIStackView()            // tags + spacer + CV (right side)
    private let firstLineTags = UIStackView()        // tags that fit on first line (before CV)
    private let lineSpacer = UIView()
    private let cvButton = UIButton(type: .system)

    private var extraTagLines: [UIStackView] = []    // additional wrapped lines
    private var allChipViews: [ChipLabel] = []       // chips for measurement & reuse

    private var currentVM: CandidateVM?
    private var lastWidth: CGFloat = 0

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

    // MARK: - Build UI
    private func buildUI() {
        backgroundColor = UIColor(named: "sumaWhite")
        layer.cornerRadius = Layout.corner
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Layout.shadowOpacity
        layer.shadowRadius = Layout.shadowRadius
        layer.shadowOffset = Layout.shadowOffset

        // Header image (16:9)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.imageCorner
        imageView.backgroundColor = UIColor(named: "Header")?.withAlphaComponent(0.15)
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor,
                                          multiplier: 9.0/16.0).isActive = true

        // Title / Subtitle
        nameLabel.font = InterFont.bold(24)
        nameLabel.textColor = UIColor(named: "Surface")  // username color
        nameLabel.numberOfLines = 1

        subtitleLabel.font = InterFont.regular(16)
        subtitleLabel.textColor = UIColor(named: "TextSecondary")
        subtitleLabel.numberOfLines = 2

        // Meta rows
        locationIcon.tintColor = UIColor(named: "TextSecondary")
        locationIcon.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            locationIcon.widthAnchor.constraint(equalToConstant: 18),
            locationIcon.heightAnchor.constraint(equalToConstant: 18)
        ])

        locationLabel.font = InterFont.regular(14)
        locationLabel.textColor = UIColor(named: "TextSecondary")

        locationRow.axis = .horizontal
        locationRow.alignment = .center
        locationRow.spacing = 6
        locationRow.addArrangedSubview(locationIcon)
        locationRow.addArrangedSubview(locationLabel)

        websiteIcon.tintColor = UIColor(named: "TextSecondary")
        websiteIcon.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            websiteIcon.widthAnchor.constraint(equalToConstant: 18),
            websiteIcon.heightAnchor.constraint(equalToConstant: 18)
        ])

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

        // Bio
        bioLabel.font = InterFont.regular(16)
        bioLabel.textColor = UIColor(named: "Surface") // bio color
        bioLabel.numberOfLines = 4

        // --- Tags + View CV ---
        // Vertical block that can host multiple lines
        tagsBlock.axis = .vertical
        tagsBlock.alignment = .fill
        tagsBlock.spacing = Layout.tagLineSpacing

        // First line: tags (left) + spacer + CV button (right)
        firstLine.axis = .horizontal
        firstLine.alignment = .center
        firstLine.spacing = Layout.chipSpacing

        firstLineTags.axis = .horizontal
        firstLineTags.alignment = .leading
        firstLineTags.spacing = Layout.chipSpacing

        firstLine.addArrangedSubview(firstLineTags)
        firstLine.addArrangedSubview(lineSpacer)
        firstLine.setCustomSpacing(Layout.chipSpacing, after: firstLineTags)

        // CV Button
        cvButton.setTitle("View CV", for: .normal)
        cvButton.setImage(nil, for: .normal) // remove icon
        cvButton.titleLabel?.font = InterFont.semibold(16)
        cvButton.setTitleColor(UIColor(named: "Background2"), for: .normal)
        cvButton.backgroundColor = UIColor(named: "Surface")
        cvButton.layer.cornerRadius = 14
        cvButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
        cvButton.heightAnchor.constraint(equalToConstant: Layout.cvHeight).isActive = true
        cvButton.addTarget(self, action: #selector(openCV), for: .touchUpInside)
        firstLine.addArrangedSubview(cvButton)

        tagsBlock.addArrangedSubview(firstLine)

        // Main vertical content
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Layout.titleSpacing

        container.axis = .vertical
        container.alignment = .fill
        container.spacing = Layout.vPad
        container.translatesAutoresizingMaskIntoConstraints = false

        addSubview(container)
        container.addArrangedSubview(imageView)
        container.addArrangedSubview(contentStack)

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

    // MARK: - Apply VM
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

        // Build chip views (we’ll place them into lines later)
        allChipViews = vm.tags.map { ChipLabel(text: $0) }

        // Reset lines now; final layout happens in layoutSubviews (when we know widths)
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

    // Layout-time wrapping so the CV button sits at the right of the first line
    public override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        if abs(w - lastWidth) > 1 {
            lastWidth = w
            rebuildTagLines(availableWidth: w)
        }
    }

    private func rebuildTagLines(availableWidth: CGFloat) {
        // Clear previous lines (except firstLine container)
        firstLineTags.arrangedSubviews.forEach { $0.removeFromSuperview() }
        extraTagLines.forEach { line in
            tagsBlock.removeArrangedSubview(line)
            line.removeFromSuperview()
        }
        extraTagLines.removeAll()

        // Early out if no chips
        guard !allChipViews.isEmpty else { return }

        // Compute how many chips fit next to the CV button on the first line
        layoutIfNeeded()
        let cvWidth = cvButton.isHidden ? 0 : (cvButton.intrinsicContentSize.width + Layout.chipSpacing)
        let horizontalPadding: CGFloat = Layout.hPad * 2  // safe approximation inside the card content
        let usableFirstLine = max(0, availableWidth - horizontalPadding - cvWidth)

        var currentLineWidth: CGFloat = 0
        var remainingChips = allChipViews

        // First line: add chips until just before overflow
        while let chip = remainingChips.first {
            let chipWidth = chip.intrinsicContentSize.width
            if currentLineWidth == 0 || currentLineWidth + Layout.chipSpacing + chipWidth <= usableFirstLine {
                firstLineTags.addArrangedSubview(chip)
                currentLineWidth += (currentLineWidth == 0 ? chipWidth : Layout.chipSpacing + chipWidth)
                remainingChips.removeFirst()
            } else {
                break
            }
        }

        // Subsequent lines: full width (no CV button)
        while !remainingChips.isEmpty {
            let line = UIStackView()
            line.axis = .horizontal
            line.alignment = .leading
            line.spacing = Layout.chipSpacing

            var lineWidth: CGFloat = 0
            while let chip = remainingChips.first {
                let chipWidth = chip.intrinsicContentSize.width
                if lineWidth == 0 || lineWidth + Layout.chipSpacing + chipWidth <= (availableWidth - horizontalPadding) {
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

// MARK: - ChipLabel
private final class ChipLabel: UILabel {
    private let insets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
    init(text: String) {
        super.init(frame: .zero)
        self.text = text
        font = InterFont.semibold(14)
        textColor = UIColor(named: "Surface")       // tag text color
        backgroundColor = UIColor(named: "Accent2") // tag pill color
        layer.cornerRadius = 12
        layer.masksToBounds = true
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }
    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: insets)) }
    override var intrinsicContentSize: CGSize {
        let b = super.intrinsicContentSize
        return CGSize(width: b.width + insets.left + insets.right,
                      height: b.height + insets.top + insets.bottom)
    }
}
