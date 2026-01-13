//
//  TemplatesView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MessageTemplate.name) private var allTemplates: [MessageTemplate]

    @State private var showingAddTemplate = false
    @State private var templateToEdit: MessageTemplate?
    @State private var showingDeleteConfirmation = false
    @State private var templateToDelete: MessageTemplate?
    @State private var showingStats = false
    @State private var templateToVariant: MessageTemplate?

    private var templatesByCategory: [TemplateCategory: [MessageTemplate]] {
        Dictionary(grouping: allTemplates, by: { $0.category })
    }

    private var sortedCategories: [TemplateCategory] {
        TemplateCategory.allCases
            .filter { templatesByCategory[$0] != nil || $0 == .custom }
            .sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            ForEach(sortedCategories) { category in
                Section {
                    let templates = templatesByCategory[category] ?? []

                    ForEach(templates) { template in
                        TemplateRow(template: template)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !template.isBuiltIn {
                                    templateToEdit = template
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if !template.isBuiltIn {
                                    Button(role: .destructive) {
                                        templateToDelete = template
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        templateToEdit = template
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(AppColors.primary)
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    templateToVariant = template
                                } label: {
                                    Label("A/B Test", systemImage: "arrow.triangle.branch")
                                }
                                .tint(.purple)
                            }
                    }

                    // Add custom template button in Custom section
                    if category == .custom {
                        Button {
                            showingAddTemplate = true
                        } label: {
                            Label("Add Custom Template", systemImage: "plus.circle.fill")
                                .foregroundStyle(AppColors.primary)
                        }
                    }
                } header: {
                    Label(category.rawValue, systemImage: category.icon)
                }
            }
        }
        .navigationTitle("Message Templates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingStats = true
                } label: {
                    Image(systemName: "chart.bar.fill")
                }
            }
        }
        .sheet(isPresented: $showingStats) {
            NavigationStack {
                TemplateStatsView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showingStats = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingAddTemplate) {
            NavigationStack {
                TemplateEditorView(mode: .create)
            }
        }
        .sheet(item: $templateToEdit) { template in
            NavigationStack {
                TemplateEditorView(mode: .edit(template))
            }
        }
        .sheet(item: $templateToVariant) { template in
            NavigationStack {
                TemplateEditorView(mode: .createVariant(template))
            }
        }
        .alert("Delete Template", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                templateToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let template = templateToDelete {
                    deleteTemplate(template)
                }
            }
        } message: {
            Text("Are you sure you want to delete this template? This cannot be undone.")
        }
    }

    private func deleteTemplate(_ template: MessageTemplate) {
        modelContext.delete(template)
        try? modelContext.save()
        templateToDelete = nil
    }
}

struct TemplateRow: View {
    let template: MessageTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(template.name)
                    .font(.headline)

                if template.isBuiltIn {
                    Text("Built-in")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }

                Spacer()

                if !template.isBuiltIn {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(template.preview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        TemplatesView()
    }
    .modelContainer(for: [Prospect.self, MessageTemplate.self], inMemory: true)
}
