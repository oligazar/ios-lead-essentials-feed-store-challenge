//
//  CoreDataHelpers.swift
//  FeedStoreChallenge
//
//  Created by Alexander on 6/5/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

internal extension NSPersistentContainer {
	
	enum LoadingError: Swift.Error {
		case modelNotFound
		case failedToLoadPersistentStores(Swift.Error)
	}
	
	static func load(modelName name: String, url: URL, in bundle: Bundle) throws -> NSPersistentContainer {
		guard let model = NSManagedObjectModel.with(name, in: bundle) else {
			throw LoadingError.modelNotFound
		}
		
		let description = NSPersistentStoreDescription(url: url)
		let container = NSPersistentContainer.init(name: name, managedObjectModel: model)
		container.persistentStoreDescriptions = [description]
		var loadError: Swift.Error?
		container.loadPersistentStores { loadError = $1 }
		try loadError.map {
			throw LoadingError.failedToLoadPersistentStores($0)
		}
		return container
	}
}

private extension NSManagedObjectModel {
	static func with(_ name: String, in bundle: Bundle) -> NSManagedObjectModel? {
		bundle
			.url(forResource: name, withExtension: "momd")
			.flatMap { NSManagedObjectModel(contentsOf: $0) }
	}
}
