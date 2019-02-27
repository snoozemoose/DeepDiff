//
//  IndexPathConverter.swift
//  DeepDiff
//
//  Created by Khoa Pham.
//  Copyright © 2018 Khoa Pham. All rights reserved.
//

import Foundation

public struct ChangeWithSectionIndex {

  public let inserts: [Int]
  public let deletes: [Int]
  public let replaces: [Int]
  public let moves: [(from: Int, to: Int)]

  public init(
    inserts: [Int],
    deletes: [Int],
    replaces:[Int],
    moves: [(from: Int, to: Int)]) {

    self.inserts = inserts
    self.deletes = deletes
    self.replaces = replaces
    self.moves = moves
  }
}

public struct ChangeWithIndexPath {
  
  public let inserts: [IndexPath]
  public let deletes: [IndexPath]
  public let replaces: [IndexPath]
  public let moves: [(from: IndexPath, to: IndexPath)]

  public init(
    inserts: [IndexPath],
    deletes: [IndexPath],
    replaces:[IndexPath],
    moves: [(from: IndexPath, to: IndexPath)]) {

    self.inserts = inserts
    self.deletes = deletes
    self.replaces = replaces
    self.moves = moves
  }
}

public class IndexPathConverter {
  
  public init() {}
  
  public static func convert<T>(changes: [Change<T>], section: Int) -> ChangeWithIndexPath {
    let inserts = changes.compactMap({ $0.insert }).map({ $0.index.toIndexPath(section: section) })
    let deletes = changes.compactMap({ $0.delete }).map({ $0.index.toIndexPath(section: section) })
    let replaces = changes.compactMap({ $0.replace }).map({ $0.index.toIndexPath(section: section) })
    let moves = changes.compactMap({ $0.move }).map({
      (
        from: $0.fromIndex.toIndexPath(section: section),
        to: $0.toIndex.toIndexPath(section: section)
      )
    })
    
    return ChangeWithIndexPath(
      inserts: inserts,
      deletes: deletes,
      replaces: replaces,
      moves: moves
    )
  }

  public static func convertSectionChanges<T>(changes: [Change<T>]) -> ChangeWithSectionIndex {
    let inserts = changes.compactMap({ $0.insert }).map({ $0.index })
    let deletes = changes.compactMap({ $0.delete }).map({ $0.index })
    let replaces = changes.compactMap({ $0.replace }).map({ $0.index })
    let moves = changes.compactMap({ $0.move }).map({
      (
        from: $0.fromIndex,
        to: $0.toIndex
      )
    })

    return ChangeWithSectionIndex(
      inserts: inserts,
      deletes: deletes,
      replaces: replaces,
      moves: moves
    )
  }
}

extension Int {
  
  fileprivate func toIndexPath(section: Int) -> IndexPath {
    return IndexPath(item: self, section: section)
  }
}
