//
//  RavenConfig.swift
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 03.09.14.
//

import Foundation

public class RavenConfig {
    let serverUrl: NSURL!
    let publicKey: String!
    let secretKey: String!
    let projectId: String!
    
    public init? (DSN : String) {
        if let DSNURL = NSURL(string: DSN), host = DSNURL.host {
            var pathComponents = DSNURL.pathComponents!
            
            pathComponents.removeAtIndex(0) // always remove the first slash
            
            if let projectId = pathComponents.last {
                self.projectId = projectId
                
                pathComponents.removeLast() // remove the project id...
                
                var path = pathComponents.joinWithSeparator("/")  // ...and construct the path again
                
                // Add a slash to the end of the path if there is a path
                if (path != "") {
                    path += "/"
                }
                
                let scheme: String = DSNURL.scheme ?? "http"
                
                var port = DSNURL.port
                if (port == nil) {
                    if (DSNURL.scheme == "https") {
                        port = 443;
                    } else {
                        port = 80;
                    }
                }
                
                //Setup the URL
                serverUrl = NSURL(string: "\(scheme)://\(host):\(port!)\(path)/api/\(projectId)/store/")
                
                //Set the public and secret keys if the exist
                publicKey = DSNURL.user ?? ""
                secretKey = DSNURL.password ?? ""
                
                return
            }
        }
        
        //The URL couldn't be parsed, so initialize to blank values and return nil
        serverUrl = NSURL()
        publicKey = ""
        secretKey = ""
        projectId = ""
        
        return nil
    }
}
