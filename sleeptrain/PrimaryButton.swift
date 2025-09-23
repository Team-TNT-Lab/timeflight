
struct PrimaryButton: View {
    let buttonText: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(buttonText)
                .font(.title3.weight(.heavy))
                .frame(maxWidth: .infinity, minHeight: 56)
                .foregroundStyle(.black)
                .background(.white)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .contentShape(Capsule())
        .accessibilityLabel(Text(buttonText))
    }
}
