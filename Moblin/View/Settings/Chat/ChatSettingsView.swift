@ -1,281 +1,98 @@
import SwiftUI

struct ChatSettingsView: View {
    @StateObject private var viewModel: ChatSettingsViewModel

    var body: some View {
        Form {
            // General Section
            Section {
                Toggle("Enabled", isOn: $viewModel.isEnabled)
                    .onChange(of: viewModel.isEnabled) { _ in
                        viewModel.toggleEnabled()
                    }
            }

            // Appearance Section
            Section(header: Text("Appearance")) {
                fontSizeSlider
                colorPickers
            }

            // Geometry Section
            Section(header: Text("Geometry")) {
                heightSlider
                widthSlider
            }
        }
        .navigationTitle("Chat Settings")
    }

    // Font Size Slider
    private var fontSizeSlider: some View {
        HStack {
            Text("Font size")
            Slider(
                value: $viewModel.fontSize,
                in: 10 ... 30,
                step: 1
            )
            .onChange(of: viewModel.fontSize) { value in
                viewModel.updateFontSize(to: value)
            }
            Text("\(Int(viewModel.fontSize))")
                .frame(width: 25)
        }
    }

    // Geometry Sliders
    private var heightSlider: some View {
        HStack {
            Text("Height")
            Slider(
                value: $viewModel.height,
                in: 0.2 ... 1.0,
                step: 0.05
            )
            .onChange(of: viewModel.height) { value in
                viewModel.updateHeight(to: value)
            }
            Text("\(Int(viewModel.height * 100))%")
                .frame(width: 55)
        }
    }

    private var widthSlider: some View {
        HStack {
            Text("Width")
            Slider(
                value: $viewModel.width,
                in: 0.2 ... 1.0,
                step: 0.05
            )
            .onChange(of: viewModel.width) { value in
                viewModel.updateWidth(to: value)
            }
            Text("\(Int(viewModel.width * 100))%")
                .frame(width: 55)
        }
    }

    // Color Pickers
    private var colorPickers: some View {
        VStack {
            ColorPicker("Timestamp Color", selection: $viewModel.timestampColor)
                .onChange(of: viewModel.timestampColor) { color in
                    viewModel.updateTimestampColor(to: color)
                }
            ColorPicker("Username Color", selection: $viewModel.usernameColor)
                .onChange(of: viewModel.usernameColor) { color in
                    viewModel.updateUsernameColor(to: color)
                }
            ColorPicker("Message Color", selection: $viewModel.messageColor)
                .onChange(of: viewModel.messageColor) { color in
                    viewModel.updateMessageColor(to: color)
                }
        }
    }
}