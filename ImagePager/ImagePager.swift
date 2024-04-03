//
//  ImagePager.swift
//  ImagePager
//
//  Created by 川尻辰義 on 2024/04/03.
//

import Foundation
import SwiftUI
import NukeUI

struct ImagePager: View {
    @State private var pagerState: ImagePagerState
    let imageUrls: [URL]
    let onDismiss: () -> Void
    
    init(pagerState: ImagePagerState, imageUrls: [URL], onDismiss: @escaping () -> Void) {
        self.pagerState = pagerState
        self.imageUrls = imageUrls
        self.onDismiss = onDismiss
    }

    var body: some View {
        GeometryReader { geometry in
            let pageSize = geometry.size
            HStack(spacing: 0) {
                ForEach(imageUrls, id: \.absoluteString) { imageUrl in
                    ImagePagerPage(
                        pagerState: $pagerState,
                        imageUrl: imageUrl,
                        pageSize: pageSize,
                        onDismiss: onDismiss
                    ).frame(width: pageSize.width, height: pageSize.height)
                }
            }
            .frame(width: pageSize.width * CGFloat(pagerState.pageCount), height: pageSize.height)
            // ✅ オフセットを変えることで擬似的に HorizontalPager の振る舞いを再現する
            .offset(pagerState.offset)
            .background(Color.black)
        }
    }
}

private struct ImagePagerPage: View {
    @Binding var pagerState: ImagePagerState
    let imageUrl: URL?
    let pageSize: CGSize
    let onDismiss: () -> Void
    
    var body: some View {
        // 📝 B/43では画像の表示に Nuke (LazyImage)　を使用している
        // https://github.com/kean/Nuke
        LazyImage(url: imageUrl) { state in
            if case .success(let response) = state.result {
                let imageSize = response.image.size
                let widthFitSize = CGSize(
                    width: pageSize.width,
                    height: imageSize.height * (pageSize.width / imageSize.width)
                )
                let heightFitSize = CGSize(
                    width: imageSize.width * (pageSize.height / imageSize.height),
                    height: pageSize.height
                )
                let fitImageSize = widthFitSize.height > pageSize.height ? heightFitSize : widthFitSize
                Image(uiImage: response.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: pageSize.width, height: pageSize.height)
                    .modifier(
                        ImageGestureModifier(
                            pageSize: pageSize,
                            imageSize: fitImageSize,
                            onDraggingOver: {
                                pagerState.moveToDesiredOffset(pageSize: pageSize, additionalOffset: $0)
                            },
                            onDraggingOverEnded: { predictedEndTranslation in
                                // ✅ 水平方向のドラッグ操作が完了した後、 `predictedEndTranslation` （慣性を考慮した移動量）を基に前後のページへ移動する
                                let scrollThreshold = pageSize.width / 2.0
                                withAnimation(.easeOut) {
                                    if predictedEndTranslation.width < -scrollThreshold {
                                        pagerState.scrollToNextPage(pageSize: pageSize)
                                    } else if predictedEndTranslation.width > scrollThreshold {
                                        pagerState.scrollToPrevPage(pageSize: pageSize)
                                    } else {
                                        pagerState.moveToDesiredOffset(pageSize: pageSize)
                                    }
                                }
                                
                                // 垂直方向のドラッグ操作が完了した後、 `predictedEndTranslation` を基に必要に応じて画面を閉じる
                                let dismisssThreshold = pageSize.height / 4.0
                                if abs(predictedEndTranslation.height) > dismisssThreshold {
                                    withAnimation(.easeOut) {
                                        pagerState.invokeDismissTransition(
                                            pageSize: pageSize,
                                            predictedEndTranslationY: predictedEndTranslation.height
                                        )
                                    }
                                    onDismiss()
                                }
                            },
                            onDraggingOverCanceled: {
                                pagerState.moveToDesiredOffset(pageSize: pageSize)
                            }
                        )
                    )
            }
        }
    }
}

struct ImagePagerState {
    private(set) var pageCount: Int
    private(set) var currentIndex: Int
    private(set) var offset: CGSize = .zero

    private var prevIndex: Int {
        max(currentIndex - 1, 0)
    }
    private var nextIndex: Int {
        min(currentIndex + 1, pageCount - 1)
    }

    init(pageCount: Int, initialIndex: Int = 0, pageSize: CGSize) {
        self.pageCount = pageCount
        self.currentIndex = initialIndex
        offset = CGSize(
            width: -pageSize.width * CGFloat(currentIndex) + offset.width,
            height: offset.height
        )
    }

    mutating func scrollToPrevPage(pageSize: CGSize) {
        currentIndex = prevIndex
        moveToDesiredOffset(pageSize: pageSize)
    }

    mutating func scrollToNextPage(pageSize: CGSize) {
        currentIndex = nextIndex
        moveToDesiredOffset(pageSize: pageSize)
    }

    mutating func invokeDismissTransition(pageSize: CGSize, predictedEndTranslationY: CGFloat) {
        moveToDesiredOffset(
            pageSize: pageSize,
            additionalOffset: CGSize(width: 0, height: predictedEndTranslationY)
        )
    }

    mutating func moveToDesiredOffset(pageSize: CGSize, additionalOffset: CGSize = .zero) {
        offset = CGSize(
            width: -pageSize.width * CGFloat(currentIndex) + additionalOffset.width,
            height: additionalOffset.height
        )
    }
}
