import UIKit
import WebKit

protocol ProfileViewControllerProtocol: AnyObject {
    func showAlertGetAvatarError()
    func logoutProfile()
}

final class ProfileViewController: UIViewController {
    
    // MARK: - Private properties
    private var profileScreenView: ProfileScreenView!
    private var profileImageServiceObserver: NSObjectProtocol?
    private var errorAlertPresenter: ErrorAuthAlertPresenterProtocol?
    private var logoutAlertPresenter: LogoutAlertPresenterProtocol?
    private let profileService = ProfileService.shared
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        profileScreenView = ProfileScreenView(viewController: self)
        errorAlertPresenter = ErrorAuthAlertPresenter(delegate: self)
        logoutAlertPresenter = LogoutAlertPresenter(delegate: self)
        setupView()
        
        if let profile = profileService.profile {
            updateProfileDetails(profile: profile)
        }
        
        profileImageServiceObserver = NotificationCenter.default
            .addObserver(forName: ProfileImageService.didChangeNotification,
                         object: nil,
                         queue: .main,
                         using: { [weak self] _ in
                guard let self = self else { return }
                self.updateAvatar()
            })
        updateAvatar()
    }
    
    // MARK: - Override methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    // MARK: - Private methods
    private func setupView() {
        view.backgroundColor = .ypBackground
        setScreenViewOnViewController(view: profileScreenView)
    }
    
    private func updateProfileDetails(profile: Profile) {
        profileScreenView.updateProfile(from: profile)
    }
    
    private func updateAvatar() {
        guard let profileImageURL = ProfileImageService.shared.avatarURL,
              let url = URL(string: profileImageURL) else { return }
        profileScreenView.updateAvatar(url)
    }
    
    private func showLogoutAlert() {
        let alertModel = LogoutAlertModel(
            title: "????????, ????????!",
            message: "??????????????, ?????? ???????????? ???????????",
            buttonText: "????") { [weak self] _ in
                guard let self = self else { return }
                UIBlockingProgressHUD.show()
                OAuth2TokenStorage.shared.removeToken()
                self.cleanCookies()
                self.showAuthViewController()
                UIBlockingProgressHUD.dismiss()
            }
        logoutAlertPresenter?.requestShowLogoutAlert(alertModel: alertModel)
    }
    
    private func showAuthViewController() {
        guard let window = UIApplication.shared.windows.first else { fatalError("Invalid configuration")}
        let tabBarVC = AuthViewController()
        window.rootViewController = tabBarVC
    }
    
    private func cleanCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
}

extension ProfileViewController: ProfileViewControllerProtocol {
    func logoutProfile() {
        showLogoutAlert()
    }
    
    func showAlertGetAvatarError() {
        showImageErrorAlert()
    }
    
    private func showImageErrorAlert() {
        let alertModel = ErrorAlertModel(
            title: "??????-???? ?????????? ???? ??????(",
            message: "???? ?????????????? ?????????????????? ????????????",
            buttonText: "Ok", completion: nil)
        
        errorAlertPresenter?.requestShowResultAlert(alertModel: alertModel)
    }
}

extension ProfileViewController: ErrorAlertPresenterDelegate {
    func showErrorAlert(alertController: UIAlertController?) {
        guard let alertController = alertController else { return }
        present(alertController, animated: true)
    }
}

extension ProfileViewController: LogoutAlertPresenterDelegate {
    func showLogoutAlert(alertController: UIAlertController?) {
        guard let alertController = alertController else { return }
        present(alertController, animated: true)
    }
}
