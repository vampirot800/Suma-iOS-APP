//
//  SignupViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 22/10/25.
//

import UIKit
import FirebaseAuth

final class SignupViewController: UIViewController {

    // MARK: - Outlets (connect these in Storyboard)
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var roleSegment: UISegmentedControl! // 0 = Media Creator, 1 = Enterprise
    @IBOutlet weak var createButton: UIButton!

    // NEW: one-line bio and the Choose Tags button
    @IBOutlet weak var bioTextField: UITextField!       // connect to your “Write a Bio” UITextField
    @IBOutlet weak var pickTagsButton: UIButton!        // connect to the green “Choose tags” button

    // MARK: - State
    private var selectedTags: [String] = []             // updated by TagPicker

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Account"

        // Text input types
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .username
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no

        passwordField.isSecureTextEntry = true
        passwordField.textContentType = .password
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no
        passwordField.smartDashesType = .no
        passwordField.smartQuotesType = .no
        passwordField.spellCheckingType = .no

        firstNameField.autocorrectionType = .no
        firstNameField.textContentType = .name

        [firstNameField, emailField, passwordField, bioTextField].forEach { styleTextField($0) }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Make the button a pill after it has a size
        createButton.layer.cornerRadius = createButton.bounds.height / 2
        createButton.layer.masksToBounds = true
    }

    // MARK: - Actions
    // IBAction for the storyboard button "Choose tags"
    @IBAction func pickTagsTapped(_ sender: UIButton) {
        let picker = TagPickerViewController(
            initialSelection: Set(selectedTags),
            onDone: { [weak self] selection in
                guard let self else { return }
                self.selectedTags = Array(selection).sorted()
                // Optional: show a count on the button
                let base = "Choose tags"
                self.pickTagsButton.setTitle(
                    self.selectedTags.isEmpty ? base : "\(base) (\(self.selectedTags.count))",
                    for: .normal
                )
            }
        )
        present(UINavigationController(rootViewController: picker), animated: true)
    }

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
                // AuthService.signUp should already lower-case tags to create `searchable`
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
        tf.layer.cornerRadius = 12
        tf.layer.masksToBounds = true

        // Left padding
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.leftView = pad
        tf.leftViewMode = .always
    }
}
