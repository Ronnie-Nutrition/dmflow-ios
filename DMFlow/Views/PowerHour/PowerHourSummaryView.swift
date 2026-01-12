//
//  PowerHourSummaryView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI

struct PowerHourSummaryView: View {
    let contactsMade: Int
    let skipped: Int
    let sessionDuration: TimeInterval
    let onDismiss: () -> Void

    private var formattedDuration: String {
        let minutes = Int(sessionDuration) / 60
        let seconds = Int(sessionDuration) % 60

        if minutes > 0 {
            return "\(minutes) min \(seconds) sec"
        } else {
            return "\(seconds) seconds"
        }
    }

    private var motivationalMessage: String {
        if contactsMade >= 10 {
            return "Outstanding! You're crushing it!"
        } else if contactsMade >= 5 {
            return "Great work! You're building momentum."
        } else if contactsMade >= 1 {
            return "Nice start! Every contact counts."
        } else {
            return "Ready to try again when you are!"
        }
    }

    private var totalProcessed: Int {
        contactsMade + skipped
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Celebration icon
            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: contactsMade > 0 ? "bolt.fill" : "bolt")
                    .font(.system(size: 50))
                    .foregroundStyle(AppColors.success)
            }

            // Title
            Text("Power Hour Complete!")
                .font(.title)
                .fontWeight(.bold)

            // Stats
            HStack(spacing: 40) {
                StatBox(
                    value: contactsMade,
                    label: "Contacted",
                    color: AppColors.success
                )

                StatBox(
                    value: skipped,
                    label: "Skipped",
                    color: .secondary
                )
            }

            // Duration
            VStack(spacing: 4) {
                Text("Session Duration")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(formattedDuration)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Motivational message
            Text(motivationalMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Done button
            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatBox: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text("\(value)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(width: 100)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

#Preview {
    PowerHourSummaryView(
        contactsMade: 8,
        skipped: 2,
        sessionDuration: 1120,
        onDismiss: {}
    )
    .background(AppColors.background)
}
