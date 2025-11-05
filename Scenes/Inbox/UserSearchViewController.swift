//
//  UserSearchViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 28/10/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

final class UserSearchViewController: UIViewController {
    // Called by Inbox when a user is picked
    var onSelect: ((AppUser) -> Void)?

    // UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar(frame: .zero)

    // Data
    private var users: [AppUser] = []

    // Diffable: use Int to avoid Sendable/actor issues
    private typealias DS = UITableViewDiffableDataSource<Int, String>
    private var dataSource: DS!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Start a chat"
        view.backgroundColor = .systemBackground
        buildUI()
        configureDataSource()
        loadUsers()
    }

    // MARK: - UI
    private func buildUI() {
        searchBar.placeholder = "Search by name, email, or tag"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self

        view.addSubview(searchBar)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Diffable Data Source
    private func configureDataSource() {
        dataSource = DS(tableView: tableView) { [weak self] table, indexPath, itemId in
            guard
                let self = self,
                let u = self.users.first(where: { $0.id == itemId })
            else { return UITableViewCell() }

            let cell = table.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.numberOfLines = 2
            cell.textLabel?.text = u.displayName.isEmpty ? (u.username) : u.displayName
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }

    private func applySnapshot(_ list: [AppUser]? = nil, animated: Bool = true) {
        let current = list ?? users
        var snap = NSDiffableDataSourceSnapshot<Int, String>()
        snap.appendSections([0])
        snap.appendItems(current.compactMap { $0.id })
        dataSource.apply(snap, animatingDifferences: animated)
    }

    // MARK: - Data
    private func loadUsers() {
        Task {
            do {
                let qs = try await FirebaseService.shared.users.getDocuments()
                let me = FirebaseService.shared.auth.currentUser?.uid
                let all = qs.documents.compactMap { AppUser(doc: $0) }.filter { $0.id != me }
                await MainActor.run {
                    self.users = all
                    self.applySnapshot()
                }
            } catch {
                await MainActor.run {
                    let a = UIAlertController(title: "Error",
                                              message: error.localizedDescription,
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(a, animated: true)
                }
            }
        }
    }
}

// MARK: - Search
extension UserSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        guard !text.isEmpty else { applySnapshot(); return }
        let q = text.lowercased()
        let filtered = users.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.username.lowercased().contains(q) ||
            $0.searchable.joined(separator: " ").lowercased().contains(q)
        }
        applySnapshot(filtered)
    }
}

// MARK: - Selection
extension UserSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let id = dataSource.itemIdentifier(for: indexPath),
            let user = users.first(where: { $0.id == id })
        else { return }
        onSelect?(user)
    }
}
