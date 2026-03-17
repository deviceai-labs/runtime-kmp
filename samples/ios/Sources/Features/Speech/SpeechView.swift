import SwiftUI
import ComposableArchitecture

struct SpeechView: View {
    let store: StoreOf<SpeechFeature>

    var body: some View {
        Group {
            if store.modelPath == nil {
                noModelView
            } else {
                mainContent
            }
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Transcribe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear") { store.send(.clearTapped) }
                    .disabled(store.transcript.isEmpty && store.errorMessage == nil)
            }
        }
    }

    private var noModelView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No STT model selected")
                .font(.headline)
            Text("Tap the \u{24B8} icon above to download a Whisper model.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private var mainContent: some View {
        VStack(spacing: 24) {
            transcriptArea
            Spacer()
            recordButton
        }
        .padding(24)
    }

    // MARK: - Transcript area

    private var transcriptArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if store.isTranscribing {
                    HStack(spacing: 10) {
                        ProgressView().tint(AppTheme.accent)
                        Text("Transcribing…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                } else if !store.transcript.isEmpty {
                    Text(store.transcript)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !store.segments.isEmpty {
                        Divider()
                        ForEach(store.segments) { seg in
                            HStack(alignment: .top, spacing: 8) {
                                Text(formatMs(seg.startMs))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 52, alignment: .trailing)
                                Text(seg.text)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                } else if let error = store.errorMessage {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red.opacity(0.85))

                } else {
                    Text("Tap the mic to start recording.\nRuns fully on-device with Whisper.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .liquidGlassCardIfAvailable()
    }

    // MARK: - Record button

    private var recordButton: some View {
        Button {
            store.send(.recordButtonTapped)
        } label: {
            ZStack {
                Circle()
                    .fill(store.isRecording ? Color.red : AppTheme.accent)
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: (store.isRecording ? Color.red : AppTheme.accent).opacity(0.45),
                        radius: store.isRecording ? 20 : 10
                    )
                    .animation(.easeInOut(duration: 0.25), value: store.isRecording)

                Image(systemName: store.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
            }
        }
        .disabled(store.isTranscribing)
        .scaleEffect(store.isRecording ? 1.08 : 1.0)
        .animation(.spring(response: 0.3), value: store.isRecording)
        .padding(.bottom, 16)
    }

    private func formatMs(_ ms: Int64) -> String {
        let s = ms / 1000
        let m = s / 60
        return String(format: "%d:%02d", m, s % 60)
    }
}
