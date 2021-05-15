//
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
	private static let modelName = "FeedStore"
	private static let model = NSManagedObjectModel(name: modelName, in: Bundle(for: CoreDataFeedStore.self))

	private let container: NSPersistentContainer
	private let context: NSManagedObjectContext

	struct ModelNotFound: Error {
		let modelName: String
	}

	public init(storeURL: URL) throws {
		guard let model = CoreDataFeedStore.model else {
			throw ModelNotFound(modelName: CoreDataFeedStore.modelName)
		}

		container = try NSPersistentContainer.load(
			name: CoreDataFeedStore.modelName,
			model: model,
			url: storeURL
		)
		context = container.newBackgroundContext()
	}

	public func retrieve(completion: @escaping RetrievalCompletion) {
		perform { context in
			do {
				let request = NSFetchRequest<ManagedCache>(entityName: "ManagedCache")
				if let managedCache = try context.fetch(request).first {
					let localFeed: [LocalFeedImage] = managedCache.feed.map { managed in
						let xxx = managed as! ManagedFeedImage
						let local = LocalFeedImage(id: xxx.id, description: xxx.imageDescription, location: xxx.location, url: xxx.url)
						return local
					}
					completion(.found(feed: localFeed, timestamp: managedCache.timestamp))

				} else {
					completion(.empty)
				}
			} catch {
				completion(.failure(error))
			}
		}
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		perform { context in
			do {
				let managedFeed: [ManagedFeedImage] = feed.map { image in
					let managedImage = ManagedFeedImage(context: context)
					managedImage.id = image.id
					managedImage.imageDescription = image.description
					managedImage.location = image.location
					managedImage.url = image.url
					return managedImage
				}
				let cache = ManagedCache(context: context)
				cache.timestamp = timestamp
				cache.feed = NSOrderedSet(array: managedFeed)
				try context.save()

				completion(nil)
			} catch {
				completion(error)
			}
		}
	}

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		fatalError("Must be implemented")
	}

	private func perform(completion: @escaping (NSManagedObjectContext) -> Void) {
		let context = self.context
		context.perform {
			completion(context)
		}
	}
}

@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
	@NSManaged var timestamp: Date
	@NSManaged var feed: NSOrderedSet
}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
	@NSManaged var id: UUID
	@NSManaged var imageDescription: String?
	@NSManaged var location: String?
	@NSManaged var url: URL
	@NSManaged var cache: ManagedCache
}
