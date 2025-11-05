//
//  LoginViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import UIKit
import FirebaseAuth

final class LoginViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background

        emailField.keyboardType = .emailAddress
        emailField.textContentType = .username
        passwordField.isSecureTextEntry = true
        passwordField.textContentType = .password

        styleTextField(emailField, placeholder: "Email")
        styleTextField(passwordField, placeholder: "Password")
    }

    
    // MARK: - Actions
    @IBAction func signInTapped(_ sender: UIButton) {
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordField.text ?? ""

        // If this alert never appears, your button is NOT wired to this IBAction.
        guard !email.isEmpty, !password.isEmpty else {
            alert(title: "Missing Info", message: "Please enter your email and password.")
            return
        }

        loginButton.isEnabled = false

        Task {
            do {
                try await AuthService.shared.signIn(email: email, password: password)
                try await AuthService.shared.ensureUserDoc(displayNameFallback: "New User")
                await MainActor.run { self.swapToMainRoot() }
            } catch {
                await MainActor.run {
                    self.loginButton.isEnabled = true
                    self.alert(title: "Sign in failed", message: self.prettyAuthError(error))
                }
            }
        }
    }
    

    // MARK: - Navigation helper
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
            case .userNotFound, .wrongPassword: return "Email and/or password are incorrect."
            case .invalidEmail:                 return "That email address looks invalid."
            case .networkError:                 return "Network error. Please try again."
            default:                            return ns.localizedDescription
            }
        }
        return ns.localizedDescription
    }
    
    private func styleTextField(_ tf: UITextField, placeholder: String) {
        tf.borderStyle = .none
        tf.textColor = Theme.textPrimary
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: Theme.textSecondary.withAlphaComponent(0.7)]
        )
        tf.backgroundColor = UIColor.white.withAlphaComponent(0.92) // matches your figma “pill”
        tf.layer.cornerRadius = 16        // <- roundness here
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 0

        // left padding
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.leftViewMode = .always
    }
    
    //Delete top navigation item bar
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }


}

