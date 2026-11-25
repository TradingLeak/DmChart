import SwiftUI
import UIKit

struct ChartScreen: View {
    @StateObject private var webModel = ChartWebViewModel()
    @State private var isShareSheetPresented = false
    @State private var urlToShare: URL?

    private let background = Color(red: 10.0 / 255.0, green: 15.0 / 255.0, blue: 28.0 / 255.0)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ChartWebView(model: webModel)

            if webModel.isLoading && webModel.loadError == nil {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Color.white.opacity(0.08)
                        Rectangle()
                            .fill(Color(red: 68.0 / 255.0, green: 224.0 / 255.0, blue: 204.0 / 255.0))
                            .frame(width: geometry.size.width * webModel.progress)
                    }
                }
                .frame(height: 2)
                .frame(maxHeight: .infinity, alignment: .top)
                .accessibilityLabel("Đang tải DmChart")
                .allowsHitTesting(false)
            }

            if !webModel.hasLoadedPage && webModel.loadError != nil {
                ConnectionErrorView(action: webModel.reload)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            chartMenu
                .padding(.trailing, 14)
                .padding(.bottom, 14)
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let urlToShare {
                ActivityView(activityItems: [urlToShare])
            }
        }
        .preferredColorScheme(.dark)
    }

    private var chartMenu: some View {
        Menu {
            Button {
                webModel.goBack()
            } label: {
                Label("Quay lại", systemImage: "chevron.backward")
            }
            .disabled(!webModel.canGoBack)

            Button {
                webModel.goForward()
            } label: {
                Label("Đi tiếp", systemImage: "chevron.forward")
            }
            .disabled(!webModel.canGoForward)

            Button {
                webModel.reload()
            } label: {
                Label("Tải lại trang", systemImage: "arrow.clockwise")
            }

            Divider()

            Button {
                guard let currentURL = webModel.currentURL else { return }
                urlToShare = currentURL
                isShareSheetPresented = true
            } label: {
                Label("Chia sẻ liên kết", systemImage: "square.and.arrow.up")
            }
            .disabled(webModel.currentURL == nil)

            Button {
                webModel.openCurrentPageInBrowser()
            } label: {
                Label("Mở trong trình duyệt", systemImage: "safari")
            }
            .disabled(webModel.currentURL == nil)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().stroke(Color.white.opacity(0.16), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
        }
        .accessibilityLabel("Công cụ DmChart")
    }
}

private struct ConnectionErrorView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 38, weight: .regular))
                .foregroundStyle(Color.teal)
                .padding(.bottom, 2)

            Text("Không thể tải DmChart")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Text("Kiểm tra kết nối internet rồi thử lại.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button(action: action) {
                Label("Thử lại", systemImage: "arrow.clockwise")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(red: 68.0 / 255.0, green: 224.0 / 255.0, blue: 204.0 / 255.0), in: Capsule())
            }
            .padding(.top, 6)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 10.0 / 255.0, green: 15.0 / 255.0, blue: 28.0 / 255.0).ignoresSafeArea())
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
