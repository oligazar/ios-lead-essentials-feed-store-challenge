//
//  ManagedCache.swift
//  FeedStoreChallenge
//
//  Created by Alexander on 6/5/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

@objc(ManagedCache)
internal class ManagedCache: NSManagedObject {
	@NSManaged var timestamp: Date
	@NSManaged var feed: NSOrderedSet
}

extension ManagedCache {
	
	internal static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
		guard let entityName = ManagedCache.entity().name else { return nil }
		let request = NSFetchRequest<ManagedCache>(entityName: entityName)
		request.returnsDistinctResults = false

		return try context.fetch(request).first
	}
	
	internal var localFeed: [LocalFeedImage] {
		return feed.compactMap { ($0 as? ManagedFeedImage)?.local }
	}
	
	internal static func newUniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
		try find(in: context).map(context.delete)
		
		return ManagedCache(context: context)
	}
}
