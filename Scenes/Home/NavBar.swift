//
//  NavBar.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import Foundation
import UIKit

extension UIViewController {
    func hideNavBar() { navigationController?.setNavigationBarHidden(true, animated: false) }
    func showNavBar() { navigationController?.setNavigationBarHidden(false, animated: false) }
}
