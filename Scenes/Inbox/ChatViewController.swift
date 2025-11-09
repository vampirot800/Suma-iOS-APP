//
//  ChatViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 28/10/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

// MARK: -T heme helpers
private func appColor(_ name: String, fallback: UIColor) -> UIColor {
    UIColor(named: name) ?? fallback
}
private func inter(_ weight: String = "Regular", _ size: CGFloat) -> UIFont {
    let map: [String:String] = [
        "Regular": "Inter-Regular",
        "SemiBold": "Inter-SemiBold",
        "Bold": "Inter-Bold"
    ]
    return UIFont(name: map[weight] ?? "Inter-Regular", size: size) ?? .systemFont(ofSize: size)
}

// MARK: - Message bubble

private final class MessageCell: UITableViewCell {
    private let bubble = UIView()
    private let label = UILabel()
    private var leadingC: NSLayoutConstraint!
    private var trailingC: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.layer.cornerRadius = 18
        bubble.layer.masksToBounds = true

        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = inter("Regular", 16)

        contentView.addSubview(bubble)
        bubble.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -14),

            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75)
        ])

        leadingC  = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingC = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        leadingC.isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(text: String, outgoing: Bool) {
        label.text = text

        if outgoing {
            bubble.backgroundColor = appColor("likeGreen", fallback: UIColor.systemGreen)
            label.textColor = .white
            leadingC.isActive = false
            trailingC.isActive = true
            bubble.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
        } else {
            bubble.backgroundColor = appColor("Surface", fallback: UIColor.secondarySystemBackground)
            label.textColor = appColor("Background2", fallback: .systemGroupedBackground)
            trailingC.isActive = false
            leadingC.isActive = true
            bubble.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
        }
        layoutIfNeeded()
    }
}

// MARK: - Chat VC

final class ChatViewController: UIViewController {

    // Inputs
    private let chatId: String
    private let otherUser: AppUser?

    // State
    private var messages: [Message] = []
    private var listener: ListenerRegistration?
    private var me: String { Auth.auth().currentUser?.uid ?? "" }

    // NAV state snapshots (so changes don't leak to other VCs)
    private var previousNavBarHidden = false
    private var previousTranslucent  = false
    private var previousBgImage: UIImage?
    private var previousShadowImage: UIImage?

    // UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputBar = UIView()
    private let fieldContainer = UIView()
    private let textView = UITextView()
    private let placeholder = UILabel()
    private let sendButton = UIButton(type: .system)

    // Diffable
    private typealias DS = UITableViewDiffableDataSource<Int, String>
    private var dataSource: DS!

    // Init
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
        navigationController?.navigationBar.titleTextAttributes = [
            .font: inter("SemiBold", 17)
        ]

        // Full themed background
        view.backgroundColor = appColor("Background2", fallback: .systemGroupedBackground)

        buildTable()
        buildInputBar()
        configureDataSource()
        observeMessages()
        tableView.keyboardDismissMode = .interactive
    }

    // MARK: - UI

    private func buildTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(MessageCell.self, forCellReuseIdentifier: "msg")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 12, right: 0)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
    }

    private func buildInputBar() {
        // Green rounded bar stuck to keyboard
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.backgroundColor = appColor("Header", fallback: UIColor.systemGreen)
        inputBar.layer.cornerRadius = 22
        inputBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        inputBar.layer.masksToBounds = true

        // Message field container (pill)
        fieldContainer.translatesAutoresizingMaskIntoConstraints = false
        fieldContainer.backgroundColor = appColor("sumaWhite", fallback: .systemBackground)
        fieldContainer.layer.cornerRadius = 18
        fieldContainer.layer.masksToBounds = true

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.font = inter("Regular", 16)
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)

        placeholder.translatesAutoresizingMaskIntoConstraints = false
        placeholder.text = "Message…"
        placeholder.textColor = appColor("TestSecondary", fallback: .secondaryLabel)
        placeholder.font = inter("Regular", 16)

        // Circular send button with glyph
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        let plane = UIImage(systemName: "paperplane.fill")
        sendButton.setImage(plane, for: .normal)
        sendButton.tintColor = .white
        sendButton.backgroundColor = appColor("BrandPrimary", fallback: UIColor.systemGreen)
        sendButton.layer.cornerRadius = 22
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        // Hierarchy
        view.addSubview(inputBar)
        inputBar.addSubview(fieldContainer)
        fieldContainer.addSubview(textView)
        fieldContainer.addSubview(placeholder)
        inputBar.addSubview(sendButton)

        // Constraints
        let bottom = inputBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        NSLayoutConstraint.activate([
            inputBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            bottom,
            inputBar.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),

            fieldContainer.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 14),
            fieldContainer.topAnchor.constraint(equalTo: inputBar.topAnchor, constant: 10),
            fieldContainer.bottomAnchor.constraint(equalTo: inputBar.bottomAnchor, constant: -10),

            sendButton.leadingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: 10),
            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -14),
            sendButton.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44),

            textView.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -8),
            textView.topAnchor.constraint(equalTo: fieldContainer.topAnchor, constant: 6),
            textView.bottomAnchor.constraint(equalTo: fieldContainer.bottomAnchor, constant: -6),

            placeholder.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 4),
            placeholder.topAnchor.constraint(equalTo: textView.topAnchor, constant: 2),

            // Tie table bottom to the bar top
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor)
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

    // MARK: - Nav handling (Chat-only)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let nav = navigationController {
            // snapshot previous state so we can restore when leaving chat
            previousNavBarHidden = nav.isNavigationBarHidden
            previousTranslucent  = nav.navigationBar.isTranslucent
            previousBgImage      = nav.navigationBar.backgroundImage(for: .default)
            previousShadowImage  = nav.navigationBar.shadowImage

            // show the bar so back control can exist, but keep it visually transparent
            nav.setNavigationBarHidden(false, animated: animated)
            applyTransparentNavBarForChat()
            nav.interactivePopGestureRecognizer?.isEnabled = true
        }

        navigationItem.hidesBackButton = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupBackButton() // keep your logic; we just ensure a fallback below
        // Fallback: if pushed and system back didn't render, add one.
        if navigationItem.leftBarButtonItem == nil,
           navigationController?.viewControllers.first != self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "chevron.backward"),
                style: .plain,
                target: self,
                action: #selector(forceBack)
            )
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // restore nav bar visibility and visuals so other VCs aren't affected
        navigationController?.setNavigationBarHidden(previousNavBarHidden, animated: animated)
        restoreNavBarAppearance()
    }

    // Make the nav bar fully transparent while Chat is visible (no black header)
    private func applyTransparentNavBarForChat() {
        if #available(iOS 15.0, *) {
            let clear = UINavigationBarAppearance()
            clear.configureWithTransparentBackground()
            clear.backgroundColor = .clear
            clear.shadowColor = .clear

            navigationItem.standardAppearance   = clear
            navigationItem.scrollEdgeAppearance = clear
            navigationItem.compactAppearance    = clear
        } else {
            guard let navBar = navigationController?.navigationBar else { return }
            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.shadowImage = UIImage()
            navBar.isTranslucent = true
            navBar.backgroundColor = .clear
        }
        // keep your layout under the clear bar so your custom header remains unchanged
        edgesForExtendedLayout = [.top, .left, .right, .bottom]
    }

    private func restoreNavBarAppearance() {
        if #available(iOS 15.0, *) {
            navigationItem.standardAppearance   = nil
            navigationItem.scrollEdgeAppearance = nil
            navigationItem.compactAppearance    = nil
        } else {
            guard let navBar = navigationController?.navigationBar else { return }
            navBar.setBackgroundImage(previousBgImage, for: .default)
            navBar.shadowImage = previousShadowImage
            navBar.isTranslucent = previousTranslucent
            navBar.backgroundColor = nil
        }
    }

    @objc private func forceBack() {
        navigationController?.popViewController(animated: true)
    }

    // Back/close handling (your method kept)
    private func setupBackButton() {
        let isRootOfPresentedNav =
        (navigationController?.viewControllers.first == self) && (presentingViewController != nil)

        if isRootOfPresentedNav {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                systemItem: .close,
                primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
            )
        } else {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}

extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholder.isHidden = !textView.text.isEmpty
    }
}
