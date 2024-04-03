//
//  ImageGestureModifier.swift
//  ImagePager
//
//  Created by 川尻辰義 on 2024/04/03.
//

import Foundation
import SwiftUI

struct ImageGestureModifier: ViewModifier {
    let pageSize: CGSize
    let imageSize: CGSize

    // ✅ 画像端を超えてドラッグした際の移動量をコールバックで受け取れるようにしている
    let onDraggingOver: (CGSize) -> Void
    let onDraggingOverEnded: (CGSize) -> Void
    let onDraggingOverCanceled: () -> Void

    @State private var currentScale: CGFloat = 1.0
    @State private var previousScale: CGFloat = 1.0

    @State private var currentOffset = CGSize.zero
    @State private var unclampedOffset = CGSize.zero
    @State private var previousTranslation = CGSize.zero

    @State private var draggingOverAxis: DraggingOverAxis?

    // ドラッグ操作用の Gesture
    var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                handleDragGestureValueChanged(value)
            }
            .onEnded { value in
                handleDragGestureValueChanged(value)

                previousTranslation = .zero
                unclampedOffset = currentOffset

                let (draggableRangeX, draggableRangeY) = calculateDraggableRange()
                if draggingOverAxis == .horizontal {
                    if currentOffset.width <= draggableRangeX.lowerBound || draggableRangeX.upperBound <= currentOffset.width {
                        onDraggingOverEnded(CGSize(width: value.predictedEndTranslation.width, height: 0))
                    } else {
                        onDraggingOverCanceled()
                    }
                } else if draggingOverAxis == .vertical {
                    if currentOffset.height <= draggableRangeY.lowerBound || draggableRangeY.upperBound <= currentOffset.height {
                        onDraggingOverEnded(CGSize(width: 0, height: value.predictedEndTranslation.height))
                    } else {
                        onDraggingOverCanceled()
                    }
                }

                draggingOverAxis = nil
            }
    }
    // ピンチインでの拡大・縮小操作用の Gesture
    var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / previousScale
                previousScale = value
                currentScale = clamp(min: 1.0, val: currentScale * delta, max: 2.5)
            }
            .onEnded { _ in
                previousScale = 1.0
                withAnimation {
                    currentOffset = clampInDraggableRange(offset: currentOffset)
                }
            }
    }

    func body(content: Content) -> some View {
        content.offset(x: currentOffset.width, y: currentOffset.height)
            .scaleEffect(currentScale)
            .clipShape(Rectangle())
            .gesture(dragGesture)
            .simultaneousGesture(pinchGesture)
    }
    
    /// ドラッグ操作の移動量から画像の表示位置（オフセット）を確定させる
    ///
    /// 画像端を超えてドラッグしていた場合は移動量を `onDraggingOver` のコールバックに通知する。
    private func handleDragGestureValueChanged(_ value: DragGesture.Value) {
        let delta = CGSize(
            width: value.translation.width - previousTranslation.width,
            height: value.translation.height - previousTranslation.height
        )
        previousTranslation = CGSize(
            width: value.translation.width,
            height: value.translation.height
        )
        unclampedOffset = CGSize(
            width: unclampedOffset.width + delta.width / currentScale,
            height: unclampedOffset.height + delta.height / currentScale
        )

        currentOffset = clampInDraggableRange(offset: unclampedOffset)
        
        // ✅ 画像端を考慮したオフセット（ `currentOffset` ）と考慮しないオフセット（ `unclampedOffset` ）に差がある場合にコールバックを呼び出す
        // 画像端を超えてドラッグを開始した後はもう一方向の移動量を無視し、前後の画像への切り替えと画面を閉じる操作を同時に機能させない
        switch draggingOverAxis {
        case .horizontal:
            if unclampedOffset.width != currentOffset.width {
                onDraggingOver(CGSize(width: unclampedOffset.width - currentOffset.width, height: 0))
            } else {
                draggingOverAxis = nil
                onDraggingOverCanceled()
            }
        case .vertical:
            if unclampedOffset.height != currentOffset.height {
                onDraggingOver(CGSize(width: 0, height: unclampedOffset.height - currentOffset.height))
            } else {
                draggingOverAxis = nil
                onDraggingOverCanceled()
            }
        case nil:
            if unclampedOffset != currentOffset {
                if abs(unclampedOffset.width - currentOffset.width) > abs(unclampedOffset.height - currentOffset.height) {
                    draggingOverAxis = .horizontal
                    onDraggingOver(CGSize(width: unclampedOffset.width - currentOffset.width, height: 0))
                } else {
                    draggingOverAxis = .vertical
                    onDraggingOver(CGSize(width: 0, height: unclampedOffset.height - currentOffset.height))
                }
            }
        }
    }

    private func calculateDraggableRange() -> (ClosedRange<CGFloat>, ClosedRange<CGFloat>) {
        let scaledImageSize = CGSize(
            width: imageSize.width * currentScale,
            height: imageSize.height * currentScale
        )
        let draggableSize = CGSize(
            width: max(0, scaledImageSize.width - pageSize.width),
            height: max(0, scaledImageSize.height - pageSize.height)
        )
        return (
            -(draggableSize.width / 2 / currentScale)...(draggableSize.width / 2 / currentScale),
            -(draggableSize.height / 2 / currentScale)...(draggableSize.height / 2 / currentScale)
        )
    }

    private func clampInDraggableRange(offset: CGSize) -> CGSize {
        let (draggableHorizontalRange, draggableVerticalRange) = calculateDraggableRange()
        return CGSize(
            width: clamp(
                min: draggableHorizontalRange.lowerBound,
                val: offset.width,
                max: draggableHorizontalRange.upperBound
            ),
            height: clamp(
                min: draggableVerticalRange.lowerBound,
                val: offset.height,
                max: draggableVerticalRange.upperBound
            )
        )
    }

    private enum DraggingOverAxis: Equatable {
        case horizontal
        case vertical
    }
}

func clamp(min: CGFloat, val: CGFloat, max: CGFloat) -> CGFloat {
    if min > val {
        return min
    }
    
    if max > val {
        return val
    }
    
    return max
}
