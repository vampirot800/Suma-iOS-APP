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

    // MARK: - IBOutlets (connect all of these in Interface Builder)
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var deckView: UIView!
    @IBOutlet private weak var dislikeButton: UIButton!
    @IBOutlet private weak var likeButton: UIButton!

    // MARK: - Data used to render cards
    private var allCandidates: [CandidateVM] = []
    private var queue: [CandidateVM] = []
    private var topCard: SwipeCardView?

    // Firestore
    private let db = Firestore.firestore()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load real people from Firestore instead of demo data
        fetchUsersFromFirestore()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topCard?.frame = deckView.bounds
    }

    // MARK: - IBAction hooks
    @IBAction private func segmentedChanged(_ sender: UISegmentedControl) {
        applyFilter()
        layoutDeck()
        presentNextCardIfNeeded()
    }

    @IBAction private func didTapDislike(_ sender: UIButton) {
        guard let card = topCard else { return }
        animateOff(card, toRight: false)
    }

    @IBAction private func didTapLike(_ sender: UIButton) {
        guard let card = topCard else { return }
        animateOff(card, toRight: true)
    }

    // MARK: - Firestore fetch
    private func fetchUsersFromFirestore() {
        guard let myUID = Auth.auth().currentUser?.uid else { return }

        // Read public profile data for signed-in users (allowed by your rules)
        db.collection("users")
            .whereField("displayName", isGreaterThan: "")    // light index-friendly filter
            .limit(to: 80)                                   // paging later if needed
            .getDocuments { [weak self] snap, error in
                guard let self = self else { return }
                if let error = error {
                    print("Fetch users error:", error)
                    return
                }
                let docs = snap?.documents ?? []

                // Map -> CandidateVM used by SwipeCardView
                var vms: [CandidateVM] = []
                vms.reserveCapacity(docs.count)

                for doc in docs {
                    // Skip myself
                    if doc.documentID == myUID { continue }

                    let data = doc.data()

                    let displayName = (data["displayName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                        ?? (data["username"] as? String)
                        ?? "—"

                    let role = (data["role"] as? String) ?? ""
                    let bio  = (data["bio"] as? String) ?? ""

                    let tags = (data["tags"] as? [String]) ?? []

                    // Preferred: Storage download URL already stored as string
                    let photoURLString = data["photoURL"] as? String
                    let photoURL = URL(string: photoURLString ?? "")

                    let cvURLString = data["cvURL"] as? String
                    let cvURL = URL(string: cvURLString ?? "")
                    
                    // Pull optional meta fields from the user doc
                    let website: String? = {
                        let raw = (data["website"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        return raw.isEmpty ? nil : raw
                    }()

                    let location: String? = {
                        let raw = (data["location"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        return raw.isEmpty ? nil : raw
                    }()


                    // You can choose what to show as the subtitle; Figma shows role + maybe site
                    let subtitle: String
                    if !role.isEmpty {
                        subtitle = role
                    } else if !bio.isEmpty {
                        // short bio tease
                        subtitle = bio
                    } else {
                        subtitle = "—"
                    }

                    let vm = CandidateVM(
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
                    self.applyFilter()
                    self.layoutDeck()
                    self.presentNextCardIfNeeded()
                }
            }
    }

    // MARK: - Filtering (kept simple; tweak to your needs)
    private var filtered: [CandidateVM] {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // For You
            return allCandidates
        case 1: // Portfolios — proxy using tags presence
            return allCandidates.filter { !$0.tags.isEmpty }
        default: // Ideas — proxy using role/bio keywords
            return allCandidates.filter { vm in
                let r = (vm.role ?? "").lowercased()
                let b = (vm.bio ?? "").lowercased()
                return r.contains("design") || r.contains("media") || b.contains("idea")
            }
        }
    }

    private func applyFilter() { queue = filtered }

    // MARK: - Deck management
    private func layoutDeck() {
        deckView.subviews.forEach { $0.removeFromSuperview() }
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
    }

    private func presentNextCardIfNeeded() {
        guard topCard == nil else { return }
        guard !queue.isEmpty else { return }
        layoutDeck()
    }

    private func addPan(to card: UIView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        card.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
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
                animateOff(card, toRight: percent > 0)
            } else {
                UIView.animate(withDuration: 0.25) {
                    card.center = CGPoint(x: self.deckView.bounds.midX, y: self.deckView.bounds.midY)
                    card.transform = .identity
                }
            }
        default:
            break
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
}
