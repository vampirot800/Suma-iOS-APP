//
//  Font+Inter.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import Foundation

import UIKit

extension UIFont {
    enum InterWeight { case regular, medium, semibold }

    static func inter(_ weight: InterWeight, size: CGFloat) -> UIFont {
        let name: String
        switch weight {
        case .regular:  name = "Inter-Regular"
        case .medium:   name = "Inter-Medium"
        case .semibold: name = "Inter-SemiBold"
        }
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size)
    }
}

extension Theme.Font {
    static func title() -> UIFont {
        UIFontMetrics(forTextStyle: .title1).scaledFont(for: .inter(.semibold, size: 28))
    }
    static func headline() -> UIFont {
        UIFontMetrics(forTextStyle: .headline).scaledFont(for: .inter(.medium, size: 17))
    }
    static func body() -> UIFont {
        UIFontMetrics(forTextStyle: .body).scaledFont(for: .inter(.regular, size: 16))
    }
    static func caption() -> UIFont {
        UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .inter(.regular, size: 12))
    }
}
