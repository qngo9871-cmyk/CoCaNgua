import SwiftUI

enum GameSetupMode: String, CaseIterable, Identifiable {
    case solo, passAndPlay
    var id: String { rawValue }
}

struct HomeView: View {
    @EnvironmentObject var loc: LocalizationManager
    @StateObject private var purchases = PurchaseManager.shared
    @State private var showGame = false
    @State private var showRules = false
    @State private var showUpgrade = false
    @State private var showOnboarding = false
    @State private var mode: GameSetupMode = .solo
    @State private var localPlayerCount: Int = 2
    @State private var selectedDifficulty: AIDifficulty = .normal
    @State private var game = GameModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.05, green: 0.20, blue: 0.12), .black],
                                startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 22) {
                    Spacer()

                    VStack(spacing: 6) {
                        Text("🐴").font(.system(size: 52))
                        Text(L("home.title")).font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text(L("home.subtitle")).font(.subheadline).foregroundStyle(.white.opacity(0.7))
                    }

                    modeSection
                    difficultySection

                    VStack(spacing: 12) {
                        Button { startGame() } label: {
                            Text(L("home.play")).font(.title3.bold()).frame(maxWidth: 260).padding()
                        }
                        .buttonStyle(.borderedProminent).tint(.green)

                        HStack(spacing: 20) {
                            Button { showOnboarding = true } label: {
                                Text(L("home.howtoplay")).foregroundStyle(.white.opacity(0.85))
                            }
                            Button { showRules = true } label: {
                                Text(L("home.rules")).foregroundStyle(.white.opacity(0.85))
                            }
                        }

                        if !purchases.isPro {
                            Button { showUpgrade = true } label: {
                                Text(L("home.upgrade")).font(.footnote).foregroundStyle(.yellow)
                            }
                        }
                    }

                    Spacer()

                    Picker("", selection: $loc.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)
                    .padding(.bottom, 24)
                }
                .padding()
            }
            .navigationDestination(isPresented: $showGame) {
                GameView(game: game)
            }
            .sheet(isPresented: $showRules) { RulesView() }
            .sheet(isPresented: $showUpgrade) { UpgradeView() }
            .sheet(isPresented: $showOnboarding) { OnboardingView(onFinished: { showOnboarding = false }) }
            .task { await purchases.loadProduct() }
        }
    }

    private var modeSection: some View {
        VStack(spacing: 10) {
            Picker(L("home.mode"), selection: $mode) {
                Text(L("home.mode.solo")).tag(GameSetupMode.solo)
                Text(L("home.mode.passAndPlay") + (purchases.isPro ? "" : " 🔒")).tag(GameSetupMode.passAndPlay)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)

            if mode == .passAndPlay {
                if purchases.isPro {
                    Stepper(value: $localPlayerCount, in: 2...4) {
                        Text(String(format: L("home.players"), localPlayerCount))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: 280)
                } else {
                    Button { showUpgrade = true } label: {
                        Text(L("home.mode.passAndPlayLocked")).font(.caption).foregroundStyle(.yellow)
                    }
                }
            }
        }
    }

    private var difficultySection: some View {
        VStack(spacing: 8) {
            Text(L("home.difficulty")).font(.caption).foregroundStyle(.white.opacity(0.6))
            if purchases.isPro {
                Picker("", selection: $selectedDifficulty) {
                    ForEach(AIDifficulty.allCases) { d in
                        Text(L(d.titleKey)).tag(d)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
            } else {
                Button { showUpgrade = true } label: {
                    HStack(spacing: 6) {
                        Text(L("difficulty.normal")).font(.subheadline.bold())
                        Image(systemName: "lock.fill").font(.caption2)
                    }
                    .foregroundStyle(.white.opacity(0.85))
                }
                Text(L("home.difficultyLocked")).font(.caption2).foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private func startGame() {
        if mode == .passAndPlay && !purchases.isPro {
            showUpgrade = true
            return
        }
        let difficulty: AIDifficulty = purchases.isPro ? selectedDifficulty : .normal
        let humanCount = mode == .solo ? 1 : localPlayerCount
        game = GameModel()
        game.startMatch(humanCount: humanCount, aiDifficulty: difficulty)
        showGame = true
    }
}

#Preview { HomeView().environmentObject(LocalizationManager.shared) }
