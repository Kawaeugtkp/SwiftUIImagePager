//
//  ContentView.swift
//  ImagePager
//
//  Created by 川尻辰義 on 2024/04/03.
//

import SwiftUI

struct ContentView: View {
    @State private var showImagePager = false
    @State private var showImagePager2 = false
    @State private var showImagePager3 = false
    @State private var showImagePager4 = false
    private let images = [URL(string: "https://doremifahiroba.com/wp-content/uploads/2022/11/EP01_30-1024x576.jpg")!, URL(string: "https://realsound.jp/wp-content/uploads/2023/01/20230121-gudetama-07.jpg")!, URL(string: "https://eiga.k-img.com/images/anime/news/117485/photo/46fcf777bd7b0902/640.jpg?1669974887")!, URL(string: "https://netofuli.com/wp-content/uploads/2022/12/%E3%82%B9%E3%82%AF%E3%83%AA%E3%83%BC%E3%83%B3%E3%82%B7%E3%83%A7%E3%83%83%E3%83%88-2022-12-17-18.40.30.jpg")!]

    var body: some View {
        ZStack {
            VStack(spacing: 40) {
                Button(action: {
                    showImagePager = true
                }, label: {
                    Text("show image pager")
                })
                Button(action: {
                    showImagePager2 = true
                }, label: {
                    Text("show image pager")
                })
                Button(action: {
                    showImagePager3 = true
                }, label: {
                    Text("show image pager")
                })
                Button(action: {
                    showImagePager4 = true
                }, label: {
                    Text("show image pager")
                })
            }
            
            if showImagePager {
                ImagePager(pagerState: ImagePagerState(pageCount: images.count, pageSize: getRect().size), imageUrls: images) {
                    withAnimation {
                        showImagePager = false
                    }
                }
            }
            if showImagePager2 {
                ImagePager(pagerState: ImagePagerState(pageCount: images.count, initialIndex: 1, pageSize: getRect().size), imageUrls: images) {
                    showImagePager2 = false
                }
            }
            if showImagePager3 {
                ImagePager(pagerState: ImagePagerState(pageCount: images.count, initialIndex: 2, pageSize: getRect().size), imageUrls: images) {
                    showImagePager3 = false
                }
            }
            if showImagePager4 {
                ImagePager(pagerState: ImagePagerState(pageCount: images.count, initialIndex: 3, pageSize: getRect().size), imageUrls: images) {
                    showImagePager4 = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

extension View {
    
    func getRect() -> CGRect {
        let window = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return window?.screen.bounds ?? .zero
    }
}
