//
//  PaywallView.swift
//  DMFlow
//
//  Created by Ronnie Craig
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private let subscriptionManager = SubscriptionManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    productsSection
                    restoreButton
                    termsSection
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("DMFlow Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Upgrade to DMFlow Pro")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Unlock powerful features to supercharge your outreach and grow your business faster.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureRow(icon: "person.3.fill", title: "Unlimited Prospects", description: "No limits on your pipeline")
            FeatureRow(icon: "doc.text.fill", title: "Unlimited Templates", description: "Create as many scripts as you need")
            FeatureRow(icon: "sparkles", title: "AI Message Suggestions", description: "Context-aware follow-up messages")
            FeatureRow(icon: "arrow.triangle.branch", title: "A/B Script Analytics", description: "Track which messages convert best")
            FeatureRow(icon: "chart.bar.doc.horizontal", title: "Advanced Stats", description: "Detailed metrics and conversion insights")
            FeatureRow(icon: "square.and.arrow.up", title: "Export Data", description: "Export your prospects to CSV")
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var productsSection: some View {
        VStack(spacing: 12) {
            if subscriptionManager.isLoading && subscriptionManager.products.isEmpty {
                ProgressView()
                    .padding()
            } else {
                if let yearly = subscriptionManager.yearlyProduct {
                    ProductButton(
                        product: yearly,
                        isSelected: selectedProduct?.id == yearly.id,
                        badge: "BEST VALUE",
                        duration: "1 Year",
                        subtitle: "Save 52% - just $3.33/month"
                    ) {
                        selectedProduct = yearly
                    }
                }

                if let monthly = subscriptionManager.monthlyProduct {
                    ProductButton(
                        product: monthly,
                        isSelected: selectedProduct?.id == monthly.id,
                        badge: nil,
                        duration: "1 Month",
                        subtitle: "Billed monthly, cancel anytime"
                    ) {
                        selectedProduct = monthly
                    }
                }

                Button {
                    Task {
                        await purchase()
                    }
                } label: {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Subscribe Now")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedProduct != nil ? Color.orange : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(selectedProduct == nil || isPurchasing)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            if let yearly = subscriptionManager.yearlyProduct {
                selectedProduct = yearly
            }
        }
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task {
                await subscriptionManager.restorePurchases()
                if subscriptionManager.isPro {
                    dismiss()
                }
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("DMFlow Pro includes unlimited prospects, unlimited templates, AI message suggestions, A/B analytics, advanced stats, and data export for the duration of your subscription.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Payment will be charged to your Apple ID account. Manage or cancel your subscription in Settings > Apple ID > Subscriptions.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                if let privacyURL = URL(string: "https://ronnie-nutrition.github.io/dmflow-ios/privacy/") {
                    Link("Privacy Policy", destination: privacyURL)
                }
                if let termsURL = URL(string: "https://ronnie-nutrition.github.io/dmflow-ios/terms/") {
                    Link("Terms of Use", destination: termsURL)
                }
            }
            .font(.caption2)
        }
        .padding(.horizontal)
    }

    private func purchase() async {
        guard let product = selectedProduct else { return }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let success = try await subscriptionManager.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ProductButton: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let duration: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .fontWeight(.medium)
                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text(duration)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(duration == "1 Year" ? "/year" : "/month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .orange : .secondary)
            }
            .padding()
            .background(isSelected ? Color.orange.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
}
