//
//  UICollectionView+Extensions.swift
//  DeepDiff
//
//  Created by Khoa Pham.
//  Copyright © 2018 Khoa Pham. All rights reserved.
//

import UIKit

public extension UICollectionView {

  /// Animate reload in a batch update
  ///
  /// - Parameters:
  ///   - changes: The changes from diff
  ///   - section: The section that all calculated IndexPath belong
  ///   - updateData: Update your data source model
  ///   - completion: Called when operation completes
  public func reloadItems<T: DiffAware>(
    changes: [Change<T>],
    section: Int = 0,
    updateData: () -> Void,
    completion: ((Bool) -> Void)? = nil) {

    let changesWithIndexPath = IndexPathConverter.convert(changes: changes, section: section)

    performBatchUpdates({
      updateData()
      insideItemsUpdate(changesWithIndexPath: changesWithIndexPath)
    }, completion: { finished in
      completion?(finished)
    })

    // reloadRows needs to be called outside the batch
    outsideItemsUpdate(changesWithIndexPath: changesWithIndexPath)
  }

  // MARK: - Helper

  private func insideItemsUpdate(changesWithIndexPath: ChangeWithIndexPath) {
    changesWithIndexPath.deletes.executeIfPresent {
      deleteItems(at: $0)
    }

    changesWithIndexPath.inserts.executeIfPresent {
      insertItems(at: $0)
    }

    changesWithIndexPath.moves.executeIfPresent {
      $0.forEach { move in
        moveItem(at: move.from, to: move.to)
      }
    }
  }

  private func outsideItemsUpdate(changesWithIndexPath: ChangeWithIndexPath) {
    changesWithIndexPath.replaces.executeIfPresent {
      self.reloadItems(at: $0)
    }
  }
}

public struct Section<T: DiffAware, U: DiffAware>: DiffAware {
  public let id: T
  public var items: [U]

  public init(id: T, items: [U]) {
    self.id = id
    self.items = items
  }

  public var diffId: Int { return id.diffId }

  public static func compareContent(_ a: Section, _ b: Section) -> Bool {
    return T.compareContent(a.id, b.id) &&
      a.items.count == b.items.count &&
      a.items.enumerated().allSatisfy { U.compareContent($0.element, b.items[$0.offset]) }
  }
}

public extension UICollectionView {

  // Reload sections
  public func reloadSections<T: DiffAware, U: DiffAware> (
    changes: [Change<Section<T, U>>],
    updateData: () -> Void,
    completion: ((Bool) -> Void)? = nil) {

    let changesWithSectionIndex = IndexPathConverter.convertSectionChanges(changes: changes)
    let reloadChanges = sectionReloads(changes: changes)

    performBatchUpdates({
      updateData()
      reloadChanges.insideChanges()
      reloadChanges.outSideChanges() // hmm why is this bad? I don't get outsideItemsUpdate(:)...
      insideSectionsUpdate(changesWithSectionIndex: changesWithSectionIndex)
    }, completion: { finished in
      completion?(finished)
    })

  }

  private func insideSectionsUpdate(changesWithSectionIndex: ChangeWithSectionIndex) {
    changesWithSectionIndex.deletes.executeIfPresent {
      deleteSections(IndexSet($0))
    }

    changesWithSectionIndex.inserts.executeIfPresent {
      insertSections(IndexSet($0))
    }

    changesWithSectionIndex.moves.executeIfPresent {
      $0.forEach { move in
        moveSection(move.from, toSection: move.to) // This section needs to be internally diff'ed too
      }
    }
  }

  // Not used here but could be put inside the `performBatchUpdates` in `reloadSections(:)`
  // if the `reloadChanges.outSideChanges()`is removed.
//  private func outsideSectionsUpdate(changesWithSectionIndex: ChangeWithSectionIndex) {
//    changesWithSectionIndex.replaces.executeIfPresent {
//      self.reloadSections(IndexSet($0))
//    }
//  }

  private func sectionReloads<T: DiffAware, U: DiffAware>(
    changes: [Change<Section<T, U>>]) -> (insideChanges: () -> (), outSideChanges: () -> ()) {

    let replaces = changes.filter({ return $0.replace != nil })
    let itemChangesMap = replaces.reduce(into: [Int : [Change<U>]]()) {
      $0[$1.replace!.index] = diff(old: $1.replace!.oldItem.items, new: $1.replace!.newItem.items)
    }

    let changesWithIndexPath = itemChangesMap.map { IndexPathConverter.convert(changes: $1, section: $0) }

    let insideChanges = { [weak self] in
      changesWithIndexPath.forEach { self?.insideItemsUpdate(changesWithIndexPath: $0) }
    }

    let outsideChanges = { [weak self] in
      changesWithIndexPath.forEach { self?.outsideItemsUpdate(changesWithIndexPath: $0) }
    }

    return (insideChanges, outsideChanges)
  }
}
