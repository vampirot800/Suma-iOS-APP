//
//  LikedUserPortfolioViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 10/11/25.
//

import UIKit
import FirebaseFirestore

/// Displays the portfolio of a user that was previously liked.
/// Dynamically observes portfolio updates from Firestore.
final class LikedUserPortfolioViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: - Properties

    private let userId: String
    private let displayName: String
    private let repo = PortfolioRepository()
    private var listener: ListenerRegistration?
    private var items: [PortfolioItem] = []

    private var collection: UICollectionView!

    // MARK: - Initialization

    init(userId: String, displayName: String) {
        self.userId = userId
        self.displayName = displayName
        super.init(nibName: nil, bundle: nil)
        title = "\(displayName)’s Portfolio"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "Background")
        setupCollectionView()
        observePortfolio()
    }

    deinit { listener?.remove() }

    // MARK: - UI Setup

    /// Creates and configures the collection view layout.
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)

        collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.backgroundColor = .clear
        collection.alwaysBounceVertical = true
        collection.dataSource = self
        collection.delegate = self
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "PortfolioItemCell")
        view.addSubview(collection)

        NSLayoutConstraint.activate([
            collection.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collection.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collection.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collection.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Firestore

    /// Observes Firestore updates to this user's portfolio in real time.
    private func observePortfolio() {
        listener = repo.observePortfolioItems(of: userId) { [weak self] items in
            self?.items = items
            self?.collection.reloadData()
        }
    }

    // MARK: - DataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: "PortfolioItemCell", for: indexPath)
        let item = items[indexPath.item]

        // Reset reused cell content
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.layer.masksToBounds = true
        cell.contentView.backgroundColor = UIColor(named: "Background2")

        // Configure labels
        let title = UILabel()
        title.font = .systemFont(ofSize: 16, weight: .semibold)
        title.text = item.title

        let role = UILabel()
        role.font = .systemFont(ofSize: 14)
        role.textColor = UIColor(named: "TextSecondary")
        role.text = item.role

        let desc = UILabel()
        desc.font = .systemFont(ofSize: 14)
        desc.numberOfLines = 0
        desc.text = item.description

        // Stack layout for labels
        let stack = UIStackView(arrangedSubviews: [title, role, desc])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12)
        ])

        return cell
    }

    // MARK: - Layout

    func collectionView(_ cv: UICollectionView, layout layoutObj: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: cv.bounds.width - 32, height: 140)
    }
}
