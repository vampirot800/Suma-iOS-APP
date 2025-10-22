//
//  SignupViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 22/10/25.
//


import UIKit
import FirebaseAuth

final class SignupViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var roleSegment: UISegmentedControl! // 0=Media Creator, 1=Enterprise
    @IBOutlet weak var createButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Account"
        emailField.keyboardType = .emailAddress
        passwordField.isSecureTextEntry = true
    }

    // MARK: - Actions
    @IBAction func createAccountTapped(_ sender: UIButton) {
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordField.text ?? ""
        let name = (firstNameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            alert(title: "Missing Info", message: "Please enter first name, email and password.")
            return
        }

        let displayName = name
        let role = (roleSegment.selectedSegmentIndex == 1) ? "enterprise" : "media creator"

        createButton.isEnabled = false

        Task {
            do {
                try await AuthService.shared.signUp(
                    email: email,
                    password: password,
                    displayName: displayName,
                    role: role,
                    bio: "",
                    tags: []
                )
                await MainActor.run { self.swapToMainRoot() }
            } catch {
                await MainActor.run {
                    self.createButton.isEnabled = true
                    self.alert(title: "Sign up failed", message: self.prettyAuthError(error))
                }
            }
        }
    }

    // MARK: - Navigation
    private func swapToMainRoot() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let home = sb.instantiateViewController(withIdentifier: "HomeVC")
        let nav = UINavigationController(rootViewController: home)

        guard
            let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
            let window = scene.windows.first
        else { return }

        window.rootViewController = nav
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: nil)
        window.makeKeyAndVisible()
    }


    // MARK: - UI helpers
    private func alert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    private func prettyAuthError(_ error: Error) -> String {
        let ns = error as NSError
        if ns.domain == AuthErrorDomain {
            if let authCode = AuthErrorCode(rawValue: ns.code) {
                switch authCode {
                case .emailAlreadyInUse:
                    return "An account already exists for that email."
                case .weakPassword:
                    return "Password is too weak. Try a longer one."
                case .invalidEmail:
                    return "That email address looks invalid."
                case .networkError:
                    return "Network error. Please try again."
                default:
                    return ns.localizedDescription
                }
            }
        }
        return ns.localizedDescription
    }
}
