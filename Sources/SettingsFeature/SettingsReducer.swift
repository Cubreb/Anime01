//
//  SettingsReducer.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/8/22.
//  Copyright © 2022. All rights reserved.
//

import Build
import ComposableArchitecture
import DiscordClient
import FileClient
import ImageDatabaseClient
import SharedModels
import UserDefaultsClient
import Utilities
import ViewComponents

// MARK: - SettingsReducer

public struct SettingsReducer: ReducerProtocol {
    public init() {}

    public struct State: Equatable {
        // MARK: Anime Providers

        public var animeProviders = Loadable<[ProviderInfo]>.idle

        // MARK: Discord Properties

        public var supportsDiscord = false
        public var discordStatus = DiscordClient.Status.offline

        public var buildVersion = "Unknown"

        // MARK: Storage Settings

        public var imageCacheUsage = 0
        public var imageCacheCapacity = 0

        // MARK: User Settings

        @BindableState
        public var userSettings = UserSettings()

        public init() {}
    }

    public enum Action: BindableAction {
        case onAppear
        case refetchImageCache
        case resetImageCache
        case discordStatus(DiscordClient.Status)
        case binding(BindingAction<State>)
    }

    @Dependency(\.build)
    var build
    @Dependency(\.fileClient)
    var fileClient
    @Dependency(\.discordClient)
    var discordClient
    @Dependency(\.userDefaultsClient)
    var userDefaultsClient

    public var body: some ReducerProtocol<State, Action> {
        CombineReducers {
            BindingReducer()
            Reduce(core)
        }
        .onChange(of: \.userSettings) { userSettings, _, _ in
            struct SaveDebounceID: Hashable {}

            return .run {
                try await withTaskCancellation(id: SaveDebounceID.self, cancelInFlight: true) {
                    try await fileClient.save(userSettings: userSettings)
                }
            }
        }
    }
}

public extension SettingsReducer.State {
    var selectableAnimeProviders: Selectable<ProviderInfo> {
        .init(
            items: animeProviders.value ?? [],
            selected: userSettings.preferredProvider
        )
    }
}

extension SettingsReducer {
    struct DiscordClientStatusCancellable: Hashable {}

    private func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            state.buildVersion = "\(build.version()) (\(build.gitSha()))"
            return .merge(
                setupDiscord(&state),
                setupCache(&state)
            )

        case let .discordStatus(status):
            state.discordStatus = status

        case .resetImageCache:
            return .run { send in
                await ImageDatabase.shared.reset()
                await send(.refetchImageCache)
            }

        case .refetchImageCache:
            return setupCache(&state)

        case .binding(\.$userSettings.discordEnabled):
            let enabled = state.userSettings.discordEnabled

            return .run { _ in
                try await discordClient.setActive(enabled)
            }

        case .binding:
            break
        }
        return .none
    }

    private func setupDiscord(_ state: inout State) -> EffectTask<Action> {
        state.supportsDiscord = discordClient.isSupported
        if state.supportsDiscord {
            return .run { send in
                await withTaskCancellation(
                    id: DiscordClientStatusCancellable.self,
                    cancelInFlight: true
                ) {
                    for await status in discordClient.status() {
                        await send(.discordStatus(status))
                    }
                }
            }
        } else {
            return .none
        }
    }

    private func setupCache(_ state: inout State) -> EffectTask<Action> {
        state.imageCacheUsage = ImageDatabase.shared.diskUsage()
        state.imageCacheCapacity = ImageDatabase.shared.maxDiskCapacity()
        return .none
    }
}

public extension FileClient {
    func save(userSettings: UserSettings) async throws {
        try await save(userSettings, to: FileClient.userSettingsFileName)
    }

    func loadUserSettings() async throws -> UserSettings {
        try await load(UserSettings.self, from: FileClient.userSettingsFileName)
    }

    static let userSettingsFileName = "user-settings"
}
