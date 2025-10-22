//
//  Theme.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import UIKit

enum Theme {
    // Colors
    static let background    = UIColor(named: "Background")    ?? .systemBackground
    static let surface       = UIColor(named: "Surface")       ?? .secondarySystemBackground
    static let primary       = UIColor(named: "Primary")       ?? .systemBlue
    static let accent        = UIColor(named: "Accent")        ?? .systemGreen
    static let textPrimary   = UIColor(named: "TextPrimary")   ?? .label
    static let textSecondary = UIColor(named: "TextSecondary") ?? .secondaryLabel
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
    enum Radius {
        static let md: CGFloat = 12
        static let pill: CGFloat = 22
    }

    enum Font {
    }

    static func applyGlobalAppearance() {
        UIView.appearance().tintColor = primary

        // Navigation bar
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = surface
        nav.titleTextAttributes = [.foregroundColor: textPrimary]
        nav.largeTitleTextAttributes = [.foregroundColor: textPrimary]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = primary

        // Tab bar
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = surface
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = primary
        UITabBar.appearance().unselectedItemTintColor = textSecondary

        UILabel.appearance().textColor = textPrimary
    }
}
