//
//  SearchViewController.swift
//  Netflix Clone
//
//  Created by Ramazan Ceylan on 9.02.2023.
//

import UIKit

class SearchViewController: UIViewController {
  
  private var titles: [Title] = [Title]()
  
  private let discoverTableView: UITableView = {
    let tableView = UITableView()
    tableView.register(TitleTableViewCell.self, forCellReuseIdentifier: TitleTableViewCell.identifier)
    return tableView
  }()
  
  private let searchController :UISearchController = {
    let controller = UISearchController(searchResultsController: SearchResultsViewController())
    controller.searchBar.placeholder = "Search for a Movie or a Tv show"
    controller.searchBar.searchBarStyle = .minimal
    return controller
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Search"
    navigationController?.navigationBar.prefersLargeTitles = true
    navigationController?.navigationItem.largeTitleDisplayMode = .always
    
    view.backgroundColor = .systemBackground
    
    view.addSubview(discoverTableView)
    discoverTableView.delegate = self
    discoverTableView.dataSource = self
    navigationItem.searchController = searchController
    navigationController?.navigationBar.tintColor = .white
    
    fetchDiscoverMovies()
    searchController.searchResultsUpdater = self
  }
  
  private func fetchDiscoverMovies() {
    APICaller.shared.getDiscoverMovies { [weak self] result in
      switch result {
      case .success(let titles):
        self?.titles = titles
        DispatchQueue.main.async {
          self?.discoverTableView.reloadData()
        }
      case .failure(let error):
        print(error.localizedDescription)
      }
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    discoverTableView.frame = view.bounds
  }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return titles.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.identifier, for: indexPath) as? TitleTableViewCell else {
      return UITableViewCell()
    }
    
    let title = titles[indexPath.row]
    let model = TitleViewModel(titleName: title.originalName ?? title.originalTitle ?? "Unknown name", posterURL: title.posterPath ?? "")
    cell.configure(with: model)
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 140
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let title = titles[indexPath.row]
    guard let titleName = title.originalTitle ?? title.originalName else { return }
    
    APICaller.shared.getMovie(with: titleName) { [weak self] result in
      switch result {
      case .success(let videoElement):
        DispatchQueue.main.async {
          let vc = TitlePreviewViewController()
          vc.configure(with: TitlePreviewViewModel(title: titleName, youtubeView: videoElement, titleOverview: title.overview ?? ""))
          self?.navigationController?.pushViewController(vc, animated: true)
        }
      case .failure(let error):
        print(error.localizedDescription)
      }
    }
  }
  
}

extension SearchViewController: UISearchResultsUpdating, SearchResultsViewControllerDelegate {
  func updateSearchResults(for searchController: UISearchController) {
    let searchBar = searchController.searchBar
    
    guard let query = searchBar.text,
          !query.trimmingCharacters(in: .whitespaces).isEmpty,
          query.trimmingCharacters(in: .whitespaces).count >= 3,
          let resultsController = searchController.searchResultsController as? SearchResultsViewController else { return }
    
    resultsController.delegate = self
    
    APICaller.shared.search(with: query) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let titles):
          resultsController.titles = titles
          resultsController.searchResultsCollectionView.reloadData()
        case .failure(let error):
          print(error.localizedDescription)
        }
      }
      
    }
  }
  
  func searchResultsViewControllerDidTapItem(_ viewModel: TitlePreviewViewModel) {
    DispatchQueue.main.async { [weak self] in
      let vc = TitlePreviewViewController()
      vc.configure(with: viewModel)
      self?.navigationController?.pushViewController(vc, animated: true)
    }
  }
  
}
