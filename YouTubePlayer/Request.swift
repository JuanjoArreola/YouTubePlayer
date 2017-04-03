//
//  Request.swift
//  YouTubePlayer
//
//  Created by Juan Jose Arreola Simon on 4/30/16.
//  Copyright © 2016 juanjo. All rights reserved.
//

import Foundation

internal let syncQueue = DispatchQueue(label: "com.youtubeplayer.SyncQueue", attributes: DispatchQueue.Attributes.concurrent)

enum RequestError: Error {
    case canceled
}

public protocol Cancellable {
    func cancel()
}

open class Request<T: Any>: Cancellable, CustomDebugStringConvertible {
    
    var completionHandlers: [(_ getObject: () throws -> T) -> Void]? = []
    private var result: (() throws -> T)?
    
    open var subrequest: Cancellable? {
        didSet {
            if cancelled {
                subrequest?.cancel()
            }
        }
    }
    
    open var completed: Bool {
        return result != nil
    }
    
    open var cancelled = false
    
    public convenience init(completionHandler: @escaping (_ getObject: () throws -> T) -> Void) {
        self.init()
        completionHandlers!.append(completionHandler)
    }
    
    open func cancel() {
        sync() { self.cancelled = true }
        subrequest?.cancel()
        complete(withError: RequestError.canceled)
    }
    
    open func complete(withObject object: T) {
        if result == nil {
            result = { return object }
            callHandlers()
        }
    }
    
    open func complete(withError error: Error) {
        if result == nil {
            result = { throw error }
            callHandlers()
        }
    }
    
    func callHandlers() {
        guard let getClosure = result else { return }
        for handler in completionHandlers! {
            handler(getClosure)
        }
        sync() { self.completionHandlers = nil }
    }
    
    open func add(completionHandler completion: @escaping (_ getObject: () throws -> T) -> Void) {
        if let getClosure = result {
            completion(getClosure)
        } else {
            sync() { self.completionHandlers?.append(completion) }
        }
    }
    
    open var debugDescription: String {
        return String(describing: self)
    }
}

private func sync(_ closure: @escaping () -> Void) {
    syncQueue.async(flags: .barrier, execute: closure)
}


open class URLSessionDataTaskRequest<T: Any>: Request<T> {
    
    var dataTask: URLSessionDataTask?
    
    override open func cancel() {
        Log.debug("Cancelling: \(dataTask?.originalRequest?.url?.absoluteString ?? "")")
        dataTask?.cancel()
        super.cancel()
    }
    
    override open var debugDescription: String {
        var desc = "URLRequest<\(T.self)>"
        if let url = dataTask?.originalRequest?.url {
            desc += "(\(url))"
        }
        return desc
    }
}
