import UIKit
import DeepDiff
import Anchors

class CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

  var collectionView: UICollectionView!
  var sections = [DiffAwareSection<String, Int>]()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.white

    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 10
    layout.minimumInteritemSpacing = 10

    sections = [DiffAwareSection<String, Int>(id: "First section", items: []),
                DiffAwareSection<String, Int>(id: "Second section", items: [])]

    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.contentInset = UIEdgeInsets(top: 15, left: 15, bottom: 10, right: 15)
    collectionView.backgroundColor = .white

    view.addSubview(collectionView)
    activate(
      collectionView.anchor.edges
    )

    collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "headerView")
    (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).headerReferenceSize = CGSize(width: 100, height: 50)
    collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Reload", style: .plain, target: self, action: #selector(reload)
    )
  }

  @objc func reload() {
    replaceItemsInFirstSectionAndReplaceSecondSection()
  }

  func replaceItemsInFirstSectionAndReplaceSecondSection() {
    let oldSections = self.sections
    var newSections = self.sections
    newSections[0].items = DataSet.generateItems()
    newSections[1] = DiffAwareSection<String, Int>(id: String("Random section #\(arc4random())"), items: DataSet.generateItems())
    let changes = diff(old: self.sections, new: newSections)

    let exception = tryBlock {
      self.collectionView.reloadSections(changes: changes, updateData: {
        self.sections = newSections
      })
    }

    if let exception = exception {
      print(exception as Any)
      print(oldSections)
      print(newSections)
      print(changes)
    }
  }

  // MARK: - UICollectionViewDataSource

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return sections.count
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return sections[section].items.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CollectionViewCell
    let item = sections[indexPath.section].items[indexPath.item]

    cell.label.text = "\(item)"

    return cell
  }

  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                     withReuseIdentifier: "headerView",
                                                                     for: indexPath) as! SectionHeaderView
    headerView.setup()
    return headerView
  }

  func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
    (view as! SectionHeaderView).update(title: sections[indexPath.section].id)
  }

  // MARK: - UICollectionViewDelegateFlowLayout

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

    let size = collectionView.frame.size.width / 5
    return CGSize(width: size, height: size)
  }
}
