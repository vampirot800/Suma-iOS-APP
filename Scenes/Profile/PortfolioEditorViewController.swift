//
//  PortfolioEditorViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 10/11/25.
//


import UIKit
import UniformTypeIdentifiers
import SafariServices
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class PortfolioEditorViewController: UIViewController {

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Set up your Portfolio!"
        l.font = .systemFont(ofSize: 22, weight: .bold)
        return l
    }()

    private let howButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("How does it work?", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(named: "Header") ?? .systemGreen
        b.layer.cornerRadius = 16
        b.heightAnchor.constraint(equalToConstant: 46).isActive = true
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return b
    }()

    // Help bubble (tinted card)
    private let helpCard: UIView = {
        let v = UIView()
        let base = UIColor(named: "Header") ?? .systemGreen
        v.backgroundColor = base.withAlphaComponent(0.12)
        v.layer.cornerRadius = 14
        v.layer.masksToBounds = true
        v.isHidden = true
        return v
    }()
    private let helpLabel: UILabel = {
        let l = UILabel()
        l.text = "Add short cards describing past work: a title, your role, time period and a brief description. You can also upload your CV (PDF). These will appear on your profile."
        l.font = .systemFont(ofSize: 14)
        l.textColor = .label
        l.numberOfLines = 0
        return l
    }()

    private let cvTitle = labeled("Include your CV")

    // We'll compute fills once so we can invert them reliably
    private lazy var lightFill: UIColor = {
        UIColor(named: "BrandSecondary") ?? UIColor(white: 0.92, alpha: 1.0)
    }()
    private lazy var darkFill: UIColor = {
        // If Surface is not set or is light, fall back to Header
        UIColor(named: "Surface") ?? (UIColor(named: "Header") ?? .systemGreen)
    }()

    // UPLOAD (now the darker style, white text)
    private lazy var uploadCVButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Upload file", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = darkFill
        b.layer.cornerRadius = 16
        b.heightAnchor.constraint(equalToConstant: 52).isActive = true
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return b
    }()

    // VIEW CV (now the lighter style, black text)
    private lazy var viewCVButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("View CV", for: .normal)
        b.setTitleColor(.label, for: .normal) // readable on light background
        b.backgroundColor = lightFill
        b.layer.cornerRadius = 12
        b.heightAnchor.constraint(equalToConstant: 42).isActive = true
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        b.isEnabled = false
        b.alpha = 0.6
        return b
    }()

    private let cardsTitle = labeled("Add experience cards")

    private let addCardButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Click to add new cards", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(named: "Header") ?? .systemGreen
        b.layer.cornerRadius = 16
        b.heightAnchor.constraint(equalToConstant: 56).isActive = true
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return b
    }()

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Save", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(named: "Header") ?? .systemGreen
        b.layer.cornerRadius = 18
        b.heightAnchor.constraint(equalToConstant: 50).isActive = true
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        return b
    }()

    // 👇 Single reusable height constraint we will update
    private var tableHeightConstraint: NSLayoutConstraint?

    // MARK: - Data
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var items: [PortfolioItem] = [] { didSet { tableView.reloadData(); DispatchQueue.main.async { self.updateTableHeight() } } }
    private var currentCVURL: URL?

    // MARK: - Life
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Portfolios"
        view.backgroundColor = UIColor(named: "Background2") ?? .systemGroupedBackground

        navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .close, target: self, action: #selector(close))
        buildUI()
        bindActions()
        Task { await loadCurrentCV(); await fetchProjects() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeight()
    }

    // MARK: - UI
    private func buildUI() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stack.axis = .vertical
        stack.spacing = 16
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = .init(top: 24, left: 20, bottom: 24, right: 20)
        scrollView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        // Top
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(howButton)

        helpCard.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        helpCard.addSubview(helpLabel)
        NSLayoutConstraint.activate([
            helpLabel.leadingAnchor.constraint(equalTo: helpCard.leadingAnchor, constant: 12),
            helpLabel.trailingAnchor.constraint(equalTo: helpCard.trailingAnchor, constant: -12),
            helpLabel.topAnchor.constraint(equalTo: helpCard.topAnchor, constant: 12),
            helpLabel.bottomAnchor.constraint(equalTo: helpCard.bottomAnchor, constant: -12)
        ])
        stack.addArrangedSubview(helpCard)

        // CV
        stack.addArrangedSubview(cvTitle)
        stack.addArrangedSubview(uploadCVButton)
        stack.addArrangedSubview(viewCVButton)

        // Cards
        stack.addArrangedSubview(cardsTitle)
        stack.addArrangedSubview(addCardButton)

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.layer.cornerRadius = 16

        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = false
        stack.addArrangedSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        // 👇 Keep a single height constraint (updated later)
        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 80)
        tableHeightConstraint?.isActive = true

        // Save
        stack.addArrangedSubview(saveButton)
    }

    private static func labeled(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.textColor = .secondaryLabel
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        return l
    }
}

// MARK: - Actions
private extension PortfolioEditorViewController {
    func bindActions() {
        howButton.addTarget(self, action: #selector(toggleHelp), for: .touchUpInside)
        uploadCVButton.addTarget(self, action: #selector(uploadCV), for: .touchUpInside)
        viewCVButton.addTarget(self, action: #selector(openCV), for: .touchUpInside)
        addCardButton.addTarget(self, action: #selector(addCard), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(close), for: .touchUpInside)
    }

    @objc func toggleHelp() {
        UIView.transition(with: helpCard, duration: 0.25, options: .transitionCrossDissolve) {
            self.helpCard.isHidden.toggle()
        }
    }

    @objc func close() { dismiss(animated: true) }

    @objc func uploadCV() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf], asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc func openCV() {
        guard let url = currentCVURL else { return }
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }

    @objc func addCard() {
        let vc = ProjectCardEditorViewController()
        vc.onSave = { [weak self] in Task { await self?.fetchProjects() } }
        present(UINavigationController(rootViewController: vc), animated: true)
    }
}

// MARK: - Data
private extension PortfolioEditorViewController {
    var uid: String? { Auth.auth().currentUser?.uid }

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
                // 👇 Do NOT create a new constraint; just update the existing one
                self.updateTableHeight()
            }
        } catch {
            print("fetchProjects error: \(error)")
        }
    }

    func loadCurrentCV() async {
        guard let uid else { return }
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            if let urlStr = doc.data()?["cvURL"] as? String, let url = URL(string: urlStr), !urlStr.isEmpty {
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
        } catch { }
    }

    func uploadCVData(_ data: Data) async {
        guard let uid else { return }
        let ref = storage.reference().child("userFiles/\(uid)/cv.pdf")
        let meta = StorageMetadata(); meta.contentType = "application/pdf"

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
            await MainActor.run {
                self.viewCVButton.isEnabled = false
                self.viewCVButton.alpha = 0.6
            }
        }
    }

    func deleteProject(at indexPath: IndexPath) async {
        guard let uid, let id = items[indexPath.row].id else { return }
        do {
            try await db.collection("users").document(uid)
                .collection("portfolios").document(id).delete()
            await fetchProjects()
        } catch {
            print("deleteProject error: \(error)")
        }
    }

    // 👇 Centralized updater for the single height constraint
    func updateTableHeight() {
        tableView.layoutIfNeeded()
        let target = max(80, tableView.contentSize.height)
        if tableHeightConstraint?.constant != target {
            tableHeightConstraint?.constant = target
            view.layoutIfNeeded()
        }
    }
}

// MARK: - Table
extension PortfolioEditorViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.backgroundColor = UIColor(named: "Header") ?? .systemGreen

        cell.contentView.layer.cornerRadius = 12
        cell.contentView.layer.masksToBounds = true

        var cfg = UIListContentConfiguration.subtitleCell()
        cfg.text = item.title.isEmpty ? "Untitled Project" : item.title
        let formatter = DateFormatter(); formatter.dateFormat = "MMM yyyy"
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
        let del = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _,_,done in
            Task { await self?.deleteProject(at: indexPath); done(true) }
        }
        return .init(actions: [del])
    }
}

// MARK: - Document picker
extension PortfolioEditorViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        do { let data = try Data(contentsOf: url); Task { await uploadCVData(data) } }
        catch { }
    }
}

// Helper
private func labeled(_ text: String) -> UILabel {
    let l = UILabel()
    l.text = text
    l.textColor = .secondaryLabel
    l.font = .systemFont(ofSize: 15, weight: .semibold)
    return l
}
