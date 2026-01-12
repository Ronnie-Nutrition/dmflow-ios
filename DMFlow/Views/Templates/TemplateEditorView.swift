//
//  TemplateEditorView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    enum Mode {
        case create
        case edit(MessageTemplate)
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mode: Mode

    @State private var name: String = ""
    @State private var category: TemplateCategory = .custom
    @State private var content: String = ""
    @State private var showingPlaceholderHelp = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingTemplate: MessageTemplate? {
        if case .edit(let template) = mode { return template }
        return nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !content.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var previewText: String {
        // Show preview with sample data
        let sampleProspect = Prospect(name: "Sarah Johnson")
        return TemplateService.shared.replacePlaceholders(content, prospect: sampleProspect)
    }

    var body: some View {
        Form {
            Section {
                TextField("Template Name", text: $name)

                Picker("Category", selection: $category) {
                    ForEach(TemplateCategory.allCases.filter { $0 != .custom || !isEditing }) { cat in
                        Label(cat.rawValue, systemImage: cat.icon)
                            .tag(cat)
                    }
                }
            } header: {
                Text("Details")
            }

            Section {
                TextEditor(text: $content)
                    .frame(minHeight: 120)

                Button {
                    showingPlaceholderHelp = true
                } label: {
                    Label("Insert Placeholder", systemImage: "curlybraces")
                }
            } header: {
                Text("Message Content")
            } footer: {
                Text("Use placeholders like {{name}} to personalize messages")
            }

            if !content.isEmpty {
                Section {
                    Text(previewText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Preview")
                } footer: {
                    Text("Preview shows how the message will look with sample data (Sarah Johnson)")
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Template" : "New Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveTemplate()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            if let template = editingTemplate {
                name = template.name
                category = template.category
                content = template.content
            }
        }
        .sheet(isPresented: $showingPlaceholderHelp) {
            PlaceholderHelpSheet(onSelect: { placeholder in
                content += placeholder
                showingPlaceholderHelp = false
            })
            .presentationDetents([.medium])
        }
    }

    private func saveTemplate() {
        if let template = editingTemplate {
            // Update existing template
            template.name = name.trimmingCharacters(in: .whitespaces)
            template.category = category
            template.content = content.trimmingCharacters(in: .whitespaces)
            template.updatedAt = Date()
        } else {
            // Create new template
            let template = MessageTemplate(
                name: name.trimmingCharacters(in: .whitespaces),
                category: category,
                content: content.trimmingCharacters(in: .whitespaces),
                isBuiltIn: false
            )
            modelContext.insert(template)
        }

        try? modelContext.save()
        dismiss()
    }
}

struct PlaceholderHelpSheet: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(TemplateService.placeholderInfo, id: \.placeholder) { info in
                        Button {
                            onSelect(info.placeholder)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(info.placeholder)
                                        .font(.headline)
                                        .fontDesign(.monospaced)
                                    Text(info.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(AppColors.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Available Placeholders")
                } footer: {
                    Text("Tap a placeholder to insert it into your message")
                }
            }
            .navigationTitle("Placeholders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TemplateEditorView(mode: .create)
    }
    .modelContainer(for: [Prospect.self, MessageTemplate.self], inMemory: true)
}
