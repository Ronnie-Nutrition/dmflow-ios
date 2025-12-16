//
//  ProspectSection.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI

struct ProspectSection: View {
    let title: String
    let icon: String
    let color: Color
    let prospects: [Prospect]
    var showCount: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)

                Text(title)
                    .font(.headline)

                if showCount {
                    Text("\(prospects.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(color)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            ForEach(prospects) { prospect in
                NavigationLink {
                    ProspectDetailView(prospect: prospect)
                } label: {
                    ProspectListItem(prospect: prospect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

struct ProspectListItem: View {
    let prospect: Prospect

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: prospect.platform.icon)
                .font(.body)
                .foregroundStyle(prospect.platform.color)
                .frame(width: 32, height: 32)
                .background(prospect.platform.color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(prospect.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if prospect.isHotLead {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                HStack(spacing: 8) {
                    Text(prospect.stage.displayName)
                        .font(.caption2)
                        .foregroundStyle(prospect.stage.color)

                    if let followUp = prospect.nextFollowUp {
                        Text(followUp, format: .dateTime.month().day())
                            .font(.caption2)
                            .foregroundStyle(prospect.isOverdue ? AppColors.danger : .secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProspectSection(
        title: "Hot Leads",
        icon: "flame.fill",
        color: .orange,
        prospects: [
            Prospect(name: "John Smith", platform: .instagram, isHotLead: true),
            Prospect(name: "Jane Doe", platform: .facebook, isHotLead: true)
        ]
    )
    .padding()
    .background(AppColors.background)
    .modelContainer(for: Prospect.self, inMemory: true)
}
