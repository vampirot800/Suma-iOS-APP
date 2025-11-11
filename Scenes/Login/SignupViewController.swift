//
//  SignupViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 22/10/25.
//

import UIKit
import FirebaseAuth

/// Handles account creation for new users.
/// Validates basic input, creates the user via `AuthService`,
/// and transitions to the Home flow on success.
final class SignupViewController: UIViewController {

    // MARK: - IBOutlets (Storyboard)

    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    /// 0 = Media Creator, 1 = Enterprise
    @IBOutlet weak var roleSegment: UISegmentedControl!
    @IBOutlet weak var createButton: UIButton!

    /// One-line bio input shown on the signup screen.
    @IBOutlet weak var bioTextField: UITextField!
    /// Opens the modal tag picker.
    @IBOutlet weak var pickTagsButton: UIButton!

    // MARK: - State

    /// Tags selected in the tag picker; persisted to Firestore by `AuthService.signUp`.
    private var selectedTags: [String] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Account"

        // Email
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .username
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no

        // Password
        passwordField.isSecureTextEntry = true
        passwordField.textContentType = .password
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no
        passwordField.smartDashesType = .no
        passwordField.smartQuotesType = .no
        passwordField.spellCheckingType = .no

        // Name
        firstNameField.autocorrectionType = .no
        firstNameField.textContentType = .name

        [firstNameField, emailField, passwordField, bioTextField].forEach { styleTextField($0) }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Make the button a pill after it has a size.
        createButton.layer.cornerRadius = createButton.bounds.height / 2
        createButton.layer.masksToBounds = true
    }

    // MARK: - Actions

    /// Opens the tag picker and updates `selectedTags` when done.
    @IBAction func pickTagsTapped(_ sender: UIButton) {
        let picker = TagPickerViewController(
            initialSelection: Set(selectedTags),
            onDone: { [weak self] selection in
                guard let self else { return }
                self.selectedTags = Array(selection).sorted()

                // Optional badge showing selected count.
                let base = "Choose tags"
                self.pickTagsButton.setTitle(
                    self.selectedTags.isEmpty ? base : "\(base) (\(self.selectedTags.count))",
                    for: .normal
                )
            }
        )
        present(UINavigationController(rootViewController: picker), animated: true)
    }

    /// Attempts to create the account; shows alerts on failure.
    @IBAction func createAccountTapped(_ sender: UIButton) {
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordField.text ?? ""
        let name = (firstNameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let bio = (bioTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let role = (roleSegment.selectedSegmentIndex == 1) ? "enterprise" : "media creator"

        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            alert(title: "Missing Info", message: "Please enter first name, email and password.")
            return
        }

        createButton.isEnabled = false

        Task {
            do {
                // `AuthService.signUp` is responsible for creating `searchable` from tags.
                try await AuthService.shared.signUp(
                    email: email,
                    password: password,
                    displayName: name,
                    role: role,
                    bio: bio,
                    tags: selectedTags
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

    /// Replaces the root controller with Home after a successful signup.
    private func swapToMainRoot() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let home = sb.instantiateViewController(withIdentifier: "HomeVC")
        let nav = UINavigationController(rootViewController: home)

        guard
            let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
            let window = scene.windows.first
        else { return }

        window.rootViewController = nav
        UIView.transition(
            with: window,
            duration: 0.25,
            options: .transitionCrossDissolve,
            animations: nil
        )
        window.makeKeyAndVisible()
    }

    // MARK: - UI Helpers

    /// Shows a simple OK alert.
    private func alert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    /// Maps Firebase Auth errors to friendly messages.
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

    /// Applies rounded styling and padding to text fields.
    private func styleTextField(_ tf: UITextField?) {
        guard let tf else { return }
        tf.layer.cornerRadius = 12
        tf.layer.masksToBounds = true

        // Left padding
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.leftView = pad
        tf.leftViewMode = .always
    }
}
