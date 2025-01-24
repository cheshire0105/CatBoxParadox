import SwiftUI
import UIKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                IntroViewWrapper()
                    .edgesIgnoringSafeArea(.all) // 전체 화면 적용
            }
            .navigationViewStyle(.stack)
            .edgesIgnoringSafeArea(.all) // 네비게이션 뷰 전체 화면 적용
        }
    }
}

struct IntroViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let introVC = IntroViewController()
        let navController = UINavigationController(rootViewController: introVC)

        navController.isNavigationBarHidden = false

        // 전체 화면으로 확장
        navController.view.backgroundColor = .clear
        navController.navigationBar.isTranslucent = true

        return navController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
