//
//  Theme.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import UIKit

enum Theme {
    // MARK: - Palette (semantic)
    static let background    = UIColor(named: "Background")    ?? .systemBackground      // Mist/Ink
    static let surface       = UIColor(named: "Surface")       ?? .secondarySystemBackground // Pine
    static let primary       = UIColor(named: "Primary")       ?? .systemGreen           // Mint
    static let accent        = UIColor(named: "Accent")        ?? .systemTeal            // Sage
    static let textPrimary   = UIColor(named: "TextPrimary")   ?? .label                 // Ink/White
    static let textSecondary = UIColor(named: "TextSecondary") ?? .secondaryLabel
    static let divider       = UIColor(named: "Divider")       ?? UIColor.label.withAlphaComponent(0.12)

    // MARK: - Spacing & Radii
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let pill: CGFloat = 22
        static let card: CGFloat = 24
    }

    // MARK: - Fonts (Inter helpers live in Font+Inter.swift)
    enum Font { }

    // MARK: - Global appearance
    static func applyGlobalAppearance() {
        // Tint for controls
        UIView.appearance().tintColor = primary

        // Navigation Bar - solid Pine with white titles
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = surface
        nav.titleTextAttributes = [.foregroundColor: UIColor.white,
                                   .font: Theme.Font.navTitle()]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white,
                                        .font: Theme.Font.navLargeTitle()]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = primary // back button & bar items

        // Tab Bar - solid Pine, Mint selected, Sage unselected
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = surface
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = primary
        UITabBar.appearance().unselectedItemTintColor = accent

        // Labels default to TextPrimary unless explicitly styled
        UILabel.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).textColor = textPrimary
    }
}

// MARK: - Reusable UI styles
extension UIButton {
    /// Mint filled rounded button (for primary CTAs)
    func applyPrimaryCTA() {
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = Theme.primary
        cfg.baseForegroundColor = Theme.surface // Pine text on Mint
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        self.configuration = cfg
        self.layer.cornerRadius = Theme.Radius.lg
        self.clipsToBounds = true
        self.titleLabel?.font = Theme.Font.button()
    }

    /// Mist filled secondary button
    func applySecondaryCTA() {
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = Theme.background
        cfg.baseForegroundColor = Theme.surface
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        self.configuration = cfg
        self.layer.cornerRadius = Theme.Radius.lg
        self.clipsToBounds = true
        self.titleLabel?.font = Theme.Font.button()
    }
}

extension UITextField {
    /// Rounded Mist textfield with internal padding and optional left icon.
    func applySumaField(placeholder: String, leftIcon: UIImage? = nil) {
        backgroundColor = Theme.background
        textColor = Theme.textPrimary
        font = Theme.Font.body()
        layer.cornerRadius = Theme.Radius.md
        layer.borderWidth = 0
        layer.masksToBounds = true

        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: Theme.textSecondary]
        )

        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        leftView = leftIcon == nil ? pad : {
            let iv = UIImageView(image: leftIcon)
            iv.tintColor = Theme.textSecondary
            let c = UIStackView(arrangedSubviews: [UIView(frame: .init(x: 0, y: 0, width: 8, height: 1)), iv])
            c.axis = .horizontal
            c.alignment = .center
            c.spacing = 8
            c.frame = CGRect(x: 0, y: 0, width: 36, height: 24)
            return c
        }()
        leftViewMode = .always
        // right padding keeps caret away from the edge
        let right = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        rightView = right
        rightViewMode = .always
    }
}
