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
  public func reload<T: DiffAware>(
    changes: [Change<T>],
    section: Int = 0,
    updateData: () -> Void,
    completion: ((Bool) -> Void)? = nil) {
    
    let changesWithIndexPath = IndexPathConverter().convert(changes: changes, section: section)
    
    performBatchUpdates({
      updateData()
      insideUpdate(changesWithIndexPath: changesWithIndexPath)
    }, completion: { finished in
      completion?(finished)
    })

    // reloadRows needs to be called outside the batch
    outsideUpdate(changesWithIndexPath: changesWithIndexPath)
  }
  
  // MARK: - Helper
  
  private func insideUpdate(changesWithIndexPath: ChangeWithIndexPath) {
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

  private func outsideUpdate(changesWithIndexPath: ChangeWithIndexPath) {
    changesWithIndexPath.replaces.executeIfPresent {
      self.reloadItems(at: $0)
    }
  }
}

public extension UICollectionView {

  /// Animate reload in a batch update
  ///
  /// - Parameters:
  ///   - changes: The changes from diff
  ///   - updateData: Update your data source model
  ///   - completion: Called when operation completes
  public func reloadSections<T: DiffAware>(
    changes: [Change<T>],
    updateData: () -> Void,
    completion: ((Bool) -> Void)? = nil) {

    let changesWithSectionIndex = ChangeWithSectionIndex.convert(changes: changes)

    performBatchUpdates({
      sectionReloads(changesWithSectionIndex: changesWithSectionIndex)
      updateData()
      sectionRearranges(changesWithSectionIndex: changesWithSectionIndex)
    }, completion: { finished in
      completion?(finished)
    })
  }

  private func sectionRearranges(changesWithSectionIndex: ChangeWithSectionIndex) {
    changesWithSectionIndex.deletes.executeIfPresent {
      deleteSections(IndexSet($0))
    }

    changesWithSectionIndex.inserts.executeIfPresent {
      insertSections(IndexSet($0))
    }

    changesWithSectionIndex.moves.executeIfPresent {
      $0.forEach { move in
        moveSection(move.from, toSection: move.to)
      }
    }
  }

  private func sectionReloads(changesWithSectionIndex: ChangeWithSectionIndex) {
    changesWithSectionIndex.replaces.executeIfPresent {
      self.reloadSections(IndexSet($0))
    }
  }
}

