//
//  UICollectionView+Extensions.swift
//  DeepDiff
//
//  Created by Khoa Pham.
//  Copyright © 2018 Khoa Pham. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit

public extension UICollectionView {
  
  /// Animate reload in a batch update
  ///
  /// - Parameters:
  ///   - changes: The changes from diff
  ///   - section: The section that all calculated IndexPath belong
  ///   - updateData: Update your data source model
  ///   - completion: Called when operation completes
  func reload<T: DiffAware>(
    changes: [Change<T>],
    section: Int = 0,
    updateData: () -> Void,
    completion: ((Bool) -> Void)? = nil) {

    let changesWithIndexPath = IndexPathConverter().convert(changes: changes, section: section)

    let group = DispatchGroup()
    var insertDeleteMoveFinished = false
    var reloadFinished = false

    // reloads indices should be based on the pre-update state according to 33´37 into https://developer.apple.com/videos/play/wwdc2018/225/
    group.enter()
    UIView.performWithoutAnimation { // recommended since reloads are never animated anyway (see 37´10 into https://developer.apple.com/videos/play/wwdc2018/225/)
        performBatchUpdates({
            reloads(changesWithIndexPath: changesWithIndexPath)
        }, completion: { finished in
            reloadFinished = finished
            group.leave()
        })
    }

    group.enter()
    performBatchUpdates({
        updateData()
        rearranges(changesWithIndexPath: changesWithIndexPath)
    }, completion: { finished in
        insertDeleteMoveFinished = finished
        group.leave()
    })

    group.notify(queue: .main) {
        completion?(reloadFinished && insertDeleteMoveFinished)
    }
  }

  // MARK: - Helper

  private func rearranges(changesWithIndexPath: ChangeWithIndexPath) {
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

  private func reloads(changesWithIndexPath: ChangeWithIndexPath) {
    changesWithIndexPath.replaces.executeIfPresent {
      self.reloadItems(at: $0)
    }
  }
}

#endif
