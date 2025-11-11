//
//  NavBar.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import UIKit

/// Convenience extension for toggling the navigation bar visibility.
extension UIViewController {

    /// Hides the navigation bar without animation.
    func hideNavBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    /// Shows the navigation bar without animation.
    func showNavBar() {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}
