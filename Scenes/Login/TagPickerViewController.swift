//
//  TagPickerViewController.swift
//  FIT3178-App
//
//  Simple multi-select tag picker with a large, built-in catalog.
//  Presents as a modal; returns selection via onDone closure.
//

import UIKit

final class TagPickerViewController: UITableViewController {

    // Large catalog; expand as you like
    private let allTags: [String] = [
        "travel","food","photo","video","design","branding","ux","ui","illustration","music",
        "podcast","fashion","beauty","gaming","sports","fitness","health","wellness","yoga",
        "technology","ai","software","coding","education","finance","investing","real estate",
        "marketing","ads","content","copywriting","newsletter","shorts","reels","tiktok",
        "youtube","instagram","x","photography","portrait","landscape","wedding","events",
        "architecture","interiors","3d","animation","vfx","drone","product","ecommerce",
        "recipes","chef","coffee","bars","restaurants","hospitality","lifestyle","family",
        "pets","cars","motorcycles","outdoors","camping","surf","skate","startup","saas",
        "mobile apps","science","psychology","coaching","mindfulness","self improvement",
        "books","reviews","how-to","tutorials","tips","culture","art","dance","cinema",
        "documentary","travel tips","hotels","airbnb","gear","bts","time-lapse","macro",
        "street","film","analog","lighting","color grading","sound","voice over","interviews"
    ].sorted()

    private var selected: Set<String>
    private let onDone: (Set<String>) -> Void

    init(initialSelection: Set<String>, onDone: @escaping (Set<String>) -> Void) {
        self.selected = initialSelection
        self.onDone = onDone
        super.init(style: .insetGrouped)
        title = "Choose Tags"
        modalPresentationStyle = .pageSheet
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(close)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done", style: .done, target: self, action: #selector(done)
        )
    }

    @objc private func close() { dismiss(animated: true) }
    @objc private func done() {
        onDone(selected)
        dismiss(animated: true)
    }

    // MARK: - Table
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        allTags.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let tag = allTags[indexPath.row]
        var cfg = cell.defaultContentConfiguration()
        cfg.text = tag
        cell.contentConfiguration = cfg
        cell.accessoryType = selected.contains(tag) ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tag = allTags[indexPath.row]
        if selected.contains(tag) { selected.remove(tag) } else { selected.insert(tag) }
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = selected.contains(tag) ? .checkmark : .none
        }
    }
}
