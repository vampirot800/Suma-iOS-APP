//
//  ProfileViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//


import UIKit
import FirebaseAuth
import FirebaseFirestore

final class ProfileViewController: UIViewController {

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var roleLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var websiteButton: UIButton!
    @IBOutlet private weak var bioBodyLabel: UILabel!

    private let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        avatarImageView.layer.cornerRadius = 36
        avatarImageView.clipsToBounds = true
        Task { await loadProfile() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Defensive refresh in case delegate wasn’t called for any reason
        Task { await loadProfile() }
    }

    @IBAction private func editProfileTapped(_ sender: UIButton) {
        let vc = EditProfileViewController()
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    // MARK: - Data
    private func defaultRoleText(from raw: String?) -> String {
        guard let raw, raw.isEmpty == false else { return "media creator" }
        return raw
    }
    private func defaultBio(_ text: String?) -> String {
        let t = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "No bio yet." : t
    }

    private func applyUI(name: String, role: String, location: String?, website: String?, bio: String?, photoURL: String?) async {
        nameLabel.text = name
        roleLabel.text = defaultRoleText(from: role)
        locationLabel.text = (location?.isEmpty == false) ? location : "—"
        bioBodyLabel.text = defaultBio(bio)

        if let website, website.isEmpty == false {
            websiteButton.setTitle(website, for: .normal)
            websiteButton.isHidden = false
        } else {
            websiteButton.setTitle(nil, for: .normal)
            websiteButton.isHidden = true
        }

        if let photoURL, let url = URL(string: photoURL) {
            await loadAvatar(from: url)
        } else {
            await MainActor.run {
                self.avatarImageView.image = UIImage(systemName: "person.circle.fill")
                self.avatarImageView.tintColor = .systemGray3
            }
        }
    }

    private func loadProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let snap = try await db.collection("users").document(uid).getDocument()
            let data = snap.data() ?? [:]

            let name     = data["displayName"] as? String ?? "User"
            let role     = data["role"] as? String ?? "media creator"
            let location = data["location"] as? String
            let website  = data["website"] as? String
            let bio      = data["bio"] as? String
            let photoURL = data["photoURL"] as? String

            await applyUI(name: name, role: role, location: location, website: website, bio: bio, photoURL: photoURL)
        } catch {
            await MainActor.run { self.showError("Failed to load profile", error) }
        }
    }

    @MainActor
    private func showError(_ title: String, _ error: Error) {
        let ac = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    private func loadAvatar(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                await MainActor.run { self.avatarImageView.image = img }
            } else {
                await MainActor.run { self.avatarImageView.image = UIImage(systemName: "person.circle.fill") }
            }
        } catch {
            await MainActor.run { self.avatarImageView.image = UIImage(systemName: "person.circle.fill") }
        }
    }

    @IBAction private func websiteTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal),
              let url = URL(string: title),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Delegate
extension ProfileViewController: ProfileEditingDelegate {
    func editProfileViewControllerDidSave() {
        Task { await loadProfile() }
    }
}
