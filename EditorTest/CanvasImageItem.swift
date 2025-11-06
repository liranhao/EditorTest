import UIKit

final class CanvasImageItem: BaseCanvasItem {
    private let imageView: UIImageView

    init(image: UIImage, initialSize: CGSize, minimumSide: CGFloat) {
        self.imageView = UIImageView(image: image)
        super.init(initialSize: initialSize, minimumSide: minimumSide)
        configureImageView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureImageView() {
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.isUserInteractionEnabled = false
        imageView.contentMode = .scaleToFill
        addSubview(imageView)
        sendSubviewToBack(imageView)
    }
}




