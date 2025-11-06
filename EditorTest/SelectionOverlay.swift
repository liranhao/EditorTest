// MARK: - Selection Overlay

import UIKit

class SelectionOverlay: UIView {
    private enum Edge {
        case top
        case bottom
        case left
        case right
    }

    private enum HandlePosition: Int, CaseIterable {
        case topLeft
        case top
        case topRight
        case left
        case right
        case bottomLeft
        case bottom
        case bottomRight

        var isCorner: Bool {
            switch self {
            case .topLeft, .topRight, .bottomLeft, .bottomRight:
                return true
            default:
                return false
            }
        }

        var direction: CGPoint {
            switch self {
            case .topLeft:
                return CGPoint(x: -1, y: -1)
            case .topRight:
                return CGPoint(x: 1, y: -1)
            case .bottomLeft:
                return CGPoint(x: -1, y: 1)
            case .bottomRight:
                return CGPoint(x: 1, y: 1)
            default:
                return .zero
            }
        }

        func centerPoint(in rect: CGRect) -> CGPoint {
            switch self {
            case .topLeft:
                return CGPoint(x: rect.minX, y: rect.minY)
            case .top:
                return CGPoint(x: rect.midX, y: rect.minY)
            case .topRight:
                return CGPoint(x: rect.maxX, y: rect.minY)
            case .left:
                return CGPoint(x: rect.minX, y: rect.midY)
            case .right:
                return CGPoint(x: rect.maxX, y: rect.midY)
            case .bottomLeft:
                return CGPoint(x: rect.minX, y: rect.maxY)
            case .bottom:
                return CGPoint(x: rect.midX, y: rect.maxY)
            case .bottomRight:
                return CGPoint(x: rect.maxX, y: rect.maxY)
            }
        }
    }

    private let handleSize: CGFloat = 12.0
    private let rotationHandleSize = CGSize(width: 28.0, height: 28.0)
    private let rotationHandleVerticalOffset: CGFloat = 22.0
    private let borderHitWidth: CGFloat = 36.0
    private let minimumSide: CGFloat
    private let tapScaleStep: CGFloat

    private weak var hostView: BaseCanvasItem?
    private var handleViews: [HandlePosition: UIView] = [:]

    private var activeEdges: Set<Edge> = []
    private var activeCorner: HandlePosition?
    private var initialBounds: CGRect = .zero
    private var initialCenter: CGPoint = .zero
    private var initialTouchPoint: CGPoint = .zero
    private var initialRotationAngle: CGFloat = 0.0
    private var initialHostTransform: CGAffineTransform = .identity

    private lazy var borderLongPress: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleBorderLongPress(_:)))
        gesture.minimumPressDuration = 0.3
        gesture.cancelsTouchesInView = false
        return gesture
    }()

    private lazy var borderPanGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleBorderPan(_:)))
        gesture.cancelsTouchesInView = false
        return gesture
    }()

    private weak var rotationHandle: UIView?

    init(hostView: BaseCanvasItem, minimumSide: CGFloat, tapScaleStep: CGFloat) {
        self.hostView = hostView
        self.minimumSide = minimumSide
        self.tapScaleStep = tapScaleStep
        super.init(frame: hostView.bounds)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        layer.borderWidth = 2.0
        layer.borderColor = UIColor.systemBlue.cgColor
        addGestureRecognizer(borderLongPress)
        addGestureRecognizer(borderPanGesture)
        createHandles()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func syncWithHost() {
        guard let host = hostView else { return }
        frame = host.bounds
        setNeedsLayout()
        layoutIfNeeded()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let handleHitRange = handleSize + 12.0
        for view in handleViews.values {
            if view.frame.insetBy(dx: -handleHitRange, dy: -handleHitRange).contains(point) {
                return true
            }
        }

        if let rotationHandle,
           rotationHandle.frame.insetBy(dx: -handleHitRange, dy: -handleHitRange).contains(point) {
            return true
        }

        let innerRect = bounds.insetBy(dx: borderHitWidth, dy: borderHitWidth)
        if innerRect.contains(point) {
            return false
        }
        return bounds.insetBy(dx: -borderHitWidth * 0.5, dy: -borderHitWidth * 0.5).contains(point)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for (position, view) in handleViews {
            view.bounds = CGRect(origin: .zero, size: CGSize(width: handleSize, height: handleSize))
            view.layer.cornerRadius = handleSize / 2
            view.center = position.centerPoint(in: bounds)
        }

        if let rotationHandle {
            rotationHandle.bounds = CGRect(origin: .zero, size: rotationHandleSize)
            rotationHandle.layer.cornerRadius = rotationHandleSize.width / 2
            rotationHandle.center = CGPoint(x: bounds.midX, y: bounds.minY - rotationHandleVerticalOffset)
        }
    }

    private func createHandles() {
        for position in HandlePosition.allCases {
            let dot = UIView(frame: CGRect(origin: .zero, size: CGSize(width: handleSize, height: handleSize)))
            dot.backgroundColor = .systemBlue
            dot.layer.cornerRadius = handleSize / 2
            dot.layer.masksToBounds = true
            dot.tag = position.rawValue
            dot.isUserInteractionEnabled = position.isCorner

            if position.isCorner {
                let pan = UIPanGestureRecognizer(target: self, action: #selector(handleCornerPan(_:)))
                pan.cancelsTouchesInView = true
                dot.addGestureRecognizer(pan)

                let tap = UITapGestureRecognizer(target: self, action: #selector(handleCornerTap(_:)))
                tap.numberOfTapsRequired = 1
                tap.require(toFail: pan)
                dot.addGestureRecognizer(tap)
            }

            addSubview(dot)
            handleViews[position] = dot
        }

        setupRotationHandle()
    }

    private func setupRotationHandle() {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear
        container.layer.masksToBounds = true
        container.isUserInteractionEnabled = true

        let iconImage = UIImage(named: "transform_icon")
        let imageView = UIImageView(image: iconImage)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = container.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(imageView)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleRotationPan(_:)))
        container.addGestureRecognizer(pan)

        addSubview(container)
        rotationHandle = container
    }

    var interactionOutsets: UIEdgeInsets {
        let horizontalMargin = handleSize / 2
        let bottomMargin = handleSize / 2
        let topMargin = rotationHandleVerticalOffset + rotationHandleSize.height / 2
        return UIEdgeInsets(top: topMargin, left: horizontalMargin, bottom: bottomMargin, right: horizontalMargin)
    }

    @objc private func handleBorderPan(_ gesture: UIPanGestureRecognizer) {
        guard let host = hostView, let superview = host.superview else { return }
        host.ensureSelection()
        let translation = gesture.translation(in: superview)
        guard gesture.state == .began || gesture.state == .changed else { return }
        let proposedCenter = CGPoint(x: host.center.x + translation.x, y: host.center.y + translation.y)
        let constrained = host.constrainedFrame(for: host.bounds.size, center: proposedCenter)
        host.bounds.size = constrained.size
        host.center = constrained.center
        gesture.setTranslation(.zero, in: superview)
        syncWithHost()
    }

    @objc private func handleBorderLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let host = hostView, let superview = host.superview else { return }
        let location = gesture.location(in: superview)

        switch gesture.state {
        case .began:
            host.ensureSelection()
            let localPoint = gesture.location(in: self)
            let edges = edges(at: localPoint)
            guard !edges.isEmpty else { return }
            activeEdges = edges
            initialBounds = host.bounds
            initialCenter = host.center
            initialTouchPoint = location
        case .changed:
            guard !activeEdges.isEmpty else { return }
            let translation = CGPoint(x: location.x - initialTouchPoint.x, y: location.y - initialTouchPoint.y)
            resizeUsingEdges(activeEdges, translation: translation)
        default:
            activeEdges.removeAll()
        }
    }

    @objc private func handleCornerPan(_ gesture: UIPanGestureRecognizer) {
        guard let host = hostView, let superview = host.superview, let view = gesture.view,
              let position = HandlePosition(rawValue: view.tag) else { return }
        let location = gesture.location(in: superview)

        switch gesture.state {
        case .began:
            host.ensureSelection()
            activeCorner = position
            initialBounds = host.bounds
            initialCenter = host.center
            initialTouchPoint = location
        case .changed:
            guard let activeCorner else { return }
            let translation = CGPoint(x: location.x - initialTouchPoint.x, y: location.y - initialTouchPoint.y)
            resizeUsingCorner(activeCorner, translation: translation)
        default:
            activeCorner = nil
        }
    }

    @objc private func handleCornerTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended,
              let host = hostView,
              let view = gesture.view,
              let position = HandlePosition(rawValue: view.tag) else { return }

        host.ensureSelection()
        let currentSize = host.bounds.size
        guard currentSize.width > 0, currentSize.height > 0 else { return }

        var scaleDelta: CGFloat = position == .topRight || position == .bottomRight ? (1.0 + tapScaleStep) : (1.0 - tapScaleStep)
        let minScaleForWidth = minimumSide / currentSize.width
        let minScaleForHeight = minimumSide / currentSize.height
        if scaleDelta < 1.0 {
            scaleDelta = max(scaleDelta, max(minScaleForWidth, minScaleForHeight))
        }

        let proposedSize = CGSize(width: currentSize.width * scaleDelta, height: currentSize.height * scaleDelta)
        let constrained = host.constrainedFrame(for: proposedSize, center: host.center)
        host.bounds.size = constrained.size
        host.center = constrained.center
        host.setNeedsLayout()
        host.layoutIfNeeded()
        syncWithHost()
    }

    private func edges(at point: CGPoint) -> Set<Edge> {
        var edges: Set<Edge> = []
        let threshold = borderHitWidth * 0.6

        if abs(point.y - bounds.minY) <= threshold {
            edges.insert(.top)
        }
        if abs(point.y - bounds.maxY) <= threshold {
            edges.insert(.bottom)
        }
        if abs(point.x - bounds.minX) <= threshold {
            edges.insert(.left)
        }
        if abs(point.x - bounds.maxX) <= threshold {
            edges.insert(.right)
        }
        return edges
    }

    private func resizeUsingEdges(_ edges: Set<Edge>, translation: CGPoint) {
        guard hostView != nil else { return }
        var newBounds = initialBounds
        var newCenter = initialCenter

        if edges.contains(.right) {
            var width = initialBounds.width + translation.x
            width = max(minimumSide, width)
            let deltaWidth = width - initialBounds.width
            newBounds.size.width = width
            newCenter.x = initialCenter.x + deltaWidth / 2
        }

        if edges.contains(.left) {
            var width = initialBounds.width - translation.x
            width = max(minimumSide, width)
            let deltaWidth = width - initialBounds.width
            newBounds.size.width = width
            newCenter.x = initialCenter.x - deltaWidth / 2
        }

        if edges.contains(.bottom) {
            var height = initialBounds.height + translation.y
            height = max(minimumSide, height)
            let deltaHeight = height - initialBounds.height
            newBounds.size.height = height
            newCenter.y = initialCenter.y + deltaHeight / 2
        }

        if edges.contains(.top) {
            var height = initialBounds.height - translation.y
            height = max(minimumSide, height)
            let deltaHeight = height - initialBounds.height
            newBounds.size.height = height
            newCenter.y = initialCenter.y - deltaHeight / 2
        }

        apply(bounds: newBounds, center: newCenter)
    }

    private func resizeUsingCorner(_ corner: HandlePosition, translation: CGPoint) {
        guard hostView != nil else { return }
        let direction = corner.direction
        guard direction != .zero else { return }

        let diagonal = CGPoint(x: initialBounds.width * direction.x, y: initialBounds.height * direction.y)
        let diagonalLength = hypot(diagonal.x, diagonal.y)
        guard diagonalLength > 0 else { return }

        let projected = translation.x * direction.x + translation.y * direction.y
        var scale = 1.0 + projected / diagonalLength
        let minScaleForWidth = minimumSide / initialBounds.width
        let minScaleForHeight = minimumSide / initialBounds.height
        let minimumAllowedScale = max(minScaleForWidth, minScaleForHeight)
        if scale < minimumAllowedScale {
            scale = minimumAllowedScale
        }

        let newWidth = initialBounds.width * scale
        let newHeight = initialBounds.height * scale
        let deltaWidth = newWidth - initialBounds.width
        let deltaHeight = newHeight - initialBounds.height

        var newBounds = initialBounds
        newBounds.size = CGSize(width: newWidth, height: newHeight)

        var newCenter = initialCenter
        newCenter.x += direction.x * (deltaWidth / 2)
        newCenter.y += direction.y * (deltaHeight / 2)

        apply(bounds: newBounds, center: newCenter)
    }

    @objc private func handleRotationPan(_ gesture: UIPanGestureRecognizer) {
        guard let host = hostView, let superview = host.superview else { return }
        let location = gesture.location(in: superview)

        switch gesture.state {
        case .began:
            host.ensureSelection()
            initialHostTransform = host.transform
            let vector = CGPoint(x: location.x - host.center.x, y: location.y - host.center.y)
            initialRotationAngle = atan2(vector.y, vector.x)
        case .changed:
            let vector = CGPoint(x: location.x - host.center.x, y: location.y - host.center.y)
            let angle = atan2(vector.y, vector.x)
            let delta = angle - initialRotationAngle
            host.transform = initialHostTransform.rotated(by: delta)
        default:
            break
        }
    }

    private func apply(bounds: CGRect, center: CGPoint) {
        guard let host = hostView else { return }
        let constrained = host.constrainedFrame(for: bounds.size, center: center)
        host.bounds.size = constrained.size
        host.center = constrained.center
        host.setNeedsLayout()
        host.layoutIfNeeded()
        syncWithHost()
    }
}
