//
//  CavasView.swift
//  EditorTest
//
//  Created by ITHPNB04248 on 2025/11/5.
//

import UIKit

class CanvasView: UIView {
    private let minimumImageDimension: CGFloat = 60.0

    private lazy var canvasPinchGesture: UIPinchGestureRecognizer = {
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(handleCanvasPinch(_:)))
        return gesture
    }()

    private lazy var canvasPanGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleCanvasPan(_:)))
        return gesture
    }()

    private lazy var canvasTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleCanvasTap(_:)))
        gesture.cancelsTouchesInView = false
        return gesture
    }()

    private var selectedItem: BaseCanvasItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGray6
        isUserInteractionEnabled = true

        addGestureRecognizer(canvasPinchGesture)
        addGestureRecognizer(canvasPanGesture)
        addGestureRecognizer(canvasTapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleCanvasPinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.state == .began || gesture.state == .changed else { return }
        let scale = gesture.scale
        transform = transform.scaledBy(x: scale, y: scale)
        gesture.scale = 1.0
    }

    @objc private func handleCanvasPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview)
        guard gesture.state == .began || gesture.state == .changed else { return }
        center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        gesture.setTranslation(.zero, in: superview)
    }

    @objc private func handleCanvasTap(_ gesture: UITapGestureRecognizer) {
        guard let selectedItem else { return }
        let location = gesture.location(in: self)
        if selectedItem.frame.contains(location) { return }
        deselectCurrentItem()
    }

    func addImage(image: UIImage) {
        let targetSize = calculateInitialSize(for: image)
        let imageItem = CanvasImageItem(image: image, initialSize: targetSize, minimumSide: minimumImageDimension)
        imageItem.center = CGPoint(x: bounds.midX, y: bounds.midY)
        imageItem.delegate = self
        addSubview(imageItem)
        bringSubviewToFront(imageItem)
        selectItem(imageItem)
    }

    func removeImage(imageView: UIImageView) {
        if let container = imageView.superview as? CanvasImageItem {
            if container === selectedItem {
                deselectCurrentItem()
            }
            container.removeFromSuperview()
        } else {
            imageView.removeFromSuperview()
        }
    }

    func addText(text: String) {
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        textView.text = text
        addSubview(textView)
        textView.isUserInteractionEnabled = true
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handleTextPinch(_:)))
        textView.addGestureRecognizer(pinchGesture)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTextPan(_:)))
        textView.addGestureRecognizer(panGesture)
    }

    func removeText(textView: UITextView) {
        textView.removeFromSuperview()
    }

    private func calculateInitialSize(for image: UIImage) -> CGSize {
        let maxWidth = bounds.width / 2
        let maxHeight = bounds.height / 2
        let widthScale = maxWidth / image.size.width
        let heightScale = maxHeight / image.size.height
        let targetScale = min(widthScale, heightScale, 1.0)
        let safeMinimumSide = min(minimumImageDimension, min(maxWidth, maxHeight))
        var targetSize = CGSize(width: image.size.width * targetScale, height: image.size.height * targetScale)
        if safeMinimumSide > 0 && (targetSize.width < safeMinimumSide || targetSize.height < safeMinimumSide) {
            let minScale = max(safeMinimumSide / image.size.width, safeMinimumSide / image.size.height)
            targetSize = CGSize(width: image.size.width * minScale, height: image.size.height * minScale)
        }
        return targetSize
    }

    private func selectItem(_ item: BaseCanvasItem) {
        guard selectedItem !== item else { return }
        selectedItem?.setSelected(false)
        selectedItem = item
        item.setSelected(true)
        bringSubviewToFront(item)
        setCanvasGestures(enabled: false)
    }

    private func deselectCurrentItem() {
        selectedItem?.setSelected(false)
        selectedItem = nil
        setCanvasGestures(enabled: true)
    }

    private func setCanvasGestures(enabled: Bool) {
        canvasPanGesture.isEnabled = enabled
        canvasPinchGesture.isEnabled = enabled
    }

    @objc private func handleTextPinch(_ gesture: UIPinchGestureRecognizer) {
        guard let targetView = gesture.view else { return }
        guard gesture.state == .began || gesture.state == .changed else { return }
        let scale = gesture.scale
        targetView.transform = targetView.transform.scaledBy(x: scale, y: scale)
        gesture.scale = 1.0
    }

    @objc private func handleTextPan(_ gesture: UIPanGestureRecognizer) {
        guard let targetView = gesture.view else { return }
        let translation = gesture.translation(in: self)
        guard gesture.state == .began || gesture.state == .changed else { return }
        targetView.center = CGPoint(x: targetView.center.x + translation.x, y: targetView.center.y + translation.y)
        gesture.setTranslation(.zero, in: self)
    }
}

extension CanvasView: CanvasItemDelegate {
    func canvasItemDidRequestSelection(_ item: BaseCanvasItem) {
        selectItem(item)
    }
}
