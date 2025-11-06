import UIKit

protocol CanvasItemDelegate: AnyObject {
    func canvasItemDidRequestSelection(_ item: BaseCanvasItem)
}

class BaseCanvasItem: UIView {
    weak var delegate: CanvasItemDelegate?

    let minimumSide: CGFloat
    var tapScaleStep: CGFloat { 0.12 }

    private let extendedHitOutset: CGFloat = 5.0

    private var selectionOverlay: SelectionOverlay?
    private(set) var isSelected: Bool = false

    init(initialSize: CGSize, minimumSide: CGFloat) {
        self.minimumSide = minimumSide
        super.init(frame: CGRect(origin: .zero, size: initialSize))
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        selectionOverlay?.syncWithHost()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if super.point(inside: point, with: event) {
            return true
        }
        let expandedBounds = bounds.insetBy(dx: -extendedHitOutset, dy: -36)
        return expandedBounds.contains(point)
    }

    func setSelected(_ selected: Bool) {
        guard selected != isSelected else { return }
        isSelected = selected
        if selected {
            if selectionOverlay == nil {
                selectionOverlay = makeSelectionOverlay()
                if let overlay = selectionOverlay {
                    addSubview(overlay)
                }
            }
            selectionOverlay?.isHidden = false
            selectionOverlay?.syncWithHost()
        } else {
            selectionOverlay?.isHidden = true
        }
        didChangeSelection(isSelected: selected)
    }

    func ensureSelection() -> Bool {
        if !isSelected {
            delegate?.canvasItemDidRequestSelection(self)
        }
        return isSelected
    }

    func didChangeSelection(isSelected: Bool) {
        // 子类可覆写以响应选中状态变化
    }

    func applyScale(_ scale: CGFloat) {
        guard let superview else { return }
        let currentSize = bounds.size
        guard currentSize.width > 0, currentSize.height > 0 else { return }

        var appliedScale = scale
        let minScaleForWidth = minimumSide / currentSize.width
        let minScaleForHeight = minimumSide / currentSize.height
        let minimumAllowedScale = max(minScaleForWidth, minScaleForHeight)
        if appliedScale < minimumAllowedScale {
            appliedScale = minimumAllowedScale
        }

        var newSize = CGSize(width: currentSize.width * appliedScale, height: currentSize.height * appliedScale)
        newSize = clampedSize(for: newSize, in: superview.bounds)

        bounds.size = newSize
        center = clampedCenter(for: center, in: superview.bounds, usingSize: newSize)
        selectionOverlay?.syncWithHost()
    }

    func configureAdditionalGestures() {
        // 子类可覆写，添加附加手势
    }

    func makeSelectionOverlay() -> SelectionOverlay {
        SelectionOverlay(hostView: self, minimumSide: minimumSide, tapScaleStep: tapScaleStep)
    }

    private func commonInit() {
        isUserInteractionEnabled = true
        clipsToBounds = false
        configureBaseGestures()
        configureAdditionalGestures()
    }

    private func configureBaseGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        delegate?.canvasItemDidRequestSelection(self)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard ensureSelection() else { return }
        guard let superview else { return }
        let translation = gesture.translation(in: superview)
        guard gesture.state == .began || gesture.state == .changed else { return }
        let proposedCenter = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        let constrained = constrainedFrame(for: bounds.size, center: proposedCenter)
        bounds.size = constrained.size
        center = constrained.center
        gesture.setTranslation(.zero, in: superview)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard ensureSelection() else { return }
        guard gesture.state == .began || gesture.state == .changed else { return }
        applyScale(gesture.scale)
        gesture.scale = 1.0
    }

    private func clampedCenter(for proposedCenter: CGPoint, in bounds: CGRect, usingSize size: CGSize? = nil) -> CGPoint {
        let referenceSize = size ?? frame.size
        let halfWidth = referenceSize.width / 2
        let halfHeight = referenceSize.height / 2

        let minX = bounds.minX + halfWidth
        let maxX = bounds.maxX - halfWidth
        let minY = bounds.minY + halfHeight
        let maxY = bounds.maxY - halfHeight

        let clampedX = max(minX, min(maxX, proposedCenter.x))
        let clampedY = max(minY, min(maxY, proposedCenter.y))

        return CGPoint(x: clampedX, y: clampedY)
    }

    private func clampedSize(for proposedSize: CGSize, in bounds: CGRect) -> CGSize {
        let maxWidth = bounds.width
        let maxHeight = bounds.height
        let width = min(maxWidth, max(minimumSide, proposedSize.width))
        let height = min(maxHeight, max(minimumSide, proposedSize.height))
        return CGSize(width: width, height: height)
    }

    func constrainedFrame(for proposedSize: CGSize, center proposedCenter: CGPoint) -> (size: CGSize, center: CGPoint) {
        guard let superview else { return (proposedSize, proposedCenter) }
        var size = clampedSize(for: proposedSize, in: superview.bounds)
        var center = proposedCenter

        // try to keep within bounds; if center is out of range, pull back and optionally shrink
        let tolerance: CGFloat = 0.5
        var adjustedCenter = clampedCenter(for: center, in: superview.bounds, usingSize: size)

        if abs(adjustedCenter.x - center.x) > tolerance || abs(adjustedCenter.y - center.y) > tolerance {
            center = adjustedCenter
            size = clampedSize(for: size, in: superview.bounds)
            adjustedCenter = clampedCenter(for: center, in: superview.bounds, usingSize: size)
        }

        return (size, adjustedCenter)
    }
}

