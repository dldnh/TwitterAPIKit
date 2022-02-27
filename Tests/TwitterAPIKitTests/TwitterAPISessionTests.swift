import XCTest

@testable import TwitterAPIKit

private class GetTwitterReqeust: TwitterAPIRequest {
    var method: HTTPMethod { return .get }
    var path: String { return "/get.json" }
    var parameters: [String: Any] {
        return ["hoge": "😀"]  //= %F0%9F%98%80
    }
}

private class PostTwitterReqeust: TwitterAPIRequest {
    var method: HTTPMethod { return .post }
    var path: String { return "/post.json" }
    var parameters: [String: Any] {
        return ["hoge": "😀"]  //= %F0%9F%98%80
    }
}

private class EmptyRequest: TwitterAPIRequest {
    var method: HTTPMethod { return .get }
    var path: String { return "/empty.json" }
    var parameters: [String: Any] {
        return [:]
    }
}

private class QueryAndBodyRequest: TwitterAPIRequest {
    var method: HTTPMethod { return .post }
    var path: String { return "/query_and_body.json" }

    var queryParameters: [String: Any] {
        return ["query": "value"]
    }

    var bodyParameters: [String: Any] {
        return ["body": "value"]
    }
}

class TwitterAPISessionTests: XCTestCase {

    lazy var session: TwitterAPISession =
        ({

            let config = URLSessionConfiguration.default
            config.protocolClasses = [MockURLProtocol.self]
            let urlSession = URLSession.init(configuration: config)

            return TwitterAPISession(
                auth: .oauth(consumerKey: "", consumerSecret: "", oauthToken: "", oauthTokenSecret: ""),
                configuration: config,
                environment: .init(
                    apiURL: URL(string: "https://api.example.com")!,
                    uploadURL: URL(string: "https://upload.example.com")!)
            )
        })()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGET() throws {

        MockURLProtocol.requestAssert = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/get.json?hoge=%F0%9F%98%80")
            XCTAssertNil(request.httpBody)
        }

        let exp = expectation(description: "")
        session.send(GetTwitterReqeust()).responseData(queue: .main) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }

    func testPOST() throws {
        MockURLProtocol.requestAssert = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/post.json")
            XCTAssertNil(request.httpBody)
            let data = try! Data(reading: request.httpBodyStream!)
            let body = String(data: data, encoding: .utf8)!
            XCTAssertEqual(body, "hoge=%F0%9F%98%80")
        }

        let exp = expectation(description: "")
        session.send(PostTwitterReqeust()).responseData(queue: .main) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }

    func testEmpty() throws {
        MockURLProtocol.requestAssert = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/empty.json")
            XCTAssertNil(request.httpBody)
        }

        let exp = expectation(description: "")
        session.send(EmptyRequest()).responseData(queue: .main) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }

    func testQueryAndBody() throws {
        MockURLProtocol.requestAssert = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/query_and_body.json?query=value")
            XCTAssertNil(request.httpBody)
            let data = try! Data(reading: request.httpBodyStream!)
            let body = String(data: data, encoding: .utf8)!
            XCTAssertEqual(body, "body=value")
        }

        let exp = expectation(description: "")
        session.send(QueryAndBodyRequest()).responseData(queue: .main) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
}

extension Data {
    init(reading input: InputStream) throws {
        self.init()
        input.open()
        defer {
            input.close()
        }

        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            if read < 0 {
                //Stream error occured
                throw input.streamError!
            } else if read == 0 {
                //EOF
                break
            }
            self.append(buffer, count: read)
        }
    }
}
