import SwiftUI

struct SplashView: View {
    @State private var revealStep = 0
    @State private var wordVisible = false
    @State private var taglineVisible = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            Circle()
                .fill(VaultPalette.purple.opacity(0.09))
                .frame(width: 330, height: 330)
                .blur(radius: 30)
                .scaleEffect(revealStep > 0 ? 1 : 0.55)

            VStack(spacing: 17) {
                AnimatedVaultMark(revealStep: revealStep)
                    .frame(width: 164, height: 132)

                Text("VAULT")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .tracking(wordVisible ? 7 : 13)
                    .opacity(wordVisible ? 1 : 0)
                    .offset(y: wordVisible ? 0 : 9)
                    .accessibilityLabel("VAULT")

                Text("Визуальные идеи. В полном порядке.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .opacity(taglineVisible ? 1 : 0)
                    .offset(y: taglineVisible ? 0 : 7)
            }
        }
        .task {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.76)) { revealStep = 1 }
            try? await Task.sleep(for: .milliseconds(170))
            withAnimation(.spring(response: 0.48, dampingFraction: 0.74)) { revealStep = 2 }
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.spring(response: 0.46, dampingFraction: 0.72)) { revealStep = 3 }
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) { revealStep = 4 }
            withAnimation(.easeOut(duration: 0.48)) { wordVisible = true }
            try? await Task.sleep(for: .milliseconds(260))
            withAnimation(.easeOut(duration: 0.4)) { taglineVisible = true }
        }
    }
}

struct OnboardingView: View {
    let completion: () -> Void
    @State private var page = 0

    private let pages = [
        OnboardingPage(
            symbol: "square.and.arrow.down.on.square.fill",
            colors: [.blue, VaultPalette.purple],
            title: "Сохраняйте отовсюду",
            message: "Фото, видео, Reels и ссылки попадают в VAULT через системное меню «Поделиться»."
        ),
        OnboardingPage(
            symbol: "wand.and.stars",
            colors: [VaultPalette.purple, .pink],
            title: "Порядок без рутины",
            message: "VAULT распознаёт текст, находит дубликаты и помогает превратить сохранённое в понятные коллекции."
        ),
        OnboardingPage(
            symbol: "lock.shield.fill",
            colors: [.teal, .blue],
            title: "Ваше — значит личное",
            message: "Материалы хранятся локально, защищаются Face ID и всегда доступны для полного экспорта."
        )
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            Circle()
                .fill(VaultPalette.purple.opacity(0.12))
                .frame(width: 360, height: 360)
                .blur(radius: 50)
                .offset(x: 150, y: -300)
            Circle()
                .fill(Color.blue.opacity(0.10))
                .frame(width: 330, height: 330)
                .blur(radius: 55)
                .offset(x: -160, y: 330)

            VStack(spacing: 0) {
                HStack {
                    Image("VaultMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 40)
                    Text("VAULT")
                        .font(.headline.bold())
                    Spacer()
                    Button("Пропустить", action: completion)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        OnboardingPageView(page: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? VaultPalette.purple : Color.secondary.opacity(0.22))
                            .frame(width: index == page ? 24 : 8, height: 8)
                            .animation(.easeOut(duration: 0.22), value: page)
                    }
                }
                .padding(.bottom, 24)

                Button {
                    if page < pages.count - 1 {
                        withAnimation(.easeInOut) { page += 1 }
                    } else {
                        completion()
                    }
                } label: {
                    HStack {
                        Text(page == pages.count - 1 ? "Открыть мой VAULT" : "Продолжить")
                        Spacer()
                        Image(systemName: page == pages.count - 1 ? "checkmark" : "arrow.right")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 56)
                    .background(VaultPalette.purple.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: VaultPalette.purple.opacity(0.28), radius: 16, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
                .accessibilityIdentifier("onboardingContinueButton")
            }
        }
    }
}

private struct OnboardingPage {
    let symbol: String
    let colors: [Color]
    let title: String
    let message: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                RoundedRectangle(cornerRadius: 44, style: .continuous)
                    .fill(LinearGradient(colors: page.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 230, height: 230)
                    .shadow(color: page.colors.last?.opacity(0.28) ?? .clear, radius: 28, y: 16)
                Circle()
                    .fill(.white.opacity(0.13))
                    .frame(width: 170, height: 170)
                    .offset(x: 78, y: -82)
                Image(systemName: page.symbol)
                    .font(.system(size: 76, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 22)
            }
        }
        .padding(.horizontal, 20)
    }
}

private struct AnimatedVaultMark: View {
    let revealStep: Int

    var body: some View {
        ZStack(alignment: .bottom) {
            card(color: Color(red: 0.11, green: 0.49, blue: 0.96), width: 112, height: 76)
                .offset(y: revealStep >= 1 ? -48 : 4)
                .opacity(revealStep >= 1 ? 1 : 0)
            card(color: Color(red: 0.98, green: 0.67, blue: 0.08), width: 126, height: 82)
                .offset(y: revealStep >= 2 ? -34 : 4)
                .opacity(revealStep >= 2 ? 1 : 0)
            card(color: Color(red: 0.95, green: 0.10, blue: 0.48), width: 140, height: 88)
                .offset(y: revealStep >= 3 ? -19 : 4)
                .opacity(revealStep >= 3 ? 1 : 0)
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.62, green: 0.32, blue: 1), Color(red: 0.38, green: 0.08, blue: 0.86)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 158, height: 103)
                .overlay {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 39, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(y: 4)
                }
                .scaleEffect(revealStep >= 4 ? 1 : 0.76)
                .opacity(revealStep >= 4 ? 1 : 0)
                .shadow(color: VaultPalette.purple.opacity(0.28), radius: 18, y: 10)
        }
        .accessibilityHidden(true)
    }

    private func card(color: Color, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(color)
            .frame(width: width, height: height)
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
