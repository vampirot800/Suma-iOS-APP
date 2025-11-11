//
//  ProjectDetailViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 11/11/25.
//
//  Displays detailed information about a portfolio project
//  (title, role, dates, skills, description, and media links)
//  in a bottom-sheet style presentation.
//

import UIKit

/// A modal bottom-sheet–style controller that presents detailed information
/// about a `PortfolioItem`. Includes smooth entrance animation and dynamic layout.
final class ProjectDetailViewController: UIViewController {

    // MARK: - Properties

    private let item: PortfolioItem
    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private var animator: UIViewPropertyAnimator?

    // MARK: - Initialization

    init(item: PortfolioItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        configureContent()
        prepareForEntranceAnimation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateEntrance()
    }

    // MARK: - Layout Setup

    /// Sets up the scrollable layout and stack constraints.
    private func setupLayout() {
        view.backgroundColor = UIColor(named: "Background") ?? .systemBackground
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scroll)
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -40),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    // MARK: - Content Configuration

    /// Populates the stack with project information:
    /// title, role, dates, skills, description, and media links.
    private func configureContent() {
        // Title
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.numberOfLines = 0
        titleLabel.text = item.title.isEmpty ? "Untitled Project" : item.title
        stack.addArrangedSubview(titleLabel)

        // Role + Dates
        let metaLabel = UILabel()
        metaLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        metaLabel.textColor = UIColor(named: "TextSecondary") ?? .secondaryLabel
        metaLabel.text = formattedMetaText()
        stack.addArrangedSubview(metaLabel)

        // Skills chips
        if !item.skills.isEmpty {
            let chipStack = buildSkillChips(from: item.skills)
            stack.addArrangedSubview(chipStack)
        }

        // Description
        if !item.description.isEmpty {
            let descLabel = UILabel()
            descLabel.font = .systemFont(ofSize: 15)
            descLabel.numberOfLines = 0
            descLabel.text = item.description
            stack.addArrangedSubview(descLabel)
        }

        // Media URLs
        if !item.mediaURLs.isEmpty {
            let mediaHeader = UILabel()
            mediaHeader.font = .systemFont(ofSize: 15, weight: .semibold)
            mediaHeader.text = "Media"
            stack.addArrangedSubview(mediaHeader)

            for urlStr in item.mediaURLs.prefix(6) {
                let button = UIButton(type: .system)
                button.setTitle(urlStr, for: .normal)
                button.contentHorizontalAlignment = .left
                button.titleLabel?.lineBreakMode = .byTruncatingMiddle
                button.addAction(UIAction { _ in
                    if let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }, for: .touchUpInside)
                stack.addArrangedSubview(button)
            }
        }
    }

    /// Builds the label text combining role and date range.
    private func formattedMetaText() -> String {
        var parts: [String] = []
        if !item.role.isEmpty { parts.append(item.role) }

        let df = DateFormatter()
        df.dateFormat = "MMM yyyy"

        if item.startDate != nil || item.endDate != nil {
            let range: String
            switch (item.startDate, item.endDate) {
            case let (s?, e?): range = "\(df.string(from: s)) – \(df.string(from: e))"
            case let (s?, nil): range = "\(df.string(from: s)) – Present"
            case let (nil, e?): range = "Until \(df.string(from: e))"
            default: range = ""
            }
            if !range.isEmpty { parts.append(range) }
        }
        return parts.joined(separator: " · ")
    }

    /// Creates horizontally scrolling skill chips.
    private func buildSkillChips(from skills: [String]) -> UIStackView {
        let chips = UIStackView()
        chips.axis = .horizontal
        chips.spacing = 8
        chips.alignment = .leading
        chips.distribution = .fill
        chips.translatesAutoresizingMaskIntoConstraints = false

        for skill in skills.prefix(8) {
            let pill = UILabel()
            pill.text = "  \(skill)  "
            pill.font = .systemFont(ofSize: 13, weight: .medium)
            pill.textColor = (UIColor(named: "Header") ?? view.tintColor)
            pill.backgroundColor = (UIColor(named: "Header") ?? view.tintColor).withAlphaComponent(0.15)
            pill.layer.cornerRadius = 10
            pill.layer.masksToBounds = true
            pill.setContentHuggingPriority(.required, for: .horizontal)
            pill.setContentCompressionResistancePriority(.required, for: .horizontal)
            chips.addArrangedSubview(pill)
        }
        return chips
    }

    // MARK: - Animation

    /// Prepares the initial hidden state for smooth scale-in animation.
    private func prepareForEntranceAnimation() {
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
    }

    /// Fades and scales the view in smoothly upon presentation.
    private func animateEntrance() {
        animator?.stopAnimation(true)
        animator = UIViewPropertyAnimator(duration: 0.25, curve: .easeOut) { [weak self] in
            guard let self else { return }
            self.view.alpha = 1
            self.view.transform = .identity
        }
        animator?.startAnimation()
    }
}
