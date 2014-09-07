//
//  RavenConfigTests.swift
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 06.09.14.
//  Copyright (c) 2014 OKB. All rights reserved.
//

import XCTest

class RavenConfigTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSetDSNWithPort()
    {
        var config = RavenConfig()
        let didParse = config.setDSN("http://public_key:secret_key@example.com:8000/project-id")
        
        XCTAssert(didParse, "Failed to parse DSN")
        
        XCTAssert(config.publicKey! == "public_key", "Got incorrect publicKey \(config.publicKey!)")
        XCTAssert(config.secretKey! == "secret_key", "Got incorrect secretKey \(config.secretKey!)")
        XCTAssert(config.projectId! == "project-id", "Got incorrect projectId \(config.projectId!)")
        
        let expectedURL = "http://example.com:8000/api/project-id/store/"
        
        XCTAssert(config.serverUrl!.absoluteString! == expectedURL, "Got incorrect serverURL \(config.serverUrl!.absoluteString!)")
    }
    
    func testSetDSNWithSSLPortUndefined()
    {
        
        var config = RavenConfig()
        let didParse = config.setDSN("https://public_key:secret_key@example.com/project-id")
        
        XCTAssert(didParse, "Failed to parse DSN")
        
        XCTAssert(config.publicKey! == "public_key", "Got incorrect publicKey \(config.publicKey!)")
        XCTAssert(config.secretKey! == "secret_key", "Got incorrect secretKey \(config.secretKey!)")
        XCTAssert(config.projectId! == "project-id", "Got incorrect projectId \(config.projectId!)")

        
        let expectedURL = "https://example.com:443/api/project-id/store/"
        
        XCTAssert(config.serverUrl!.absoluteString! == expectedURL, "Got incorrect serverURL \(config.serverUrl!.absoluteString!)")

        
    }
    
    func testSetDSNWithoutSSLPortUndefined()
    {
        
        var config = RavenConfig()
        let didParse = config.setDSN("http://public_key:secret_key@example.com/project-id")
        
        XCTAssert(didParse, "Failed to parse DSN")
        
        XCTAssert(config.publicKey! == "public_key", "Got incorrect publicKey \(config.publicKey!)")
        XCTAssert(config.secretKey! == "secret_key", "Got incorrect secretKey \(config.secretKey!)")
        XCTAssert(config.projectId! == "project-id", "Got incorrect projectId \(config.projectId!)")

        
        let expectedURL = "http://example.com:80/api/project-id/store/"
        
        XCTAssert(config.serverUrl!.absoluteString! == expectedURL, "Got incorrect serverURL \(config.serverUrl!.absoluteString!)")
        
    }
}
