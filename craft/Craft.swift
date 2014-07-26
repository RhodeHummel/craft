//
//  Craft.swift
//  craft
//
//  Created by Tommy Leung on 6/28/14.
//  Copyright (c) 2014 Tommy Leung. All rights reserved.
//

import Foundation

public typealias Result = (value: Any?) -> Any?
public typealias Action = (resolve: (value: Any?) -> (), reject: (value: Any?) -> ()) -> ()

public class Craft
{
    /**
     * creates a Promise
     * You generally want to use the constructor that takes an Action closure
     * @return Promise
     */
    public class func promise() -> Promise
    {
        return promise(nil)
    }
    
    /**
     * creates a Promise with an Action closure that is passed in the resolve
     * and reject closures as parameters; work here should be done asynchronously
     * and resolved or rejected as necessary
     *
     * @return Promise
     */
    public class func promise(action: Action?) -> Promise
    {
        let d = Deferred.create()
        
        let q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_async(q, {
            
            dispatch_sync(dispatch_get_main_queue(), {
                if let a = action
                {
                    a(resolve: d.resolve, reject: d.reject)
                }
            })
        })
        
        return d.promise;
    }
    
    /**
     * Executes an array of promises and rejects immediately with any of them fail
     * The returned promise will resolve once all the promises in the array are resolved
     * The results will be stored in the data property of a BulkResult object; the
     * results will be in the same order as the array of promises
     * @return Promise
     */
    public class func all(promises: [Promise]) -> Promise
    {
        let d = Deferred.create()
        
        var results: [Any?] = Array()
        let count = promises.count
        var fulfilled = 0
        
        func attach(promise: Promise, index: Int) -> ()
        {
            promise.then({
                (value: Any?) -> Any? in
                
                results[index] = value
                ++fulfilled
                
                if (fulfilled >= count)
                {
                    d.resolve(results)
                }
                
                return nil
            }, reject: {
                (value: Any?) -> Any? in
                
                d.reject(value)
                
                return nil
            })
        }
        
        for var i = 0; i < count; ++i
        {
            results.append(nil)
            let promise = promises[i]
            
            attach(promise, i)
        }
        
        return d.promise
    }
    
    /**
     * Executes an array of Promises and results in an array of results
     * from each executed Promise after all Promises have been resolved
     * or rejected
     * @return Promise
     */
    public class func allSettled(promises: [Promise]) -> Promise
    {
        let d = Deferred.create()
        
        var results: [Any?] = Array()
        let count = promises.count
        var fulfilled = 0
        
        func attach(promise: Promise, index: Int) -> ()
        {
            func response(value: Any?) -> Any?
            {
                ++fulfilled
                
                if (fulfilled >= count)
                {
                    d.resolve(results)
                }
                
                return nil
            }
            
            promise.then({
                (value: Any?) -> Any? in
                
                let res = SettledResult(state: PromiseState.FULFILLED, value: value)
                results[index] = res
                
                return response(value)
            }, reject: {
                (value: Any?) -> Any? in
                
                let res = SettledResult(state: PromiseState.REJECTED, value: value)
                results[index] = res
                
                return response(value)
            })
        }
        
        for var i = 0; i < count; ++i
        {
            results.append(nil)
            let promise = promises[i]
            
            attach(promise, i)
        }
        
        return d.promise
    }
}