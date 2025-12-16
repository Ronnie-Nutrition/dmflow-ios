//
//  ProspectCard.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI

struct ProspectCard: View {
    let prospect: Prospect
    let onSwipeRight: () -> Void
    let onSwipeLeft: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showingDetail = false

    private let swipeThreshold: CGFloat = 100

    var body: some View {
        ZStack {
            HStack {
                if offset > 0 {
                    swipeActionView(
                        icon: "arrow.right.circle.fill",
                        color: AppColors.success,
                        text: prospect.stage.next?.displayName ?? ""
                    )
                    Spacer()
                }

                if offset < 0 {
                    Spacer()
                    swipeActionView(
                        icon: "arrow.left.circle.fill",
                        color: AppColors.warning,
                        text: prospect.stage.previous?.displayName ?? ""
                    )
                }
            }

            cardContent
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let canSwipeRight = prospect.stage.next != nil
                            let canSwipeLeft = prospect.stage.previous != nil

                            if value.translation.width > 0 && canSwipeRight {
                                offset = value.translation.width
                            } else if value.translation.width < 0 && canSwipeLeft {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3)) {
                                if offset > swipeThreshold {
                                    onSwipeRight()
                                } else if offset < -swipeThreshold {
                                    onSwipeLeft()
                                }
                                offset = 0
                            }
                        }
                )
        }
        .sheet(isPresented: $showingDetail) {
            NavigationStack {
                ProspectDetailView(prospect: prospect)
            }
        }
    }

    private var cardContent: some View {
        Button {
            showingDetail = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: prospect.platform.icon)
                    .font(.title3)
                    .foregroundStyle(prospect.platform.color)
                    .frame(width: 36, height: 36)
                    .background(prospect.platform.color.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(prospect.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        if prospect.isHotLead {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }

                    if let handle = prospect.handle, !handle.isEmpty {
                        Text("@\(handle)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if prospect.isOverdue {
                        Text("Overdue")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.danger)
                    } else if prospect.isDueToday {
                        Text("Today")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.warning)
                    }

                    Text("\(prospect.daysSinceLastContact)d")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func swipeActionView(icon: String, color: Color, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
            if !text.isEmpty {
                Text(text)
                    .font(.caption2)
            }
        }
        .foregroundStyle(color)
        .frame(width: 80)
    }
}

#Preview {
    VStack {
        ProspectCard(
            prospect: Prospect(
                name: "John Smith",
                handle: "johnsmith",
                platform: .instagram,
                stage: .engaged,
                isHotLead: true
            ),
            onSwipeRight: {},
            onSwipeLeft: {}
        )

        ProspectCard(
            prospect: Prospect(
                name: "Jane Doe",
                platform: .facebook,
                stage: .new
            ),
            onSwipeRight: {},
            onSwipeLeft: {}
        )
    }
    .padding()
    .background(AppColors.background)
    .modelContainer(for: Prospect.self, inMemory: true)
}
