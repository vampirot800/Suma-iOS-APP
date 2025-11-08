//
//  UserSearchViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 28/10/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class UserSearchViewController: UIViewController {

    // Called by Inbox when a user is picked
    var onSelect: ((AppUser) -> Void)?

    // MARK: UI (programmatic only)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar(frame: .zero)

    // MARK: Data
    private var users: [AppUser] = []

    // Diffable uses String ids
    private typealias DS = UITableViewDiffableDataSource<Int, String>
    private var dataSource: DS!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Start a chat"
        view.backgroundColor = UIColor(named: "Background2") ?? .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72 

        buildUI()
        configureDataSource()
        loadUsers()
    }
    
    

    // MARK: - UI
    private func buildUI() {
        // Search
        searchBar.placeholder = "Search by name, email, or tag"
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.delegate = self
        searchBar.searchTextField.backgroundColor = .white
        searchBar.searchTextField.layer.cornerRadius = 18
        searchBar.searchTextField.layer.masksToBounds = true

        // Table
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserCell")
        tableView.rowHeight = 56
        tableView.estimatedRowHeight = 56
        tableView.separatorStyle = .singleLine
        tableView.delegate = self
        tableView.backgroundColor = UIColor(named: "Background2")
        tableView.separatorColor   = UIColor(named: "Divider") ?? .separator
        tableView.contentInset     = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

        // Layout
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

    // MARK: - Diffable
    private func configureDataSource() {
        dataSource = DS(tableView: tableView) { [weak self] table, indexPath, itemId in
            guard
                let self = self,
                let u = self.users.first(where: { $0.id == itemId })
            else { return UITableViewCell() }

            let cell = table.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)

            // Backgrounds
            cell.backgroundColor = UIColor(named: "Background2")
            cell.contentView.backgroundColor = UIColor(named: "Background2")

            // Subtitle style (title + role/username), multiline secondary text
            var cfg = UIListContentConfiguration.subtitleCell()
            let nameFont = UIFont(name: "Inter-SemiBold", size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
            let subFont  = UIFont(name: "Inter-Regular",  size: 13) ?? .systemFont(ofSize: 13, weight: .regular)
            
            cfg.secondaryTextProperties.numberOfLines = 0
            cfg.textToSecondaryTextVerticalPadding = 4

            cfg.text = u.displayName.isEmpty ? u.username : u.displayName
            cfg.textProperties.font  = nameFont
            cfg.textProperties.color = UIColor(named: "TextPrimary") ?? .label

            cfg.secondaryText = u.role.isEmpty ? u.username : u.role
            cfg.secondaryTextProperties.font  = subFont
            cfg.secondaryTextProperties.color = (UIColor(named: "TextPrimary") ?? .secondaryLabel).withAlphaComponent(0.7)
            cfg.secondaryTextProperties.numberOfLines = 2
            cfg.prefersSideBySideTextAndSecondaryText = false
            cfg.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)

            cell.contentConfiguration = cfg
            cell.selectionStyle = .default
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
                let me = Auth.auth().currentUser?.uid
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
        tableView.deselectRow(at: indexPath, animated: true)
        guard
            let id = dataSource.itemIdentifier(for: indexPath),
            let user = users.first(where: { $0.id == id })
        else { return }
        onSelect?(user)
    }
}

