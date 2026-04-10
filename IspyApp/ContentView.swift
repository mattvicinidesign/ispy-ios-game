import SwiftUI
import SpriteKit

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
    var clues: [String] = []
    var items: [FindableItem] = []
}

enum ActiveScreen {
    case menu, level
}

// MARK: - Root

struct ContentView: View {

    @State private var state = GameState()

    var body: some View {
        ZStack {
            Color(white: 0.08)
                .ignoresSafeArea()

            SpriteView(scene: sceneForScreen())
                .ignoresSafeArea()
                .id(state.activeScreen)
                .transition(.opacity)

            switch state.activeScreen {
            case .menu:
                MenuOverlay(state: state)
                    .transition(.opacity)
            case .level:
                LevelOverlay(state: state)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: state.activeScreen)
    }

    private func sceneForScreen() -> SKScene {
        switch state.activeScreen {
        case .menu:
            let scene = MenuScene()
            scene.scaleMode = .resizeFill
            return scene
        case .level:
            let scene = FirstScene(gameState: state)
            scene.scaleMode = .resizeFill
            return scene
        }
    }
}

// MARK: - Menu overlay (replaces all MenuScene UI)

private struct MenuOverlay: View {
    let state: GameState

    var body: some View {
        VStack(spacing: 40) {
            Text("I Spy")
                .font(.custom("AvenirNext-Bold", size: 52))
                .foregroundStyle(.white)

            Button {
                state.activeScreen = .level
            } label: {
                Text("Play Level 1")
                    .font(.custom("AvenirNext-Bold", size: 34))
                    .foregroundStyle(.white)
                    .frame(width: 320, height: 110)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(white: 0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(.white.opacity(0.5), lineWidth: 3)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Level overlay (back button + HUD + win screen)

private struct LevelOverlay: View {
    let state: GameState

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topBar
                Spacer()
                itemBar
            }

            if state.isComplete {
                winOverlay
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                state.activeScreen = .menu
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .font(.custom("AvenirNext-DemiBold", size: 17))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var itemBar: some View {
        HStack(spacing: 0) {
            ForEach(state.items) { item in
                let found = item.id < state.foundFlags.count && state.foundFlags[item.id]
                FindableItemView(item: item, found: found)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Rectangle())
    }

    private var winOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("You found them all!")
                    .font(.custom("AvenirNext-Bold", size: 28))
                    .foregroundStyle(.white)

                Text(state.levelName)
                    .font(.custom("AvenirNext-Regular", size: 17))
                    .foregroundStyle(Color(white: 0.85))

                Button {
                    state.activeScreen = .menu
                } label: {
                    Text("Back to menu")
                        .font(.custom("AvenirNext-DemiBold", size: 18))
                        .foregroundStyle(.white)
                        .frame(width: 220, height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(white: 0.22))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(.white.opacity(0.45), lineWidth: 2)
                                )
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 20)
            }
        }
    }
}

// MARK: - Findable item cell (reusable — swap icon for real asset later)

private struct FindableItemView: View {
    let item: FindableItem
    let found: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(found ? Color(red: 0.5, green: 0.95, blue: 0.55).opacity(0.25) : Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(found ? Color(red: 0.5, green: 0.95, blue: 0.55) : .white)

                if found {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.45))
                        .offset(x: 16, y: -16)
                }
            }

            Text(item.name)
                .font(.custom("AvenirNext-Regular", size: 10))
                .foregroundStyle(found ? Color(red: 0.5, green: 0.95, blue: 0.55) : Color(white: 0.75))
                .lineLimit(1)
        }
    }
}

#Preview {
    ContentView()
}
