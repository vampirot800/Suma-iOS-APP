//
//  InboxViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//


import UIKit
import FirebaseAuth
import FirebaseFirestore

final class InboxViewController: UIViewController {
    
    // MARK: - State
    private var threads: [ChatThread] = []
    private var userCache: [String: AppUser] = [:]
    private var threadListener: ListenerRegistration?
    private var me: String? { Auth.auth().currentUser?.uid }
    
    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    private let emptyCard = UIView()
    private let emptyTitle = UILabel()
    private let emptySubtitle = UILabel()
    private let emptyStartButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Start a new chat"
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false          // FIX: enable Auto Layout
        return b
    }()
    
    private lazy var headerStartButton: UIButton = {
        let b = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "Start a new chat"
        b.configuration = config
        b.backgroundColor = .secondarySystemBackground
        b.layer.cornerRadius = 12
        b.addTarget(self, action: #selector(startNewChatTapped), for: .touchUpInside)
        return b
    }()
    
    // Diffable
    private typealias DS = UITableViewDiffableDataSource<Int, String>
    private var dataSource: DS!
    
    deinit { threadListener?.remove() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Inbox"
        view.backgroundColor = .systemBackground
        buildTable()
        buildEmptyState()
        configureDataSource()
        
        updateEmptyStateVisibility()                                  // FIX: show empty state immediately
        observeThreads()
    }
    
    // MARK: - Build UI
    private func buildTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.rowHeight = 72
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func buildEmptyState() {
        emptyCard.translatesAutoresizingMaskIntoConstraints = false
        emptyCard.backgroundColor = .secondarySystemBackground
        emptyCard.layer.cornerRadius = 18
        
        emptyTitle.text = "Start a new chat"
        emptyTitle.font = .systemFont(ofSize: 26, weight: .semibold)
        emptyTitle.textAlignment = .center
        emptyTitle.translatesAutoresizingMaskIntoConstraints = false
        
        emptySubtitle.text = "Search any user and send them a message."
        emptySubtitle.numberOfLines = 0
        emptySubtitle.textAlignment = .center
        emptySubtitle.textColor = .secondaryLabel
        emptySubtitle.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStartButton.addTarget(self, action: #selector(startNewChatTapped), for: .touchUpInside)
        
        [emptyTitle, emptySubtitle, emptyStartButton].forEach { emptyCard.addSubview($0) }
        view.addSubview(emptyCard)
        
        NSLayoutConstraint.activate([
            emptyCard.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            emptyCard.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            emptyCard.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyTitle.topAnchor.constraint(equalTo: emptyCard.topAnchor, constant: 24),
            emptyTitle.leadingAnchor.constraint(equalTo: emptyCard.leadingAnchor, constant: 16),
            emptyTitle.trailingAnchor.constraint(equalTo: emptyCard.trailingAnchor, constant: -16),
            
            emptySubtitle.topAnchor.constraint(equalTo: emptyTitle.bottomAnchor, constant: 8),
            emptySubtitle.leadingAnchor.constraint(equalTo: emptyTitle.leadingAnchor),
            emptySubtitle.trailingAnchor.constraint(equalTo: emptyTitle.trailingAnchor),
            
            emptyStartButton.topAnchor.constraint(equalTo: emptySubtitle.bottomAnchor, constant: 20),
            emptyStartButton.centerXAnchor.constraint(equalTo: emptyCard.centerXAnchor),
            emptyStartButton.bottomAnchor.constraint(equalTo: emptyCard.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - DataSource
    private func configureDataSource() {
        dataSource = DS(tableView: tableView) { [weak self] table, indexPath, itemId in
            guard
                let self = self,
                let thread = self.threads.first(where: { $0.id == itemId })
            else { return UITableViewCell() }
            
            let cell = table.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            
            let otherId = thread.participants.first { $0 != self.me } ?? ""
            let other = self.userCache[otherId]
            
            var config = cell.defaultContentConfiguration()
            config.text = other?.displayName ?? "Chat"
            config.textProperties.font = .systemFont(ofSize: 16, weight: .semibold)
            
            var subtitle = other?.role ?? ""
            if let last = thread.lastmessage, !last.isEmpty { subtitle = last }
            config.secondaryText = subtitle
            config.secondaryTextProperties.color = .secondaryLabel
            
            cell.contentConfiguration = config
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    private func applySnapshot(animated: Bool = true) {
        var snap = NSDiffableDataSourceSnapshot<Int, String>()
        snap.appendSections([0])
        snap.appendItems(threads.compactMap { $0.id })
        dataSource.apply(snap, animatingDifferences: animated)
    }
    
    // MARK: - Data (live)
    private func observeThreads() {
        guard let uid = me else { return }
        threadListener = ChatRepository.shared.observeThreads(for: uid) { [weak self] threads in
            guard let self = self else { return }
            self.threads = threads
            self.preloadOthers(threads: threads)
            DispatchQueue.main.async {
                self.updateEmptyStateVisibility()
                self.applySnapshot()
            }
        }
    }
    
    private func preloadOthers(threads: [ChatThread]) {
        guard let me = me else { return }
        let otherIds = Set(threads.compactMap { $0.participants.first(where: { $0 != me }) })
        let missing = otherIds.filter { userCache[$0] == nil }
        guard !missing.isEmpty else { return }
        
        let group = DispatchGroup()
        let usersRef = FirebaseService.shared.users
        for oid in missing {
            group.enter()
            usersRef.document(oid).getDocument { [weak self] snap, _ in
                defer { group.leave() }
                guard let self = self, let snap = snap, snap.exists,
                      let u = AppUser(doc: snap) else { return }
                self.userCache[oid] = u
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.applySnapshot(animated: false)
        }
    }
    
    private func updateEmptyStateVisibility() {
        let isEmpty = threads.isEmpty
        emptyCard.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        
        if !isEmpty {
            let header = UIView()
            header.backgroundColor = .clear
            header.addSubview(headerStartButton)
            headerStartButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                headerStartButton.leadingAnchor.constraint(equalTo: header.layoutMarginsGuide.leadingAnchor),
                headerStartButton.trailingAnchor.constraint(equalTo: header.layoutMarginsGuide.trailingAnchor),
                headerStartButton.topAnchor.constraint(equalTo: header.layoutMarginsGuide.topAnchor, constant: 8),
                headerStartButton.bottomAnchor.constraint(equalTo: header.layoutMarginsGuide.bottomAnchor, constant: -8)
            ])
            header.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
            header.frame.size.height = 56
            tableView.tableHeaderView = header
        } else {
            tableView.tableHeaderView = nil
        }
    }
    
    // MARK: - Actions
    @objc private func startNewChatTapped() {
        let vc = UserSearchViewController()
        
        vc.onSelect = { [weak self] user in
            guard let self = self,
                  let me = self.me,
                  let otherId = user.id,
                  otherId != me else { return }
            
            Task {
                do {
                    // Create (or reuse) the 1:1 thread
                    let chatId = try await ChatRepository.shared.ensureDirectThread(with: otherId)
                    
                    await MainActor.run {
                        let chatVC = ChatViewController(chatId: chatId, other: user)
                        chatVC.modalPresentationStyle = .fullScreen
                        
                        // Always dismiss the search, THEN present chat modally full-screen.
                        let presentChat: () -> Void = {
                            let nav = UINavigationController(rootViewController: chatVC)
                            nav.modalPresentationStyle = .fullScreen
                            self.present(nav, animated: true)
                        }
                        
                        if let presented = self.presentedViewController {
                            presented.dismiss(animated: true) { presentChat() }
                        } else {
                            presentChat()
                        }
                    }
                } catch {
                    await MainActor.run {
                        let a = UIAlertController(
                            title: "Couldn't start chat",
                            message: error.localizedDescription,
                            preferredStyle: .alert
                        )
                        a.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(a, animated: true)
                    }
                }
            }
        }
        
        // Present the search in a sheet or full screen—your call.
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
}
extension InboxViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard
            let id = dataSource.itemIdentifier(for: indexPath),
            let thread = threads.first(where: { $0.id == id })
        else { return }

        let otherId = thread.participants.first { $0 != me } ?? ""
        let other = userCache[otherId] ?? AppUser(
            id: otherId, displayName: "Chat", username: otherId,
            role: "", bio: "", photoURL: nil, tags: [], searchable: []
        )

        let vc = ChatViewController(chatId: id, other: other)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
