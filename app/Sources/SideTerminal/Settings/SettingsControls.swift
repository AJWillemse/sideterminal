import SwiftUI
import AppKit
import Carbon.HIToolbox
import SideTerminalCore

// MARK: - Shortcut recorder

/// macOS-style shortcut recorder: click, press the chord, done. The combo
/// is probed system-wide before it's accepted; a taken shortcut is refused
/// with feedback and the previous one stays active.
struct ShortcutRecorder: View {
    @EnvironmentObject var settings: AppSettings

    @State private var isRecording = false
    @State private var message: String?
    @State private var messageIsError = false
    @State private var keyMonitor: Any?

    private var currentDisplay: String? {
        HotKeySpec(string: settings.globalShortcut)?.display
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            HStack(spacing: 6) {
                Button(action: toggleRecording) {
                    HStack(spacing: 6) {
                        if isRecording {
                            Image(systemName: "record.circle.fill")
                                .foregroundStyle(.red)
                                .font(.system(size: 11))
                            Text("Press shortcut…")
                                .foregroundStyle(.secondary)
                        } else if let display = currentDisplay {
                            Text(display)
                                .font(.system(size: 13, weight: .medium))
                        } else {
                            Text("Record Shortcut")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(minWidth: 132)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color(nsColor: .quaternarySystemFill))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(
                                isRecording ? Color.accentColor : Color(nsColor: .separatorColor),
                                lineWidth: isRecording ? 1.5 : 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .help(isRecording ? "Press the keys, or Esc to cancel" : "Click to record a new shortcut")

                if !isRecording, currentDisplay != nil {
                    Button {
                        settings.globalShortcut = ""
                        note("Shortcut removed", error: false)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .help("Remove the shortcut")
                }
            }

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(messageIsError ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                    .transition(.opacity)
            }
        }
        .onDisappear { stopRecording() }
    }

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        isRecording = true
        message = nil
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
            return nil // swallow while recording
        }
    }

    private func stopRecording() {
        isRecording = false
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    private func handle(_ event: NSEvent) {
        // Esc cancels (unless it's part of a chord).
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if Int(event.keyCode) == kVK_Escape,
           flags.intersection([.command, .option, .control]).isEmpty {
            stopRecording()
            return
        }

        guard let (spec, string) = HotKeySpec.from(event: event) else {
            note("Use ⌘, ⌥ or ⌃ plus a key", error: true)
            return // keep recording
        }

        let available = (NSApp.delegate as? AppDelegate)?
            .testShortcutAvailability(spec) ?? GlobalHotKey.isAvailable(spec)
        if available {
            settings.globalShortcut = string
            note("\(spec.display) is now active", error: false)
        } else {
            note("\(spec.display) isn’t available — another app is using it", error: true)
        }
        stopRecording()
    }

    private func note(_ text: String, error: Bool) {
        withAnimation(.easeOut(duration: 0.15)) {
            message = text
            messageIsError = error
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                if message == text { message = nil }
            }
        }
    }
}

// MARK: - Font picker

/// A modern font chooser: a compact button that opens a searchable,
/// scrolling popover anchored to the row — every family previewed in its
/// own typeface. Never leaves the settings panel, never takes the screen.
struct FontPickerButton: View {
    @EnvironmentObject var settings: AppSettings
    @State private var showPicker = false
    @State private var search = ""

    static let defaultLabel = "SideTerminal Default"

    /// Fixed-pitch families installed on this Mac; terminals need monospace.
    private static let monospacedFamilies: [String] = {
        let manager = NSFontManager.shared
        return manager.availableFontFamilies.filter { family in
            guard let font = manager.font(
                withFamily: family, traits: [], weight: 5, size: 12
            ) else { return false }
            return font.isFixedPitch
        }
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }()

    private var families: [String] {
        var list = Self.monospacedFamilies
        if !settings.fontFamily.isEmpty, !list.contains(settings.fontFamily) {
            list.insert(settings.fontFamily, at: 0)
        }
        guard !search.isEmpty else { return list }
        return list.filter { $0.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        Button {
            search = ""
            showPicker.toggle()
        } label: {
            HStack(spacing: 6) {
                Text(settings.fontFamily.isEmpty ? Self.defaultLabel : settings.fontFamily)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 12)
            .frame(minWidth: 150, maxWidth: 230)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color(nsColor: .quaternarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPicker, arrowEdge: .bottom) {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    TextField("Search fonts", text: $search)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)

                Divider()

                ScrollView {
                    LazyVStack(spacing: 1) {
                        if search.isEmpty {
                            fontRow(
                                title: Self.defaultLabel,
                                previewFont: .monospacedSystemFont(ofSize: 13, weight: .regular),
                                selected: settings.fontFamily.isEmpty
                            ) {
                                settings.fontFamily = ""
                            }
                            Divider().padding(.vertical, 3)
                        }
                        ForEach(families, id: \.self) { family in
                            fontRow(
                                title: family,
                                previewFont: NSFont(name: family, size: 13)
                                    ?? .monospacedSystemFont(ofSize: 13, weight: .regular),
                                selected: settings.fontFamily == family
                            ) {
                                settings.fontFamily = family
                            }
                        }
                        if families.isEmpty {
                            Text("No fonts match “\(search)”")
                                .foregroundStyle(.secondary)
                                .font(.callout)
                                .padding(.vertical, 20)
                        }
                    }
                    .padding(6)
                }
                .frame(width: 280, height: 300)
            }
        }
    }

    @ViewBuilder
    private func fontRow(
        title: String,
        previewFont: NSFont,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
            showPicker = false
        } label: {
            HStack {
                Text(title)
                    .font(Font(previewFont))
                    .lineLimit(1)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(selected ? Color.accentColor.opacity(0.14) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Validated path field
// PathRequirement (path validation) lives in SideTerminalCore so it's tested.

/// Free-form path entry with live verification: a quiet green check when
/// the path resolves, a red mark with a hint when it doesn't. Empty always
/// counts as valid — it means "use the default", which is shown as the
/// placeholder so the effective value is never a mystery.
struct ValidatedPathField: View {
    @Binding var text: String
    let placeholder: String
    let requirement: PathRequirement
    let invalidHint: String

    private var isValid: Bool {
        text.isEmpty || requirement.validate(text)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 6) {
                if !text.isEmpty {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(isValid ? AnyShapeStyle(.green) : AnyShapeStyle(.red))
                        .font(.system(size: 12))
                        .help(isValid ? "Path verified" : invalidHint)
                }
                TextField("", text: $text, prompt: Text(placeholder))
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
            }
            if !text.isEmpty, !isValid {
                Text(invalidHint)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
