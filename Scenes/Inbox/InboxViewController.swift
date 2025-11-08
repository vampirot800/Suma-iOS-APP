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

    private typealias DS = UITableViewDiffableDataSource<Int, String>
    private var dataSource: DS!

    deinit { threadListener?.remove() }

    override func viewDidLoad() {
        super.viewDidLoad()

        // CTA (always visible)
        ctaCard.layer.cornerRadius = 20
        ctaCard.layer.masksToBounds = true
        ctaButton.addTarget(self, action: #selector(startNewChatTapped), for: .touchUpInside)

        // Table
        tableView.backgroundColor = UIColor(named: "Background2")
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.allowsSelection = true


        tableView.rowHeight = 110
        tableView.estimatedRowHeight = 110

        configureDataSource()
        observeThreads()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Keep space so the list never hides under the CTA card
        let cardFrame = view.convert(ctaCard.frame, from: ctaCard.superview)
        let overlapHeight = max(0, view.bounds.maxY - cardFrame.minY)
        var inset = tableView.contentInset
        inset.bottom = overlapHeight + 16
        tableView.contentInset = inset
        tableView.verticalScrollIndicatorInsets.bottom = inset.bottom
    }

    // MARK: - DataSource
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

            // Title
            cell.usernameLabel.text = other?.displayName.isEmpty == false
                ? other?.displayName
                : (other?.username ?? "Chat")

            // Snippet: ONLY last message (no fallback)
            cell.snippetLabel.text = thread.lastmessage ?? ""
            cell.usernameLabel.transform = CGAffineTransform(translationX: 0, y: 6)
            cell.snippetLabel.transform  = CGAffineTransform(translationX: 0, y: 6)

            cell.selectionStyle = .default
            return cell
        }
    }

    private func applySnapshot(animated: Bool = true) {
        var snap = NSDiffableDataSourceSnapshot<Int, String>()
        snap.appendSections([0])
        snap.appendItems(threads.compactMap { $0.id })
        dataSource.apply(snap, animatingDifferences: animated)
    }

    // MARK: - Firestore live threads
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

                // Show ONLY started chats → must have a non-empty lastmessage.
                self.threads = all.filter { ($0.lastmessage?.isEmpty == false) }

                // Preload "other" user info for display
                let otherIds = Set(self.threads.compactMap { t in
                    t.participants.first { $0 != uid }
                })
                self.fetchUsersIfNeeded(ids: Array(otherIds)) { [weak self] in
                    self?.applySnapshot()
                }
            }
    }

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
                    let u = AppUser(doc: snap)
                else { return }
                self.userCache[oid] = u
            }
        }
        group.notify(queue: .main, execute: completion)
    }

    // MARK: - Actions
    @IBAction func segmentedChanged(_ sender: UISegmentedControl) { }

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

// MARK: - Table delegate (open chat on tap)
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

    // enforce the 130pt height here for consistency
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 130 }
}
