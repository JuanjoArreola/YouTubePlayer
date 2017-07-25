//
//  Networking.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 4/30/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation
import AsyncRequest

enum FetchError: Error {
    case invalidData
    case parseError
    case notFound
    case notImplemented
}

func request(url: URL, completion: @escaping ((data: Data?, response: URLResponse?, error: Error?)) -> Void) -> URLSessionDataTask {
    let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
    
    let task = URLSession.shared.dataTask(with: request, completionHandler: completion)
    task.resume()
    return task
}

func startRequest(with url: URL, completion: @escaping (_ getResult: () throws -> (data: Data, response: URLResponse?)) -> Void) -> Cancellable {
    let dataRequest = URLSessionRequest<(data: Data, response: URLResponse?)>(completionHandler: completion)
    dataRequest.dataTask = request(url: url) { (data: Data?, response: URLResponse?, error: Error?) in
        do {
            if let error = error {
                throw error
            }
            guard let validData = data else {
                throw FetchError.invalidData
            }
            DispatchQueue.main.async {
                dataRequest.complete(with: (data: validData, response: response))
            }
        } catch {
            DispatchQueue.main.async {
                dataRequest.complete(with: error)
            }
        }
    }
    return dataRequest
}
