//
//  XCTestCase+MemoryLeakTracking.swift
//  Tests
//
//  Created by Alexander on 6/5/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest

extension XCTestCase {
	
	internal func trackMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance \(String(describing: instance)) should've been dallocated. Potential memory leak", file: file, line: line)
		}
	}
	
}
