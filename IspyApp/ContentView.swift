import SwiftUI
import SpriteKit

// MARK: - Shared navigation + game state

@Observable
final class GameState {
    var activeScreen: ActiveScreen = .menu
    var foundFlags: [Bool] = []
    var isComplete = false
    var levelName = ""
    var clues: [String] = []
}

enum ActiveScreen {
    case menu, level
}

// MARK: - Root

struct ContentView: View {

    @State private var state = GameState()

    var body: some View {
        ZStack {
            SpriteView(scene: sceneForScreen())
                .ignoresSafeArea()
                .id(state.activeScreen)

            switch state.activeScreen {
            case .menu:
                MenuOverlay(state: state)
            case .level:
                LevelOverlay(state: state)
            }
        }
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
            VStack {
                topBar
                Spacer()
                clueBar
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

    private var clueBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !state.levelName.isEmpty {
                Text(state.levelName.uppercased())
                    .font(.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundStyle(Color(white: 0.75))
                    .frame(maxWidth: .infinity)
            }
            ForEach(Array(state.clues.enumerated()), id: \.offset) { i, clue in
                let found = i < state.foundFlags.count && state.foundFlags[i]
                HStack(alignment: .top, spacing: 8) {
                    Text(found ? "✓" : "○")
                        .foregroundStyle(found ? Color(red: 0.5, green: 0.95, blue: 0.55) : .white)
                    Text(clue)
                        .foregroundStyle(found ? Color(red: 0.5, green: 0.95, blue: 0.55) : .white)
                }
                .font(.custom("AvenirNext-Regular", size: 15))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.05, opacity: 0.82))
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

#Preview {
    ContentView()
}
