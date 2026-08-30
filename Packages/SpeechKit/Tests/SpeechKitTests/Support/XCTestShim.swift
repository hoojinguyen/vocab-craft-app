#if !canImport(XCTest)
import Foundation

public struct XCTUnwrapError: Error {}

public final class XCTestExpectation {
    public let expectationDescription: String
    private var isFulfilled = false

    public init(description: String) {
        self.expectationDescription = description
    }

    public func fulfill() {
        isFulfilled = true
    }
}

@MainActor
open class XCTestCase {
    public init() {}
    open func setUp() {}
    open func tearDown() {}
    open func setUpWithError() throws {}
    open func tearDownWithError() throws {}
    open func setUp() async throws {}
    open func tearDown() async throws {}

    public func expectation(description: String) -> XCTestExpectation {
        XCTestExpectation(description: description)
    }

    public func wait(for expectations: [XCTestExpectation], timeout: TimeInterval) {}

    public func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {}
}

public func XCTUnwrap<T>(_ expression: @autoclosure () throws -> T?, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) throws -> T {
    let value = try expression()
    guard let unwrapped = value else {
        print("❌ XCTUnwrap failed [\(file):\(line)]: \(message)")
        throw XCTUnwrapError()
    }
    return unwrapped
}

public func XCTAssertEqual<T: Equatable>(_ a: @autoclosure () throws -> T, _ b: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        let valA = try a()
        let valB = try b()
        if valA != valB {
            print("❌ Assertion Failed [\(file):\(line)]: \(valA) != \(valB). \(message)")
        }
    } catch {
        print("❌ Assertion Error [\(file):\(line)]: \(error). \(message)")
    }
}

public func XCTAssertNotEqual<T: Equatable>(_ a: @autoclosure () throws -> T, _ b: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        let valA = try a()
        let valB = try b()
        if valA == valB {
            print("❌ Assertion Failed [\(file):\(line)]: \(valA) == \(valB). \(message)")
        }
    } catch {
        print("❌ Assertion Error [\(file):\(line)]: \(error). \(message)")
    }
}

public func XCTAssertEqual<T: FloatingPoint>(_ a: @autoclosure () throws -> T, _ b: @autoclosure () throws -> T, accuracy: T, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        let valA = try a()
        let valB = try b()
        if abs(valA - valB) > accuracy {
            print("❌ Assertion Failed [\(file):\(line)]: \(valA) != \(valB) within accuracy \(accuracy). \(message)")
        }
    } catch {
        print("❌ Assertion Error [\(file):\(line)]: \(error). \(message)")
    }
}

public func XCTAssertTrue(_ condition: @autoclosure () throws -> Bool, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        if try !condition() {
            print("❌ Assertion Failed [\(file):\(line)]: Expected true. \(message)")
        }
    } catch {
        print("❌ Assertion Error [\(file):\(line)]: \(error). \(message)")
    }
}

public func XCTAssertFalse(_ condition: @autoclosure () throws -> Bool, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        if try condition() {
            print("❌ Assertion Failed [\(file):\(line)]: Expected false. \(message)")
        }
    } catch {
        print("❌ Assertion Error [\(file):\(line)]: \(error). \(message)")
    }
}

public func XCTAssertNil(_ value: @autoclosure () throws -> Any?, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        if try value() != nil {
            print("❌ Assertion Failed [\(file):\(line)]: Expected nil. \(message)")
        }
    } catch {
        print("❌ Assertion Error [\(file):\(line)]: \(error). \(message)")
    }
}

public func XCTAssertNotNil(_ value: @autoclosure () throws -> Any?, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        if try value() == nil {
            print("❌ Assertion Failed [\(file):\(line)]: Expected not nil. \(message)")
        }
    } catch {
        print("❌ Assertion Error [\(file):\(line)]: \(error). \(message)")
    }
}

public func XCTAssertLessThan<T: Comparable>(_ a: @autoclosure () throws -> T, _ b: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        let valA = try a()
        let valB = try b()
        if valA >= valB {
            print("❌ Assertion Failed [\(file):\(line)]: \(valA) >= \(valB). \(message)")
        }
    } catch {
        print("❌ Assertion Error [\(file):\(line)]: \(error). \(message)")
    }
}

public func XCTAssertLessThanOrEqual<T: Comparable>(_ a: @autoclosure () throws -> T, _ b: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        let valA = try a()
        let valB = try b()
        if valA > valB {
            print("❌ Assertion Failed [\(file):\(line)]: \(valA) > \(valB). \(message)")
        }
    } catch {
        print("❌ Assertion Error [\(file):\(line)]: \(error). \(message)")
    }
}

public func XCTAssertGreaterThan<T: Comparable>(_ a: @autoclosure () throws -> T, _ b: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        let valA = try a()
        let valB = try b()
        if valA <= valB {
            print("❌ Assertion Failed [\(file):\(line)]: \(valA) <= \(valB). \(message)")
        }
    } catch {
        print("❌ Assertion Error [\(file):\(line)]: \(error). \(message)")
    }
}

public func XCTAssertGreaterThanOrEqual<T: Comparable>(_ a: @autoclosure () throws -> T, _ b: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    do {
        let valA = try a()
        let valB = try b()
        if valA < valB {
            print("❌ Assertion Failed [\(file):\(line)]: \(valA) < \(valB). \(message)")
        }
    } catch {
        print("❌ Assertion Error [\(file):\(line)]: \(error). \(message)")
    }
}

public func XCTFail(_ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    print("❌ XCTFail [\(file):\(line)]: \(message)")
}
#endif
