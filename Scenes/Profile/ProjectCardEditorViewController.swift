//
//  ProjectCardEditorViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 10/11/25.
//
//  Description:
//  Editor for a single portfolio "project card". Supports creating a new entry
//  or editing an existing one. Persists data in Firestore under
//  users/{uid}/portfolios/{projectId}.
//


import UIKit
import FirebaseAuth
import FirebaseFirestore

/// Modal editor for a portfolio project card (title, role, dates, description, skills).
final class ProjectCardEditorViewController: UIViewController {

    // MARK: - Callbacks

    /// Invoked after a successful save, so caller can refresh lists.
    var onSave: (() -> Void)?

    // MARK: - Editing State

    /// Non-nil when editing an existing project.
    private var existing: PortfolioItem?

    // MARK: - UI

    private let scroll = UIScrollView()
    private let stack  = UIStackView()

    private let titleField = field("Project title")
    private let roleField  = field("Your role")

    private let descView: UITextView = {
        let v = UITextView()
        v.font = .systemFont(ofSize: 16)
        v.layer.cornerRadius = 12
        v.backgroundColor = UIColor(named: "BrandSecondary") ?? .secondarySystemGroupedBackground
        v.heightAnchor.constraint(equalToConstant: 140).isActive = true
        v.textContainerInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        return v
    }()

    private let startPicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .date
        p.preferredDatePickerStyle = .compact
        return p
    }()

    private let endPicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .date
        p.preferredDatePickerStyle = .compact
        return p
    }()

    private let skillsField = field("Skills (comma-separated)")

    private let saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Save Project", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(named: "Header") ?? .systemGreen
        b.layer.cornerRadius = 16
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return b
    }()

    // MARK: - Firebase

    private let db = Firestore.firestore()
    private var uid: String? { Auth.auth().currentUser?.uid }

    // MARK: - Initializers

    /// Convenience init to open the editor pre-populated with an existing item.
    convenience init(itemToEdit: PortfolioItem) {
        self.init()
        self.existing = itemToEdit
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = existing == nil ? "New Project" : "Edit Project"
        view.backgroundColor = UIColor(named: "Background2") ?? .systemGroupedBackground
        navigationItem.leftBarButtonItem = .init(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(close)
        )

        buildUI()

        if let e = existing {
            populate(from: e)
        }

        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
    }

    // MARK: - UI Construction

    /// Builds and lays out the editor UI.
    private func buildUI() {
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stack.axis = .vertical
        stack.spacing = 14
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 24, right: 20)
        scroll.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])

        // Fields
        stack.addArrangedSubview(label("Title"))
        stack.addArrangedSubview(titleField)

        stack.addArrangedSubview(label("Role"))
        stack.addArrangedSubview(roleField)

        stack.addArrangedSubview(label("Description"))
        stack.addArrangedSubview(descView)

        // Dates row
        let row = UIStackView(arrangedSubviews: [
            label("From"), startPicker,
            UIView(), // flexible spacer
            label("To"), endPicker
        ])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        stack.addArrangedSubview(row)

        // Skills
        stack.addArrangedSubview(label("Skills"))
        stack.addArrangedSubview(skillsField)

        // Save button
        stack.addArrangedSubview(saveButton)
    }

    /// Populates fields from an existing `PortfolioItem`.
    private func populate(from item: PortfolioItem) {
        titleField.text = item.title
        roleField.text  = item.role
        descView.text   = item.description
        if let s = item.startDate { startPicker.date = s }
        if let e = item.endDate { endPicker.date = e }
        if !item.skills.isEmpty { skillsField.text = item.skills.joined(separator: ", ") }
    }

    // MARK: - Actions

    /// Dismisses the editor without saving.
    @objc private func close() { dismiss(animated: true) }

    /// Validates, then saves the project to Firestore using incremental merges.
    @objc private func save() {
        guard let uid = Auth.auth().currentUser?.uid else {
            presentError(title: "Not signed in", message: "No authenticated user.")
            return
        }

        // Prepare values
        let title = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let role  = (roleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let desc  = (descView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        // Ensure [String] (not [Substring])
        let skills: [String] = (skillsField.text ?? "")
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let mediaURLs: [String] = [] // explicit empty array of String

        let startTs = Timestamp(date: startPicker.date)
        let endTs   = Timestamp(date: endPicker.date)
        let created = Timestamp(date: Date())

        let colRef = db.collection("users").document(uid).collection("portfolios")
        let docRef: DocumentReference = {
            if let existingId = existing?.id {
                return colRef.document(existingId)
            } else {
                return colRef.document()
            }
        }()

        print("🔥 [STEP] Target doc:", docRef.path)
        print("🔥 [STEP] UID:", uid)

        Task {
            /// Helper that merges a single patch and reports rule failures precisely.
            func tryMerge(_ patch: [String: Any], label: String) async -> Bool {
                print("🔥 [STEP] TRY:", label, "| PATCH:", patch.map { "\($0.key):\(type(of: $0.value))" }.joined(separator: ", "))
                do {
                    try await docRef.setData(patch, merge: true)
                    print("✅ [STEP] OK:", label)
                    return true
                } catch {
                    let err = error as NSError
                    print("❌ [STEP] FAIL:", label, "|", err.domain, err.code, err.userInfo)
                    await MainActor.run {
                        self.presentError(
                            title: "Blocked at: \(label)",
                            message: "Rule rejected this field.\n\(err.domain) \(err.code)\n\(err.localizedDescription)"
                        )
                    }
                    return false
                }
            }

            // 1) Ensure the doc exists with a title
            if !(await tryMerge(["title": title.isEmpty ? "Untitled" : title], label: "title")) { return }

            // 2) Add remaining fields one by one (easier to diagnose rule failures)
            if !(await tryMerge(["role": role], label: "role")) { return }
            if !(await tryMerge(["description": desc], label: "description")) { return }
            if !(await tryMerge(["skills": skills], label: "skills (Array<String>)")) { return }
            if !(await tryMerge(["mediaURLs": mediaURLs], label: "mediaURLs (Array<String>)")) { return }
            if !(await tryMerge(["startDate": startTs], label: "startDate (Timestamp)")) { return }
            if !(await tryMerge(["endDate": endTs], label: "endDate (Timestamp)")) { return }
            if !(await tryMerge(["createdAt": created], label: "createdAt (Timestamp)")) { return }

            // Success
            await MainActor.run {
                self.onSave?()
                self.dismiss(animated: true)
            }
        }
    }

    // MARK: - Debug / Alerts

    /// Prints a key/value dump with types — useful for diagnosing rule failures.
    private func debugDumpPayload(_ dict: [String: Any]) {
        print("🔥 [PORTFOLIO] PAYLOAD DUMP:")
        dict.forEach { k, v in print("   -", k, "=", v, "| TYPE:", type(of: v)) }
    }

    /// Presents a simple alert with title and message.
    private func presentError(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(.init(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

// MARK: - UI Helpers (unchanged)

/// Creates a styled text field with padding and rounded corners.
private func field(_ ph: String) -> UITextField {
    let tf = UITextField()
    tf.placeholder = ph
    tf.backgroundColor = UIColor(named: "BrandSecondary") ?? .secondarySystemGroupedBackground
    tf.layer.cornerRadius = 12
    tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
    tf.leftViewMode = .always
    tf.heightAnchor.constraint(equalToConstant: 48).isActive = true
    return tf
}

/// Creates a small, semibold secondary label used as a field title.
private func label(_ text: String) -> UILabel {
    let l = UILabel()
    l.text = text
    l.textColor = .secondaryLabel
    l.font = .systemFont(ofSize: 15, weight: .semibold)
    return l
}
