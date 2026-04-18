import SwiftUI

struct ValidationResultsView: View {

    let report: ValidationReport
    var onGoToSettings: (() -> Void)? = nil

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Summary banner
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: report.isValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundStyle(report.isValid ? .green : .red)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(report.isValid ? "Ready to Export" : "Issues Found")
                                .font(.headline)
                            Text(report.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    if hasMetadataIssues, let goToSettings = onGoToSettings {
                        Button {
                            dismiss()
                            goToSettings()
                        } label: {
                            Label("Fix in Book Settings", systemImage: "gear")
                        }
                    }
                }

                // Errors
                if !report.errors.isEmpty {
                    Section {
                        ForEach(report.errors, id: \.self) { error in
                            IssueRow(text: error, severity: .error)
                        }
                    } header: {
                        Label("Errors — Must Fix", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }

                // Warnings
                if !report.warnings.isEmpty {
                    Section {
                        ForEach(report.warnings, id: \.self) { warning in
                            IssueRow(text: warning, severity: .warning)
                        }
                    } header: {
                        Label("Warnings", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }

                // Info
                if !report.info.isEmpty {
                    Section {
                        ForEach(report.info, id: \.self) { note in
                            IssueRow(text: note, severity: .info)
                        }
                    } header: {
                        Label("Notes", systemImage: "info.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }

                if report.totalIssues == 0 {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.green)
                            Text("No Issues")
                                .font(.headline)
                            Text("Your document passed all checks for \(report.format.rawValue).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle("Validation — \(report.format.rawValue)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // True if any issue string mentions missing metadata fields
    private var hasMetadataIssues: Bool {
        let all = report.errors + report.warnings + report.info
        return all.contains { $0.localizedCaseInsensitiveContains("missing") && $0.localizedCaseInsensitiveContains("metadata") }
    }
}

// MARK: - Issue Row

private struct IssueRow: View {

    enum Severity { case error, warning, info }

    let text: String
    let severity: Severity

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 2)
    }

    private var iconName: String {
        switch severity {
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var iconColor: Color {
        switch severity {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

// MARK: - Preview

#Preview {
    let report = ValidationReport(
        format: .kdp,
        errors: ["Missing required metadata: title"],
        warnings: ["Long text without chapter breaks"],
        info: ["PDF format has fewer requirements"]
    )
    ValidationResultsView(report: report) {
        print("Go to settings tapped")
    }
}
