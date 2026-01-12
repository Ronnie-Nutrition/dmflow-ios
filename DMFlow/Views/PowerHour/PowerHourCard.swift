//
//  PowerHourCard.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI

struct PowerHourCard: View {
    let prospect: Prospect
    @Binding var suggestedMessage: String?
    @Binding var isGeneratingMessage: Bool
    @Binding var showCopiedFeedback: Bool

    let onContacted: () -> Void
    let onSkip: () -> Void
    let onSnooze: () -> Void
    let onGenerateMessage: () -> Void
    let onRegenerateMessage: () -> Void

    @State private var localCopiedFeedback = false
    @State private var offset: CGFloat = 0
    @State private var showingTemplatePicker = false
    private let swipeThreshold: CGFloat = 120

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                contextSection
                aiMessageSection
                actionsSection
            }
            .padding()
        }
        .offset(x: offset)
        .gesture(swipeGesture)
        .sheet(isPresented: $showingTemplatePicker) {
            TemplatePickerView(prospect: prospect) { message in
                suggestedMessage = message
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Platform icon
            ZStack {
                Circle()
                    .fill(prospect.platform.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: prospect.platform.icon)
                    .font(.largeTitle)
                    .foregroundStyle(prospect.platform.color)
            }

            // Name and handle
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text(prospect.name)
                        .font(.title)
                        .fontWeight(.bold)

                    if prospect.isHotLead {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    }
                }

                if let handle = prospect.handle, !handle.isEmpty {
                    if let profileURL = prospect.platform.profileURL(for: handle) {
                        Button {
                            UIApplication.shared.open(profileURL)
                        } label: {
                            HStack(spacing: 4) {
                                Text("@\(handle)")
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                            }
                            .font(.subheadline)
                            .foregroundStyle(prospect.platform.color)
                        }
                    } else {
                        Text("@\(handle)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Platform badge
                Text(prospect.platform.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(prospect.platform.color.opacity(0.15))
                    .foregroundStyle(prospect.platform.color)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Context Section

    private var contextSection: some View {
        VStack(spacing: 16) {
            // Funnel stage
            HStack {
                Image(systemName: prospect.stage.icon)
                    .foregroundStyle(prospect.stage.color)
                Text(prospect.stage.displayName)
                    .fontWeight(.medium)
                Spacer()
                Text(prospect.stage.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(prospect.stage.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Stats row
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(prospect.daysSinceLastContact)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(prospect.daysSinceLastContact > 7 ? AppColors.warning : .primary)
                    Text("days ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                if let followUp = prospect.nextFollowUp {
                    VStack(spacing: 4) {
                        Text(followUpStatus(for: followUp))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(prospect.isOverdue ? AppColors.danger : AppColors.warning)
                        Text("follow-up")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Notes preview
            if let notes = prospect.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundStyle(.secondary)
                        Text("Notes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }

                    Text(notes)
                        .font(.body)
                        .lineLimit(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - AI Message Section

    private var aiMessageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Suggested Message", systemImage: "sparkles")
                    .font(.headline)

                Spacer()

                if !UsageTracker.shared.isPro {
                    Text("PRO")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }

            if let message = suggestedMessage {
                VStack(alignment: .leading, spacing: 12) {
                    Text(message)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    HStack {
                        Button {
                            UIPasteboard.general.string = message
                            localCopiedFeedback = true
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                localCopiedFeedback = false
                            }
                        } label: {
                            Label(localCopiedFeedback ? "Copied!" : "Copy",
                                  systemImage: localCopiedFeedback ? "checkmark" : "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .tint(localCopiedFeedback ? .green : nil)
                        .controlSize(.small)

                        Spacer()

                        Button {
                            onRegenerateMessage()
                        } label: {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isGeneratingMessage)
                    }
                }
            } else {
                HStack(spacing: 12) {
                    Button {
                        onGenerateMessage()
                    } label: {
                        HStack {
                            if isGeneratingMessage {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Generating...")
                            } else {
                                Image(systemName: "sparkles")
                                Text("AI Suggest")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                    .disabled(isGeneratingMessage)

                    Button {
                        showingTemplatePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Template")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Primary action - Contacted
            Button {
                onContacted()
            } label: {
                Label("Mark as Contacted", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.success)

            HStack(spacing: 12) {
                // Skip
                Button {
                    onSkip()
                } label: {
                    Label("Skip", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                // Snooze
                Button {
                    onSnooze()
                } label: {
                    Label("Snooze 1 Day", systemImage: "clock.arrow.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.warning)
            }

            // Swipe hint
            Text("Swipe right to mark contacted, left to skip")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
        }
        .padding()
    }

    // MARK: - Helpers

    private func followUpStatus(for date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let followUpDay = calendar.startOfDay(for: date)

        let days = calendar.dateComponents([.day], from: today, to: followUpDay).day ?? 0

        if days < 0 {
            return "Overdue \(abs(days))d"
        } else if days == 0 {
            return "Today"
        } else {
            return "In \(days)d"
        }
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation.width
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if value.translation.width > swipeThreshold {
                        // Swipe right - mark contacted
                        onContacted()
                    } else if value.translation.width < -swipeThreshold {
                        // Swipe left - skip
                        onSkip()
                    }
                    offset = 0
                }
            }
    }
}

#Preview {
    PowerHourCard(
        prospect: Prospect(
            name: "John Smith",
            handle: "johnsmith",
            platform: .instagram,
            stage: .engaged,
            nextFollowUp: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            notes: "Interested in weight loss products. Has a large following.",
            isHotLead: true
        ),
        suggestedMessage: .constant(nil),
        isGeneratingMessage: .constant(false),
        showCopiedFeedback: .constant(false),
        onContacted: {},
        onSkip: {},
        onSnooze: {},
        onGenerateMessage: {},
        onRegenerateMessage: {}
    )
    .padding()
    .background(AppColors.background)
}
