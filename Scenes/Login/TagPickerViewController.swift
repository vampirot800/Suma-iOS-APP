//
//  TagPickerViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 22/10/25.
//
//  A simple multi-select tag picker with a large, built-in catalog.
//  Presented modally; returns selection through an `onDone` closure.
//

import UIKit

/// Displays a scrollable list of predefined content tags that users can select or deselect.
/// Commonly used during account setup or profile editing.
final class TagPickerViewController: UITableViewController {

    // MARK: - Properties

    /// Predefined tag catalog.
    /// Expand or customize this list to fit your app’s domain.
    private let allTags: [String] = [
        "travel", "food", "photo", "video", "design", "branding", "ux", "ui", "illustration", "music",
        "podcast", "fashion", "beauty", "gaming", "sports", "fitness", "health", "wellness", "yoga",
        "technology", "ai", "software", "coding", "education", "finance", "investing", "real estate",
        "marketing", "ads", "content", "copywriting", "newsletter", "shorts", "reels", "tiktok",
        "youtube", "instagram", "x", "photography", "portrait", "landscape", "wedding", "events",
        "architecture", "interiors", "3d", "animation", "vfx", "drone", "product", "ecommerce",
        "recipes", "chef", "coffee", "bars", "restaurants", "hospitality", "lifestyle", "family",
        "pets", "cars", "motorcycles", "outdoors", "camping", "surf", "skate", "startup", "saas",
        "mobile apps", "science", "psychology", "coaching", "mindfulness", "self improvement",
        "books", "reviews", "how-to", "tutorials", "tips", "culture", "art", "dance", "cinema",
        "documentary", "travel tips", "hotels", "airbnb", "gear", "bts", "time-lapse", "macro",
        "street", "film", "analog", "lighting", "color grading", "sound", "voice over", "interviews"
    ].sorted()

    /// Current selection of tags (mutable during interaction).
    private var selectedTags: Set<String>

    /// Closure executed when the user taps “Done”.
    /// Sends back the final selection to the presenting controller.
    private let onDone: (Set<String>) -> Void

    // MARK: - Initialization

    /// Creates a new instance of the tag picker.
    /// - Parameters:
    ///   - initialSelection: Preselected tags to display as checked.
    ///   - onDone: Closure called with the final selection when user finishes.
    init(initialSelection: Set<String>, onDone: @escaping (Set<String>) -> Void) {
        self.selectedTags = initialSelection
        self.onDone = onDone
        super.init(style: .insetGrouped)

        title = "Choose Tags"
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    // MARK: - Configuration

    /// Configures navigation bar items and registers table view cells.
    private func configureUI() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(close)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(done)
        )
    }

    // MARK: - Actions

    /// Dismisses the picker without saving changes.
    @objc private func close() {
        dismiss(animated: true)
    }

    /// Confirms selection and dismisses the picker.
    @objc private func done() {
        onDone(selectedTags)
        dismiss(animated: true)
    }

    // MARK: - Table View Data Source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        allTags.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let tag = allTags[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = tag.capitalized
        config.textProperties.font = .systemFont(ofSize: 15, weight: .medium)
        config.textProperties.color = .label

        cell.contentConfiguration = config
        cell.accessoryType = selectedTags.contains(tag) ? .checkmark : .none
        return cell
    }

    // MARK: - Table View Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let tag = allTags[indexPath.row]
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }

        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = selectedTags.contains(tag) ? .checkmark : .none
        }
    }
}
