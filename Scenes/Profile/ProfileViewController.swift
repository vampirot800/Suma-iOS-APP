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

    // MARK: - Outlets (existing)
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var roleLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var websiteButton: UIButton!
    @IBOutlet private weak var bioBodyLabel: UILabel!

    // MARK: - Tags UI (existing)
    @IBOutlet private weak var tagsCollectionView: UICollectionView!
    @IBOutlet private weak var tagsHeightConstraint: NSLayoutConstraint!

    // MARK: - Portfolios UI (existing)
    @IBOutlet private weak var portfolioCollectionView: UICollectionView!
    @IBOutlet private weak var portfolioHeightConstraint: NSLayoutConstraint!

    // MARK: - State
    private let db = Firestore.firestore()
    private var tags: [String] = []
    private var portfolioItems: [PortfolioItem] = []

    // Reuse IDs
    private static let pillReuseID = "TagPillCell"
    private static let portfolioReuseID = PortfolioCardCell.reuseID

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Avatar styling like the old file
        avatarImageView.layer.cornerRadius = 36
        avatarImageView.clipsToBounds = true

        // ---- Tags collection (pills) ----
        if let cv = tagsCollectionView {
            cv.dataSource = self
            cv.delegate   = self
            cv.backgroundColor = .clear
            cv.register(PillCell.self, forCellWithReuseIdentifier: Self.pillReuseID)
            if let flow = cv.collectionViewLayout as? UICollectionViewFlowLayout {
                flow.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
                flow.minimumInteritemSpacing = 8
                flow.minimumLineSpacing = 8
                flow.sectionInset = .zero
                flow.scrollDirection = .vertical
            }
            // Let outer scroll view handle scrolling for tags
            cv.isScrollEnabled = false
        }

        // ---- Portfolio collection (cards) ----
        if let pvc = portfolioCollectionView {
            pvc.dataSource = self
            pvc.delegate   = self
            pvc.backgroundColor = .clear
            pvc.register(PortfolioCardCell.self,
                         forCellWithReuseIdentifier: Self.portfolioReuseID)

            if let flow = pvc.collectionViewLayout as? UICollectionViewFlowLayout {
                let spacing: CGFloat = 12
                flow.sectionInset = .zero
                flow.minimumInteritemSpacing = spacing
                flow.minimumLineSpacing = spacing
                flow.estimatedItemSize = .zero
            }

            // Breathe a bit inside the page
            pvc.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)

            // ✅ Make the portfolio grid itself scrollable
            pvc.isScrollEnabled = true
        }

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

    // MARK: - Actions
    @IBAction private func editProfileTapped(_ sender: UIButton) {
        let vc = EditProfileViewController()
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    @IBAction private func websiteTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal),
              let url = URL(string: title),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    @IBAction private func portfolioTapped(_ sender: UIButton) {
        let editor = PortfolioEditorViewController()
        let nav = UINavigationController(rootViewController: editor)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    // MARK: - Data loading
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

                if website.isEmpty {
                    self.websiteButton.setTitle(nil, for: .normal)
                    self.websiteButton.isHidden = true
                } else {
                    self.websiteButton.setTitle(website, for: .normal)
                    self.websiteButton.isHidden = false
                }

                self.bioBodyLabel.text = bio.isEmpty ? "No bio yet." : bio

                self.tags = tags
                self.tagsCollectionView?.reloadData()
                self.updateTagsHeight()
            }

            if let s = photoURL, let url = URL(string: s) {
                await loadAvatar(from: url)
            }
        } catch {
            print("Profile load error: \(error)")
        }
    }

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
            print("Portfolios fetch error: \(error)")
        }
    }

    private func loadAvatar(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                await MainActor.run { self.avatarImageView.image = img }
            }
        } catch { /* ignore */ }
    }

    // MARK: - Dynamic heights
    private func updateTagsHeight() {
        guard let cv = tagsCollectionView, let h = tagsHeightConstraint else { return }
        cv.collectionViewLayout.invalidateLayout()
        cv.layoutIfNeeded()
        h.constant = cv.collectionViewLayout.collectionViewContentSize.height
        view.layoutIfNeeded()
    }

    private func updatePortfoliosHeight() {
        // Instead of matching content height, size to visible space so the collection view can scroll internally.
        guard let cv = portfolioCollectionView, let h = portfolioHeightConstraint else { return }

        // Force the latest frames before measuring
        view.layoutIfNeeded()
        cv.collectionViewLayout.invalidateLayout()
        cv.layoutIfNeeded()

        // Calculate available vertical space from the top of the portfolio grid to the safe-area bottom.
        let bottomInset = view.safeAreaInsets.bottom
        let available = view.bounds.height - cv.frame.minY - bottomInset - 12

        if available.isFinite, available > 0 {
            h.constant = available
            view.layoutIfNeeded()
        } else if h.constant == 0 {
            // Fallback height if layout hasn’t resolved yet
            h.constant = 300
            view.layoutIfNeeded()
        }
    }
}

// MARK: - Pill cell (tags)
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

// MARK: - UICollectionView DataSource & Delegate
extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == tagsCollectionView {
            return tags.count
        } else if collectionView == portfolioCollectionView {
            return portfolioItems.count
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == tagsCollectionView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: Self.pillReuseID,
                for: indexPath
            ) as! PillCell
            cell.configure(text: tags[indexPath.item])
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: Self.portfolioReuseID,
                for: indexPath
            ) as! PortfolioCardCell
            cell.configure(with: portfolioItems[indexPath.item])
            return cell
        }
    }

    // 2-column grid for portfolio cards; pills use automatic sizing
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        if collectionView == tagsCollectionView {
            // auto-sized via estimatedItemSize; a small fallback is fine
            return CGSize(width: 50, height: 30)
        }

        // ---- Portfolio grid (2 columns) ----
        let spacing: CGFloat = 12
        let insets = collectionView.contentInset
        let width = collectionView.bounds.width - insets.left - insets.right
        let columns: CGFloat = 2
        let totalSpacing = spacing * (columns - 1)
        let itemW = floor((width - totalSpacing) / columns)
        // Tall enough for title + subtitle (and your future skill line)
        return CGSize(width: itemW, height: 130)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView == portfolioCollectionView else { return }
        let item = portfolioItems[indexPath.item]
        let editor = ProjectCardEditorViewController(itemToEdit: item)
        editor.onSave = { [weak self] in Task { await self?.fetchPortfolios() } }
        present(UINavigationController(rootViewController: editor), animated: true)
    }
}

// MARK: - Edit profile delegate (refresh)
extension ProfileViewController: ProfileEditingDelegate {
    func editProfileViewControllerDidSave() {
        Task { await loadProfile(); await fetchPortfolios() }
    }
}
