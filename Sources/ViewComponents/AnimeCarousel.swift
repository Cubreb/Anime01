//
//  AnimeCarousel.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/17/22.
//
//  Modified version of https://github.com/manuelduarte077/CustomCarouselList/blob/main/Shared/View/SnapCarousel.swift

import SwiftUI
import Foundation
import SharedModels
import IdentifiedCollections

public struct AnimeCarousel<Content: View, T: AnimeRepresentable>: View {

    /// Properties....

    @Binding var position: Int

    var spacing: CGFloat

    var list: [T]
    var content: (T) -> Content

    public init(
        position: Binding<Int>,
        spacing: CGFloat = 0,
        items: [T],
        @ViewBuilder content: @escaping (T)->Content
    ) {
        self._position = position
        self.list = items
        self.spacing = spacing
        self.content = content
    }

    // Offset...
    @GestureState private var translation: CGFloat = 0

    public var body: some View {
        ZStack(alignment: .bottom) {
            scrollItems

            VStack(spacing: 8) {
                header
                indicators
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom))
        }
    }
}

extension AnimeCarousel {
    private var anime: (any AnimeRepresentable)? {
        translation == .zero ? list[safe: position] : nil
    }

    @ViewBuilder
    var header: some View {
        ZStack {
            if let anime {
                Text(anime.title)
                    .font(.title.weight(.bold))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                EmptyView()
            }
        }
        .animation(.spring(), value: translation == .zero)
    }
}

extension AnimeCarousel {
    @ViewBuilder
    var scrollItems: some View {
        GeometryReader { proxy in
            HStack(spacing: spacing) {
                ForEach(list) { item in
                    content(item)
                        .frame(width: proxy.size.width)
                }
            }
            .padding(.horizontal, spacing)
            .offset(x: -CGFloat(position) * proxy.size.width)
            .offset(x: translation)
            .highPriorityGesture(
                DragGesture()
                    .updating($translation, body: { value, out, _ in
                        let shouldRestrict = position == 0 && value.translation.width > 0 || position == list.count - 1 && value.translation.width < 0
//                        out = value.translation.width / (shouldRestrict ? log10(abs(value.translation.width)) : 1)
                        out = shouldRestrict ? 0 : value.translation.width
                    })
                    .onEnded({ value in
                        let offset = -(value.translation.width / proxy.size.width)
                        let roundIndex: Int

                        if abs(offset) > 0.3 {
                            roundIndex = offset > 0 ? 1 : -1
                        } else {
                            roundIndex = 0
                        }

                        position = max(min(position + roundIndex, list.count - 1), 0)
                    })
            )
        }
        .animation(.easeInOut, value: translation == 0)
    }
}

extension AnimeCarousel {
    @ViewBuilder
    var indicators: some View {
        HStack(spacing: 6) {
            ForEach(
                indicatorStates
            ) { state in
                if state.size != .gone {
                    Circle()
                        .fill(Color.white.opacity(state.selected ? 1 : 0.5))
                        .frame(width: 6, height: 6)
                        .scaleEffect(state.scale)
                }
            }
            .animation(.spring(), value: indicatorStates)
        }
    }

    struct IndicatorState: Hashable, Identifiable {
        let id: Int
        var size: Size

        enum Size: Hashable {
            case gone
            case smallest
            case small
            case normal
            case selected
        }

        var scale: Double {
            switch size {
            case .gone:
                return 0
            case .smallest:
                return 0.5
            case .small:
                return 0.75
            case .normal:
                return 1.0
            case .selected:
                return 1.4
            }
        }

        var selected: Bool {
            size == .selected
        }
    }

    private var indicatorStates: [IndicatorState] {
        guard list.indices.count > 0 && position >= 0 && position < list.indices.count else {
            return []
        }

        var indicatorStates = list.indices.map { IndicatorState.init(id: $0, size: .gone) }
        let indicatorCount = indicatorStates.count

        let maxIndicators = 9

        let halfMaxIndicators = Int(floor(Double(maxIndicators) / 2))
        let halfMaxIndicatorsCeil = Int(ceil(Double(maxIndicators) / 2))

        let leftSideCount = position - halfMaxIndicators
        let rightSideCount = position + halfMaxIndicatorsCeil

        let addMissingLeftSideItems = leftSideCount < 0 ? abs(leftSideCount) : 0
        let addMissingRightSideItems = rightSideCount > indicatorCount ? rightSideCount - indicatorCount : 0

        let startIndex = max(leftSideCount - addMissingRightSideItems, 0)
        let endIndex = min(rightSideCount + addMissingLeftSideItems, indicatorCount)

        for index in startIndex..<endIndex {
            if (startIndex == index && leftSideCount == 0) || (startIndex + 1 == index && leftSideCount >= 1) {
                indicatorStates[index].size = .small
            } else if startIndex == index && leftSideCount >= 1 {
                indicatorStates[index].size = .smallest
            } else if (endIndex - 2 == index && rightSideCount < indicatorCount) || (endIndex - 1 == index && rightSideCount == indicatorCount) {
                indicatorStates[index].size = .small
            } else if endIndex - 1 == index && rightSideCount < indicatorCount {
                indicatorStates[index].size = .smallest
            } else {
                indicatorStates[index].size = .normal
            }
        }

        indicatorStates[position].size = .selected

        return indicatorStates
    }
}
