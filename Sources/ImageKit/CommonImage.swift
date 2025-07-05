//
//  CommonImage.swift
//  ImageKit
//
//  Created by Thomas Rademaker on 7/5/25.
//

import SwiftUI
import StorageKit

public enum ImagePlaceholder {
    case sfSymbol(String?, tint: Color? = nil, font: Font? = nil)
    case imageResource(ImageResource)
    case view(any View)
}

public enum ImageType {
    case url(url: String?, placeholder: ImagePlaceholder? = nil)
    case asset(ImageResource)
    case diskURL(path: URL, placeholder: ImagePlaceholder? = nil)
    case data(Data?, placeholder: ImagePlaceholder? = nil)
}

public struct CommonImage: View {
    let image: ImageType
    
    public init(image: ImageType) {
        self.image = image
    }
    
    public var body: some View {
        switch image {
        case .url(let imageURL, let placeholder):
            URLImage(imageURL: imageURL, placeholder: placeholder)
        case .asset(let imageResource):
            Image(imageResource)
                .resizable()
        case .diskURL(let path, let placeholder):
            if let imageData = try? Data(contentsOf: path),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                PlaceholderImageView(placeholder: placeholder)
            }
        case .data(let data, let placeholder):
            if let data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                PlaceholderImageView(placeholder: placeholder)
            }
        }
    }
}

fileprivate struct URLImage: View {
    @Environment(\.imageFetcher) private var imageFetcher
    var imageURL: String?
    var placeholder: ImagePlaceholder?
    @State private var diskURL: URL?
    
    var body: some View {
        Group {
            if let diskURL {
                CommonImage(image: .diskURL(path: diskURL, placeholder: placeholder))
            } else {
                AsyncImage(url: URL(string: imageURL ?? ""), content: {
                    $0.resizable()
                }, placeholder: {
                    PlaceholderImageView(placeholder: placeholder)
                })
            }
        }
        .onAppear(perform: checkIfFileExists)
        .task { await fetchImage() }
    }
    
    private func checkIfFileExists() {
        guard let imageURL else { return }
        let normalizedURL = ImageFetcher.normalizeURL(imageURL)
        if Storage.fileExists(normalizedURL, in: .caches) {
            diskURL = Storage.url(for: normalizedURL, in: .caches)
        }
    }
    
    private func fetchImage() async {
        guard let imageURL else { return }
        await imageFetcher.fetchImage(from: imageURL)
    }
}

fileprivate struct PlaceholderImageView: View {
    var placeholder: ImagePlaceholder?
    
    var body: some View {
        switch placeholder {
        case .sfSymbol(let symbol, let tint, let font):
            CommonSystemImage(systemName: symbol, tint: tint, font: font)
        case .imageResource(let imageResource):
            Image(imageResource).resizable()
        case .view(let view):
            AnyView(view)
        case nil:
            EmptyView()
        }
    }
}

fileprivate struct CommonSystemImage: View {
    var systemName: String?
    var tint: Color?
    var font: Font?
    
    var body: some View {
        ZStack {
            Color.white
            
            Image(systemName: systemName ?? "")
                .font(font ?? .system(size: 16))
                .foregroundStyle(tint ?? Color.black)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ZStack {
        Color.black
        CommonImage(image: .url(url: nil, placeholder: .sfSymbol("bag.fill", tint: .gray)))
            .frame(width: 132, height: 120)
    }
}
