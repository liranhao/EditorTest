//
//  CanvasTextItem.swift
//  EditorTest
//
//  Created by ITHPNB04248 on 2025/11/6.
//

import UIKit

final class CanvasTextItem: BaseCanvasItem, UITextViewDelegate {
    private static let defaultFont: UIFont = .systemFont(ofSize: 24, weight: .semibold)
    private static let horizontalPadding: CGFloat = 6.0
    private static let verticalPadding: CGFloat = 2.0

    private let textView: UITextView
    private lazy var editGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleEditDoubleTap(_:)))
        gesture.numberOfTapsRequired = 2
        return gesture
    }()

    private var isEditingText: Bool = false

    init(text: String, initialSize: CGSize? = nil, minimumSide: CGFloat) {
        let resolvedSize = CanvasTextItem.estimatedSize(for: text, proposed: initialSize, minimumSide: minimumSide)
        textView = UITextView(frame: CGRect(origin: .zero, size: resolvedSize))
        super.init(initialSize: resolvedSize, minimumSide: minimumSide)
        configureTextView(with: text)
        addGestureRecognizer(editGesture)
        adjustSizeToFitText() // Ensure bounds align with text content
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textView.frame = bounds
    }

    override func didChangeSelection(isSelected: Bool) {
        super.didChangeSelection(isSelected: isSelected)
        if isSelected {
            textView.layer.borderWidth = 0
        } else {
            stopEditing()
        }
    }

    @objc private func handleEditDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        guard ensureSelection() else { return }
        startEditing()
    }

    private func configureTextView(with text: String) {
        textView.text = text
        textView.font = CanvasTextItem.defaultFont
        textView.textColor = .label
        textView.textAlignment = .center
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isEditable = false
        textView.isSelectable = false
        textView.isUserInteractionEnabled = false
        textView.returnKeyType = .done
        textView.backgroundColor = .clear
        textView.delegate = self
        addSubview(textView)
        sendSubviewToBack(textView)
    }

    private func startEditing() {
        guard !isEditingText else { return }
        isEditingText = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.becomeFirstResponder()
    }

    private func stopEditing() {
        guard isEditingText else { return }
        isEditingText = false
        textView.resignFirstResponder()
        textView.isEditable = false
        textView.isSelectable = false
        textView.isUserInteractionEnabled = false
    }

    private func adjustSizeToFitText() {
        let maxWidth: CGFloat = max(bounds.width, 160.0)
        textView.textContainer.size = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        textView.layoutManager.ensureLayout(for: textView.textContainer)

        var usedRect = textView.layoutManager.usedRect(for: textView.textContainer).integral
        if usedRect.height == 0 {
            usedRect.size.height = CanvasTextItem.defaultFont.lineHeight
        }

        var rawSize = CGSize(
            width: max(minimumSide, usedRect.width + CanvasTextItem.horizontalPadding * 2),
            height: max(minimumSide, usedRect.height + CanvasTextItem.verticalPadding * 2)
        )

        let constrained = constrainedFrame(for: rawSize, center: center)
        bounds.size = constrained.size
        center = constrained.center
        setNeedsLayout()
        layoutIfNeeded()
    }

    override func minimumContentSize() -> CGSize {
        textView.textContainer.size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        textView.layoutManager.ensureLayout(for: textView.textContainer)
        var usedRect = textView.layoutManager.usedRect(for: textView.textContainer).integral
        if usedRect.height == 0 {
            usedRect.size.height = CanvasTextItem.defaultFont.lineHeight
        }
        return CGSize(
            width: max(minimumSide, usedRect.width + CanvasTextItem.horizontalPadding * 2),
            height: max(minimumSide, usedRect.height + CanvasTextItem.verticalPadding * 2)
        )
    }

    private static func estimatedSize(for text: String, proposed: CGSize?, minimumSide: CGFloat) -> CGSize {
        if let proposed, proposed != .zero {
            return proposed
        }

        let maxWidth: CGFloat = 260.0
        let attributes: [NSAttributedString.Key: Any] = [.font: CanvasTextItem.defaultFont]
        let bounding = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).integral

        let width = max(minimumSide, bounding.width + CanvasTextItem.horizontalPadding * 2)
        let height = max(minimumSide, bounding.height + CanvasTextItem.verticalPadding * 2)
        return CGSize(width: width, height: height)
    }

    // MARK: UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        adjustSizeToFitText()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        stopEditing()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            stopEditing()
            return false
        }
        return true
    }
}
