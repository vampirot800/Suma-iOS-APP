//
//  MainPageViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import UIKit

final class MainPageViewController: ScrollingStackViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SUMA"

        let search = UISearchBar()
        search.placeholder = "Search tags, influencers, companies"
        stackView.addArrangedSubview(search)

        let cardsPlaceholder = UIView()
        cardsPlaceholder.backgroundColor = .secondarySystemBackground
        cardsPlaceholder.layer.cornerRadius = 12
        cardsPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        cardsPlaceholder.heightAnchor.constraint(equalToConstant: 600).isActive = true

        let label = UILabel()
        label.text = "Matches/Tinder-style cards here"
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        cardsPlaceholder.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: cardsPlaceholder.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: cardsPlaceholder.centerYAnchor)
        ])
        stackView.addArrangedSubview(cardsPlaceholder)
    }
}
