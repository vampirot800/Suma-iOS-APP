//
//  EditProfileViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 23/10/25.
//
//

import UIKit
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

protocol ProfileEditingDelegate: AnyObject {
    func editProfileViewControllerDidSave()
}

final class EditProfileViewController: UIViewController {

    // MARK: - Theme (colors pulled from Assets; keep your palette)
    struct AppColors {
        static let surface = UIColor(named: "Background2") ?? UIColor.systemGroupedBackground
        static let header  = UIColor(named: "Header") ?? UIColor.systemGreen
        static let fieldBG = UIColor(named: "BrandSecondary") ?? UIColor.secondarySystemGroupedBackground
        static let text    = UIColor.label
        static let pill    = UIColor.white
    }

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let content = UIStackView()

    private let avatarButton: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = AppColors.fieldBG
        b.clipsToBounds = true
        b.layer.cornerRadius = 48
        b.widthAnchor.constraint(equalToConstant: 96).isActive = true
        b.heightAnchor.constraint(equalToConstant: 96).isActive = true
        b.imageView?.contentMode = .scaleAspectFill
        b.setImage(UIImage(systemName: "person.crop.circle"), for: .normal)
        b.tintColor = .systemGray3
        return b
    }()
    private let cameraBadge: UIImageView = {
        let i = UIImageView(image: UIImage(systemName: "camera.fill"))
        i.tintColor = .white
        i.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        i.layer.cornerRadius = 12
        i.clipsToBounds = true
        i.translatesAutoresizingMaskIntoConstraints = false
        i.widthAnchor.constraint(equalToConstant: 24).isActive = true
        i.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return i
    }()

    private let nameField = UITextField()
    private let roleField = UITextField()
    private let locationField = UITextField()
    private let websiteField = UITextField()
    private let bioView = UITextView()

    private let saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Save", for: .normal)
        b.setTitleColor(AppColors.pill, for: .normal)
        b.backgroundColor = AppColors.header
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.layer.cornerRadius = 16
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        b.isEnabled = false
        b.alpha = 0.5
        return b
    }()

    // MARK: - Data
    weak var delegate: ProfileEditingDelegate?
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var selectedAvatar: UIImage? { didSet { updateSaveAvailability() } }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.surface
        title = "Edit Profile"
        configureForm()
        loadCurrentValues()
    }

    // MARK: - UI building
    private func configureForm() {
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        content.axis = .vertical
        content.spacing = 16
        content.layoutMargins = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)
        content.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        // Avatar row + badge
        let avatarRow = UIView()
        avatarRow.translatesAutoresizingMaskIntoConstraints = false
        avatarRow.heightAnchor.constraint(equalToConstant: 96).isActive = true
        avatarRow.addSubview(avatarButton)
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarButton.leadingAnchor.constraint(equalTo: avatarRow.leadingAnchor),
            avatarButton.centerYAnchor.constraint(equalTo: avatarRow.centerYAnchor)
        ])
        avatarButton.addTarget(self, action: #selector(avatarTapped), for: .touchUpInside)

        avatarButton.addSubview(cameraBadge)
        NSLayoutConstraint.activate([
            cameraBadge.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: -4),
            cameraBadge.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor, constant: -4)
        ])

        content.addArrangedSubview(avatarRow)

        // Fields
        configureTextField(nameField, title: "Display Name", placeholder: "Your name")
        configureTextField(roleField, title: "Role", placeholder: "media creator")
        configureTextField(locationField, title: "Location", placeholder: "City, Country")
        configureTextField(websiteField, title: "Website", placeholder: "https://example.com")

        // Bio
        content.addArrangedSubview(label("Bio", weight: .semibold))
        bioView.backgroundColor = AppColors.fieldBG
        bioView.textColor = AppColors.text
        bioView.font = .systemFont(ofSize: 16)
        bioView.layer.cornerRadius = 12
        bioView.textContainerInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        bioView.heightAnchor.constraint(equalToConstant: 160).isActive = true
        bioView.delegate = self
        content.addArrangedSubview(bioView)

        // Save
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        content.addArrangedSubview(saveButton)

        [nameField, roleField, locationField, websiteField].forEach {
            $0.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        }
    }

    private func configureTextField(_ tf: UITextField, title: String, placeholder: String) {
        content.addArrangedSubview(label(title, weight: .semibold))
        tf.backgroundColor = AppColors.fieldBG
        tf.textColor = AppColors.text
        tf.font = .systemFont(ofSize: 16)
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.leftViewMode = .always
        tf.heightAnchor.constraint(equalToConstant: 48).isActive = true
        tf.placeholder = placeholder
        content.addArrangedSubview(tf)
    }

    private func label(_ text: String, weight: UIFont.Weight) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 15, weight: weight)
        l.textColor = .secondaryLabel
        return l
    }

    // MARK: - Load existing values
    private func loadCurrentValues() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task {
            do {
                let snap = try await db.collection("users").document(uid).getDocument()
                guard let data = snap.data() else { return }
                nameField.text     = data["displayName"] as? String
                roleField.text     = data["role"] as? String
                locationField.text = data["location"] as? String
                websiteField.text  = data["website"] as? String
                bioView.text       = data["bio"] as? String

                if let s = data["photoURL"] as? String, let url = URL(string: s) {
                    let (d, _) = try await URLSession.shared.data(from: url)
                    if let img = UIImage(data: d) {
                        avatarButton.setImage(img, for: .normal)
                    }
                }
            } catch {
                print("Failed to load profile: \(error)")
            }
        }
    }

    // MARK: - Actions
    @objc private func textChanged() { updateSaveAvailability() }

    private func updateSaveAvailability() {
        let changed =
            !(nameField.text ?? "").isEmpty ||
            !(roleField.text ?? "").isEmpty ||
            !(locationField.text ?? "").isEmpty ||
            !(websiteField.text ?? "").isEmpty ||
            !(bioView.text ?? "").isEmpty ||
            selectedAvatar != nil

        saveButton.isEnabled = changed
        saveButton.alpha = changed ? 1.0 : 0.5
    }

    @objc private func avatarTapped() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func saveTapped() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let name     = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let role     = roleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let location = locationField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let website  = websiteField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bio      = bioView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        Task {
            view.isUserInteractionEnabled = false
            defer { view.isUserInteractionEnabled = true }

            var payload: [String: Any] = [
                "displayName": name,
                "role": role,
                "location": location,
                "website": website,
                "bio": bio
            ]

            // Upload avatar if changed
            var uploadedURL: URL?
            if let image = selectedAvatar, let data = image.jpegData(compressionQuality: 0.88) {
                let ref = storage.reference().child("avatars/\(uid).jpg")
                let meta = StorageMetadata()
                meta.contentType = "image/jpeg"
                _ = try? await ref.putDataAsync(data, metadata: meta)
                uploadedURL = try? await ref.downloadURL()
                if let u = uploadedURL { payload["photoURL"] = u.absoluteString }
            }

            do {
                try await db.collection("users").document(uid).setData(payload, merge: true)

                // Keep FirebaseAuth profile photo in sync
                if let u = uploadedURL {
                    try await AuthService.shared.setUserPhotoURL(u)
                }

                delegate?.editProfileViewControllerDidSave()
                dismiss(animated: true)
            } catch {
                presentError("Couldn’t save profile", error.localizedDescription)
            }
        }
    }

    // MARK: - Helpers
    private func presentError(_ title: String, _ message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

// MARK: - PHPicker
extension EditProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self, let img = object as? UIImage else { return }
            DispatchQueue.main.async {
                self.selectedAvatar = img
                self.avatarButton.setImage(img, for: .normal)
            }
        }
    }
}

// MARK: - UITextViewDelegate
extension EditProfileViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) { updateSaveAvailability() }
}
