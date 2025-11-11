//
//  ProfileViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//
//  Description:
//  Displays the user's profile including avatar, name, role, bio, tags, and portfolio projects.
//  Data is loaded from Firestore and displayed in two collection views: tags (pills) and portfolios (cards).
//  Includes buttons for editing profile, viewing portfolio editor, and accessing external website links.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class ProfileViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var roleLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var websiteButton: UIButton!
    @IBOutlet private weak var bioBodyLabel: UILabel!

    @IBOutlet private weak var tagsCollectionView: UICollectionView!
    @IBOutlet private weak var tagsHeightConstraint: NSLayoutConstraint!

    @IBOutlet private weak var portfolioCollectionView: UICollectionView!
    @IBOutlet private weak var portfolioHeightConstraint: NSLayoutConstraint!

    // MARK: - Properties
    private let db = Firestore.firestore()
    private var tags: [String] = []
    private var portfolioItems: [PortfolioItem] = []

    // Reuse identifiers
    private static let pillReuseID = "TagPillCell"
    private static let portfolioReuseID = PortfolioCardCell.reuseID

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollections()
        Task { await loadProfile(); await fetchPortfolios() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await loadProfile(); await fetchPortfolios() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTagsHeight()
        updatePortfoliosHeight()
    }

    // MARK: - Setup
    /// Configures the avatar image view and general appearance.
    private func setupUI() {
        avatarImageView.layer.cornerRadius = 36
        avatarImageView.clipsToBounds = true
    }

    /// Registers data sources and layouts for the tags and portfolio collection views.
    private func setupCollections() {
        // ---- Tags collection ----
        if let tagsCV = tagsCollectionView {
            tagsCV.dataSource = self
            tagsCV.delegate = self
            tagsCV.backgroundColor = .clear
            tagsCV.register(PillCell.self, forCellWithReuseIdentifier: Self.pillReuseID)

            if let flow = tagsCV.collectionViewLayout as? UICollectionViewFlowLayout {
                flow.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
                flow.minimumInteritemSpacing = 8
                flow.minimumLineSpacing = 8
                flow.sectionInset = .zero
                flow.scrollDirection = .vertical
            }
            tagsCV.isScrollEnabled = false
        }

        // ---- Portfolio collection ----
        if let pvc = portfolioCollectionView {
            pvc.dataSource = self
            pvc.delegate = self
            pvc.backgroundColor = .clear
            pvc.register(PortfolioCardCell.self, forCellWithReuseIdentifier: Self.portfolioReuseID)

            if let flow = pvc.collectionViewLayout as? UICollectionViewFlowLayout {
                flow.sectionInset = .zero
                flow.minimumInteritemSpacing = 12
                flow.minimumLineSpacing = 12
                flow.estimatedItemSize = .zero
            }

            pvc.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            pvc.isScrollEnabled = true
        }
    }

    // MARK: - Actions
    /// Opens the Edit Profile screen.
    @IBAction private func editProfileTapped(_ sender: UIButton) {
        let vc = EditProfileViewController()
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    /// Opens the user's personal website.
    @IBAction private func websiteTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal),
              let url = URL(string: title),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    /// Opens the Portfolio Editor view.
    @IBAction private func portfolioTapped(_ sender: UIButton) {
        let editor = PortfolioEditorViewController()
        let nav = UINavigationController(rootViewController: editor)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    // MARK: - Firestore Data
    /// Loads user profile data (name, role, bio, tags, avatar) from Firestore.
    private func loadProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            guard let data = doc.data() else { return }

            let displayName = data["displayName"] as? String ?? ""
            let role        = data["role"] as? String ?? ""
            let location    = data["location"] as? String ?? ""
            let website     = data["website"] as? String ?? ""
            let bio         = (data["bio"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let photoURL    = data["photoURL"] as? String
            let tags        = data["tags"] as? [String] ?? []

            await MainActor.run {
                self.nameLabel.text = displayName.isEmpty ? "—" : displayName
                self.roleLabel.text = role.isEmpty ? "media creator" : role
                self.locationLabel.text = location.isEmpty ? "—" : location
                self.bioBodyLabel.text = bio.isEmpty ? "No bio yet." : bio

                // Website visibility
                if website.isEmpty {
                    self.websiteButton.setTitle(nil, for: .normal)
                    self.websiteButton.isHidden = true
                } else {
                    self.websiteButton.setTitle(website, for: .normal)
                    self.websiteButton.isHidden = false
                }

                self.tags = tags
                self.tagsCollectionView?.reloadData()
                self.updateTagsHeight()
            }

            if let s = photoURL, let url = URL(string: s) {
                await loadAvatar(from: url)
            }
        } catch {
            print("❌ Profile load error: \(error)")
        }
    }

    /// Loads and displays the user's portfolio cards from Firestore.
    private func fetchPortfolios() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let snap = try await db.collection("users").document(uid)
                .collection("portfolios")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            let items = snap.documents.compactMap { PortfolioItem(doc: $0) }
            await MainActor.run {
                self.portfolioItems = items
                self.portfolioCollectionView?.reloadData()
                self.updatePortfoliosHeight()
            }
        } catch {
            print("❌ Portfolios fetch error: \(error)")
        }
    }

    /// Loads the user's avatar image asynchronously.
    private func loadAvatar(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                await MainActor.run { self.avatarImageView.image = img }
            }
        } catch { print("❌ Avatar load error: \(error)") }
    }

    // MARK: - Dynamic Layout
    /// Updates the height constraint of the tags collection based on content.
    private func updateTagsHeight() {
        guard let cv = tagsCollectionView, let h = tagsHeightConstraint else { return }
        cv.collectionViewLayout.invalidateLayout()
        cv.layoutIfNeeded()
        h.constant = cv.collectionViewLayout.collectionViewContentSize.height
        view.layoutIfNeeded()
    }

    /// Updates the portfolio collection height dynamically to allow internal scrolling.
    private func updatePortfoliosHeight() {
        guard let cv = portfolioCollectionView, let h = portfolioHeightConstraint else { return }

        view.layoutIfNeeded()
        cv.collectionViewLayout.invalidateLayout()
        cv.layoutIfNeeded()

        let bottomInset = view.safeAreaInsets.bottom
        let available = view.bounds.height - cv.frame.minY - bottomInset - 12

        if available.isFinite, available > 0 {
            h.constant = available
            view.layoutIfNeeded()
        } else if h.constant == 0 {
            h.constant = 300
            view.layoutIfNeeded()
        }
    }
}

// MARK: - Pill Cell (Tag Bubble)
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

    /// Configures the pill text.
    func configure(text: String) { label.text = text }
}

// MARK: - UICollectionViewDataSource & Delegate
extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == tagsCollectionView { return tags.count }
        if collectionView == portfolioCollectionView { return portfolioItems.count }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == tagsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.pillReuseID, for: indexPath) as! PillCell
            cell.configure(text: tags[indexPath.item])
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.portfolioReuseID, for: indexPath) as! PortfolioCardCell
            cell.configure(with: portfolioItems[indexPath.item])
            return cell
        }
    }

    // Defines layout size per section (tags vs portfolio grid)
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == tagsCollectionView {
            return CGSize(width: 50, height: 30) // auto-sized via estimatedItemSize
        }

        let spacing: CGFloat = 12
        let insets = collectionView.contentInset
        let width = collectionView.bounds.width - insets.left - insets.right
        let columns: CGFloat = 2
        let totalSpacing = spacing * (columns - 1)
        let itemWidth = floor((width - totalSpacing) / columns)
        return CGSize(width: itemWidth, height: 130)
    }

    /// Opens an existing portfolio item in the project card editor.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView == portfolioCollectionView else { return }
        let item = portfolioItems[indexPath.item]
        let editor = ProjectCardEditorViewController(itemToEdit: item)
        editor.onSave = { [weak self] in Task { await self?.fetchPortfolios() } }
        present(UINavigationController(rootViewController: editor), animated: true)
    }
}

// MARK: - Edit Profile Delegate
extension ProfileViewController: ProfileEditingDelegate {
    func editProfileViewControllerDidSave() {
        Task { await loadProfile(); await fetchPortfolios() }
    }
}
