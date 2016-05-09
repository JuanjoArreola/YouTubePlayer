//
//  Networking.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 4/30/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation

enum FetchError: ErrorType {
    case InvalidData
    case ParseError
    case NotFound
    case NotImplemented
}

func requestURL(url: NSURL, completion: ((data: NSData?, response: NSURLResponse?, error:NSError?)) -> Void) -> NSURLSessionDataTask {
    let request = NSMutableURLRequest(URL: url, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10)
    
    let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: completion)
    task.resume()
    return task
}

func startRequestWithURL(url: NSURL, completion: (getResult: () throws -> (data: NSData, response: NSURLResponse?)) -> Void) -> Cancellable {
    let request = URLRequest<(data: NSData, response: NSURLResponse?)>(completionHandler: completion)
    request.dataTask = requestURL(url) { (data: NSData?, response: NSURLResponse?, error: NSError?) in
        do {
            if let error = error {
                throw error
            }
            guard let validData = data else {
                throw FetchError.InvalidData
            }
            dispatch_async(dispatch_get_main_queue()) {
                request.completeWithObject((data: validData, response: response))
            }
        } catch {
            dispatch_async(dispatch_get_main_queue()) {
                request.completeWithError(error)
            }
        }
    }
    return request
}