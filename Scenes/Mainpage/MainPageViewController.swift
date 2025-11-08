////
//  MainPageViewController.swift
//  FIT3178-App
//
//  Storyboard-only version (no programmatic UI fallbacks)
//

import UIKit

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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        makeDemoData()
        applyFilter()
        layoutDeck()
        presentNextCardIfNeeded()
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


    // MARK: - Demo data & filtering (unchanged logic)
    private func makeDemoData() {
        let raw: [(String, String, [String])] = [
            ("Lia Gomez", "Offers: travel • food • photo", ["travel","food","photo"]),
            ("GamerZone", "GamerZone • www.gamerzone.com", ["lorem","ipsum","dolor","sit amet","consectetur"]),
            ("Glam Studio", "Offers: makeup • hair", ["beauty","studio","photo"]),
            ("Jet Travel", "Tours & travel", ["travel","adventure","video"]),
            ("Cafe Verde", "Local coffee brand", ["coffee","beans","roastery"])
        ]
        allCandidates = raw.map { CandidateVM(name: $0.0, subtitle: $0.1, tags: $0.2, image: nil) }
    }

    private var filtered: [CandidateVM] {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return allCandidates
        case 1:
            return allCandidates.filter {
                $0.name.lowercased().contains("zone")
                || $0.tags.contains(where: { ["lorem","ipsum","dolor","sit amet","consectetur"].contains($0) })
            }
        default:
            return allCandidates.filter {
                let n = $0.name.lowercased()
                return n.contains("travel") || n.contains("glam")
                    || n.contains("brands")
                    || n.contains("cafe")
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
