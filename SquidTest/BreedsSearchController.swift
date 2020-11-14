//
//  BreedsSearchController.swift
//  SquidTest
//
//  Created by Daniel Vebman on 11/11/20.
//  Copyright © 2020 Daniel Vebman. All rights reserved.
//

import Combine
import Squid
import UIKit

// MARK: - DetailTableViewCell

class DetailTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - BreedsSearchController

class BreedsSearchController: UITableViewController {

    @Published private var searchQuery: String?
    private var searchCancellable: AnyCancellable?
    private var breeds: [Breed] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    private var x: AnyCancellable?

    func parseThrows(_ i: String) throws -> Int {
        if let n = Int(i) {
            return n
        } else {
            throw NSError(domain: "A", code: 3, userInfo: nil)
        }
    }

    override func viewDidLoad() {
        Squid.Logger.silence(true)

        title = "Search breeds"

        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search for a breed"
        navigationItem.searchController = search

        tableView.register(DetailTableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetSearch()
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    private func resetSearch() {
        searchCancellable = $searchQuery
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .replaceNil(with: "")
            .filter { $0.count > 0 }
            .setFailureType(to: Squid.Error.self)
            .flatMap { query in BreedsRequest(queryString: query).schedule(with: DogApi()) }
            .receive(on: RunLoop.main)
            .catch { error -> Just<[Breed]> in
                if case .noConnection = error {
                    self.showNoConnectionAlert()
                    self.searchCancellable?.cancel()
                } else {
                    print(error)
                }
                return Just([])
            }
            .assign(to: \BreedsSearchController.breeds, on: self)
    }

    func showNoConnectionAlert() {
        let alert = UIAlertController(
            title: "No connection",
            message: "Please check your Internet connection and retry.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in
            self.resetSearch()
        }))
        present(alert, animated: true)
    }

}

// MARK: - UISearchResultsUpdating

extension BreedsSearchController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        searchQuery = searchController.searchBar.text
    }

}

// MARK: - UITableViewDataSource

extension BreedsSearchController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return breeds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = breeds[indexPath.row].name
        cell.detailTextLabel?.text = breeds[indexPath.row].temperament
        return cell
    }

}

// MARK: - UITableViewDelegate

extension BreedsSearchController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(
            BreedViewController(id: breeds[indexPath.row].id),
            animated: true
        )
    }

}
