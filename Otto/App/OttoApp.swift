import SwiftUI
import SwiftData

@main
struct OttoApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .fontDesign(.rounded)
                .background(Color.appBackground.ignoresSafeArea())
                .task {
                    await appState.subscriptionManager.observeTransactionUpdates()
                }
        }
        .modelContainer(for: [Vehicle.self, ChatSession.self, ChatMessage.self])
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Vehicle.createdAt) private var vehicles: [Vehicle]

    @State private var dragOffset: CGFloat = 0
    private let sidebarFraction: CGFloat = 0.82

    private let springAnimation = Animation.spring(response: 0.35, dampingFraction: 0.85)

    var body: some View {
        Group {
            if appState.subscriptionManager.shouldShowPaywall {
                PaywallView()
            } else if vehicles.isEmpty {
                OnboardingView()
            } else {
                GeometryReader { geo in
                    let sidebarWidth = geo.size.width * sidebarFraction

                    ZStack(alignment: .leading) {
                        // Sidebar — sits behind, revealed when main content pushes right
                        ChatHistoryView()
                            .frame(width: sidebarWidth)
                            .background(Color.appBackground.ignoresSafeArea())

                        // Main content — pushes right when sidebar opens
                        mainContent(geo: geo, sidebarWidth: sidebarWidth)
                    }
                    .gesture(sidebarDragGesture(sidebarWidth: sidebarWidth))
                }
                .ignoresSafeArea(.keyboard)
            }
        }
        .onAppear {
            if appState.activeVehicle == nil {
                appState.activeVehicle = vehicles.first(where: { $0.isActive }) ?? vehicles.first
            }
            // Always start with a fresh chat on launch
            if appState.activeSession == nil, let vehicle = appState.activeVehicle {
                let session = ChatSession(title: "New Chat", vehicle: vehicle)
                modelContext.insert(session)
                appState.activeSession = session
            }
            appState.subscriptionManager.updatePaywallVisibility()
        }
        .task {
            await appState.subscriptionManager.refreshSubscriptionStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                appState.lastBackgroundDate = Date()
            case .active:
                // Create a fresh chat if returning after 30+ minutes
                if let backgroundDate = appState.lastBackgroundDate,
                   Date().timeIntervalSince(backgroundDate) > AppState.freshChatThreshold,
                   let vehicle = appState.activeVehicle {
                    let session = ChatSession(title: "New Chat", vehicle: vehicle)
                    modelContext.insert(session)
                    appState.activeSession = session
                }
                appState.lastBackgroundDate = nil
                // Refresh subscription status when returning to foreground
                Task {
                    await appState.subscriptionManager.refreshSubscriptionStatus()
                }
            default:
                break
            }
        }
        .onChange(of: vehicles.count) { oldCount, newCount in
            if oldCount == 0 && newCount > 0 {
                let vehicle = vehicles.first(where: { $0.isActive }) ?? vehicles.first
                appState.activeVehicle = vehicle

                if let vehicle, appState.activeSession == nil {
                    let session = ChatSession(title: "New Chat", vehicle: vehicle)
                    modelContext.insert(session)
                    appState.activeSession = session
                }
            } else if appState.activeVehicle == nil {
                appState.activeVehicle = vehicles.first(where: { $0.isActive }) ?? vehicles.first
            }
            appState.subscriptionManager.updatePaywallVisibility()
        }
        .onChange(of: appState.subscriptionManager.isSubscribed) {
            appState.subscriptionManager.updatePaywallVisibility()
        }
    }

    @ViewBuilder
    private func mainContent(geo: GeometryProxy, sidebarWidth: CGFloat) -> some View {
        let isOpen = appState.showSidebar

        NavigationStack {
            ChatView()
        }
        .frame(width: geo.size.width)
        .background(Color.appBackground.ignoresSafeArea())
        .mask {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .ignoresSafeArea()
        }
        .shadow(color: .black.opacity(isOpen ? 0.15 : 0), radius: 10, x: -3)
        .overlay {
            if isOpen {
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(Color.black.opacity(0.04))
                    .ignoresSafeArea()
                    .allowsHitTesting(true)
                    .onTapGesture {
                        withAnimation(springAnimation) {
                            appState.showSidebar = false
                        }
                    }
            }
        }
        .offset(x: mainOffset(sidebarWidth: sidebarWidth))
        .animation(springAnimation, value: appState.showSidebar)
        .onChange(of: appState.showSidebar) { _, isOpen in
            if isOpen {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }

    private func mainOffset(sidebarWidth: CGFloat) -> CGFloat {
        if appState.showSidebar {
            return sidebarWidth + min(dragOffset, 0)
        } else {
            return max(dragOffset, 0)
        }
    }

    private func sidebarDragGesture(sidebarWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                if appState.showSidebar {
                    // Drag left to close
                    if value.translation.width < 0 {
                        dragOffset = value.translation.width
                    }
                } else {
                    // Drag right from left edge to open
                    if value.startLocation.x < 30 && value.translation.width > 0 {
                        dragOffset = value.translation.width
                    }
                }
            }
            .onEnded { value in
                if appState.showSidebar {
                    if value.translation.width < -80 || value.predictedEndTranslation.width < -120 {
                        withAnimation(springAnimation) { appState.showSidebar = false }
                    }
                } else {
                    if value.startLocation.x < 30 &&
                       (value.translation.width > 80 || value.predictedEndTranslation.width > 120) {
                        withAnimation(springAnimation) { appState.showSidebar = true }
                    }
                }
                withAnimation(springAnimation) { dragOffset = 0 }
            }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: [Vehicle.self, ChatSession.self, ChatMessage.self], inMemory: true)
}
