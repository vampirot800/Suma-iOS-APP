//
//  PortfolioEditorViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 10/11/25.
//
//  Description:
//  Allows users to manage their portfolio by adding, editing, or deleting
//  project cards and uploading their CV. This view controller integrates
//  with Firebase Firestore and Storage to persist user data.
//

import UIKit
import UniformTypeIdentifiers
import SafariServices
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - PortfolioEditorViewController

final class PortfolioEditorViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Set up your Portfolio!"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        return label
    }()

    private let howButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("How does it work?", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(named: "Header") ?? .systemGreen
        button.layer.cornerRadius = 16
        button.heightAnchor.constraint(equalToConstant: 46).isActive = true
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()

    // MARK: Help bubble
    private let helpCard: UIView = {
        let view = UIView()
        let base = UIColor(named: "Header") ?? .systemGreen
        view.backgroundColor = base.withAlphaComponent(0.12)
        view.layer.cornerRadius = 14
        view.isHidden = true
        return view
    }()

    private let helpLabel: UILabel = {
        let label = UILabel()
        label.text = """
        Add short cards describing past work: a title, your role, time period and a brief description.
        You can also upload your CV (PDF). These will appear on your profile.
        """
        label.font = .systemFont(ofSize: 14)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    private let cvTitle = labeled("Include your CV")

    // MARK: Color definitions
    private lazy var lightFill: UIColor = {
        UIColor(named: "BrandSecondary") ?? UIColor(white: 0.92, alpha: 1.0)
    }()
    private lazy var darkFill: UIColor = {
        UIColor(named: "Surface") ?? (UIColor(named: "Header") ?? .systemGreen)
    }()

    // MARK: CV Buttons
    private lazy var uploadCVButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Upload file", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = darkFill
        button.layer.cornerRadius = 16
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return button
    }()

    private lazy var viewCVButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View CV", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = darkFill
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 42).isActive = true
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.isEnabled = false
        button.alpha = 0.6
        return button
    }()

    private let cardsTitle = labeled("Add experience cards")

    private let addCardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Click to add new cards", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(named: "Header") ?? .systemGreen
        button.layer.cornerRadius = 16
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return button
    }()

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(named: "Header") ?? .systemGreen
        button.layer.cornerRadius = 18
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        return button
    }()

    // MARK: - Constraints
    private var tableHeightConstraint: NSLayoutConstraint?

    // MARK: - Data
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var items: [PortfolioItem] = [] {
        didSet {
            tableView.reloadData()
            DispatchQueue.main.async { self.updateTableHeight() }
        }
    }
    private var currentCVURL: URL?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Portfolios"
        view.backgroundColor = UIColor(named: "Background2") ?? .systemGroupedBackground

        navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .close,
                                                 target: self,
                                                 action: #selector(close))

        buildUI()
        bindActions()

        // Load user data
        Task {
            await loadCurrentCV()
            await fetchProjects()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeight()
    }

    // MARK: - UI Setup
    private func buildUI() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Main stack
        stack.axis = .vertical
        stack.spacing = 16
        stack.layoutMargins = .init(top: 24, left: 20, bottom: 24, right: 20)
        stack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        // Top section
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(howButton)

        // Help card
        helpCard.addSubview(helpLabel)
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            helpLabel.leadingAnchor.constraint(equalTo: helpCard.leadingAnchor, constant: 12),
            helpLabel.trailingAnchor.constraint(equalTo: helpCard.trailingAnchor, constant: -12),
            helpLabel.topAnchor.constraint(equalTo: helpCard.topAnchor, constant: 12),
            helpLabel.bottomAnchor.constraint(equalTo: helpCard.bottomAnchor, constant: -12)
        ])
        stack.addArrangedSubview(helpCard)

        // CV section
        stack.addArrangedSubview(cvTitle)
        stack.addArrangedSubview(uploadCVButton)
        stack.addArrangedSubview(viewCVButton)

        // Portfolio cards
        stack.addArrangedSubview(cardsTitle)
        stack.addArrangedSubview(addCardButton)

        // TableView
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isScrollEnabled = false
        tableView.layer.cornerRadius = 16
        tableView.backgroundColor = .clear
        stack.addArrangedSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 80)
        tableHeightConstraint?.isActive = true

        // Save button
        stack.addArrangedSubview(saveButton)
    }
}

// MARK: - User Interaction
private extension PortfolioEditorViewController {

    func bindActions() {
        howButton.addTarget(self, action: #selector(toggleHelp), for: .touchUpInside)
        uploadCVButton.addTarget(self, action: #selector(uploadCV), for: .touchUpInside)
        viewCVButton.addTarget(self, action: #selector(openCV), for: .touchUpInside)
        addCardButton.addTarget(self, action: #selector(addCard), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(close), for: .touchUpInside)
    }

    /// Toggles the visibility of the help information card.
    @objc func toggleHelp() {
        UIView.transition(with: helpCard, duration: 0.25, options: .transitionCrossDissolve) {
            self.helpCard.isHidden.toggle()
        }
    }

    /// Closes the editor.
    @objc func close() { dismiss(animated: true) }

    /// Opens a document picker to upload a CV file.
    @objc func uploadCV() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf], asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }

    /// Opens the currently uploaded CV in a Safari view.
    @objc func openCV() {
        guard let url = currentCVURL else { return }
        present(SFSafariViewController(url: url), animated: true)
    }

    /// Opens the project card editor to add a new portfolio entry.
    @objc func addCard() {
        let vc = ProjectCardEditorViewController()
        vc.onSave = { [weak self] in Task { await self?.fetchProjects() } }
        present(UINavigationController(rootViewController: vc), animated: true)
    }
}

// MARK: - Firebase & Data Handling
private extension PortfolioEditorViewController {

    var uid: String? { Auth.auth().currentUser?.uid }

    /// Fetches all stored portfolio items from Firestore.
    func fetchProjects() async {
        guard let uid else { return }
        do {
            let snap = try await db.collection("users").document(uid)
                .collection("portfolios")
                .order(by: "createdAt", descending: true)
                .getDocuments()

            let parsed = snap.documents.compactMap { PortfolioItem(doc: $0) }
            await MainActor.run {
                self.items = parsed
                self.updateTableHeight()
            }
        } catch {
            print("❌ fetchProjects error: \(error)")
        }
    }

    /// Loads the user's CV link from Firestore, enabling the View CV button if available.
    func loadCurrentCV() async {
        guard let uid else { return }
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            if let urlStr = doc.data()?["cvURL"] as? String,
               let url = URL(string: urlStr),
               !urlStr.isEmpty {
                self.currentCVURL = url
                await MainActor.run {
                    self.viewCVButton.isEnabled = true
                    self.viewCVButton.alpha = 1.0
                }
            } else {
                await MainActor.run {
                    self.viewCVButton.isEnabled = false
                    self.viewCVButton.alpha = 0.6
                }
            }
        } catch {
            print("❌ loadCurrentCV error: \(error)")
        }
    }

    /// Uploads CV data to Firebase Storage and saves its reference in Firestore.
    func uploadCVData(_ data: Data) async {
        guard let uid else { return }
        let ref = storage.reference().child("userFiles/\(uid)/cv.pdf")
        let meta = StorageMetadata()
        meta.contentType = "application/pdf"

        do {
            _ = try await ref.putDataAsync(data, metadata: meta)
            let url = try await ref.downloadURL()
            try await db.collection("users").document(uid)
                .setData(["cvURL": url.absoluteString], merge: true)

            self.currentCVURL = url
            await MainActor.run {
                self.viewCVButton.isEnabled = true
                self.viewCVButton.alpha = 1.0
            }
        } catch {
            print("❌ uploadCVData error: \(error)")
            await MainActor.run {
                self.viewCVButton.isEnabled = false
                self.viewCVButton.alpha = 0.6
            }
        }
    }

    /// Deletes a project card from Firestore.
    func deleteProject(at indexPath: IndexPath) async {
        guard let uid, let id = items[indexPath.row].id else { return }
        do {
            try await db.collection("users").document(uid)
                .collection("portfolios").document(id).delete()
            await fetchProjects()
        } catch {
            print("❌ deleteProject error: \(error)")
        }
    }

    /// Updates the table view height dynamically based on content size.
    func updateTableHeight() {
        tableView.layoutIfNeeded()
        let target = max(80, tableView.contentSize.height)
        if tableHeightConstraint?.constant != target {
            tableHeightConstraint?.constant = target
            view.layoutIfNeeded()
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension PortfolioEditorViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.backgroundColor = UIColor(named: "Header") ?? .systemGreen
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.layer.masksToBounds = true

        var cfg = UIListContentConfiguration.subtitleCell()
        cfg.text = item.title.isEmpty ? "Untitled Project" : item.title

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        let dateText: String = {
            guard let s = item.startDate, let e = item.endDate else { return "" }
            return "\(formatter.string(from: s)) – \(formatter.string(from: e))"
        }()

        cfg.secondaryText = [item.role, dateText].filter { !$0.isEmpty }.joined(separator: " · ")
        cfg.textProperties.color = .white
        cfg.secondaryTextProperties.color = UIColor(white: 1.0, alpha: 0.85)
        cell.contentConfiguration = cfg
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        let vc = ProjectCardEditorViewController(itemToEdit: item)
        vc.onSave = { [weak self] in Task { await self?.fetchProjects() } }
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            Task { await self?.deleteProject(at: indexPath); done(true) }
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - UIDocumentPickerDelegate
extension PortfolioEditorViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        do {
            let data = try Data(contentsOf: url)
            Task { await uploadCVData(data) }
        } catch {
            print("❌ documentPicker error: \(error)")
        }
    }
}

// MARK: - Helper
private func labeled(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.textColor = .secondaryLabel
    label.font = .systemFont(ofSize: 15, weight: .semibold)
    return label
}
