//
//  MainPageViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import UIKit

final class MainPageViewController: UIViewController {

    // MARK: - Storyboard outlets (connect these when you build the storyboard)
    @IBOutlet private weak var segmentedOutlet: UISegmentedControl?
    @IBOutlet private weak var deckViewOutlet: UIView?
    @IBOutlet private weak var dislikeButtonOutlet: UIButton?
    @IBOutlet private weak var likeButtonOutlet: UIButton?

    // Detect whether we’re using storyboard Auto Layout
    private var usingStoryboard: Bool { segmentedOutlet != nil }

    // MARK: - UI fallback (code path kept so the screen still runs without IB)
    private lazy var segmented: UISegmentedControl = {
        if let seg = segmentedOutlet { return seg }
        let seg = UISegmentedControl(items: ["For You", "Portfolios", "Ideas"])
        seg.selectedSegmentIndex = 0
        seg.selectedSegmentTintColor = .white
        seg.backgroundColor = UIColor.systemGray5
        seg.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        return seg
    }()

    private lazy var deckView: UIView = {
        if let v = deckViewOutlet { return v }
        let v = UIView()
        v.clipsToBounds = false
        v.backgroundColor = .clear
        return v
    }()

    private lazy var dislikeButton: UIButton = {
        if let b = dislikeButtonOutlet { return b }
        let b = UIButton(type: .system)
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        cfg.baseForegroundColor = .systemRed
        cfg.cornerStyle = .capsule
        cfg.image = UIImage(systemName: "xmark")
        cfg.preferredSymbolConfigurationForImage = .init(pointSize: 22, weight: .semibold)
        b.configuration = cfg
        b.layer.shadowOpacity = 0.12; b.layer.shadowRadius = 6; b.layer.shadowOffset = .init(width: 0, height: 3)
        b.addTarget(self, action: #selector(tapDislike), for: .touchUpInside)
        return b
    }()

    private lazy var likeButton: UIButton = {
        if let b = likeButtonOutlet { return b }
        let b = UIButton(type: .system)
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        cfg.baseForegroundColor = .systemGreen
        cfg.cornerStyle = .capsule
        cfg.image = UIImage(systemName: "heart.fill")
        cfg.preferredSymbolConfigurationForImage = .init(pointSize: 22, weight: .semibold)
        b.configuration = cfg
        b.layer.shadowOpacity = 0.12; b.layer.shadowRadius = 6; b.layer.shadowOffset = .init(width: 0, height: 3)
        b.addTarget(self, action: #selector(tapLike), for: .touchUpInside)
        return b
    }()

    // MARK: - Data
    private var allCandidates: [CandidateVM] = []
    private var queue: [CandidateVM] = []
    private var topCard: SwipeCardView?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        if !usingStoryboard {
            view.addSubview(segmented)
            view.addSubview(deckView)
            view.addSubview(dislikeButton)
            view.addSubview(likeButton)
        } else {
            // If using storyboard, ensure button configurations match the code look
            styleButtonsIfNeeded()
            segmented.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        }

        makeDemoData()
        applyFilter()
        layoutDeck()
        presentNextCardIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // If IB is driving Auto Layout, do not set frames.
        guard !usingStoryboard else {
            topCard?.frame = deckView.bounds
            return
        }

        let sa = view.safeAreaInsets

        // Top segmented control
        segmented.frame = CGRect(
            x: 16, y: sa.top + 8,
            width: view.bounds.width - 32, height: 36
        )

        // Deck view
        let buttonsBottomPadding: CGFloat = 22
        let deckTop = segmented.frame.maxY + 12
        let deckBottom = view.bounds.height - sa.bottom - buttonsBottomPadding - 72 - 24
        deckView.frame = CGRect(x: 16,
                                y: deckTop,
                                width: view.bounds.width - 32,
                                height: max(360, deckBottom - deckTop))

        // Buttons
        let centerX = view.bounds.midX
        dislikeButton.frame.size = CGSize(width: 72, height: 72)
        likeButton.frame.size = dislikeButton.frame.size
        dislikeButton.center = CGPoint(x: centerX - 90, y: view.bounds.height - sa.bottom - 22 - 36)
        likeButton.center    = CGPoint(x: centerX + 90, y: dislikeButton.center.y)

        // Ensure top card tracks deck bounds
        topCard?.frame = deckView.bounds
    }

    func styleButtonsIfNeeded() {
        // When buttons come from storyboard, apply the same config used in code
        if dislikeButtonOutlet != nil, dislikeButton.configuration == nil {
            var cfg = UIButton.Configuration.filled()
            cfg.baseBackgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
            cfg.baseForegroundColor = .systemRed
            cfg.cornerStyle = .capsule
            cfg.image = UIImage(systemName: "xmark")
            cfg.preferredSymbolConfigurationForImage = .init(pointSize: 22, weight: .semibold)
            dislikeButton.configuration = cfg
            dislikeButton.layer.shadowOpacity = 0.12
            dislikeButton.layer.shadowRadius = 6
            dislikeButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        }
        if likeButtonOutlet != nil, likeButton.configuration == nil {
            var cfg = UIButton.Configuration.filled()
            cfg.baseBackgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
            cfg.baseForegroundColor = .systemGreen
            cfg.cornerStyle = .capsule
            cfg.image = UIImage(systemName: "heart.fill")
            cfg.preferredSymbolConfigurationForImage = .init(pointSize: 22, weight: .semibold)
            likeButton.configuration = cfg
            likeButton.layer.shadowOpacity = 0.12
            likeButton.layer.shadowRadius = 6
            likeButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        }
    }

    // MARK: - Demo Data / Filtering (unchanged)
    private func makeDemoData() {
        let raw: [(String, String, [String])] =
        [
            ("Lia Gomez", "Offers: travel • food • photo", ["travel","food","photo"]),
            ("GamerZone", "GamerZone • www.gamerzone.com", ["lorem","ipsum","dolor","sit amet","consectetur"]),
            ("Glam Studio", "Offers: makeup • hair", ["beauty","studio","photo"]),
            ("Jet Travel", "Tours & travel", ["travel","adventure","video"]),
            ("Cafe Verde", "Local coffee brand", ["coffee","beans","roastery"])
        ]
        allCandidates = raw.map { CandidateVM(name: $0.0, subtitle: $0.1, tags: $0.2, image: nil) }
    }

    @objc private func segChanged() {
        applyFilter()
        queue = filtered
        layoutDeck()
        presentNextCardIfNeeded()
    }

    private var filtered: [CandidateVM] {
        guard let seg = (usingStoryboard ? segmentedOutlet : segmented) else { return allCandidates }
        switch seg.selectedSegmentIndex {
        case 0:
            return allCandidates
        case 1:
            return allCandidates.filter { $0.name.lowercased().contains("zone") || $0.tags.contains(where: { ["lorem","ipsum","dolor","sit amet","consectetur"].contains($0) }) }
        default:
            return allCandidates.filter {
                let n = $0.name.lowercased()
                return n.contains("travel") || n.contains("glam")
                    || n.contains("brands")
                    || n.contains("cafe")
            }
        }
    }
    private func applyFilter() {
        queue = filtered
    }

    private func layoutDeck() {
        deckView.subviews.forEach { $0.removeFromSuperview() }
        topCard = nil

        let count = min(queue.count, 2)
        for i in (0..<count).reversed() {
            let vm = queue[i]
            let card = SwipeCardView(vm: vm)
            card.frame = deckView.bounds
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
                UIView.animate(withDuration: 0.25, animations: {
                    card.center = CGPoint(x: self.deckView.bounds.midX, y: self.deckView.bounds.midY)
                    card.transform = .identity
                })
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

    @objc private func tapDislike() { if let card = topCard { animateOff(card, toRight: false) } }
    @objc private func tapLike()    { if let card = topCard { animateOff(card, toRight: true) } }
}
