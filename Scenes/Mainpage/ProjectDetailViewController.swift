//
//  ProjectDetailViewController.swift
//  FIT3178-App
//
//  A bottom-sheet detail for a portfolio card: title, role, dates, skills, description, media URLs.
//
//
//  ProjectDetailViewController.swift
//

import UIKit

final class ProjectDetailViewController: UIViewController {

    private let item: PortfolioItem
    init(item: PortfolioItem) { self.item = item; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private var animator: UIViewPropertyAnimator?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "Background") ?? .systemBackground

        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scroll); scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -40),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)
        ])

        // Title
        let title = UILabel()
        title.font = .systemFont(ofSize: 22, weight: .bold)
        title.numberOfLines = 0
        title.text = item.title.isEmpty ? "Untitled Project" : item.title
        stack.addArrangedSubview(title)

        // Role + dates
        let meta = UILabel()
        meta.font = .systemFont(ofSize: 15, weight: .semibold)
        meta.textColor = UIColor(named: "TextSecondary") ?? .secondaryLabel
        let df = DateFormatter(); df.dateFormat = "MMM yyyy"
        var parts: [String] = []
        if !item.role.isEmpty { parts.append(item.role) }
        if item.startDate != nil || item.endDate != nil {
            let range: String
            switch (item.startDate, item.endDate) {
            case let (s?, e?): range = "\(df.string(from: s)) – \(df.string(from: e))"
            case let (s?, nil): range = "\(df.string(from: s)) – Present"
            case let (nil, e?): range = "Until \(df.string(from: e))"
            default: range = ""
            }
            if !range.isEmpty { parts.append(range) }
        }
        meta.text = parts.joined(separator: " · ")
        stack.addArrangedSubview(meta)

        // Skills chips (auto-size “pills”)
        if !item.skills.isEmpty {
            let chips = UIStackView()
            chips.axis = .horizontal
            chips.spacing = 8
            chips.alignment = .leading
            chips.distribution = .fill
            chips.translatesAutoresizingMaskIntoConstraints = false

            for skill in item.skills.prefix(8) {
                let pill = UILabel()
                pill.text = "  \(skill)  "
                pill.font = .systemFont(ofSize: 13, weight: .medium)
                pill.textColor = (UIColor(named: "Header") ?? view.tintColor)
                pill.backgroundColor = (UIColor(named: "Header") ?? view.tintColor).withAlphaComponent(0.15)
                pill.layer.cornerRadius = 10
                pill.layer.masksToBounds = true
                pill.setContentHuggingPriority(.required, for: .horizontal)
                pill.setContentCompressionResistancePriority(.required, for: .horizontal)
                chips.addArrangedSubview(pill)
            }
            stack.addArrangedSubview(chips)
        }

        // Description
        if !item.description.isEmpty {
            let desc = UILabel()
            desc.font = .systemFont(ofSize: 15)
            desc.numberOfLines = 0
            desc.text = item.description
            stack.addArrangedSubview(desc)
        }

        // Media list (optional)
        if !item.mediaURLs.isEmpty {
            let header = UILabel()
            header.font = .systemFont(ofSize: 15, weight: .semibold)
            header.text = "Media"
            stack.addArrangedSubview(header)

            for urlStr in item.mediaURLs.prefix(6) {
                let btn = UIButton(type: .system)
                btn.setTitle(urlStr, for: .normal)
                btn.contentHorizontalAlignment = .left
                btn.titleLabel?.lineBreakMode = .byTruncatingMiddle
                btn.addAction(UIAction(handler: { _ in
                    if let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }), for: .touchUpInside)
                stack.addArrangedSubview(btn)
            }
        }

        // Prepare initial state for animation
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animator?.stopAnimation(true)
        animator = UIViewPropertyAnimator(duration: 0.25, curve: .easeOut) { [weak self] in
            guard let self else { return }
            self.view.alpha = 1
            self.view.transform = .identity
        }
        animator?.startAnimation()
    }
}
