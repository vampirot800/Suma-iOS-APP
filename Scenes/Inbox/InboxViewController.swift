//
//  InboxViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import UIKit

final class InboxViewController: ScrollingStackViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Inbox"

        let placeholder = makeRow(title: "Chat with Demo User")
        let placeholder2 = makeRow(title: "Another Chat")
        stackView.addArrangedSubview(placeholder)
        stackView.addArrangedSubview(placeholder2)
    }

    private func makeRow(title: String) -> UIView {
        let label = UILabel()
        label.text = title

        let row = UIStackView(arrangedSubviews: [label, UIView(), UIImageView(image: UIImage(systemName: "chevron.right"))])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 12, left: 12, bottom: 12, right: 12)
        row.backgroundColor = .secondarySystemBackground
        row.layer.cornerRadius = 10
        return row
    }
}
