//
//  Theme.swift
//  FIT3178-App
//
//  “Color-free” theme: only typography, spacing, radii, shadows, layout helpers.
//  All colors must be provided by the caller (or via Asset Catalog in IB).
//

import UIKit

enum Theme {

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

    enum Shadow {
        /// Soft, elevated card shadow (no color set; uses layer.shadowColor if caller sets it)
        static func applyCardShadow(to view: UIView) {
            view.layer.shadowOpacity = 0.12
            view.layer.shadowRadius  = 16
            view.layer.shadowOffset  = CGSize(width: 0, height: 8)
            // view.layer.shadowColor // <- caller may set this if desired
        }

        /// Light button shadow
        static func applyButtonShadow(to view: UIView) {
            view.layer.shadowOpacity = 0.18
            view.layer.shadowRadius  = 10
            view.layer.shadowOffset  = CGSize(width: 0, height: 6)
        }
    }

    // MARK: - Fonts (implemented in Font+Inter.swift)
    enum Font { }

    // MARK: - Global appearance (fonts only; no colors/tints)
    static func applyGlobalAppearance() {
        // Navigation bar titles (font only)
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground() // background color left to system / caller
        nav.titleTextAttributes      = [.font: Theme.Font.navTitle()]
        nav.largeTitleTextAttributes = [.font: Theme.Font.navLargeTitle()]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav

    }
}

// MARK: - Reusable UI layout helpers (no colors)
extension UIButton {

    /// Capsule “pill” layout for icon/text buttons. Colors are NOT set.
    /// Provide colors via UIButton.Configuration `baseBackgroundColor` / `baseForegroundColor`
    /// after calling this method (or set in IB).
    func applyPillLayout(contentInsets: NSDirectionalEdgeInsets = .init(
        top: 18, leading: 28, bottom: 18, trailing: 28),
        symbolPointSize: CGFloat = 30,
        isFilled: Bool = true
    ) {
        var cfg: UIButton.Configuration = isFilled ? .filled() : .plain()
        cfg.cornerStyle = .capsule
        cfg.contentInsets = contentInsets
        cfg.preferredSymbolConfigurationForImage = .init(pointSize: symbolPointSize, weight: .bold)
        self.configuration = cfg
        Theme.Shadow.applyButtonShadow(to: self) // harmless; skip if not desired
    }

    /// Large rounded CTA layout (no colors).
    func applyCTALayout() {
        var cfg = UIButton.Configuration.filled()
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        self.configuration = cfg
        self.layer.cornerRadius = Theme.Radius.lg
        self.clipsToBounds = true
        self.titleLabel?.font = Theme.Font.button()
    }
}

extension UITextField {
    /// Rounded textfield layout & padding (no colors). Pass optional placeholderColor if you want.
    func applyRoundedFieldLayout(
        cornerRadius: CGFloat = Theme.Radius.md,
        leftPadding: CGFloat = 12,
        rightPadding: CGFloat = 12,
        placeholder: String? = nil,
        placeholderColor: UIColor? = nil
    ) {
        layer.cornerRadius = cornerRadius
        layer.borderWidth = 0
        layer.masksToBounds = true
        font = Theme.Font.body()

        if let text = placeholder {
            if let placeholderColor {
                attributedPlaceholder = NSAttributedString(
                    string: text, attributes: [.foregroundColor: placeholderColor]
                )
            } else {
                self.placeholder = text
            }
        }

        // Left padding (or left icon container if you replace this view)
        let leftPad = UIView(frame: CGRect(x: 0, y: 0, width: leftPadding, height: 1))
        leftView = leftPad
        leftViewMode = .always

        // Right padding
        let rightPad = UIView(frame: CGRect(x: 0, y: 0, width: rightPadding, height: 1))
        rightView = rightPad
        rightViewMode = .always
    }
}

extension UIView {
    /// Convenience for rounding
    func roundCorners(_ radius: CGFloat = Theme.Radius.lg) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
}
