//
//  DogsApi.swift
//  SquidTest
//
//  Created by Daniel Vebman on 11/10/20.
//  Copyright © 2020 Daniel Vebman. All rights reserved.
//

import Foundation
import Squid

// MARK: - DogApi

struct DogApi: HttpService {

    var apiUrl: UrlConvertible {
        "https://api.thedogapi.com/v1/"
    }

}

protocol AuthenticatedRequest: JsonRequest {

    var header: HttpHeader { get }

}

extension AuthenticatedRequest {

    var header: HttpHeader {
        [.apiKey : "17754c75-6654-4c51-baff-962e453731c2"]
    }

}

// MARK: - BreedsRequest

struct Breed: Codable {

    let id: Int
    let name: String
    let temperament: String?

}

struct BreedsRequest: AuthenticatedRequest {

    typealias Result = [Breed]

    let queryString: String

    var routes: HttpRoute {
        ["breeds", "search"]
    }

    var query: HttpQuery {
        ["q" : queryString]
    }

}

// MARK: - BreedImageRequest

struct BreedImage: Codable {

    let url: String

}

struct BreedImageRequest: AuthenticatedRequest {

    typealias Result = BreedImage

    let id: Int

    func decode(_ data: Data) throws -> BreedImage {
        let images = try JSONDecoder().decode([BreedImage].self, from: data)
        guard let image = images.first else {
            throw DecodingError.valueNotFound(
                Int.self,
                DecodingError.Context(codingPath: [CodingKeys.id], debugDescription: "No image URL.")
            )
        }
        return image
    }

    var routes: HttpRoute {
        ["images", "search"]
    }

    var query: HttpQuery {
        ["breed_id" : id, "page" : 0, "limit" : 1, "order" : "RANDOM", "size" : "med"]
    }

    private enum CodingKeys: Int, CodingKey {
        case id
    }

}
