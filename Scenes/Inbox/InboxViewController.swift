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
    
    // MARK: - Outlets (storyboard)
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmented: UISegmentedControl!
    @IBOutlet weak var ctaCard: UIView!
    @IBOutlet weak var ctaTitleLabel: UILabel!
    @IBOutlet weak var ctaSubtitleLabel: UILabel!
    @IBOutlet weak var ctaButton: UIButton!
    
    // MARK: - State
    private var threads: [ChatThread] = []
    private var userCache: [String: AppUser] = [:]
    private var threadListener: ListenerRegistration?
    private var me: String? { Auth.auth().currentUser?.uid }
    
    // Diffable
    private typealias DS = UITableViewDiffableDataSource<Int, String>
    private var dataSource: DS!
    
    deinit { threadListener?.remove() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // CTA card styling
        ctaCard.layer.cornerRadius = 20
        ctaCard.layer.masksToBounds = true
        ctaButton.addTarget(self, action: #selector(startNewChatTapped), for: .touchUpInside)
        
        // Table
        tableView.delegate = self
        tableView.rowHeight = 92
        tableView.estimatedRowHeight = 92
        tableView.separatorStyle = .none
        
        configureDataSource()
        updateEmptyStateVisibility()
        observeThreads()
    }
    
    // MARK: - DataSource
    private func configureDataSource() {
        dataSource = DS(tableView: tableView) { [weak self] table, indexPath, itemId in
            guard
                let self = self,
                let thread = self.threads.first(where: { $0.id == itemId }),
                let cell = table.dequeueReusableCell(
                    withIdentifier: ChatCardCell.reuseID,
                    for: indexPath
                ) as? ChatCardCell
            else { return UITableViewCell() }
            
            let myId = self.me ?? ""
            let otherId = thread.participants.first { $0 != myId } ?? ""
            let other = self.userCache[otherId]
            
            // Title
            cell.usernameLabel.text = other?.displayName.isEmpty == false
            ? other?.displayName
            : (other?.username ?? "Chat")
            
            // Snippet: show last message if there is one; else role
            if let last = thread.lastmessage, !last.isEmpty {
                cell.snippetLabel.text = last
            } else {
                cell.snippetLabel.text = other?.role ?? ""
            }
            return cell
        }
    }
    
    private func applySnapshot(animated: Bool = true) {
        var snap = NSDiffableDataSourceSnapshot<Int, String>()
        snap.appendSections([0])
        snap.appendItems(threads.compactMap { $0.id })
        dataSource.apply(snap, animatingDifferences: animated)
    }
    
    // MARK: - Live data
    private func observeThreads() {
        guard let uid = me else { return }
        threadListener?.remove()
        
        threadListener = ChatRepository.shared.observeStartedThreads(for: uid) { [weak self] list in
            guard let self = self else { return }
            
            // keep only chats that have a last message time
            self.threads = list
            
            // preload display names for the "other" person
            let otherIds = Set(list.compactMap { $0.participants.first { $0 != uid } })
            self.fetchUsersIfNeeded(ids: Array(otherIds)) { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.updateEmptyStateVisibility()
                    self.applySnapshot()
                }
            }
        }
    }
    
    private func fetchUsersIfNeeded(ids: [String], completion: @escaping () -> Void) {
        let missing = ids.filter { self.userCache[$0] == nil }
        guard !missing.isEmpty else { completion(); return }
        
        let group = DispatchGroup()
        let usersRef = FirebaseService.shared.users
        for oid in missing {
            group.enter()
            usersRef.document(oid).getDocument { [weak self] snap, _ in
                defer { group.leave() }
                guard
                    let self = self,
                    let snap = snap, snap.exists,
                    let u = AppUser(doc: snap)
                else { return }
                self.userCache[oid] = u
            }
        }
        group.notify(queue: .main) { completion() }
    }
    
    private func updateEmptyStateVisibility() {
        let isEmpty = threads.isEmpty
        tableView.isHidden = isEmpty
        ctaCard.isHidden = !isEmpty
    }
    
    // MARK: - Actions
    @IBAction func segmentedChanged(_ sender: UISegmentedControl) {
        // Reserved for "Opportunities" tab later
    }
    
    @objc private func startNewChatTapped() {
        let picker = UserSearchViewController()
        picker.onSelect = { [weak self] user in
            guard let self = self, let otherId = user.id else { return }
            
            // Dismiss the picker, then create/present the chat fullscreen
            self.dismiss(animated: true) {
                Task {
                    do {
                        let chatId = try await ChatRepository.shared.ensureDirectThread(with: otherId)
                        await MainActor.run {
                            let chatVC = ChatViewController(chatId: chatId, other: user)
                            let nav = UINavigationController(rootViewController: chatVC)
                            nav.modalPresentationStyle = .fullScreen
                            self.present(nav, animated: true)
                        }
                    } catch {
                        await MainActor.run {
                            let a = UIAlertController(title: "Couldn't start chat",
                                                      message: error.localizedDescription,
                                                      preferredStyle: .alert)
                            a.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(a, animated: true)
                        }
                    }
                }
            }
        }
        
        let nav = UINavigationController(rootViewController: picker)
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

        let myId = me ?? ""
        let otherId = thread.participants.first { $0 != myId } ?? ""
        let other = userCache[otherId] ?? AppUser(
            id: otherId, displayName: "Chat", username: otherId,
            role: "", bio: "", photoURL: nil, tags: [], searchable: []
        )

        let vc = ChatViewController(chatId: id, other: other)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
