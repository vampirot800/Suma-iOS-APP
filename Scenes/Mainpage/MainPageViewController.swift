//
//  MainPageViewController.swift
//  FIT3178-App
//
//  Storyboard-only version (no programmatic UI fallbacks)
//  Live Firestore-backed cards (profiles)
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class MainPageViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var deckView: UIView!
    @IBOutlet private weak var dislikeButton: UIButton!
    @IBOutlet private weak var likeButton: UIButton!

    // MARK: - Data
    private var allCandidates: [CandidateVM] = []
    private var queue: [CandidateVM] = []
    private var topCard: SwipeCardView?

    private var likedIDs: Set<String> = []
    private var passedIDs: Set<String> = []

    // Firestore
    private let db = Firestore.firestore()

    // Repos & listeners
    private let likesRepo = LikesRepository()
    private var likesListener: ListenerRegistration?

    // Portfolios CollectionView (small cards list of liked users)
    private var portfoliosCollection: UICollectionView!
    private var likedUsersVMs: [CandidateVM] = []

    // Cache: liked user id -> fetched portfolio items
    private var portfolioCache: [String: [PortfolioItem]] = [:]
    // Which rows are expanded
    private var expandedIndexPaths = Set<IndexPath>()

    // Empty-state message for "Portfolios"
    private var portfoliosEmptyView: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.font = .systemFont(ofSize: 16, weight: .semibold)
        lbl.textColor = UIColor(named: "TextSecondary") ?? .secondaryLabel
        lbl.text = "No portfolios yet.\nAdd some users by tapping the + button."
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("════════ MAIN PAGE LOADED ════════")
        print("🔐 currentUser:", Auth.auth().currentUser?.uid ?? "nil")

        print("🔌 outlets — segmentedControl:", segmentedControl as Any,
              "deckView:", deckView as Any,
              "likeButton:", likeButton as Any,
              "dislikeButton:", dislikeButton as Any)

        if segmentedControl.selectedSegmentIndex != 0 {
            segmentedControl.selectedSegmentIndex = 0
        }

        buildPortfoliosCollection()

        print("▶️ Calling observeMyLikes() …")
        observeMyLikes()
        debugProbeMyLikesRead()

        fetchUsersFromFirestore()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavBar()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        print("🧷 MainPageVC.awakeFromNib fired")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topCard?.frame = deckView.bounds
        portfoliosCollection.frame = deckView.bounds
    }

    deinit { likesListener?.remove() }

    // MARK: - IBActions
    @IBAction private func segmentedChanged(_ sender: UISegmentedControl) {
        print("🔀 segmentedChanged → index:", sender.selectedSegmentIndex)
        // Collapse any open rows when switching tabs
        expandedIndexPaths.removeAll()

        applyFilter()
        layoutDeck()
        presentNextCardIfNeeded()
        refreshPortfoliosList()
        updateVisibleContainer()
    }

    @IBAction private func didTapDislike(_ sender: UIButton) {
        guard let card = topCard else { return }
        if let uid = currentTopUserId() { passedIDs.insert(uid) }
        animateOff(card, toRight: false)
    }

    @IBAction private func didTapLike(_ sender: UIButton) {
        guard let card = topCard, let uid = currentTopUserId() else { return }
        Task { [weak self] in
            await self?.likesRepo.like(user: uid)
            await self?.verifyLikeWrite(for: uid)
        }
        animateOff(card, toRight: true)
    }

    // MARK: - Helpers
    private func currentTopUserId() -> String? { queue.first?.userId }

    // MARK: - Firestore fetch (users list)
    private func fetchUsersFromFirestore() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        print("🔎 Fetch users…")
        db.collection("users")
            .limit(to: 120)
            .getDocuments { [weak self] snap, error in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Fetch users error:", error)
                    return
                }
                let docs = snap?.documents ?? []
                print("📥 Users fetched:", docs.count)

                var vms: [CandidateVM] = []
                vms.reserveCapacity(docs.count)

                for doc in docs {
                    if doc.documentID == myUID { continue }
                    let data = doc.data()
                    let displayName = (data["displayName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                        ?? (data["username"] as? String)
                        ?? "—"
                    let role = (data["role"] as? String) ?? ""
                    let bio  = (data["bio"] as? String) ?? ""
                    let tags = (data["tags"] as? [String]) ?? []
                    let photoURL = URL(string: (data["photoURL"] as? String) ?? "")
                    let cvURL    = URL(string: (data["cvURL"] as? String) ?? "")
                    let website: String? = {
                        let raw = (data["website"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        return raw.isEmpty ? nil : raw
                    }()
                    let location: String? = {
                        let raw = (data["location"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        return raw.isEmpty ? nil : raw
                    }()
                    let subtitle: String = !role.isEmpty ? role : (!bio.isEmpty ? bio : "—")

                    let vm = CandidateVM(
                        userId: doc.documentID,
                        name: displayName,
                        subtitle: subtitle,
                        tags: tags,
                        imageURL: photoURL,
                        role: role,
                        bio: bio,
                        cvURL: cvURL,
                        website: website,
                        location: location,
                        placeholder: nil
                    )
                    vms.append(vm)
                }

                DispatchQueue.main.async {
                    self.allCandidates = vms
                    print("✅ allCandidates.count:", self.allCandidates.count)
                    self.applyFilter()
                    self.layoutDeck()
                    self.presentNextCardIfNeeded()
                    self.refreshPortfoliosList()
                    self.updateVisibleContainer()
                }
            }
    }

    // MARK: - Likes observer
    private func observeMyLikes() {
        likesListener = likesRepo.observeMyLikedIDs { [weak self] ids in
            guard let self else { return }
            print("♥️  likedIDs updated (count \(ids.count)):", Array(ids))
            self.likedIDs = ids
            self.applyFilter()
            self.layoutDeck()
            self.presentNextCardIfNeeded()
            self.refreshPortfoliosList()
            self.updateVisibleContainer()
        }
        print("📡 observeMyLikes listener is", likesListener == nil ? "nil" : "non-nil")
    }

    // MARK: - Filtering
    private var filtered: [CandidateVM] {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // For You
            return allCandidates.filter { vm in
                !likedIDs.contains(vm.userId) && !passedIDs.contains(vm.userId)
            }
        case 1: // Portfolios
            return []
        default: return allCandidates
        }
    }
    private func applyFilter() { queue = filtered }

    // MARK: - Deck management
    private func layoutDeck() {
        guard segmentedControl.selectedSegmentIndex == 0 else {
            deckView.subviews.forEach { if $0 !== portfoliosCollection { $0.removeFromSuperview() } }
            topCard = nil
            return
        }
        deckView.subviews.forEach { if $0 !== portfoliosCollection { $0.removeFromSuperview() } }
        topCard = nil

        let count = min(queue.count, 2)
        for i in (0..<count).reversed() {
            let vm = queue[i]
            let card = SwipeCardView(vm: vm)
            card.frame = deckView.bounds
            card.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            card.transform = CGAffineTransform(scaleX: 1 - CGFloat(i) * 0.03, y: 1 - CGFloat(i) * 0.03)
            card.layer.zPosition = CGFloat(100 - i)
            deckView.addSubview(card)
            if i == 0 {
                addPan(to: card)
                topCard = card
            }
        }
        deckView.bringSubviewToFront(portfoliosCollection)
    }

    private func presentNextCardIfNeeded() {
        guard segmentedControl.selectedSegmentIndex == 0 else { return }
        guard topCard == nil, !queue.isEmpty else { return }
        layoutDeck()
    }

    private func addPan(to card: UIView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        card.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        guard segmentedControl.selectedSegmentIndex == 0 else { return }
        guard let card = topCard else { return }
        let trans = gr.translation(in: view)
        let percent = min(1, max(-1, trans.x / (view.bounds.width/2)))
        let rot: CGFloat = .pi/18 * percent

        switch gr.state {
        case .changed:
            card.center = CGPoint(x: deckView.bounds.midX + trans.x, y: deckView.bounds.midY + trans.y)
            card.transform = CGAffineTransform(rotationAngle: rot)
        case .ended, .cancelled:
            let velocity = gr.velocity(in: view).x
            if abs(percent) > 0.35 || abs(velocity) > 600 {
                let toRight = percent > 0
                if toRight, let uid = currentTopUserId() {
                    Task { [weak self] in
                        await self?.likesRepo.like(user: uid)
                        await self?.verifyLikeWrite(for: uid)
                    }
                } else if let uid = currentTopUserId() {
                    passedIDs.insert(uid)
                }
                animateOff(card, toRight: toRight)
            } else {
                UIView.animate(withDuration: 0.25) {
                    card.center = CGPoint(x: self.deckView.bounds.midX, y: self.deckView.bounds.midY)
                    card.transform = .identity
                }
            }
        default: break
        }
    }

    private func animateOff(_ card: UIView, toRight: Bool) {
        let dx: CGFloat = (toRight ? 1 : -1) * view.bounds.width * 1.2
        UIView.animate(withDuration: 0.25, animations: {
            card.center.x += dx
            card.alpha = 0.2
        }, completion: { _ in
            card.removeFromSuperview()
            if !self.queue.isEmpty { self.queue.removeFirst() }
            self.topCard = nil
            self.layoutDeck()
            self.presentNextCardIfNeeded()
        })
    }

    // MARK: - Portfolios collection (liked users)
    private func buildPortfoliosCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 16, right: 0)

        portfoliosCollection = UICollectionView(frame: deckView.bounds, collectionViewLayout: layout)
        portfoliosCollection.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        portfoliosCollection.backgroundColor = .clear
        portfoliosCollection.alwaysBounceVertical = true
        portfoliosCollection.isHidden = true
        portfoliosCollection.register(LikedUserCell.self, forCellWithReuseIdentifier: LikedUserCell.reuseID)
        portfoliosCollection.dataSource = self
        portfoliosCollection.delegate = self

        // Empty-state
        let emptyContainer = UIView(frame: deckView.bounds)
        emptyContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        emptyContainer.addSubview(portfoliosEmptyView)
        NSLayoutConstraint.activate([
            portfoliosEmptyView.centerXAnchor.constraint(equalTo: emptyContainer.centerXAnchor),
            portfoliosEmptyView.centerYAnchor.constraint(equalTo: emptyContainer.centerYAnchor),
            portfoliosEmptyView.leadingAnchor.constraint(greaterThanOrEqualTo: emptyContainer.leadingAnchor, constant: 24),
            portfoliosEmptyView.trailingAnchor.constraint(lessThanOrEqualTo: emptyContainer.trailingAnchor, constant: -24)
        ])
        portfoliosCollection.backgroundView = emptyContainer

        deckView.addSubview(portfoliosCollection)
        deckView.sendSubviewToBack(portfoliosCollection)
    }

    private func refreshPortfoliosList() {
        likedUsersVMs = allCandidates.filter { likedIDs.contains($0.userId) }
        portfoliosCollection.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        let showPortfolios = segmentedControl.selectedSegmentIndex == 1
        let showEmpty = showPortfolios && likedUsersVMs.isEmpty
        portfoliosCollection.backgroundView?.isHidden = !showEmpty
    }

    private func updateVisibleContainer() {
        let showPortfolios = segmentedControl.selectedSegmentIndex == 1
        portfoliosCollection.isHidden = !showPortfolios
        dislikeButton.isHidden = showPortfolios
        likeButton.isHidden = showPortfolios
        updateEmptyState()
    }

    // MARK: - Likes probes
    private func debugProbeMyLikesRead() {
        guard let me = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(me).collection("likes").getDocuments { snap, err in
            if let err = err { print("❌ [Probe] likes getDocuments:", err.localizedDescription) }
            else { print("✅ [Probe] likes getDocuments OK:", snap?.documents.count ?? 0) }
        }
    }
    private func verifyLikeWrite(for likedUid: String) async {
        guard let me = Auth.auth().currentUser?.uid else { return }
        do {
            let doc = try await db.collection("users").document(me).collection("likes").document(likedUid).getDocument()
            print("🧪 [Verify] like exists?", doc.exists)
        } catch { print("❌ [Verify] like read failed:", error.localizedDescription) }
    }

    // MARK: - Fetch portfolios for a specific liked user
    private func fetchPortfoliosOnce(for userId: String, completion: @escaping ([PortfolioItem]) -> Void) {
        if let cached = portfolioCache[userId] {
            completion(cached); return
        }
        db.collection("users").document(userId).collection("portfolios")
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snap, err in
                guard let self = self else { return }
                if let err = err {
                    print("❌ portfolios fetch for \(userId):", err.localizedDescription)
                    completion([]); return
                }
                let items: [PortfolioItem] = (snap?.documents ?? []).compactMap { PortfolioItem(doc: $0) }
                self.portfolioCache[userId] = items
                completion(items)
            }
    }

    // MARK: - Match / Chat helpers

    /// Returns true if *both* users have liked each other.
    private func isMutualLike(otherUid: String, completion: @escaping (Bool) -> Void) {
        guard let me = Auth.auth().currentUser?.uid else { completion(false); return }
        db.collection("users").document(otherUid)
            .collection("likes").document(me)
            .getDocument { doc, err in
                if let err = err {
                    print("❌ mutualLike read failed:", err.localizedDescription)
                    completion(false); return
                }
                completion(doc?.exists == true)
            }
    }

    /// Create (or reuse) a 1:1 chat with `otherUid` and push ChatViewController.
    private func openOrCreateChat(with otherUid: String) {
        ensureChat(with: otherUid) { [weak self] chatId in
            guard let self = self, let chatId = chatId else { return }
            DispatchQueue.main.async {
                let chatVC = ChatViewController(chatId: chatId, other: nil)
                if let nav = self.navigationController {
                    nav.pushViewController(chatVC, animated: true)
                } else {
                    let nav = UINavigationController(rootViewController: chatVC)
                    nav.modalPresentationStyle = .automatic
                    self.present(nav, animated: true)
                }
            }
        }
    }

    /// Ensures a 1:1 chat exists; returns the chatId.
    private func ensureChat(with otherUid: String, completion: @escaping (String?) -> Void) {
        guard let me = Auth.auth().currentUser?.uid else { completion(nil); return }
        
        db.collection("chats")
            .whereField("participants", arrayContains: me)
            .getDocuments { [weak self] snap, err in
                guard let self = self else { completion(nil); return }
                if let err = err {
                    print("❌ chat lookup:", err.localizedDescription)
                }
                
                if let existing = snap?.documents.first(where: {
                    let arr = ($0.data()["participants"] as? [String]) ?? []
                    return Set(arr) == Set([me, otherUid])
                }) {
                    completion(existing.documentID)
                    return
                }
                
                // Create a new chat if none exists
                let doc = self.db.collection("chats").document()
                let payload: [String: Any] = [
                    "participants": [me, otherUid],
                    "isgroupchat": false,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                doc.setData(payload) { err in
                    if let err = err {
                        print("❌ chat create:", err.localizedDescription)
                        completion(nil)
                    } else {
                        completion(doc.documentID)
                    }
                }
            }
    }
}

/// MARK: - Data Source
extension MainPageViewController: UICollectionViewDataSource {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        likedUsersVMs.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: LikedUserCell.reuseID, for: indexPath) as! LikedUserCell
        let vm = likedUsersVMs[indexPath.item]

        let collapsedVM = LikedUserCell.ViewModel(
            name: vm.name,
            role: vm.role ?? "—",
            location: vm.location,
            website: vm.website,
            bio: vm.bio,
            photoURL: vm.imageURL
        )

        if expandedIndexPaths.contains(indexPath) {
            let items = portfolioCache[vm.userId] ?? []
            cell.configureExpanded(collapsedVM, portfolios: items)

            // Toggle "Message" button based on mutual-like state
            isMutualLike(otherUid: vm.userId) { isMatch in
                DispatchQueue.main.async { cell.setMatch(isMatched: isMatch) }
            }
        } else {
            cell.configureCollapsed(collapsedVM)
            cell.setMatch(isMatched: false)
        }

        // Open website
        cell.onWebsiteTap = { url in
            if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
        }

        // Tap on a portfolio project → present large detail sheet (animated in ProjectDetailVC)
        cell.onProjectTap = { [weak self] item in
            guard let self = self else { return }
            let vc = ProjectDetailViewController(item: item)
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            }
            self.present(vc, animated: true)
        }

        // "Message" button → ensure chat and push ChatViewController
        cell.onMessageTap = { [weak self] in
            self?.openOrCreateChat(with: vm.userId)
        }

        return cell
    }
}

// MARK: - Delegate + dynamic sizing
extension MainPageViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vm = likedUsersVMs[indexPath.item]
        if expandedIndexPaths.contains(indexPath) {
            // Collapse
            expandedIndexPaths.remove(indexPath)
            cv.performBatchUpdates({
                cv.reloadItems(at: [indexPath])
            }, completion: nil)
        } else {
            // Expand: fetch portfolios if needed, then reload
            fetchPortfoliosOnce(for: vm.userId) { [weak self] _ in
                guard let self = self else { return }
                self.expandedIndexPaths.insert(indexPath)
                cv.performBatchUpdates({
                    cv.reloadItems(at: [indexPath])
                }, completion: nil)
            }
        }
    }

    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Stable heights to avoid deformation
        let width = cv.bounds.width
        let height: CGFloat = expandedIndexPaths.contains(indexPath) ? 380 : 92
        return CGSize(width: width, height: height)
    }

    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 10, left: 0, bottom: 16, right: 0)
    }

    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        12
    }
}
