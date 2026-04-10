import SwiftUI
import SpriteKit

// MARK: - Layout scaling

struct ScaledMetric {
    let factor: CGFloat
    func value(_ base: CGFloat) -> CGFloat { base * factor }
}

private struct ScaleKey: EnvironmentKey {
    static let defaultValue = ScaledMetric(factor: 1.0)
}

extension EnvironmentValues {
    var uiScale: ScaledMetric {
        get { self[ScaleKey.self] }
        set { self[ScaleKey.self] = newValue }
    }
}

// MARK: - Shared navigation + game state

struct FindableItem: Identifiable {
    let id: Int
    let name: String
    let icon: String
}

@Observable
final class GameState {
    var activeScreen: ActiveScreen = .menu
    var foundFlags: [Bool] = []
    var isComplete = false
    var levelName = ""
    var items: [FindableItem] = []
    var settingsOpen = false

    // Currency
    var coins: Int = 0
    static let coinsPerFind = 10
    static let coinsPerLevel = 50
    static let hintCost = 25

    // Hint — index of the item to highlight, nil when idle
    var hintTargetIndex: Int?

    var canAffordHint: Bool {
        coins >= Self.hintCost && !isComplete && foundFlags.contains(false)
    }

    func awardFind() {
        coins += Self.coinsPerFind
    }

    func awardLevelComplete() {
        coins += Self.coinsPerLevel
    }

    func useHint() {
        guard canAffordHint else { return }
        let unfound = foundFlags.enumerated().compactMap { i, found in found ? nil : i }
        guard let target = unfound.randomElement() else { return }
        coins -= Self.hintCost
        hintTargetIndex = target
    }
}

enum ActiveScreen {
    case menu, level
}

// MARK: - Root

struct ContentView: View {

    @State private var state = GameState()
    @State private var sceneID = UUID()
    @State private var currentScene: SKScene?
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var uiScale: ScaledMetric {
        ScaledMetric(factor: sizeClass == .regular ? 1.35 : 1.0)
    }

    var body: some View {
        ZStack {
            Color(white: 0.08)
                .ignoresSafeArea()

            if let scene = currentScene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
                    .id(sceneID)
                    .transition(.opacity)
            }

            switch state.activeScreen {
            case .menu:
                MenuOverlay(state: state)
                    .transition(.opacity)
            case .level:
                LevelOverlay(state: state)
                    .transition(.opacity)
            }
        }
        .environment(\.uiScale, uiScale)
        .animation(.easeInOut(duration: 0.25), value: state.activeScreen)
        .preferredColorScheme(.dark)
        .onChange(of: state.activeScreen) { _, _ in
            buildScene()
        }
        .onAppear { buildScene() }
    }

    private func buildScene() {
        state.settingsOpen = false
        state.hintTargetIndex = nil

        let scene: SKScene
        switch state.activeScreen {
        case .menu:
            scene = MenuScene()
        case .level:
            scene = FirstScene(gameState: state)
        }
        scene.scaleMode = .resizeFill
        currentScene = scene
        sceneID = UUID()
    }
}

// MARK: - Menu overlay (replaces all MenuScene UI)

private struct MenuOverlay: View {
    let state: GameState
    @Environment(\.uiScale) private var scale

    var body: some View {
        ZStack {
            VStack(spacing: scale.value(40)) {
                Text("I Spy")
                    .font(.custom("AvenirNext-Bold", size: scale.value(52)))
                    .foregroundStyle(.white)

                Button {
                    state.activeScreen = .level
                } label: {
                    Text("Play Level 1")
                        .font(.custom("AvenirNext-Bold", size: scale.value(34)))
                        .foregroundStyle(.white)
                        .frame(width: scale.value(320), height: scale.value(110))
                        .background(
                            RoundedRectangle(cornerRadius: scale.value(18))
                                .fill(Color(white: 0.18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: scale.value(18))
                                        .strokeBorder(.white.opacity(0.5), lineWidth: 3)
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            VStack {
                HStack {
                    Spacer()
                    CoinPill(coins: state.coins)
                    SettingsButton(state: state)
                }
                .padding(.horizontal, scale.value(16))
                .padding(.top, scale.value(8))
                Spacer()
            }

            if state.settingsOpen {
                SettingsSheet(state: state)
            }
        }
    }
}

// MARK: - Level overlay (back button + HUD + win screen)

private struct LevelOverlay: View {
    let state: GameState
    @Environment(\.uiScale) private var scale

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topBar
                Spacer()
                HStack {
                    Spacer()
                    HintButton(state: state)
                }
                .padding(.trailing, scale.value(16))
                .padding(.bottom, scale.value(10))
                itemBar
            }

            if state.isComplete {
                winOverlay
            }

            if state.settingsOpen {
                SettingsSheet(state: state)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: scale.value(10)) {
            Button {
                state.activeScreen = .menu
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .font(.custom("AvenirNext-DemiBold", size: scale.value(17)))
                    .foregroundStyle(.white)
                    .padding(.horizontal, scale.value(14))
                    .padding(.vertical, scale.value(8))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: scale.value(10)))
            }
            Spacer()
            CoinPill(coins: state.coins)
            SettingsButton(state: state)
        }
        .padding(.horizontal, scale.value(16))
        .padding(.top, scale.value(8))
    }

    private var itemBar: some View {
        HStack(spacing: 0) {
            ForEach(state.items) { item in
                let found = item.id < state.foundFlags.count && state.foundFlags[item.id]
                FindableItemView(item: item, found: found)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, scale.value(8))
        .padding(.vertical, scale.value(10))
        .background(.ultraThinMaterial, in: Rectangle())
    }

    private var winOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: scale.value(12)) {
                Text("You found them all!")
                    .font(.custom("AvenirNext-Bold", size: scale.value(28)))
                    .foregroundStyle(.white)

                Text(state.levelName)
                    .font(.custom("AvenirNext-Regular", size: scale.value(17)))
                    .foregroundStyle(Color(white: 0.85))

                Button {
                    state.activeScreen = .menu
                } label: {
                    Text("Back to menu")
                        .font(.custom("AvenirNext-DemiBold", size: scale.value(18)))
                        .foregroundStyle(.white)
                        .frame(width: scale.value(220), height: scale.value(52))
                        .background(
                            RoundedRectangle(cornerRadius: scale.value(14))
                                .fill(Color(white: 0.22))
                                .overlay(
                                    RoundedRectangle(cornerRadius: scale.value(14))
                                        .strokeBorder(.white.opacity(0.45), lineWidth: 2)
                                )
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, scale.value(20))
            }
        }
    }
}

// MARK: - Coin pill

private struct CoinPill: View {
    let coins: Int
    @Environment(\.uiScale) private var scale

    var body: some View {
        HStack(spacing: scale.value(5)) {
            Image(systemName: "circle.fill")
                .font(.system(size: scale.value(14)))
                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.2))
            Text("\(coins)")
                .font(.custom("AvenirNext-DemiBold", size: scale.value(16)))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, scale.value(12))
        .padding(.vertical, scale.value(7))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: scale.value(10)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(coins) coins")
    }
}

// MARK: - Hint button (level only)

private struct HintButton: View {
    let state: GameState
    @Environment(\.uiScale) private var scale

    var body: some View {
        Button {
            state.useHint()
        } label: {
            HStack(spacing: scale.value(5)) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: scale.value(15)))
                Text("\(GameState.hintCost)")
                    .font(.custom("AvenirNext-DemiBold", size: scale.value(14)))
                    .monospacedDigit()
                Image(systemName: "circle.fill")
                    .font(.system(size: scale.value(9)))
                    .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.2))
            }
            .foregroundStyle(state.canAffordHint ? .white : Color(white: 0.45))
            .padding(.horizontal, scale.value(12))
            .padding(.vertical, scale.value(8))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: scale.value(10)))
        }
        .buttonStyle(.plain)
        .disabled(!state.canAffordHint)
        .accessibilityLabel("Use hint")
        .accessibilityValue(state.canAffordHint ? "Available, costs \(GameState.hintCost) coins" : "Not enough coins")
    }
}

// MARK: - Settings button (reusable across all screens)

private struct SettingsButton: View {
    let state: GameState
    @Environment(\.uiScale) private var scale

    var body: some View {
        Button {
            state.settingsOpen = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: scale.value(18)))
                .foregroundStyle(.white)
                .padding(scale.value(10))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: scale.value(10)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
    }
}

// MARK: - Settings sheet (placeholder)

private struct SettingsSheet: View {
    let state: GameState
    @Environment(\.uiScale) private var scale

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { state.settingsOpen = false }

            VStack(spacing: scale.value(24)) {
                Text("Settings")
                    .font(.custom("AvenirNext-Bold", size: scale.value(28)))
                    .foregroundStyle(.white)

                Text("Coming soon")
                    .font(.custom("AvenirNext-Regular", size: scale.value(17)))
                    .foregroundStyle(Color(white: 0.7))

                Button {
                    state.settingsOpen = false
                } label: {
                    Text("Close")
                        .font(.custom("AvenirNext-DemiBold", size: scale.value(18)))
                        .foregroundStyle(.white)
                        .frame(width: scale.value(180), height: scale.value(48))
                        .background(
                            RoundedRectangle(cornerRadius: scale.value(14))
                                .fill(Color(white: 0.22))
                                .overlay(
                                    RoundedRectangle(cornerRadius: scale.value(14))
                                        .strokeBorder(.white.opacity(0.45), lineWidth: 2)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(scale.value(40))
            .background(
                RoundedRectangle(cornerRadius: scale.value(20))
                    .fill(Color(white: 0.12))
            )
        }
    }
}

// MARK: - Findable item cell

private struct FindableItemView: View {
    let item: FindableItem
    let found: Bool
    @Environment(\.uiScale) private var scale

    private let foundColor = Color(red: 0.5, green: 0.95, blue: 0.55)
    private let checkColor = Color(red: 0.4, green: 0.85, blue: 0.45)

    var body: some View {
        VStack(spacing: scale.value(4)) {
            ZStack {
                Circle()
                    .fill(found ? foundColor.opacity(0.25) : Color.white.opacity(0.1))
                    .frame(width: scale.value(44), height: scale.value(44))

                Image(systemName: item.icon)
                    .font(.system(size: scale.value(20)))
                    .foregroundStyle(found ? foundColor : .white)

                if found {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: scale.value(14)))
                        .foregroundStyle(checkColor)
                        .offset(x: scale.value(16), y: scale.value(-16))
                }
            }

            Text(item.name)
                .font(.custom("AvenirNext-Regular", size: scale.value(10)))
                .foregroundStyle(found ? foundColor : Color(white: 0.75))
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(found ? "found" : "not found")")
    }
}

#Preview {
    ContentView()
}
