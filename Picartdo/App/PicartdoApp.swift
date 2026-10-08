//
//  PicartdoApp.swift
//  Picartdo
//
//  Created by Oscar Bruschi on 2026-05-27.
//

import SwiftUI

@main
struct PicartdoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var session = SessionStore()
    @State private var wishlist = WishlistStore()
    @State private var taste = TastePreferenceStore()
    @State private var homeFeed = HomeFeedStore()
    @State private var marketplace = MarketplaceStore()
    @State private var threads = ThreadPostStore()
    @State private var returningFromBackground = false

    init() {
        _ = ArtworkImageCache.shared
        ArtworkImageCache.shared.warmListedAssets()
        UIWindow.appearance().backgroundColor = UIColor(named: "LaunchBackground")
            ?? UIColor(Color.picardoBackground)
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environment(session)
                .environment(wishlist)
                .environment(taste)
                .environment(homeFeed)
                .environment(marketplace)
                .environment(threads)
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .background:
                        returningFromBackground = true
                    case .active:
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            if returningFromBackground {
                                returningFromBackground = false
                                homeFeed.refresh(taste: taste)
                            } else {
                                homeFeed.refreshIfNeeded(taste: taste)
                            }
                        }
                    default:
                        break
                    }
                }
        }
    }
}
