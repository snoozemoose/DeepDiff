import UIKit
import Anchors

class CollectionViewCell: UICollectionViewCell {
  let label = UILabel()

  override func didMoveToSuperview() {
    super.didMoveToSuperview()

    addSubview(label)
    activate(
      label.anchor.center
    )

    backgroundColor = UIColor(hex: "#e67e22")
    layer.cornerRadius = 5
    layer.masksToBounds = true

    label.font = UIFont.boldSystemFont(ofSize: 20)
    label.textColor = .white
  }
}

class SectionHeaderView: UICollectionReusableView {
    let label = UILabel()
    func setup() {
        label.textColor = .black
        addSubview(label)
        activate(
            label.anchor.center
        )
    }

    func update(title: String) {
        label.text = title
    }
}
