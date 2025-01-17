//
//  SettingsView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 12/15/22.
//

import Awesome
import ComposableArchitecture
import DiscordClient
import SwiftUI
import ViewComponents

// MARK: - SettingsView

public struct SettingsView: View {
    @Environment(\.openURL)
    var openURL

    let store: StoreOf<SettingsReducer>
    @ObservedObject
    var viewStore: ViewStoreOf<SettingsReducer>

    public init(store: StoreOf<SettingsReducer>) {
        self.store = store
        self.viewStore = .init(store) { $0 }
    }

    public var body: some View {
        StackNavigation(title: "Settings") {
            ScrollView {
                LazyVStack(spacing: 24) {
                    SettingsGroupView(title: "General") {
                        SettingsRowView.listSelection(name: "Provider", selectable: viewStore.selectableAnimeProviders) { provider in
                            viewStore.send(
                                .binding(
                                    .set(\.$userSettings.preferredProvider, provider)
                                )
                            )
                        } itemView: { item in
                            Text(item.description)
                        }
                    }

                    if viewStore.supportsDiscord {
                        SettingsGroupView(title: "Discord") {
                            SettingsRowView(
                                name: "Enable",
                                active: viewStore.binding(\.$userSettings.discordEnabled)
                            )

                            if viewStore.userSettings.discordEnabled {
                                SettingsRowView(
                                    name: "Status",
                                    text: viewStore.discordStatus.rawValue
                                )
                            }
                        }
                        .animation(
                            .easeInOut(
                                duration: 0.12
                            ),
                            value: viewStore.state
                        )
                    }

                    SettingsGroupView(title: "About") {
                        SettingsRowView(
                            name: "Image Cache Utilized",
                            text: "\(viewStore.imageCacheUsage / (1_024 * 1_024)) Mb / \(viewStore.imageCacheCapacity / (1_024 * 1_024)) Mb"
                        )
                        .onLongPressGesture {
                            viewStore.send(.resetImageCache)
                        }

                        SettingsRowView.views(
                            name: "Socials"
                        ) {
                            VStack(spacing: 12) {
                                Button {
                                    // swiftlint:disable force_unwrapping
                                    openURL(.init(string: "https://github.com/AnimeNow-Team/AnimeNow")!)
                                } label: {
                                    HStack {
                                        Awesome.Brand.github.image
                                            .foregroundColor(.white)
                                            .size(24)

                                        Text("GitHub")
                                            .font(.body.weight(.bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(
                                            cornerRadius: 12,
                                            style: .continuous
                                        )
                                        .foregroundColor(
                                            .init(
                                                red: 0.09,
                                                green: 0.08,
                                                blue: 0.08
                                            )
                                        )
                                    )
                                }
                                .buttonStyle(.plain)

                                Button {
                                    // swiftlint:disable force_unwrapping
                                    openURL(.init(string: "https://discord.gg/R5v8Sa3WHE")!)
                                } label: {
                                    HStack {
                                        Awesome.Brand.discord.image
                                            .foregroundColor(.white)
                                            .size(24)

                                        Text("Join our Discord")
                                            .font(.body.weight(.bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(
                                            cornerRadius: 12,
                                            style: .continuous
                                        )
                                        .foregroundColor(
                                            .init(
                                                .sRGB,
                                                red: 0.4470,
                                                green: 0.5372,
                                                blue: 0.8549
                                            )
                                        )
                                    )
                                }
                                .buttonStyle(.plain)

                                Button {
                                    // swiftlint:disable force_unwrapping
                                    openURL(.init(string: "https://www.buymeacoffee.com/animenow")!)
                                } label: {
                                    Text("☕ Buy me a coffee")
                                        .font(.body.weight(.bold))
                                        .foregroundColor(.black)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(
                                                cornerRadius: 12,
                                                style: .continuous
                                            )
                                            .foregroundColor(.yellow)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding()
                        }
                    }
                }
                .padding(.horizontal)

                VStack {
                    Text("Made with ❤️")
                    Text("Version: \(viewStore.buildVersion)")
                }
                .padding()
                .font(.footnote.weight(.semibold))
                .foregroundColor(.gray)

                ExtraBottomSafeAreaInset()
            }
        }
        .onAppear {
            viewStore.send(.onAppear)
        }
    }
}

// MARK: - SettingsView_Previews

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            store: .init(
                initialState: .init(),
                reducer: EmptyReducer()
            )
        )
        .preferredColorScheme(.dark)
        .frame(width: 300)
        .fixedSize()
    }
}
