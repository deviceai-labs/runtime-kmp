import SwiftUI
import ComposableArchitecture
import DeviceAiCore
import DeviceAiStt
import DeviceAiLlm

struct ModelsView: View {
    @Bindable var store: StoreOf<ModelManagerFeature>

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.sttEntries) { entry in
                        SttModelRow(
                            entry: entry,
                            isInUse: store.selectedSttId == entry.id,
                            onDownload: { store.send(.sttDownloadTapped(entry.id)) },
                            onSelect:   { store.send(.sttSelectTapped(entry.id)) }
                        )
                    }
                } header: {
                    Label("Speech (Whisper STT)", systemImage: "waveform")
                }

                Section {
                    ForEach(store.llmEntries) { entry in
                        LlmModelRow(
                            entry: entry,
                            isInUse: store.selectedLlmId == entry.id,
                            onDownload: { store.send(.llmDownloadTapped(entry.id)) },
                            onSelect:   { store.send(.llmSelectTapped(entry.id)) }
                        )
                    }
                } header: {
                    Label("Chat (LLM)", systemImage: "cpu")
                }
            }
            .navigationTitle("Models")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { store.send(.appeared) }
        }
    }
}

// MARK: - STT row

private struct SttModelRow: View {
    let entry: ModelManagerFeature.SttEntry
    let isInUse: Bool
    let onDownload: () -> Void
    let onSelect:   () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Leading: name + size
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.model.displayName)
                    .font(.body)
                Text(entry.model.formattedSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Trailing: status control
            ModelStatusControl(
                status: entry.downloadStatus,
                isInUse: isInUse,
                onDownload: onDownload,
                onSelect: onSelect
            )
        }
        .padding(.vertical, 4)
    }
}

// MARK: - LLM row

private struct LlmModelRow: View {
    let entry: ModelManagerFeature.LlmEntry
    let isInUse: Bool
    let onDownload: () -> Void
    let onSelect:   () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.model.displayName)
                        .font(.body)
                    Text(entry.model.quantization)
                        .font(.caption2)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.15), in: Capsule())
                        .foregroundStyle(.secondary)
                }
                Text(entry.model.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(entry.model.formattedSize)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            ModelStatusControl(
                status: entry.downloadStatus,
                isInUse: isInUse,
                onDownload: onDownload,
                onSelect: onSelect
            )
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Shared status control

private struct ModelStatusControl: View {
    let status: ModelManagerFeature.ModelDownloadStatus
    let isInUse: Bool
    let onDownload: () -> Void
    let onSelect:   () -> Void

    var body: some View {
        switch status {
        case .notDownloaded:
            Button(action: onDownload) {
                Image(systemName: "arrow.down.circle")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
            }
            .buttonStyle(.plain)

        case .downloading(let fraction):
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.3), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.2), value: fraction)
            }
            .frame(width: 26, height: 26)

        case .downloaded:
            if isInUse {
                Text("In Use")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.accent.opacity(0.12), in: Capsule())
            } else {
                Button("Select", action: onSelect)
                    .font(.caption.weight(.medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }
}

// MARK: - Helpers

private extension ModelInfo {
    var formattedSize: String {
        let mb = Double(sizeBytes) / 1_048_576
        return mb >= 1024
            ? String(format: "%.1f GB", mb / 1024)
            : String(format: "%.0f MB", mb)
    }
}
