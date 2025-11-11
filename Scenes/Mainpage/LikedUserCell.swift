//
//  LikedUserCell.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 10/11/25.
//

import UIKit
#if canImport(SDWebImage)
import SDWebImage
#endif

/// A reusable cell used to display a liked user in the "Portfolios" section.
/// It can show both collapsed (summary) and expanded (with portfolio grid) states.
final class LikedUserCell: UICollectionViewCell {

    // MARK: - Reuse Identifier
    static let reuseID = "LikedUserCell"

    // MARK: - View Model

    /// View model used to configure the cell.
    struct ViewModel {
        let name: String
        let role: String
        let location: String?
        let website: String?
        let bio: String?
        let photoURL: URL?
    }

    // MARK: - Callbacks

    /// Called when the website button is tapped.
    var onWebsiteTap: ((URL) -> Void)?
    /// Called when a portfolio project is selected.
    var onProjectTap: ((PortfolioItem) -> Void)?
    /// Called when the "Message" button is tapped.
    var onMessageTap: (() -> Void)?

    // MARK: - UI Components

    private let card = UIView()
    private let header = UIView()
    private let avatar = UIImageView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private var headerHeightConstraint: NSLayoutConstraint!

    private let expandedContainer = UIView()
    private let scroll = UIScrollView()
    private let contentStack = UIStackView()

    private let locationLabel = UILabel()
    private let websiteButton = UIButton(type: .system)
    private let bioLabel = UILabel()
    private let messageButton = UIButton(type: .system)

    private let gridLayout = UICollectionViewFlowLayout()
    private lazy var portfolioGrid = UICollectionView(frame: .zero, collectionViewLayout: gridLayout)

    // MARK: - Data

    private var portfolioItems: [PortfolioItem] = []
    private var isExpanded = false

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildUI()
    }

    // MARK: - UI Setup

    /// Builds and lays out all UI components programmatically.
    private func buildUI() {
        contentView.backgroundColor = .clear

        // Card container
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(named: "Background2")
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
        card.layer.shadowOpacity = 1
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        contentView.addSubview(card)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])

        // Header
        header.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(header)
        headerHeightConstraint = header.heightAnchor.constraint(equalToConstant: 72)
        headerHeightConstraint.isActive = true

        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 28
        avatar.backgroundColor = UIColor(named: "Header")?.withAlphaComponent(0.2)

        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        roleLabel.font = .systemFont(ofSize: 14)
        roleLabel.textColor = UIColor(named: "TextSecondary")

        let labels = UIStackView(arrangedSubviews: [nameLabel, roleLabel])
        labels.axis = .vertical
        labels.spacing = 2
        labels.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(avatar)
        header.addSubview(labels)

        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            header.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            header.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),

            avatar.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            avatar.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 56),
            avatar.heightAnchor.constraint(equalToConstant: 56),

            labels.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            labels.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            labels.centerYAnchor.constraint(equalTo: avatar.centerYAnchor)
        ])

        // Expanded container
        expandedContainer.translatesAutoresizingMaskIntoConstraints = false
        expandedContainer.isHidden = true
        card.addSubview(expandedContainer)
        NSLayoutConstraint.activate([
            expandedContainer.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            expandedContainer.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            expandedContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 10),
            expandedContainer.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        // Scroll + stack
        scroll.translatesAutoresizingMaskIntoConstraints = false
        expandedContainer.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: expandedContainer.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: expandedContainer.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: expandedContainer.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: expandedContainer.bottomAnchor)
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -12),
            contentStack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])

        // Location label
        locationLabel.font = .systemFont(ofSize: 14)
        locationLabel.textColor = UIColor(named: "TextSecondary")

        // Website button
        websiteButton.setTitleColor(UIColor(named: "Header") ?? tintColor, for: .normal)
        websiteButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        websiteButton.contentHorizontalAlignment = .left
        websiteButton.titleLabel?.lineBreakMode = .byTruncatingMiddle
        websiteButton.addTarget(self, action: #selector(openWebsite), for: .touchUpInside)

        // Bio
        bioLabel.font = .systemFont(ofSize: 14)
        bioLabel.numberOfLines = 0

        // Message button
        messageButton.setTitle("Message", for: .normal)
        messageButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        messageButton.backgroundColor = UIColor(named: "Header")?.withAlphaComponent(0.20)
        messageButton.tintColor = UIColor(named: "Header")
        messageButton.layer.cornerRadius = 12
        messageButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        messageButton.isHidden = true
        messageButton.addAction(UIAction { [weak self] _ in self?.onMessageTap?() }, for: .touchUpInside)

        // Portfolio grid
        gridLayout.scrollDirection = .vertical
        gridLayout.minimumLineSpacing = 12
        gridLayout.minimumInteritemSpacing = 12
        portfolioGrid.backgroundColor = .clear
        portfolioGrid.translatesAutoresizingMaskIntoConstraints = false
        portfolioGrid.dataSource = self
        portfolioGrid.delegate = self
        portfolioGrid.register(PortfolioCardCell.self, forCellWithReuseIdentifier: PortfolioCardCell.reuseID)

        // Stack arrangement
        contentStack.addArrangedSubview(locationLabel)
        contentStack.addArrangedSubview(websiteButton)
        contentStack.addArrangedSubview(bioLabel)
        contentStack.addArrangedSubview(messageButton)
        contentStack.setCustomSpacing(6, after: messageButton)
        contentStack.addArrangedSubview(portfolioGrid)
        portfolioGrid.heightAnchor.constraint(equalToConstant: 220).isActive = true
    }

    // MARK: - Configuration

    /// Configures the cell in collapsed mode.
    func configureCollapsed(_ vm: ViewModel) {
        applyHeader(from: vm)
        setExpanded(false)
    }

    /// Configures the cell in expanded mode with portfolio data.
    func configureExpanded(_ vm: ViewModel, portfolios: [PortfolioItem]) {
        applyHeader(from: vm)
        locationLabel.text = vm.location ?? "—"

        if let website = vm.website, !website.isEmpty {
            websiteButton.isHidden = false
            websiteButton.setTitle(website, for: .normal)
        } else {
            websiteButton.isHidden = true
        }

        bioLabel.text = (vm.bio?.isEmpty == false) ? vm.bio : "No bio yet."
        portfolioItems = portfolios
        portfolioGrid.reloadData()
        setExpanded(true)
    }

    /// Toggles the visibility of the message button based on match status.
    func setMatch(isMatched: Bool) {
        messageButton.isHidden = !isMatched
    }

    /// Updates header labels and avatar image.
    private func applyHeader(from vm: ViewModel) {
        nameLabel.text = vm.name
        roleLabel.text = vm.role

        // Load avatar (SDWebImage if available)
        if let url = vm.photoURL {
            #if canImport(SDWebImage)
            avatar.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.circle.fill"))
            #else
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self, let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self.avatar.image = img }
            }.resume()
            #endif
        } else {
            avatar.image = UIImage(systemName: "person.circle.fill")
        }
    }

    /// Shows or hides the expanded content.
    func setExpanded(_ expanded: Bool) {
        isExpanded = expanded
        expandedContainer.isHidden = !expanded
    }

    // MARK: - Actions

    /// Opens the user’s website when tapped.
    @objc private func openWebsite() {
        guard let title = websiteButton.title(for: .normal),
              let url = URL(string: title) else { return }
        onWebsiteTap?(url)
    }
}

// MARK: - Portfolio Grid

extension LikedUserCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        portfolioItems.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: PortfolioCardCell.reuseID, for: indexPath) as! PortfolioCardCell
        cell.configure(with: portfolioItems[indexPath.item])
        return cell
    }

    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onProjectTap?(portfolioItems[indexPath.item])
    }

    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 12
        let columns: CGFloat = 2
        let totalSpacing = spacing * (columns - 1)
        let itemWidth = floor((cv.bounds.width - totalSpacing) / columns)
        return CGSize(width: itemWidth, height: 130)
    }
}
