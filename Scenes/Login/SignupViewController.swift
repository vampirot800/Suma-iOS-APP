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

        // Text input types
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .username
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no

        passwordField.isSecureTextEntry = true
        passwordField.textContentType = .newPassword
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no

        firstNameField.autocorrectionType = .no
        firstNameField.textContentType = .name

        // Match Login VC field style
        [firstNameField, emailField, passwordField].forEach {
            styleTextField($0)
        }

        // Optional: pill button like your design
        // createButton.backgroundColor = Theme.primary
        createButton.setTitleColor(.white, for: .normal)
        // createButton.titleLabel?.font = Theme.Font.headline()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Make the button a pill after it has a size
        createButton.layer.cornerRadius = createButton.bounds.height / 2
        createButton.layer.masksToBounds = true
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
        if ns.domain == AuthErrorDomain, let code = AuthErrorCode(rawValue: ns.code) {
            switch code {
            case .emailAlreadyInUse: return "An account already exists for that email."
            case .weakPassword:      return "Password is too weak. Try a longer one."
            case .invalidEmail:      return "That email address looks invalid."
            case .networkError:      return "Network error. Please try again."
            default:                 return ns.localizedDescription
            }
        }
        return ns.localizedDescription
    }

    // Same look as Login VC
    private func styleTextField(_ tf: UITextField?) {
        guard let tf else { return }
        // tf.textColor = Theme.textPrimary
        // tf.backgroundColor = Theme.surface.withAlphaComponent(0.18)
        tf.layer.cornerRadius = 12
        tf.layer.masksToBounds = true

        // Left padding
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.leftView = pad
        tf.leftViewMode = .always

        // Placeholder tint
        let placeholder = tf.placeholder ?? ""
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            // attributes: [.foregroundColor: Theme.textSecondary.withAlphaComponent(0.7)]
        )
    }
}
