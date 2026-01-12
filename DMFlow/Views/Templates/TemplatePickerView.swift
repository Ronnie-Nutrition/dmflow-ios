//
//  TemplatePickerView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData

struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MessageTemplate.name) private var allTemplates: [MessageTemplate]

    let prospect: Prospect
    let onSelect: (String) -> Void

    @State private var searchText = ""
    @State private var selectedCategory: TemplateCategory?
    @State private var showCopiedFeedback = false

    private var filteredTemplates: [MessageTemplate] {
        var templates = allTemplates

        // Filter by category
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }

        // Filter by search
        if !searchText.isEmpty {
            templates = templates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        return templates
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryPill(
                            title: "All",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }

                        ForEach(TemplateCategory.allCases) { category in
                            CategoryPill(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))

                Divider()

                // Templates list
                if filteredTemplates.isEmpty {
                    ContentUnavailableView {
                        Label("No Templates", systemImage: "doc.text")
                    } description: {
                        Text("No templates match your search")
                    }
                } else {
                    List {
                        ForEach(filteredTemplates) { template in
                            TemplatePickerRow(
                                template: template,
                                prospect: prospect,
                                onUse: { message in
                                    UIPasteboard.general.string = message
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                    onSelect(message)
                                    dismiss()
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Use Template")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search templates")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct CategoryPill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? AppColors.primary : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

struct TemplatePickerRow: View {
    let template: MessageTemplate
    let prospect: Prospect
    let onUse: (String) -> Void

    private var populatedMessage: String {
        TemplateService.shared.replacePlaceholders(template.content, prospect: prospect)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.headline)

                Spacer()

                Text(template.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }

            Text(populatedMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack {
                Spacer()

                Button {
                    onUse(populatedMessage)
                } label: {
                    Label("Copy & Use", systemImage: "doc.on.doc")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TemplatePickerView(
        prospect: Prospect(name: "John Smith", handle: "johnsmith", platform: .instagram),
        onSelect: { _ in }
    )
    .modelContainer(for: [Prospect.self, MessageTemplate.self], inMemory: true)
}
