//
//  AppFlowView.swift
//  zahlmeischter
//
//  Top-level flow: launch animation → (first run) onboarding → app. The launch plays
//  once per process; from Profil the user can replay either the intro or the launch.
//

import SwiftUI

struct AppFlowView: View {
    @Environment(AppState.self) private var appState

    private enum Phase { case launch, onboarding, app }
    @State private var phase: Phase = .launch

    var body: some View {
        ZStack {
            switch phase {
            case .launch:
                LaunchView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        phase = appState.hasOnboarded ? .app : .onboarding
                    }
                }
            case .onboarding:
                OnboardingView {
                    appState.hasOnboarded = true
                    withAnimation(.easeInOut(duration: 0.4)) { phase = .app }
                }
                .transition(.opacity)
            case .app:
                RootView(
                    replayOnboarding: { withAnimation(.easeInOut(duration: 0.4)) { phase = .onboarding } },
                    replayLaunch: { withAnimation(.easeInOut(duration: 0.4)) { phase = .launch } }
                )
                .transition(.opacity)
            }
        }
    }
}
