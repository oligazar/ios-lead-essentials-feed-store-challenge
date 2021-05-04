//
//  CoreDataFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Alexander on 4/5/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

public class CoreDataFeedStore: FeedStore {
	private let container: NSPersistentContainer
	private let context: NSManagedObjectContext
	
	public init(bundle: Bundle) throws {
		container = try NSPersistentContainer.load(modelName: "FeedStore", in: bundle)
		context = container.newBackgroundContext()
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let context = self.context
		context.perform {
			do {
				let cache = ManagedCache(context: context)
				cache.timestamp = timestamp
				let managedFeed: [ManagedFeedImage] = feed.map { local in
					let managed = ManagedFeedImage(context: context)
					managed.id = local.id
					managed.imageDescription = local.description
					managed.location = local.location
					managed.url = local.url
					return managed
				}
				cache.feed = NSOrderedSet(array: managedFeed)
				try context.save()
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		let context = self.context
		context.perform {
			do {
				let request = NSFetchRequest<ManagedCache>(entityName: "ManagedCache")
				request.returnsDistinctResults = false
				guard let cache = try context.fetch(request).first else {
					return completion(.empty)
				}
				let feed = cache.feed.compactMap { ($0 as? ManagedFeedImage)?.local }
				completion(.found(feed: feed, timestamp: cache.timestamp))
			} catch {
				completion(.failure(error))
			}
		}
	}
	
}

@objc(ManagedCache)
class ManagedCache: NSManagedObject {
	@NSManaged var timestamp: Date
	@NSManaged var feed: NSOrderedSet
}

@objc(ManagedFeedImage)
class ManagedFeedImage: NSManagedObject {
	@NSManaged var id: UUID
	@NSManaged var imageDescription: String?
	@NSManaged var location: String?
	@NSManaged var url: URL
	@NSManaged var cache: ManagedCache
	
	internal var local: LocalFeedImage {
		return LocalFeedImage(id: id, description: imageDescription, location: location, url: url)
	}
}

private extension NSPersistentContainer {
	
	enum LoadingError: Swift.Error {
		case modelNotFound
		case failedToLoadPersistentStores(Swift.Error)
	}
	
	static func load(modelName name: String, in bundle: Bundle) throws -> NSPersistentContainer {
		guard let model = NSManagedObjectModel.with(name, in: bundle) else {
			throw LoadingError.modelNotFound
		}
		
		let container = NSPersistentContainer.init(name: name, managedObjectModel: model)
		
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
