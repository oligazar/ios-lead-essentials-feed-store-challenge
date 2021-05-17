//
//  ManagedCache.swift
//  FeedStoreChallenge
//
//  Created by Alexander on 17/5/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

@objc(ManagedCache)
class ManagedCache: NSManagedObject {
	@NSManaged var timestamp: Date
	@NSManaged var feed: NSOrderedSet
}

extension ManagedCache {
	static func newUniqueInstance(context: NSManagedObjectContext) throws -> ManagedCache {
		try find(in: context).map(context.delete)

		return ManagedCache(context: context)
	}

	var localFeed: [LocalFeedImage] {
		return feed.compactMap { ($0 as? ManagedFeedImage)?.local }
	}

	static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
		guard let entityName = ManagedCache.entity().name else { return nil }
		let request = NSFetchRequest<ManagedCache>(entityName: entityName)

		return try context.fetch(request).first
	}
}
