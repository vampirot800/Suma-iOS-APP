//
//  UserSearchViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 28/10/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

/// A view controller that allows the user to search for other registered users
/// in the app to start new chat conversations.
final class UserSearchViewController: UIViewController {

    // MARK: - Public API

    /// Closure called when a user is selected from the list.
    var onSelect: ((AppUser) -> Void)?

    // MARK: - UI Components

    /// Search bar for filtering users by name, username, or tags.
    private let searchBar = UISearchBar(frame: .zero)

    /// Table view displaying the list of users.
    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: - Data

    /// Array holding all available users except the current one.
    private var users: [AppUser] = []

    /// Diffable data source type alias.
    private typealias DS = UITableViewDiffableDataSource<Int, String>
    private var dataSource: DS!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureDataSource()
        loadUsers()
    }

    // MARK: - Configuration

    /// Sets up initial view properties and layout.
    private func configureView() {
        title = "Start a chat"
        view.backgroundColor = UIColor(named: "Background2") ?? .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        buildUI()
    }

    /// Builds and lays out the search bar and table view programmatically.
    private func buildUI() {
        // Search bar setup
        searchBar.placeholder = "Search by name, email, or tag"
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.delegate = self
        searchBar.searchTextField.backgroundColor = .white
        searchBar.searchTextField.layer.cornerRadius = 18
        searchBar.searchTextField.layer.masksToBounds = true

        // Table view setup
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserCell")
        tableView.rowHeight = 56
        tableView.estimatedRowHeight = 56
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = UIColor(named: "Background2")
        tableView.separatorColor = UIColor(named: "Divider") ?? .separator
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

        // Layout setup
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Data Source

    /// Configures the diffable data source for displaying users.
    private func configureDataSource() {
        dataSource = DS(tableView: tableView) { [weak self] table, indexPath, itemId in
            guard
                let self = self,
                let user = self.users.first(where: { $0.id == itemId })
            else { return UITableViewCell() }

            let cell = table.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
            cell.backgroundColor = UIColor(named: "Background2")
            cell.contentView.backgroundColor = UIColor(named: "Background2")

            // Create a subtitle-style configuration
            var config = UIListContentConfiguration.subtitleCell()
            let nameFont = UIFont(name: "Inter-SemiBold", size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
            let subFont  = UIFont(name: "Inter-Regular", size: 13) ?? .systemFont(ofSize: 13, weight: .regular)

            config.text = user.displayName.isEmpty ? user.username : user.displayName
            config.textProperties.font = nameFont
            config.textProperties.color = UIColor(named: "TextPrimary") ?? .label

            config.secondaryText = user.role.isEmpty ? user.username : user.role
            config.secondaryTextProperties.font = subFont
            config.secondaryTextProperties.color = (UIColor(named: "TextPrimary") ?? .secondaryLabel)
                .withAlphaComponent(0.7)
            config.secondaryTextProperties.numberOfLines = 2

            config.textToSecondaryTextVerticalPadding = 4
            config.prefersSideBySideTextAndSecondaryText = false
            config.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)

            cell.contentConfiguration = config
            cell.selectionStyle = .default
            return cell
        }
    }

    /// Applies the given user list to the table view using a diffable snapshot.
    private func applySnapshot(_ list: [AppUser]? = nil, animated: Bool = true) {
        let current = list ?? users
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(current.compactMap { $0.id })
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    // MARK: - Data Loading

    /// Loads all users from Firestore except the current authenticated user.
    private func loadUsers() {
        Task {
            do {
                let snapshot = try await FirebaseService.shared.users.getDocuments()
                let currentUserId = Auth.auth().currentUser?.uid

                let allUsers = snapshot.documents
                    .compactMap { AppUser(doc: $0) }
                    .filter { $0.id != currentUserId }

                await MainActor.run {
                    self.users = allUsers
                    self.applySnapshot()
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Error",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - UISearchBarDelegate

extension UserSearchViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        guard !text.isEmpty else {
            applySnapshot()
            return
        }

        let query = text.lowercased()
        let filtered = users.filter {
            $0.displayName.lowercased().contains(query)
            || $0.username.lowercased().contains(query)
            || $0.searchable.joined(separator: " ").lowercased().contains(query)
        }

        applySnapshot(filtered)
    }
}

// MARK: - UITableViewDelegate

extension UserSearchViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard
            let id = dataSource.itemIdentifier(for: indexPath),
            let user = users.first(where: { $0.id == id })
        else { return }

        onSelect?(user)
    }
}
