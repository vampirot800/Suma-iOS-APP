//
//  ProfileViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import UIKit
import PhotosUI
import FirebaseAuth
import FirebaseStorage
internal import FirebaseFirestoreInternal

protocol EditProfileViewControllerDelegate: AnyObject {
    func editProfileDidSave()
}

final class ProfileViewController: ScrollingStackViewController, EditProfileViewControllerDelegate {

    private let header = ProfileHeaderView()
    private let aboutTitle = UILabel()
    private let aboutBody = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        buildUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProfile()
    }

    // MARK: - UI
    private func buildUI() {
        header.onEditTapped = { [weak self] in self?.presentEditProfile() }
        header.onAvatarTapped = { [weak self] in self?.pickNewAvatar() }
        stackView.addArrangedSubview(header)

        aboutTitle.text = "About"
        aboutTitle.font = UIFont.preferredFont(forTextStyle: .headline)
        aboutBody.text = "Short bio / description goes here."
        aboutBody.numberOfLines = 0
        aboutBody.font = UIFont.preferredFont(forTextStyle: .body)

        let aboutStack = UIStackView(arrangedSubviews: [aboutTitle, aboutBody])
        aboutStack.axis = .vertical
        aboutStack.spacing = 8
        stackView.addArrangedSubview(aboutStack)

        stackView.addArrangedSubview(makePlaceholder(height: 300, title: "Sumas / Achievements"))
    }

    private func makePlaceholder(height: CGFloat, title: String) -> UIView {
        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.textColor = .secondaryLabel

        let box = UIView()
        box.backgroundColor = .secondarySystemBackground
        box.layer.cornerRadius = 12
        box.translatesAutoresizingMaskIntoConstraints = false
        box.heightAnchor.constraint(equalToConstant: height).isActive = true
        box.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: box.centerYAnchor)
        ])
        return box
    }

    // MARK: - Data
    private func loadProfile() {
        Task {
            do {
                if let user = try await AuthService.shared.loadCurrentUser() {
                    await MainActor.run {
                        header.name = user.displayName
                        header.role = user.role
                        aboutBody.text = user.bio.isEmpty ? "No bio yet." : user.bio
                    }
                    if let urlString = user.photoURL, let url = URL(string: urlString) {
                        await loadAvatar(from: url)
                    } else {
                        await MainActor.run { self.header.setAvatarImage(nil) }
                    }
                }
            } catch { await MainActor.run { self.showError("Failed to load profile", error) } }
        }
    }

    @MainActor
    private func loadAvatar(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            self.header.setAvatarImage(UIImage(data: data))
        } catch {
            // Not fatal; just keep placeholder
            self.header.setAvatarImage(nil)
        }
    }

    // MARK: - Edit Profile
    private func presentEditProfile() {
        let edit = EditProfileViewController()
        Task {
            let user = try? await AuthService.shared.loadCurrentUser()
            await MainActor.run {
                edit.prefill = user
                edit.delegate = self
                let nav = UINavigationController(rootViewController: edit)
                nav.modalPresentationStyle = .formSheet
                self.present(nav, animated: true)
            }
        }
    }

    func editProfileDidSave() { loadProfile() }

    // MARK: - Avatar picking & upload
    private func pickNewAvatar() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func uploadAvatar(_ image: UIImage) {
        guard let uid = AuthService.shared.currentUserId else { return }

        // Compress to JPEG (you can tune quality)
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }

        let fs = FirebaseService.shared
        let avatarRef = fs.avatarsRoot.child("\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Simple progress HUD replacement: disable user interaction briefly
        view.isUserInteractionEnabled = false

        Task {
            do {
                _ = try await avatarRef.putDataAsync(data, metadata: metadata)
                let url = try await avatarRef.downloadURL()

                // Save downloadURL on user doc
                try await fs.users.document(uid).setData(["photoURL": url.absoluteString], merge: true)

                // Update UI
                await MainActor.run {
                    self.view.isUserInteractionEnabled = true
                    self.header.setAvatarImage(image)
                }
            } catch {
                await MainActor.run {
                    self.view.isUserInteractionEnabled = true
                    self.showError("Upload failed", error)
                }
            }
        }
    }

    // MARK: - Helpers
    private func showError(_ title: String, _ error: Error) {
        let ac = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

// MARK: - PHPicker delegate
extension ProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { object, _ in
            guard let image = object as? UIImage else { return }
            // Optionally crop to square here before upload
            self.uploadAvatar(image)
        }
    }
}
