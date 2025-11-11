//
//  IdeaDetailViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 11/11/25.
//

import UIKit

/// Displays the full detail of a selected `IdeaArticle`.
/// Includes title, metadata, and a button to open the article URL.
final class IdeaDetailViewController: UIViewController {

    // MARK: - Properties

    private let article: IdeaArticle

    // MARK: - UI Elements
    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let urlButton = UIButton(type: .system)

    // MARK: - Initializers

    init(article: IdeaArticle) {
        self.article = article
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "Background") ?? .systemBackground
        buildLayout()
        configureContent()
    }

    // MARK: - Layout Configuration

    /// Builds and constrains scrollable content layout.
    private func buildLayout() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Stack configuration
        stack.axis = .vertical
        stack.spacing = 16
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 24, leading: 20, bottom: 24, trailing: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false

        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])

        // Configure elements
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.numberOfLines = 0
        titleLabel.textColor = UIColor(named: "Surface") ?? .label

        metaLabel.font = .systemFont(ofSize: 15, weight: .regular)
        metaLabel.textColor = UIColor(named: "TextSecondary") ?? .secondaryLabel
        metaLabel.numberOfLines = 0

        urlButton.setTitle("Open Link", for: .normal)
        urlButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        urlButton.backgroundColor = UIColor(named: "Surface") ?? .secondarySystemBackground
        urlButton.setTitleColor(UIColor(named: "Background2") ?? .label, for: .normal)
        urlButton.layer.cornerRadius = 12
        urlButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        urlButton.addAction(UIAction { [weak self] _ in
            guard let self, let url = self.article.url else { return }
            UIApplication.shared.open(url)
        }, for: .touchUpInside)

        // Add arranged subviews
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(metaLabel)
        stack.addArrangedSubview(urlButton)
    }

    // MARK: - Data Configuration

    /// Populates labels and metadata for the selected article.
    private func configureContent() {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        titleLabel.text = article.title
        metaLabel.text = "\(article.points) points • \(article.author) • \(df.string(from: article.date))\n\(article.url?.absoluteString ?? article.urlString)"
    }
}
