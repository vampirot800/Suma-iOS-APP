//
//  EditProfileViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 23/10/25.
//

import UIKit
import FirebaseFirestore

final class EditProfileViewController: UIViewController {

    // Prefill model (from Firestore)
    var prefill: AppUser?
    weak var delegate: EditProfileViewControllerDelegate?

    // UI
    private let nameField = UITextField()
    private let roleSegment = UISegmentedControl(items: ["media creator", "enterprise"])
    private let bioView = UITextView()
    private let tagsField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        view.backgroundColor = .systemBackground
        setupNav()
        buildForm()
        applyPrefill()
    }

    private func setupNav() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                           target: self,
                                                           action: #selector(closeTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                            target: self,
                                                            action: #selector(saveTapped))
    }

    private func buildForm() {
        nameField.placeholder = "Display name"
        nameField.borderStyle = .roundedRect

        tagsField.placeholder = "Tags (comma separated)"
        tagsField.borderStyle = .roundedRect
        tagsField.autocapitalizationType = .none

        bioView.isScrollEnabled = false
        bioView.font = UIFont.preferredFont(forTextStyle: .body)
        bioView.backgroundColor = .secondarySystemBackground
        bioView.layer.cornerRadius = 8
        bioView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)

        let labels = [
            makeCaption("Name"),
            nameField,
            makeCaption("Role"),
            roleSegment,
            makeCaption("Bio"),
            bioView,
            makeCaption("Tags"),
            tagsField
        ]

        let stack = UIStackView(arrangedSubviews: labels)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }

    private func makeCaption(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.preferredFont(forTextStyle: .caption1)
        l.textColor = .secondaryLabel
        return l
    }

    private func applyPrefill() {
        guard let u = prefill else { return }
        nameField.text = u.displayName
        roleSegment.selectedSegmentIndex = (u.role == "enterprise") ? 1 : 0
        bioView.text = u.bio
        tagsField.text = u.searchable.joined(separator: ", ")
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard let uid = AuthService.shared.currentUserId else { return }

        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let role = (roleSegment.selectedSegmentIndex == 1) ? "enterprise" : "media creator"
        let bio  = bioView.text ?? ""
        let tags = tagsField.text?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() } ?? []

        // Merge into users/{uid}
        let fs = FirebaseService.shared
        let update: [String: Any] = [
            "displayName": name.isEmpty ? (prefill?.displayName ?? "New User") : name,
            "role": role,
            "bio": bio,
            "searchable": tags
        ]

        navigationItem.rightBarButtonItem?.isEnabled = false

        Task {
            do {
                try await fs.users.document(uid).setData(update, merge: true)
                await MainActor.run {
                    self.delegate?.editProfileDidSave()
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    let ac = UIAlertController(title: "Save failed",
                                               message: error.localizedDescription,
                                               preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            }
        }
    }
}
