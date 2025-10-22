//
//  MainPageViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import UIKit

final class MainPageViewController: UIViewController {

    // MARK: - UI
    private let segmented: UISegmentedControl = {
        let s = UISegmentedControl(items: ["Creators", "Enterprises"])
        s.selectedSegmentIndex = 0
        s.backgroundColor = .tertiarySystemFill
        return s
    }()

    // Container for the card stack
    private let deckView = UIView()

    // Bottom action buttons
    private let dislikeButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        cfg.baseForegroundColor = .systemRed
        cfg.cornerStyle = .capsule
        cfg.image = UIImage(systemName: "xmark")
        cfg.preferredSymbolConfigurationForImage = .init(pointSize: 22, weight: .semibold)
        let b = UIButton(configuration: cfg)
        b.layer.shadowOpacity = 0.12
        b.layer.shadowRadius = 6
        b.layer.shadowOffset = CGSize(width: 0, height: 3)
        return b
    }()

    private let likeButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        cfg.baseForegroundColor = .systemGreen
        cfg.cornerStyle = .capsule
        cfg.image = UIImage(systemName: "heart.fill")
        cfg.preferredSymbolConfigurationForImage = .init(pointSize: 22, weight: .semibold)
        let b = UIButton(configuration: cfg)
        b.layer.shadowOpacity = 0.12
        b.layer.shadowRadius = 6
        b.layer.shadowOffset = CGSize(width: 0, height: 3)
        return b
    }()

    // MARK: - Data (demo)
    // Pretend these are the current user's tags (from Firestore profile)
    private let myTags: [String] = ["travel", "food", "photo", "sports"].map { $0.lowercased() }

    // All candidates to display (demo data)
    private var allCandidates: [CandidateVM] = []

    // Filtered for “Creators” vs “Enterprises”
    private var queue: [CandidateVM] = []

    // Keep top card reference for gesture & programmatic swipes
    private var topCard: UIView?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Discover"
        view.backgroundColor = .systemBackground

        buildUI()
        makeDemoData()
        applyFilter()
        layoutDeck()
        presentNextCardIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let sa = view.safeAreaInsets

        // Top segmented control
        segmented.frame = CGRect(
            x: 16,
            y: sa.top + 8,
            width: view.bounds.width - 32,
            height: 36
        )

        let bottomBarHeight: CGFloat = 104   
        let buttonsExtraMargin: CGFloat = 22

        // Card deck – leave more room at the bottom so it never collides with buttons/bar
        let deckInsets = UIEdgeInsets(top: 60, left: 16,
                                      bottom: bottomBarHeight + 64, right: 16)
        deckView.frame = view.bounds.inset(by: UIEdgeInsets(
            top: sa.top + deckInsets.top,
            left: deckInsets.left,
            bottom: sa.bottom + deckInsets.bottom,
            right: deckInsets.right
        ))

        // Bottom action buttons
        let btnW: CGFloat = 64
        let btnH: CGFloat = 64
        let gap: CGFloat = 60

        // Center line for the buttons (push it up by bottomBarHeight + extra margin)
        let centerY = view.bounds.height - sa.bottom - bottomBarHeight - buttonsExtraMargin

        dislikeButton.frame = CGRect(
            x: view.bounds.midX - gap - btnW,
            y: centerY - btnH/2,
            width: btnW, height: btnH
        )

        likeButton.frame = CGRect(
            x: view.bounds.midX + gap,
            y: centerY - btnH/2,
            width: btnW, height: btnH
        )

        topCard?.frame = deckView.bounds
    }


    // MARK: - UI building
    private func buildUI() {
        segmented.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        view.addSubview(segmented)
        view.addSubview(deckView)
        view.addSubview(dislikeButton)
        view.addSubview(likeButton)

        dislikeButton.addTarget(self, action: #selector(tapDislike), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(tapLike), for: .touchUpInside)
    }

    // MARK: - Demo Data
    private func makeDemoData() {
        // Imagine these came from Firestore users (displayName, role/searchable tags, avatar url…)
        let raw: [(String, String, [String])] = [
            ("Lia Gomez",     "media creator",   ["travel","food","photo"]),
            ("Studio Nook",   "enterprise",      ["gaming","photo","events"]),
            ("Aria Chen",     "media creator",   ["fashion","beauty","photo","travel"]),
            ("Peak Brands",   "enterprise",      ["outdoors","sports","travel"]),
            ("Marco Ruiz",    "media creator",   ["sports","tech","photo"]),
            ("Cafe Amparo",   "enterprise",      ["food","coffee","photo"])
        ]

        allCandidates = raw.map { name, role, tags in
            CandidateVM(
                name: name,
                subtitle: subtitleFor(role: role, candidateTags: tags),
                tags: tags,
                image: nil // placeholder for now
            )
        }
    }

    private func subtitleFor(role: String, candidateTags: [String]) -> String {
        let overlap = candidateTags
            .map { $0.lowercased() }
            .filter { myTags.contains($0) }
        if overlap.isEmpty { return role }
        let top3 = overlap.prefix(3).joined(separator: " • ")
        return "Offers: \(top3)"
    }

    // MARK: - Filter + Deck
    @objc private func segChanged() {
        applyFilter()
        layoutDeck()
        presentNextCardIfNeeded()
    }

    private func applyFilter() {
        let creators = segmented.selectedSegmentIndex == 0
        queue = allCandidates.filter { vm in
            if creators {
                return !vm.subtitle.lowercased().hasPrefix("offers:") && vm.subtitle.lowercased().contains("media creator")
                    ? true
                    : vm.subtitle.lowercased().hasPrefix("offers:") && true // keep, creators demo
            } else {
                // simple heuristic: if name contains “Studio / Brands / Cafe” treat as enterprise in demo
                return vm.name.lowercased().contains("studio")
                    || vm.name.lowercased().contains("brands")
                    || vm.name.lowercased().contains("cafe")
            }
        }
    }

    private func layoutDeck() {
        deckView.subviews.forEach { $0.removeFromSuperview() }
        topCard = nil

        // Show up to 2 stacked cards for depth
        let count = min(queue.count, 2)
        for i in (0..<count).reversed() {
            let vm = queue[i]
            let card = SwipeCardView(vm: vm)
            card.frame = deckView.bounds
            card.transform = CGAffineTransform(scaleX: 1 - CGFloat(i) * 0.03,
                                               y: 1 - CGFloat(i) * 0.03)
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

    // MARK: - Gestures & Swipes
    private func addPan(to card: UIView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        card.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        guard let card = g.view else { return }
        let translation = g.translation(in: view)
        let percent = min(max(translation.x / (view.bounds.width/2), -1), 1)
        let rotation: CGFloat = percent * 0.15

        switch g.state {
        case .changed:
            let transform = CGAffineTransform(translationX: translation.x, y: translation.y)
                .rotated(by: rotation)
            card.transform = transform
        case .ended, .cancelled:
            let velocity = g.velocity(in: view)
            if abs(percent) > 0.35 || abs(velocity.x) > 600 {
                // Swipe away
                let isLike = percent > 0
                animateOff(card, toRight: isLike)
            } else {
                // Snap back
                UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.6) {
                    card.transform = .identity
                }
            }
        default:
            break
        }
    }

    private func animateOff(_ card: UIView, toRight: Bool) {
        let dx: CGFloat = toRight ? view.bounds.width * 1.2 : -view.bounds.width * 1.2
        UIView.animate(withDuration: 0.22, animations: {
            card.center.x += dx
            card.alpha = 0.2
        }, completion: { _ in
            card.removeFromSuperview()
            // Consume top of queue and present next
            if !self.queue.isEmpty { self.queue.removeFirst() }
            self.topCard = nil
            self.layoutDeck()
            self.presentNextCardIfNeeded()
        })
    }

    @objc private func tapDislike() {
        guard let card = topCard else { return }
        animateOff(card, toRight: false)
    }

    @objc private func tapLike() {
        guard let card = topCard else { return }
        animateOff(card, toRight: true)
    }
}
