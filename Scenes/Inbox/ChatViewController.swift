//
//  ChatViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 28/10/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

// Simple bubble cell
private final class MessageCell: UITableViewCell {
    private let bubble = UIView()
    private let label = UILabel()
    private var leadingC: NSLayoutConstraint!
    private var trailingC: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.addSubview(bubble)
        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.layer.cornerRadius = 16

        bubble.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),

            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubble.widthAnchor.constraint(lessThanOrEqualToConstant: 280)
        ])

        leadingC  = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingC = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        leadingC.isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(text: String, outgoing: Bool) {
        label.text = text

        // Theme
        if outgoing {
            bubble.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.92)
            label.textColor = .white
            leadingC.isActive = false
            trailingC.isActive = true
            bubble.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
        } else {
            bubble.backgroundColor = UIColor.secondarySystemBackground
            label.textColor = .label
            trailingC.isActive = false
            leadingC.isActive = true
            bubble.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
        }
        layoutIfNeeded()
    }
}

final class ChatViewController: UIViewController {

    // MARK: - Inputs
    private let chatId: String
    private let otherUser: AppUser?

    // MARK: - State
    private var messages: [Message] = []
    private var listener: ListenerRegistration?
    private var me: String { Auth.auth().currentUser?.uid ?? "" }

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputContainer = UIView()
    private let textView = UITextView()
    private let placeholder = UILabel()
    private let sendButton = UIButton(type: .system)

    // MARK: - Diffable
    private typealias DS = UITableViewDiffableDataSource<Int, String>
    private var dataSource: DS!

    // MARK: - Init
    init(chatId: String, other: AppUser?) {
        self.chatId = chatId
        self.otherUser = other
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
        self.modalPresentationStyle = .fullScreen
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    deinit { listener?.remove() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = otherUser?.displayName ?? "Chat"
        view.backgroundColor = .systemBackground
        
        setupBackButton()
        
        buildTable()
        buildInputBar()
        configureDataSource()
        observeMessages()
        tableView.keyboardDismissMode = .interactive
    }
    
    private func setupBackButton() {
        // If we're the root of a presented nav stack, show a Close button.
        // If we're pushed in an existing nav, the system back button appears automatically.
        let isRootOfPresentedNav =
            (navigationController?.viewControllers.first == self) && (presentingViewController != nil)

        if isRootOfPresentedNav {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                systemItem: .close,
                primaryAction: UIAction { [weak self] _ in
                    self?.dismiss(animated: true)
                }
            )
        } else {
            // When pushed, keep default back button and enable the interactive pop gesture.
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }


    // MARK: - UI Builders
    private func buildTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.register(MessageCell.self, forCellReuseIdentifier: "msg")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ])
    }

    private func buildInputBar() {
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.backgroundColor = .secondarySystemBackground

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.delegate = self

        placeholder.text = "Message…"
        placeholder.textColor = .secondaryLabel
        placeholder.translatesAutoresizingMaskIntoConstraints = false

        sendButton.setTitle("Send", for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        inputContainer.addSubview(textView)
        inputContainer.addSubview(placeholder)
        inputContainer.addSubview(sendButton)
        view.addSubview(inputContainer)

        let bottom = inputContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)

        NSLayoutConstraint.activate([
            inputContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            bottom,

            textView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            textView.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 8),
            textView.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -8),

            sendButton.leadingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 56),

            placeholder.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 4),
            placeholder.topAnchor.constraint(equalTo: textView.topAnchor, constant: 2),

            // Tie table bottom to input top
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor)
        ])
    }

    // MARK: - DataSource
    private func configureDataSource() {
        dataSource = DS(tableView: tableView) { [weak self] table, indexPath, itemId in
            guard
                let self = self,
                let msg = self.messages.first(where: { $0.id == itemId }),
                let cell = table.dequeueReusableCell(withIdentifier: "msg", for: indexPath) as? MessageCell
            else { return UITableViewCell() }

            let outgoing = (msg.senderID == self.me)
            cell.configure(text: msg.text, outgoing: outgoing)
            return cell
        }
    }

    private func applySnapshot(animated: Bool = true) {
        var snap = NSDiffableDataSourceSnapshot<Int, String>()
        snap.appendSections([0])
        snap.appendItems(messages.compactMap { $0.id })
        dataSource.apply(snap, animatingDifferences: animated)
        if let last = messages.indices.last {
            tableView.scrollToRow(at: IndexPath(row: last, section: 0), at: .bottom, animated: animated)
        }
    }

    // MARK: - Firestore
    private func observeMessages() {
        listener = ChatRepository.shared.observeMessages(chatId: chatId) { [weak self] msgs in
            guard let self = self else { return }
            self.messages = msgs
            DispatchQueue.main.async { self.applySnapshot() }
        }
    }

    // MARK: - Actions
    @objc private func sendTapped() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        Task {
            try? await ChatRepository.shared.sendText(chatId: chatId, text: text)
            await MainActor.run {
                self.textView.text = ""
                self.placeholder.isHidden = false
            }
        }
    }
}

extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholder.isHidden = !textView.text.isEmpty
    }
}
