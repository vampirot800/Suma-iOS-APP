//
//  AcknowledgementsViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import UIKit
import SafariServices

/// Represents an external library or service acknowledged in the app.
struct AcknowledgementItem {
    let name: String
    let license: String
    let url: URL?
}

/// A simple view controller listing external libraries and APIs used in the project.
final class AcknowledgementsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Properties

    /// Static list of third-party acknowledgements used in this app.
    /// Modify as needed to reflect any new frameworks or APIs.
    private let items: [AcknowledgementItem] = [
        .init(
            name: "Firebase (Auth / Firestore / Storage)",
            license: "Apache License 2.0",
            url: URL(string: "https://github.com/firebase/firebase-ios-sdk")
        ),
        .init(
            name: "Algolia Hacker News API",
            license: "Public API",
            url: URL(string: "https://hn.algolia.com/api")
        )
    ]

    /// Main table view displaying the acknowledgements.
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    // MARK: - UI Setup

    /// Configures the view controller’s user interface and layout.
    private func configureUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "Acknowledgements"

        // Add a dismiss button (for modally presented screens)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(close)
        )

        // Configure table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Configure header text
        setupHeader()
    }

    /// Sets up the table header with a brief acknowledgements summary.
    private func setupHeader() {
        let headerLabel = UILabel()
        headerLabel.text =
        """
        I acknowledge the following libraries and services used in this app. Their work makes key features possible:
        • Firebase SDKs (Auth, Firestore, Storage)
        • Algolia Hacker News API (for the Ideas tab)
        """
        headerLabel.font = .systemFont(ofSize: 14)
        headerLabel.textColor = .secondaryLabel
        headerLabel.numberOfLines = 0
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        let headerContainer = UIView()
        headerContainer.addSubview(headerLabel)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -20),
            headerLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -8)
        ])

        headerContainer.layoutIfNeeded()
        headerContainer.frame.size.height = headerLabel.intrinsicContentSize.height + 24
        tableView.tableHeaderView = headerContainer
    }

    // MARK: - Actions

    /// Dismisses the view controller.
    @objc private func close() { dismiss(animated: true) }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = UIListContentConfiguration.subtitleCell()
        config.text = item.name
        config.secondaryText = item.license
        cell.contentConfiguration = config
        cell.accessoryType = item.url == nil ? .none : .disclosureIndicator
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let url = items[indexPath.row].url else { return }
        present(SFSafariViewController(url: url), animated: true)
    }
}
