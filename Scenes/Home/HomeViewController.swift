//
//  HomeViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import Foundation
import UIKit

final class HomeViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var mainButton: UIButton!
    @IBOutlet weak var inboxButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!

    
    @IBAction func settingsTapped(_ sender: UIButton) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: "License", style: .default))
        sheet.addAction(UIAlertAction(title: "Translation", style: .default))

        sheet.addAction(UIAlertAction(title: "Log out", style: .destructive) { _ in
            do {
                try AuthService.shared.signOut()

                // Return to login
                let sb = UIStoryboard(name: "Main", bundle: nil)
                let login = sb.instantiateViewController(withIdentifier: "LoginVC")
                let nav = UINavigationController(rootViewController: login)

                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first {
                    window.rootViewController = nav
                    UIView.transition(with: window, duration: 0.25,
                                      options: .transitionCrossDissolve, animations: nil)
                    window.makeKeyAndVisible()
                }
            } catch {
                let a = UIAlertController(title: "Sign out failed",
                                          message: error.localizedDescription,
                                          preferredStyle: .alert)
                a.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(a, animated: true)
            }
        })

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad/large screens
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }

        present(sheet, animated: true)
    }
    
    
    private var currentChild: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        switchTo(.main)   // default tab when Home opens
    }

    // MARK: - Actions
    @IBAction func profileTapped(_ sender: UIButton) { switchTo(.profile) }
    @IBAction func mainTapped(_ sender: UIButton)    { switchTo(.main) }
    @IBAction func inboxTapped(_ sender: UIButton)   { switchTo(.inbox) }

    // MARK: - Tab switching
    private enum Tab { case profile, main, inbox }

    private func switchTo(_ tab: Tab) {
        let id: String
        switch tab {
        case .profile: id = "ProfileViewController"
        case .main:    id = "MainPageViewController"
        case .inbox:   id = "InboxViewController"
        }

        let vc = storyboard!.instantiateViewController(withIdentifier: id)
        setChild(vc)
        updateButtonSelection(for: tab)
    }

    private func setChild(_ newVC: UIViewController) {
        // remove current
        if let current = currentChild {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        // add new
        addChild(newVC)
        containerView.addSubview(newVC.view)
        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            newVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            newVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            newVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        newVC.didMove(toParent: self)
        currentChild = newVC
    }

    private func updateButtonSelection(for tab: Tab) {
        // simple visual state (optional)
        profileButton.isSelected = (tab == .profile)
        mainButton.isSelected    = (tab == .main)
        inboxButton.isSelected   = (tab == .inbox)
    }

}
