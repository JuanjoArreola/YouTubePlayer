//
//  Request.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 4/30/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation

internal let syncQueue: dispatch_queue_t = dispatch_queue_create("com.youtubeplayer.SyncQueue", DISPATCH_QUEUE_CONCURRENT)

enum RequestError: ErrorType {
    case Canceled
}

public protocol Cancellable {
    func cancel()
}

public class Request<T: Any>: Cancellable, CustomDebugStringConvertible {
    
    var completionHandlers: [(getObject: () throws -> T) -> Void]? = []
    private var result: (() throws -> T)?
    
    public var subrequest: Cancellable? {
        didSet {
            if cancelled {
                subrequest?.cancel()
            }
        }
    }
    
    public var completed: Bool {
        return result != nil
    }
    
    public var cancelled = false
    
    required public init() {}
    
    public convenience init(completionHandler: (getObject: () throws -> T) -> Void) {
        self.init()
        completionHandlers!.append(completionHandler)
    }
    
    public func cancel() {
        sync() { self.cancelled = true }
        subrequest?.cancel()
        completeWithError(RequestError.Canceled)
    }
    
    public func completeWithObject(object: T) {
        if result == nil {
            result = { return object }
            callHandlers()
        }
    }
    
    public func completeWithError(error: ErrorType) {
        if result == nil {
            result = { throw error }
            callHandlers()
        }
    }
    
    func callHandlers() {
        guard let getClosure = result else { return }
        for handler in completionHandlers! {
            handler(getObject: getClosure)
        }
        sync() { self.completionHandlers = nil }
    }
    
    public func addCompletionHandler(completion: (getObject: () throws -> T) -> Void) {
        if let getClosure = result {
            completion(getObject: getClosure)
        } else {
            sync() { self.completionHandlers?.append(completion) }
        }
    }
    
    public var debugDescription: String {
        return String(self)
    }
}

private func sync(closure: () -> Void) {
    dispatch_barrier_async(syncQueue, closure)
}


public class URLRequest<T: Any>: Request<T> {
    
    var dataTask: NSURLSessionDataTask?
    
    required public init() {}
    
    override public func cancel() {
        Log.debug("Cancelling: \(dataTask?.originalRequest?.URL)")
        dataTask?.cancel()
        super.cancel()
    }
    
    override public var debugDescription: String {
        var desc = "URLRequest<\(T.self)>"
        if let url = dataTask?.originalRequest?.URL {
            desc += "(\(url))"
        }
        return desc
    }
}