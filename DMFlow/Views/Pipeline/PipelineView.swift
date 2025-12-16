//
//  PipelineView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData

struct PipelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProspects: [Prospect]
    @State private var showingAddProspect = false
    @State private var selectedStage: FunnelStage?

    private func prospects(for stage: FunnelStage) -> [Prospect] {
        allProspects
            .filter { $0.stage == stage }
            .sorted { $0.lastContact > $1.lastContact }
    }

    var body: some View {
        NavigationStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(FunnelStage.pipelineStages) { stage in
                        StageColumn(
                            stage: stage,
                            prospects: prospects(for: stage),
                            onMoveNext: moveToNextStage,
                            onMovePrevious: moveToPreviousStage
                        )
                    }
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Pipeline")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddProspect = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddProspect) {
                AddProspectView()
            }
        }
    }

    private func moveToNextStage(_ prospect: Prospect) {
        withAnimation(.spring(response: 0.3)) {
            prospect.moveToNextStage()
        }
    }

    private func moveToPreviousStage(_ prospect: Prospect) {
        withAnimation(.spring(response: 0.3)) {
            prospect.moveToPreviousStage()
        }
    }
}

struct StageColumn: View {
    let stage: FunnelStage
    let prospects: [Prospect]
    let onMoveNext: (Prospect) -> Void
    let onMovePrevious: (Prospect) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: stage.icon)
                    .foregroundStyle(stage.color)

                Text(stage.displayName)
                    .font(.headline)

                Spacer()

                Text("\(prospects.count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(stage.color)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(stage.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(prospects) { prospect in
                        ProspectCard(
                            prospect: prospect,
                            onSwipeRight: { onMoveNext(prospect) },
                            onSwipeLeft: { onMovePrevious(prospect) }
                        )
                    }
                }
            }
        }
        .frame(width: 280)
    }
}

#Preview {
    PipelineView()
        .modelContainer(for: Prospect.self, inMemory: true)
}
