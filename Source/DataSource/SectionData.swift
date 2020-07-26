//
//  SectionData.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/25.
//

import Foundation

extension CollectionView {
	@usableFromInline
	struct SectionData<ItemIdentifier> {
		@usableFromInline
		let anySection: AnyHashable
		
		@inline(__always)
		@usableFromInline
		func section<Section>() -> Section {
			if let section = anySection as? Section {
				return section
			} else if let section = anySection.base as? Section {
				return section
			} else {
				fatalError("wtf are you doing")
			}
		}
		@inline(__always)
		@usableFromInline
		func trySection<Section>() -> Section? {
			anySection.base as? Section
		}
		@usableFromInline
		var items: [ItemData<ItemIdentifier>]
		@usableFromInline
		init<Section>(sectionIdentifier: Section, items: [ItemData<ItemIdentifier>] = []) where Section: Hashable {
			self.anySection = .package(sectionIdentifier)
			self.items = items
		}
		@usableFromInline
		init(anySectionIdentifier: AnyHashable) {
			self.anySection = anySectionIdentifier
			self.items = []
		}
	}
}
