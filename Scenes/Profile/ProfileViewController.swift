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

    // MARK: - Existing outlets
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var roleLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var websiteButton: UIButton!
    @IBOutlet private weak var bioBodyLabel: UILabel!

    // MARK: - Tags UI (optional; wire if present)
    @IBOutlet private weak var tagsCollectionView: UICollectionView?
    /// Optional height constraint. Connect this if you want the tag list to auto-expand
    /// and avoid inner scrolling. Safe to leave nil if you prefer the collection view to scroll.
    @IBOutlet private weak var tagsCollectionHeight: NSLayoutConstraint?

    // MARK: - State
    private let db = Firestore.firestore()
    private var tags: [String] = []
    private var programmaticTagsHeight: NSLayoutConstraint?

    // Reuse ID
    private static let pillReuseID = "TagPillCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        avatarImageView.layer.cornerRadius = 36
        avatarImageView.clipsToBounds = true

        // Configure tags collection if it exists
        if let cv = tagsCollectionView {
            cv.dataSource = self
            cv.delegate   = self

            // Register a programmatic pill cell so no storyboard cell is required
            cv.register(PillCell.self, forCellWithReuseIdentifier: Self.pillReuseID)

            if let flow = cv.collectionViewLayout as? UICollectionViewFlowLayout {
                flow.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
                flow.minimumInteritemSpacing = 8
                flow.minimumLineSpacing = 8
                flow.sectionInset = .zero
                flow.scrollDirection = .vertical
            }
        }

        Task { await loadProfile() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await loadProfile() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTagsHeight()
    }

    @IBAction private func editProfileTapped(_ sender: UIButton) {
        let vc = EditProfileViewController()
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    // MARK: - Data / UI
    private func defaultRoleText(from raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "media creator" }
        return raw
    }
    private func defaultBio(_ text: String?) -> String {
        let t = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "No bio yet." : t
    }

    private func applyUI(name: String,
                         role: String,
                         location: String?,
                         website: String?,
                         bio: String?,
                         photoURL: String?,
                         tags: [String]) async {

        nameLabel.text = name
        roleLabel.text = defaultRoleText(from: role)
        locationLabel.text = (location?.isEmpty == false) ? location : "—"
        bioBodyLabel.text = defaultBio(bio)

        if let website, !website.isEmpty {
            websiteButton.setTitle(website, for: .normal)
            websiteButton.isHidden = false
        } else {
            websiteButton.setTitle(nil, for: .normal)
            websiteButton.isHidden = true
        }

        self.tags = tags
        await MainActor.run {
            tagsCollectionView?.reloadData()
            updateTagsHeight()
        }

        if let photoURL, let url = URL(string: photoURL) {
            await loadAvatar(from: url)
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
            let tags     = (data["tags"] as? [String]) ?? []

            await applyUI(name: name,
                          role: role,
                          location: location,
                          website: website,
                          bio: bio,
                          photoURL: photoURL,
                          tags: tags)
        } catch {
            await MainActor.run { self.showError("Failed to load profile", error) }
        }
    }

    // MARK: - Tags layout helpers
    @MainActor
    private func updateTagsHeight() {
        guard let cv = tagsCollectionView else { return }
        // If you didn’t wire tagsCollectionHeight, just bail (cv can scroll).
        guard tagsCollectionHeight != nil || programmaticTagsHeight != nil else { return }

        cv.layoutIfNeeded()
        let h = max(cv.collectionViewLayout.collectionViewContentSize.height, 1)

        if let outlet = tagsCollectionHeight {
            outlet.constant = h
        } else {
            if programmaticTagsHeight == nil {
                let c = cv.heightAnchor.constraint(equalToConstant: h)
                c.priority = .defaultHigh
                c.isActive = true
                programmaticTagsHeight = c
            } else {
                programmaticTagsHeight?.constant = h
            }
        }
        view.layoutIfNeeded()
    }

    // MARK: - Avatar
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

    // MARK: - Website action
    @IBAction private func websiteTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal),
              let url = URL(string: title),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Error UI
    @MainActor
    private func showError(_ title: String, _ error: Error) {
        let ac = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

// MARK: - Collection View
extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tags.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Self.pillReuseID,
            for: indexPath
        ) as! PillCell
        cell.configure(text: tags[indexPath.item])
        return cell
    }
}

// MARK: - Edit Profile delegate
extension ProfileViewController: ProfileEditingDelegate {
    func editProfileViewControllerDidSave() {
        Task { await loadProfile() }
    }
}

// MARK: - Programmatic pill cell (no storyboard prototype required)
private final class PillCell: UICollectionViewCell {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemGray5
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(text: String) { label.text = text }
}
