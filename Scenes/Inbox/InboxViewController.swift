//
//  InboxViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

/// Displays the user’s active chat threads and allows starting new chats.
/// Connects to Firestore to fetch real-time thread updates.
final class InboxViewController: UIViewController {

    // MARK: - IBOutlets (Storyboard)
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var segmented: UISegmentedControl!
    @IBOutlet private weak var ctaCard: UIView!
    @IBOutlet private weak var ctaTitleLabel: UILabel!
    @IBOutlet private weak var ctaSubtitleLabel: UILabel!
    @IBOutlet private weak var ctaButton: UIButton!

    // MARK: - State

    /// Currently visible chat threads.
    private var threads: [ChatThread] = []

    /// Cached user profiles for chat participants.
    private var userCache: [String: AppUser] = [:]

    /// Firestore listener for thread updates.
    private var threadListener: ListenerRegistration?

    /// Current user ID.
    private var me: String? { Auth.auth().currentUser?.uid }

    /// Diffable DataSource type alias.
    private typealias DS = UITableViewDiffableDataSource<Int, String>
    private var dataSource: DS!

    deinit {
        threadListener?.remove()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCTA()
        configureTableView()
        configureDataSource()
        observeThreads()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustTableInsets()
    }

    // MARK: - UI Configuration

    /// Configures the floating call-to-action (CTA) card at the bottom.
    private func configureCTA() {
        ctaCard.layer.cornerRadius = 20
        ctaCard.layer.masksToBounds = true
        ctaButton.addTarget(self, action: #selector(startNewChatTapped), for: .touchUpInside)
    }

    /// Configures the main table view.
    private func configureTableView() {
        tableView.backgroundColor = UIColor(named: "Background2")
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.rowHeight = 110
        tableView.estimatedRowHeight = 110
        tableView.allowsSelection = true
    }

    /// Ensures the CTA card never overlaps the chat list.
    private func adjustTableInsets() {
        let cardFrame = view.convert(ctaCard.frame, from: ctaCard.superview)
        let overlapHeight = max(0, view.bounds.maxY - cardFrame.minY)
        var inset = tableView.contentInset
        inset.bottom = overlapHeight + 16
        tableView.contentInset = inset
        tableView.verticalScrollIndicatorInsets.bottom = inset.bottom
    }

    // MARK: - Data Source Configuration

    /// Creates and configures the diffable data source for the chat list.
    private func configureDataSource() {
        dataSource = DS(tableView: tableView) { [weak self] table, indexPath, itemId in
            guard
                let self = self,
                let thread = self.threads.first(where: { $0.id == itemId }),
                let cell = table.dequeueReusableCell(withIdentifier: ChatCardCell.reuseID,
                                                     for: indexPath) as? ChatCardCell
            else { return UITableViewCell() }

            let myId = self.me ?? ""
            let otherId = thread.participants.first { $0 != myId } ?? ""
            let other = self.userCache[otherId]

            // Configure the cell labels
            cell.configure(
                username: other?.displayName.isEmpty == false
                    ? (other?.displayName ?? "Chat")
                    : (other?.username ?? "Chat"),
                snippet: thread.lastmessage ?? ""
            )

            cell.selectionStyle = .default
            return cell
        }
    }

    /// Applies a new diffable snapshot to refresh the visible chat list.
    private func applySnapshot(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(threads.compactMap { $0.id })
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    // MARK: - Firestore Live Threads

    /// Subscribes to Firestore to listen for real-time chat updates.
    private func observeThreads() {
        guard let uid = me else { return }
        threadListener?.remove()

        Firestore.firestore().collection("chats")
            .whereField("participants", arrayContains: uid)
            .order(by: "lastmessagetime", descending: true)
            .addSnapshotListener { [weak self] snap, error in
                guard let self = self else { return }
                if let error = error {
                    print("observeThreads error:", error)
                    return
                }

                let all = snap?.documents.compactMap { ChatThread(doc: $0) } ?? []
                // Show only threads that contain a message.
                self.threads = all.filter { ($0.lastmessage?.isEmpty == false) }

                // Preload “other user” data for display.
                let otherIds = Set(self.threads.compactMap { t in
                    t.participants.first { $0 != uid }
                })
                self.fetchUsersIfNeeded(ids: Array(otherIds)) { [weak self] in
                    self?.applySnapshot()
                }
            }
    }

    /// Fetches missing user profiles from Firestore to populate the chat list.
    private func fetchUsersIfNeeded(ids: [String], completion: @escaping () -> Void) {
        let missing = ids.filter { self.userCache[$0] == nil }
        guard !missing.isEmpty else { completion(); return }

        let group = DispatchGroup()
        for oid in missing {
            group.enter()
            FirebaseService.shared.users.document(oid).getDocument { [weak self] snap, _ in
                defer { group.leave() }
                guard
                    let self = self,
                    let snap = snap, snap.exists,
                    let user = AppUser(doc: snap)
                else { return }
                self.userCache[oid] = user
            }
        }
        group.notify(queue: .main, execute: completion)
    }

    // MARK: - Actions

    @IBAction private func segmentedChanged(_ sender: UISegmentedControl) {
        // Reserved for future filters (e.g., unread / archived)
    }

    /// Opens a user picker to start a new chat.
    @objc private func startNewChatTapped() {
        let picker = UserSearchViewController()

        picker.onSelect = { [weak self] user in
            guard let self = self, let otherId = user.id else { return }
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
                            let alert = UIAlertController(
                                title: "Couldn't start chat",
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

        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
}

// MARK: - UITableViewDelegate

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
            id: otherId,
            displayName: "Chat",
            username: otherId,
            role: "",
            bio: "",
            photoURL: nil,
            tags: [],
            searchable: []
        )

        let chatVC = ChatViewController(chatId: id, other: other)
        chatVC.hidesBottomBarWhenPushed = true

        if let nav = navigationController {
            nav.pushViewController(chatVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: chatVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    /// Enforces consistent cell height for chat cards.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 130 }
}
