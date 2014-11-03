//
//  RavenConfig.swift
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 03.09.14.
//

import Foundation

class RavenConfig {
    let serverUrl : NSURL!
    let publicKey : String!
    let secretKey : String!
    let projectId : String!
    
    init? (DSN : String) {
        let DSNURL = NSURL(string: DSN)
        if DSNURL?.host == nil{
            return nil
        }
        
        var pathComponents = DSNURL!.pathComponents as [String]
        
        if (pathComponents.count == 0)
        {
            println("Missing path")
            return nil
        }
        
        pathComponents.removeAtIndex(0) // always remove the first slash
        
        projectId = pathComponents.last // project id is the last element of the path
        
        if projectId == nil{
            return nil
        }
        
        pathComponents.removeLast() // remove the project id...
       
        var path = "/".join(pathComponents)  // ...and construct the path again
        
        // Add a slash to the end of the path if there is a path
        if (path != "") {
            path += "/"
        }
        
        var scheme: String = DSNURL!.scheme ?? "http"
        
        var port = DSNURL!.port
        if (port == nil) {
            if (DSNURL!.scheme == "https") {
                port = 443;
            } else {
                port = 80;
            }
        }
        
        serverUrl = NSURL(string:"\(scheme)://\(DSNURL!.host!):\(port!)\(path)/api/\(projectId!)/store/")
        publicKey = DSNURL!.user
        secretKey = DSNURL!.password
    }
}
