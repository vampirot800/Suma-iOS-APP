//
//  InboxViewController.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 16/10/25.
//

import UIKit
import FirebaseAuth

final class InboxViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    private var threads: [ChatThread] = []
    private var listener: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Inbox"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        startListening()
    }

    deinit {
        (listener as? ListenerRegistration)?.remove()
    }

    private func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener = ChatRepository.shared.observeThreads(for: uid) { [weak self] threads in
            self?.threads = threads
            self?.tableView.reloadData()
        }
    }

    // MARK: - UITableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        threads.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let t = threads[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var cfg = cell.defaultContentConfiguration()
        // Show the "other" participant id as placeholder title (you can map UID -> displayName via users collection later)
        if let my = Auth.auth().currentUser?.uid {
            let others = t.participants.filter { $0 != my }
            cfg.text = others.first ?? "Chat"
        } else {
            cfg.text = "Chat"
        }
        cfg.secondaryText = t.lastmessage ?? ""
        cell.contentConfiguration = cfg
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = threads[indexPath.row]
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        vc.chatId = chat.id
        navigationController?.pushViewController(vc, animated: true)
    }
}
