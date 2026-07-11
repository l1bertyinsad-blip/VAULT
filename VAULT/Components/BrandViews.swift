import SwiftUI

struct SplashView: View {
    @State private var visible = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                Image("VaultMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 104)
                    .accessibilityHidden(true)
                Text("VAULT")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .tracking(6)
                    .accessibilityLabel("VAULT")
            }
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible ? 1 : 0.96)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.38)) { visible = true }
        }
    }
}

struct VaultEmptyState: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                Image("VaultMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 52)
            }
        } description: {
            Text(message)
        } actions: {
            Button(buttonTitle, action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
