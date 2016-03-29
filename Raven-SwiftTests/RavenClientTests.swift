//
//  RavenClientTests.swift
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 06.09.14.
//

import XCTest
@testable import Raven

let testDSN = "http://public:secret@example.com/foo"

class MockRavenClient : RavenClient {
    var lastEvent: [String: AnyObject] = [:]
    var numEvents = 0

    override func sendDictionary(dict: [String : AnyObject]) {
        lastEvent = dict
        numEvents++
    }
}


class RavenClientTests: XCTestCase {

    var client: MockRavenClient!

    override func setUp() {
        client = MockRavenClient()
        client.setDSN(testDSN)
    }

    func testSetDSNWithPort() {
        let testClient = MockRavenClient()
        testClient.setDSN("http://public_key:secret_key@example.com:8000/project-id")

        if let auth = testClient.auth {
            XCTAssert(auth.publicKey == "public_key", "Got incorrect publicKey \(auth.publicKey)")
            XCTAssert(auth.privateKey == "secret_key", "Got incorrect secretKey \(auth.privateKey)")
            XCTAssert(auth.projectID == "project-id", "Got incorrect projectId \(auth.projectID)")

            let expectedURL = "http://example.com:8000/api/project-id/store/"

            XCTAssert(auth.serverURL.absoluteString == expectedURL, "Got incorrect serverURL \(auth.serverURL.absoluteString)")
        } else {
            XCTFail("Auth attribute was nil, setDSN failed.")
        }
    }

    func testSetDSNWithSSLPortUndefined() {
        let testClient = MockRavenClient()
        testClient.setDSN("https://public_key:secret_key@example.com/project-id")

        if let auth = testClient.auth {
            XCTAssert(auth.publicKey == "public_key", "Got incorrect publicKey \(auth.publicKey)")
            XCTAssert(auth.privateKey == "secret_key", "Got incorrect secretKey \(auth.privateKey)")
            XCTAssert(auth.projectID == "project-id", "Got incorrect projectId \(auth.projectID)")

            let expectedURL = "https://example.com:443/api/project-id/store/"

            XCTAssert(auth.serverURL.absoluteString == expectedURL, "Got incorrect serverURL \(auth.serverURL.absoluteString)")
        } else {
            XCTFail("Auth attribute was nil, setDSN failed.")
        }
    }

    func testSetDSNWithoutSSLPortUndefined() {
        let testClient = MockRavenClient()
        testClient.setDSN("http://public_key:secret_key@example.com/project-id")

        if let auth = testClient.auth {
            XCTAssert(auth.publicKey == "public_key", "Got incorrect publicKey \(auth.publicKey)")
            XCTAssert(auth.privateKey == "secret_key", "Got incorrect secretKey \(auth.privateKey)")
            XCTAssert(auth.projectID == "project-id", "Got incorrect projectId \(auth.projectID)")

            let expectedURL = "http://example.com:80/api/project-id/store/"

            XCTAssert(auth.serverURL.absoluteString == expectedURL, "Got incorrect serverURL \(auth.serverURL.absoluteString)")
        } else {
            XCTFail("Auth attribute was nil, setDSN failed.")
        }
    }

    func testSetDSNWithoutAuthentication() {
        let testClient = MockRavenClient()
        testClient.setDSN("https://example.com/project-id")

        if let auth = testClient.auth {
            let expectedURL = "https://example.com:443/api/project-id/store/"
            XCTAssert(auth.serverURL.absoluteString == expectedURL, "Got incorrect serverURL \(auth.serverURL.absoluteString)")

            XCTAssertEqual(auth.publicKey, "", "Got incorrect publicKey \(auth.publicKey)")
            XCTAssertEqual(auth.privateKey, "", "Got incorrect secretKey \(auth.privateKey)")
        } else {
            XCTFail("Auth attribute was nil, setDSN failed.")
        }
    }

    func testSetDSNWithBlankURL() {
        let testClient = MockRavenClient()
        testClient.setDSN("")
        
        XCTAssertNil(testClient.auth, "The config initialized")
    }


    func testGenerateUUID() {
        let uuid = client.generateUUID()
        XCTAssert(uuid.characters.count == 32 , "Invalid value for UUID returned: \(uuid)")
    }

    func testCaptureMessageWithOnlyMessage() {
        if let auth = client.auth {
            let testMessage = "An example message"
            client.captureMessage(testMessage)
            let lastEvent = client.lastEvent

            XCTAssertNotNil(lastEvent["event_id"], "Missing event_id")
            XCTAssertNotNil(lastEvent["message"], "Missing message")
            XCTAssertNotNil(lastEvent["project"], "Missing project")
            XCTAssertNotNil(lastEvent["level"], "Missing level")
            XCTAssertNotNil(lastEvent["timestamp"], "Missing timestamp")
            XCTAssertNotNil(lastEvent["platform"], "Missing platform")

            if let message = lastEvent["message"] as? String {
                XCTAssertEqual(message, testMessage, "Invalid value for message: \(message)")
            } else {
                XCTFail("The message was not a string")
            }

            if let project = lastEvent["project"] as? String {
                XCTAssertEqual(project, auth.projectID, "Invalid value for project: \(project)")
            } else {
                XCTFail("The project was not a string")
            }

            if let level = lastEvent["level"] as? String {
                XCTAssertEqual(level, "info", "Invalid value for level: \(level) ")
            } else {
                XCTFail("The level was not a string")
            }

            if let platform = lastEvent["platform"] as? String {
                XCTAssertEqual(platform, "swift", "Invalid value for platform: \(platform)")
            } else {
                XCTFail("Platform was not a string")
            }
        } else {
            XCTFail("Auth attribute was nil, setDSN failed.")
        }
    }

    func testCaptureMessageWithMessageAndLevel() {
        if let auth = client.auth {
            let testMessage = "An example message"
            let testLevel = RavenClient.LogLevel.Warning
            client.captureMessage(testMessage, level: testLevel)
            let lastEvent = client.lastEvent

            XCTAssertNotNil(lastEvent["event_id"], "Missing event_id")
            XCTAssertNotNil(lastEvent["message"], "Missing message")
            XCTAssertNotNil(lastEvent["project"], "Missing project")
            XCTAssertNotNil(lastEvent["level"], "Missing level")
            XCTAssertNotNil(lastEvent["timestamp"], "Missing timestamp")
            XCTAssertNotNil(lastEvent["platform"], "Missing platform")


            if let message = lastEvent["message"] as? String {
                XCTAssertEqual(message, testMessage, "Invalid value for message: \(message)")
            } else {
                XCTFail("Message was not a string")
            }

            if let project = lastEvent["project"] as? String {
                XCTAssertEqual(project, auth.projectID, "Invalid value for project: \(project)")
            } else {
                XCTFail("Project was not a string")
            }

            if let level = lastEvent["level"] as? String {
                XCTAssertEqual(level, testLevel.description, "Invalid value for level: \(level)")
            } else {
                XCTFail("Warning was not a string")
            }

            if let platform = lastEvent["platform"] as? String {
                XCTAssertEqual(platform, "swift", "Invalid value for platform: \(platform)")
            } else {
                XCTFail("Platform was not a string")
            }
        } else {
            XCTFail("Auth attribute was nil, setDSN failed.")
        }
    }


    func testCaptureMessageWithMessageAndLevelAndMethodAndFileAndLine() {
        if let auth = client.auth {
            let testMessage = "An example message"
            let testLevel = RavenClient.LogLevel.Warning
            let testMethod = "method name"
            let testFile = "filename"
            let testLine = 34

            client.captureMessage(testMessage, level: testLevel, method: testMethod, file: testFile, line: testLine)
            let lastEvent = client.lastEvent

            XCTAssertNotNil(lastEvent["event_id"], "Missing event_id")
            XCTAssertNotNil(lastEvent["message"], "Missing message")
            XCTAssertNotNil(lastEvent["project"], "Missing project")
            XCTAssertNotNil(lastEvent["level"], "Missing level")
            XCTAssertNotNil(lastEvent["timestamp"], "Missing timestamp")
            XCTAssertNotNil(lastEvent["platform"], "Missing platform")
            XCTAssertNotNil(lastEvent["stacktrace"], "Missing stacktrace")

            if let message = lastEvent["message"] as? String {
                XCTAssertEqual(message, testMessage, "Invalid value for message: \(message)")
            } else {
                XCTFail("Message was not a string")
            }

            if let project = lastEvent["project"] as? String {
                XCTAssertEqual(project, auth.projectID, "Invalid value for project: \(project)")
            } else {
                XCTFail("Project was not a string")
            }

            if let level = lastEvent["level"] as? String {
                XCTAssertEqual(level, testLevel.description, "Invalid value for level: \(level)")
            } else {
                XCTFail("Warning was not a string")
            }

            if let platform = lastEvent["platform"] as? String {
                XCTAssertEqual(platform, "swift", "Invalid value for platform: \(platform)")
            } else {
                XCTFail("Platform was not a string")
            }
        } else {
            XCTFail("Auth attribute was nil, setDSN failed.")
        }
    }

    func testCaptureMessageWithMessageAndLevelAndExtraAndTags() {
        if let auth = client.auth {
            let testMessage = "An example message"
            let testLevel = RavenClient.LogLevel.Warning

            client.captureMessage(testMessage, level: testLevel, additionalExtra:["key" : "extra value"], additionalTags:["key" : "tag value", "bool": true, "number": 42])
            let lastEvent = client.lastEvent

            XCTAssertNotNil(lastEvent["event_id"], "Missing event_id")
            XCTAssertNotNil(lastEvent["message"], "Missing message")
            XCTAssertNotNil(lastEvent["project"], "Missing project")
            XCTAssertNotNil(lastEvent["level"], "Missing level")
            XCTAssertNotNil(lastEvent["timestamp"], "Missing timestamp")
            XCTAssertNotNil(lastEvent["platform"], "Missing platform")
            XCTAssertNotNil(lastEvent["extra"], "Missing extra")
            XCTAssertNotNil(lastEvent["tags"], "Missing tags")

            if let message = lastEvent["message"] as? String {
                XCTAssertEqual(message, testMessage, "Invalid value for message: \(message)")
            } else {
                XCTFail("Message was not a string")
            }

            if let project = lastEvent["project"] as? String {
                XCTAssertEqual(project, auth.projectID, "Invalid value for project: \(project)")
            } else {
                XCTFail("Project was not a string")
            }

            if let level = lastEvent["level"] as? String {
                XCTAssertEqual(level, testLevel.description, "Invalid value for level: \(level)")
            } else {
                XCTFail("Warning was not a string")
            }

            if let platform = lastEvent["platform"] as? String {
                XCTAssertEqual(platform, "swift", "Invalid value for platform: \(platform)")
            } else {
                XCTFail("Platform was not a string")
            }
        } else {
            XCTFail("The client was nil")
        }
    }

    func testClientWithExtraAndTags() {
        let firstKey = "key"
        let secondKey = "key2"
        let extraValue = "extraValue"
        let tagValue = "tagValue"

        let tagsIntegerKey = "number"
        let tagsIntegerValue = 42

        let tagsBoolKey = "bool"
        let tagsBoolValue = false

        let testMessage = "An example message"
        let testLevel = RavenClient.LogLevel.Warning

        let clientWithExtraAndTags = MockRavenClient()
        clientWithExtraAndTags.setDSN(testDSN)
        clientWithExtraAndTags.extra = [firstKey: extraValue]
        clientWithExtraAndTags.tags = [firstKey: tagValue]

        let additionalTags: [String: AnyObject] = [secondKey: tagValue, tagsIntegerKey: tagsIntegerValue, tagsBoolKey: tagsBoolValue]
        clientWithExtraAndTags.captureMessage(testMessage, level: testLevel, additionalExtra: [secondKey: extraValue], additionalTags: additionalTags)

        let lastEvent = clientWithExtraAndTags.lastEvent

        XCTAssertNotNil(lastEvent["extra"], "Missing extra")
        XCTAssertNotNil(lastEvent["tags"], "Missing tags")

        if let extra = lastEvent["extra"] as? [String: AnyObject] {
            if let extraValueForKey = extra[firstKey] as? String {
                XCTAssertEqual(extraValueForKey, extraValue, "Missing extra data")
            } else {
                XCTFail("First extra data could not be converted to a string")
            }

            if let extraValueForKey2 = extra[secondKey] as? String {
                XCTAssertEqual(extraValueForKey2, extraValue, "Missing extra data")
            } else {
                XCTFail("Second extra data could not be converted to a string")
            }
        } else {
            XCTFail("Could not parse the extra information")
        }

        if let tags = lastEvent["tags"] as? [String: AnyObject] {
            if let tagValueForKey = tags[firstKey] as? String {
                XCTAssertEqual(tagValueForKey, tagValue, "Missing tags data")
            } else {
                XCTFail("First tag data could not be converted to a string")
            }

            if let tagValueForKey2 = tags[secondKey] as? String {
                XCTAssertEqual(tagValueForKey2, tagValue, "Missing tags data")
            } else {
                XCTFail("Second tag data could not be converted to a string")
            }

            if let tagsIntegerKeyValue = tags[tagsIntegerKey] as? Int {
                XCTAssertEqual(tagsIntegerKeyValue, tagsIntegerValue, "Missin tags data")
            } else {
                XCTFail("Tags number key value could not be converted to an Int")
            }

            if let tagsBoolKeyValue = tags[tagsBoolKey] as? Bool {
                XCTAssertEqual(tagsBoolKeyValue, tagsBoolValue, "Missin tags data")
            } else {
                XCTFail("Tags bool key value could not be converted to a Bool")
            }

            XCTAssertNotNil(tags["OS version"], "Missing tags data (OS Version)")
            XCTAssertNotNil(tags["Device model"], "Missing tags data (Device Model)")
        } else {
            XCTFail("Could not parse the tag information")
        }
    }

    func testClientWithRewritingExtraAndTags() {
        let key = "key"
        let extraValue = "extraValue"
        let secondExtraValue = "AnotherExtraValue"
        let tagValue = "tagValue"
        let secondTagValue = "AnotherTagValue"

        let testMessage = "An example message"
        let testLevel = RavenClient.LogLevel.Warning

        let clientWithExtraAndTags = MockRavenClient()
        clientWithExtraAndTags.setDSN(testDSN)
        clientWithExtraAndTags.extra = [key: extraValue]
        clientWithExtraAndTags.tags = [key: tagValue]

        clientWithExtraAndTags.captureMessage(testMessage, level: testLevel, additionalExtra: [key: secondExtraValue], additionalTags:[key: secondTagValue])

        let lastEvent = clientWithExtraAndTags.lastEvent

        XCTAssertNotNil(lastEvent["extra"], "Missing extra")
        XCTAssertNotNil(lastEvent["tags"], "Missing tags")

        if let extra = lastEvent["extra"] as? [String: AnyObject] {
            if let extraValueForKey = extra[key] as? String {
                XCTAssertEqual(extraValueForKey, secondExtraValue, "Incorrect extra data")
                XCTAssertNotEqual(extraValueForKey, extraValue, "Extra data was not rewritten")
            } else {
                XCTFail("First extra data could not be converted to a string")
            }
        } else {
            XCTFail("Could not parse the extra information")
        }

        if let tags = lastEvent["tags"] as? [String: AnyObject] {
            if let tagValueForKey = tags[key] as? String {
                XCTAssertEqual(tagValueForKey, secondTagValue, "Incorrect tags data")
                XCTAssertNotEqual(tagValueForKey, tagValue, "Tag data was not rewritten")
            } else {
                XCTFail("First tag data could not be converted to a string")
            }

            XCTAssertNotNil(tags["OS version"], "Missing tags data (OS Version)")
            XCTAssertNotNil(tags["Device model"], "Missing tags data (Device Model)")
        } else {
            XCTFail("Could not parse the tag information")
        }
    }

    func testClientWithLogger() {
        let testMessage = "An example message"
        let loggerValue = "Logger value"
        let clientWithExtraAndTags = MockRavenClient()
        clientWithExtraAndTags.setDSN(testDSN)
        clientWithExtraAndTags.extra = ["key" : "value"]
        clientWithExtraAndTags.tags = ["key" : "value"]
        clientWithExtraAndTags.logger = loggerValue

        clientWithExtraAndTags.captureMessage(testMessage)

        let lastEvent = clientWithExtraAndTags.lastEvent

        if let message = lastEvent["message"] as? String {
            XCTAssertEqual(message, testMessage, "Incorrect value for message \(message)")
        } else {
            XCTFail("Message was not a string")
        }

        if let logger = lastEvent["logger"] as? String {
            XCTAssertEqual(logger, loggerValue, "Incorrect valid for the logger \(logger)")
        } else {
            XCTFail("Logger was not a string")
        }
    }
}
