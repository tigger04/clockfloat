// ABOUTME: SwiftUI settings panel for clock configuration.
// ABOUTME: Uses @AppStorage for direct UserDefaults binding; notifies Clock on changes.

import SwiftUI

struct SettingsView: View {
    @AppStorage(ClockConfiguration.Keys.fontName) private var fontName = "White Rabbit"
    @AppStorage(ClockConfiguration.Keys.timeFontSize) private var timeFontSize = 14.0
    @AppStorage(ClockConfiguration.Keys.dateFontSize) private var dateFontSize = 10.0
    @AppStorage(ClockConfiguration.Keys.timeFormat) private var timeFormat = "HH:mm"
    @AppStorage(ClockConfiguration.Keys.dateFormat) private var dateFormat = "E d"
    @AppStorage(ClockConfiguration.Keys.lateEnabled) private var lateEnabled = true
    @AppStorage(ClockConfiguration.Keys.lateOffsetMinutes) private var lateOffsetMinutes = 3
    @AppStorage(ClockConfiguration.Keys.opacity) private var opacity = 0.75
    @AppStorage(ClockConfiguration.Keys.hoverBehavior) private var hoverBehaviorRaw = HoverBehavior.none.rawValue
    @AppStorage(ClockConfiguration.Keys.initialCorner) private var initialCornerRaw = ClockConfiguration.Corner.bottomRight.rawValue

    @State private var fontNameDraft = ""
    @State private var selectedDatePreset = "E d"

    private static let dateFormatPresets = ["E d", "EEEE", "d MMM"]
    private static let customTag = "__custom__"

    var body: some View {
        Form {
            Section("Font") {
                TextField("Font Name", text: $fontNameDraft)
                    .onSubmit { commitFontName() }

                HStack {
                    Text("Time Size")
                    Spacer()
                    TextField("", value: $timeFontSize, format: .number)
                        .frame(width: 60)
                    Stepper("", value: $timeFontSize, in: 6.0...200.0, step: 0.5)
                        .labelsHidden()
                }

                HStack {
                    Text("Date Size")
                    Spacer()
                    TextField("", value: $dateFontSize, format: .number)
                        .frame(width: 60)
                    Stepper("", value: $dateFontSize, in: 6.0...200.0, step: 0.5)
                        .labelsHidden()
                }
            }

            Section("Time Format") {
                Picker("Format", selection: $timeFormat) {
                    Text("24-hour (HH:mm)").tag("HH:mm")
                    Text("12-hour (h:mm a)").tag("h:mm a")
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }

            Section("Date Format") {
                Picker("Preset", selection: $selectedDatePreset) {
                    ForEach(Self.dateFormatPresets, id: \.self) { preset in
                        Text(preset).tag(preset)
                    }
                    Text("Custom...").tag(Self.customTag)
                }
                .labelsHidden()

                if selectedDatePreset == Self.customTag {
                    TextField("e.g. yyyy-MM-dd", text: $dateFormat)
                        .onSubmit { notifyChange() }
                }
            }

            Section("Late Offset") {
                Toggle("Enable late offset", isOn: $lateEnabled)
                if lateEnabled {
                    Stepper("\(lateOffsetMinutes) minutes", value: $lateOffsetMinutes, in: 0...60)
                }
            }

            Section("Opacity") {
                HStack {
                    Slider(value: $opacity, in: 0.0...1.0)
                    Text(String(format: "%.2f", opacity))
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }

            Section("Behavior") {
                Picker("Hover Behavior", selection: $hoverBehaviorRaw) {
                    ForEach(HoverBehavior.allCases, id: \.rawValue) { behavior in
                        Text(behavior.displayName).tag(behavior.rawValue)
                    }
                }

                Picker("Initial Corner", selection: $initialCornerRaw) {
                    ForEach(ClockConfiguration.Corner.allCases, id: \.rawValue) { corner in
                        Text(corner.displayName).tag(corner.rawValue)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            fontNameDraft = fontName
            if Self.dateFormatPresets.contains(dateFormat) {
                selectedDatePreset = dateFormat
            } else {
                selectedDatePreset = Self.customTag
            }
        }
        .onChange(of: selectedDatePreset) { newValue in
            if newValue != Self.customTag {
                dateFormat = newValue
            }
        }
        .onChange(of: timeFontSize) { _ in notifyChange() }
        .onChange(of: dateFontSize) { _ in notifyChange() }
        .onChange(of: timeFormat) { _ in notifyChange() }
        .onChange(of: dateFormat) { _ in notifyChange() }
        .onChange(of: lateEnabled) { _ in notifyChange() }
        .onChange(of: lateOffsetMinutes) { _ in notifyChange() }
        .onChange(of: opacity) { _ in notifyChange() }
        .onChange(of: hoverBehaviorRaw) { _ in notifyChange() }
        .onChange(of: initialCornerRaw) { _ in notifyChange() }
    }

    private func commitFontName() {
        fontName = ClockConfiguration.validatedFontName(fontNameDraft)
        fontNameDraft = fontName
        notifyChange()
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: .clockConfigurationDidChange, object: nil)
    }
}
