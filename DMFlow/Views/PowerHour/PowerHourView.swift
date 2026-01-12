//
//  PowerHourView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData

struct PowerHourView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allProspects: [Prospect]

    @State private var currentIndex: Int = 0
    @State private var contactsMade: Int = 0
    @State private var skipped: Int = 0
    @State private var sessionStartTime: Date = Date()
    @State private var isSessionComplete: Bool = false
    @State private var showingPaywall = false
    @State private var showSuccessOverlay = false
    @State private var showSkipOverlay = false

    // AI message state for current prospect
    @State private var suggestedMessage: String?
    @State private var isGeneratingMessage = false
    @State private var aiError: String?

    private var powerHourProspects: [Prospect] {
        // Priority order: Overdue -> Today -> Hot Leads
        let overdue = allProspects.filter { $0.isOverdue && $0.stage != .client && $0.stage != .dnd }
            .sorted { ($0.nextFollowUp ?? Date()) < ($1.nextFollowUp ?? Date()) }

        let today = allProspects.filter { $0.isDueToday && $0.stage != .client && $0.stage != .dnd }
            .sorted { $0.name < $1.name }

        // Hot leads that aren't already in overdue or today
        let hot = allProspects.filter { prospect in
            prospect.isHotLead &&
            !prospect.isOverdue &&
            !prospect.isDueToday &&
            prospect.stage != .client &&
            prospect.stage != .dnd
        }
        .sorted { $0.lastContact > $1.lastContact }

        return overdue + today + hot
    }

    private var currentProspect: Prospect? {
        guard currentIndex < powerHourProspects.count else { return nil }
        return powerHourProspects[currentIndex]
    }

    private var progressText: String {
        "\(currentIndex + 1) of \(powerHourProspects.count)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                if isSessionComplete {
                    PowerHourSummaryView(
                        contactsMade: contactsMade,
                        skipped: skipped,
                        sessionDuration: Date().timeIntervalSince(sessionStartTime),
                        onDismiss: { dismiss() }
                    )
                } else if let prospect = currentProspect {
                    ZStack {
                        PowerHourCard(
                            prospect: prospect,
                            suggestedMessage: $suggestedMessage,
                            isGeneratingMessage: $isGeneratingMessage,
                            showCopiedFeedback: .constant(false),
                            onContacted: { handleContacted() },
                            onSkip: { handleSkip() },
                            onSnooze: { handleSnooze() },
                            onGenerateMessage: { generateMessage(for: prospect) },
                            onRegenerateMessage: { generateMessage(for: prospect) }
                        )
                        .id(prospect.id) // Force view refresh when prospect changes
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                        // Success overlay
                        if showSuccessOverlay {
                            VStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(.white)
                                Text("Contacted!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(AppColors.success.opacity(0.9))
                            .transition(.opacity)
                        }

                        // Skip overlay
                        if showSkipOverlay {
                            VStack {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.white)
                                Text("Skipped")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.85))
                            .transition(.opacity)
                        }
                    }
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Power Hour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if contactsMade > 0 || skipped > 0 {
                            isSessionComplete = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }

                if !isSessionComplete && currentProspect != nil {
                    ToolbarItem(placement: .principal) {
                        Text(progressText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .alert("AI Error", isPresented: .init(
                get: { aiError != nil },
                set: { if !$0 { aiError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(aiError ?? "")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.success)

            Text("All Caught Up!")
                .font(.title)
                .fontWeight(.bold)

            Text("No prospects need follow-up right now.\nGreat work staying on top of things!")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .padding(.top)
        }
        .padding()
    }

    // MARK: - Actions

    private func handleContacted() {
        guard let prospect = currentProspect else { return }

        // Mark as contacted
        prospect.markContacted()
        try? modelContext.save()

        // Haptic feedback - success
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        contactsMade += 1

        // Show success overlay
        withAnimation(.easeIn(duration: 0.2)) {
            showSuccessOverlay = true
        }

        // Move to next after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.15)) {
                showSuccessOverlay = false
            }
            moveToNext()
        }
    }

    private func handleSkip() {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        skipped += 1

        // Show skip overlay briefly
        withAnimation(.easeIn(duration: 0.15)) {
            showSkipOverlay = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.1)) {
                showSkipOverlay = false
            }
            moveToNext()
        }
    }

    private func handleSnooze() {
        guard let prospect = currentProspect else { return }

        // Snooze by 1 day
        let newDate = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: prospect.nextFollowUp ?? Date()
        )
        prospect.nextFollowUp = newDate
        prospect.updatedAt = Date()
        try? modelContext.save()

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        skipped += 1

        // Show skip overlay for snooze too
        withAnimation(.easeIn(duration: 0.15)) {
            showSkipOverlay = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.1)) {
                showSkipOverlay = false
            }
            moveToNext()
        }
    }

    private func moveToNext() {
        // Clear AI message for next prospect
        suggestedMessage = nil
        aiError = nil

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if currentIndex < powerHourProspects.count - 1 {
                currentIndex += 1
            } else {
                isSessionComplete = true
            }
        }
    }

    private func generateMessage(for prospect: Prospect) {
        guard UsageTracker.shared.canUseAI else {
            showingPaywall = true
            return
        }

        isGeneratingMessage = true

        Task {
            do {
                let message = try await AIService.shared.generateFollowUpMessage(for: prospect)
                await MainActor.run {
                    suggestedMessage = message
                    isGeneratingMessage = false
                }
            } catch let error as AIError {
                await MainActor.run {
                    isGeneratingMessage = false
                    if case .proRequired = error {
                        showingPaywall = true
                    } else {
                        aiError = error.localizedDescription
                    }
                }
            } catch {
                await MainActor.run {
                    isGeneratingMessage = false
                    aiError = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    PowerHourView()
        .modelContainer(for: Prospect.self, inMemory: true)
}
