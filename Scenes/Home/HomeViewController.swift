//
//  HomeViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import UIKit

/// Root container controller managing main tab switching between
/// Profile, MainPage, and Inbox screens.
final class HomeViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var profileButton: UIButton!
    @IBOutlet private weak var mainButton: UIButton!
    @IBOutlet private weak var inboxButton: UIButton!
    @IBOutlet private weak var settingsButton: UIButton!

    // MARK: - Properties

    private var currentChild: UIViewController?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        switchTo(.main) // default tab
    }

    // MARK: - Actions

    /// Opens the settings action sheet.
    @IBAction private func settingsTapped(_ sender: UIButton) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // Acknowledgements action
        sheet.addAction(UIAlertAction(title: "Acknowledgements", style: .default) { _ in
            let acknowledgements = AcknowledgementsViewController()
            let nav = UINavigationController(rootViewController: acknowledgements)
            nav.modalPresentationStyle = .pageSheet
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }

            // iPad popover compatibility
            if let pop = sheet.popoverPresentationController {
                pop.sourceView = sender
                pop.sourceRect = sender.bounds
            }

            self.present(nav, animated: true)
        })

        // Log out action
        sheet.addAction(UIAlertAction(title: "Log out", style: .destructive) { _ in
            self.handleSignOut()
        })

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad popover compatibility
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }

        present(sheet, animated: true)
    }

    @IBAction private func profileTapped(_ sender: UIButton) { switchTo(.profile) }
    @IBAction private func mainTapped(_ sender: UIButton)    { switchTo(.main) }
    @IBAction private func inboxTapped(_ sender: UIButton)   { switchTo(.inbox) }

    // MARK: - Navigation / Tab Switching

    /// Represents the current tab selection.
    private enum Tab { case profile, main, inbox }

    /// Switches to the selected tab by embedding the corresponding view controller.
    private func switchTo(_ tab: Tab) {
        let identifier: String
        switch tab {
        case .profile: identifier = "ProfileViewController"
        case .main:    identifier = "MainPageViewController"
        case .inbox:   identifier = "InboxViewController"
        }

        let newVC = storyboard!.instantiateViewController(withIdentifier: identifier)
        setChild(newVC)
        updateButtonSelection(for: tab)
    }

    /// Replaces the currently displayed child controller.
    private func setChild(_ newVC: UIViewController) {
        // Remove current child
        if let current = currentChild {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        // Add new child
        addChild(newVC)
        containerView.addSubview(newVC.view)
        newVC.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            newVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            newVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            newVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            newVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        newVC.didMove(toParent: self)
        currentChild = newVC
    }

    /// Updates button selection states for visual feedback.
    private func updateButtonSelection(for tab: Tab) {
        profileButton.isSelected = (tab == .profile)
        mainButton.isSelected    = (tab == .main)
        inboxButton.isSelected   = (tab == .inbox)
    }

    // MARK: - Authentication

    /// Handles sign-out logic and transition back to the login screen.
    private func handleSignOut() {
        do {
            try AuthService.shared.signOut()

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC")
            let nav = UINavigationController(rootViewController: loginVC)

            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first {
                window.rootViewController = nav
                UIView.transition(with: window, duration: 0.25,
                                  options: .transitionCrossDissolve, animations: nil)
                window.makeKeyAndVisible()
            }
        } catch {
            let alert = UIAlertController(
                title: "Sign out failed",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}
