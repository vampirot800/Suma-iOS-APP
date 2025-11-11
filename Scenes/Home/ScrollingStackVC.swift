//
//  ScrollingStackVC.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 05/10/25.
//

import UIKit

/// Reusable skeleton: UIScrollView → contentView → vertical UIStackView.
class ScrollingStackViewController: UIViewController {

    // MARK: - Public hooks
    let scrollView = UIScrollView()
    let contentView = UIView()
    let stackView = UIStackView()

    // Optional: tweak paddings in subclasses if you want
    var contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
    }

    private func buildLayout() {
        view.backgroundColor = .systemBackground

        // Scroll view pinned to the safe area
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        // Content view fills the scroll view’s content layout; width matches frame to avoid horizontal scroll
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        // Root vertical stack with margins
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)

        contentView.directionalLayoutMargins = contentInsets
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }
}
