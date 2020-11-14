//
//  BreedViewController.swift
//  SquidTest
//
//  Created by Daniel Vebman on 11/11/20.
//  Copyright © 2020 Daniel Vebman. All rights reserved.
//

import Combine
import Squid
import UIKit

class BreedViewController: UIViewController {

    private var cancellable: AnyCancellable?
    private let imageView = UIImageView()

    init(id: Int) {
        super.init(nibName: nil, bundle: nil)
        fetchImageUrl(id: id)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.backgroundColor = .white

        imageView.contentMode = .center
        imageView.frame.size = CGSize(width: view.frame.width - 40, height: view.frame.width - 100)
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        imageView.center = view.center
        imageView.image = UIImage(named: "loading")
        view.addSubview(imageView)
    }

    private func fetchImageUrl(id: Int) {
        cancellable = BreedImageRequest(id: id).schedule(with: DogApi())
            .retry(1)
            .compactMap { URL(string: $0.url) }
            .mapError { NetworkError.fetchingImageUrl($0) }
            .flatMap {
                URLSession.shared.dataTaskPublisher(for: $0)
                    .mapError { NetworkError.fetchingImageUrl($0) }
                }
            .map { UIImage(data: $0.data) }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    self.handleFailure(error: error, downloading: id)
                }
            }) { image in
                if let image = image {
                    self.imageView.contentMode = .scaleAspectFill
                    self.imageView.image = image
                } else {
                    self.imageView.image = UIImage(named: "no-dog")
                }
            }
    }

    private func handleFailure(error: NetworkError, downloading id: Int) {
        switch error {
        case .fetchingImageUrl(let error):
            print("This breed has no image :(", error)
        case .downloadingImage(let error):
            print("Failed to download image", error)
        }
        self.imageView.image = UIImage(named: "no-dog")
    }

    private enum NetworkError: Error {

        case downloadingImage(URLError)
        case fetchingImageUrl(Error)

    }

}
