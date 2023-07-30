import UIKit

class ProfileViewController: UIViewController {

    //  объекты view-элементов
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var yourAvatarImageView: UIImageView!
    @IBOutlet weak var stateAuthLabel: UILabel!
    @IBOutlet weak var nameStackView: UIStackView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var regisLoginStackView: UIStackView!
    @IBOutlet weak var registrationButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    
    var userDefaultsManager = UserDefaultsManager()
    var fireBaseAuthManager = FireBaseAuthManager()
    var fireBaseCloudManager = FireBaseCloudManager()
    let TAG = "ProfileViewController: "
    
    // MARK: при запуске экрана...
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("ProfileViewCon: viewDidLoad: entrance")

        settingsViews()  //  ...настройка view
        
        NSLog("ProfileViewCon: viewDidLoad: exit")
    }
    
    // MARK: отображение экрана
    override func viewDidAppear(_ animated: Bool) {
        NSLog("ProfileViewCon: viewDidAppear: entrance")
        
        Task {
            NSLog("ProfileViewCon: viewDidAppear: Task")
            await checkingReachability()
        }
        updateViewsVC()
        
        NSLog("ProfileViewCon: viewWillAppear: exit")
    }
    
    // MARK: действия при успешном входе
    func authTrueAction(){
        NSLog(TAG + "authTrueAction: entrance")
        
        if (userDefaultsManager.getYourName() != "0" && userDefaultsManager.getYourName() != ""){
            //nameTextField.text = userDefaultsManager.getYourName()
        }
        if (userDefaultsManager.getYourEmail() != "0"){
            //emailTextField.text = userDefaultsManager.getYourEmail()
        }
        stateAuthLabel.text = "You loggined as " + self.userDefaultsManager.getYourEmail()
        nameTextField.text = userDefaultsManager.getYourName()
        logoutButton.isHidden = false
        regisLoginStackView.isHidden = true
        nameStackView.isHidden = false
        
        NSLog(TAG + "authTrueAction: exit")
    }
    
    // MARK: действия при НЕ успешном входе
    func authFalseAction(){
        NSLog(TAG + "authFalseAction: entrance")
        
        stateAuthLabel.text = "Log in or register in the system"
        nameTextField.text = ""
        logoutButton.isHidden = true
        regisLoginStackView.isHidden = false
        nameStackView.isHidden = true
        
        NSLog(TAG + "authFalseAction: exit")
    }
    
    // MARK: отображение аватарки
    func viewAvatar(){
        NSLog(TAG + "viewAvatar: entrance")
        guard let apiURL = URL(string: self.userDefaultsManager.getYourImageURL()) else {
            fatalError("some error")
        }
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: apiURL) { (data, response, error) in
            guard let data = data, error == nil else {return}
            DispatchQueue.main.async {
                self.yourAvatarImageView.image = UIImage(data: data)
            }
        }
        task.resume()
        yourAvatarImageView.isHidden = false
        NSLog(TAG + "viewAvatar: exit")
    }
    
    // MARK: обновление view
    func updateViewsVC(){
        NSLog(TAG + "uploudViewsVC: entrance")
        if fireBaseAuthManager.stateAuth() {
            NSLog(TAG + "settingsViews: stateAuth = true")
            authTrueAction()
        } else {
            NSLog(TAG + "settingsViews: stateAuth = false")
            authFalseAction()
        }
        NSLog(TAG + "uploudViewsVC: exit")
    }
    
    // MARK: кнопка смены имени нажата
    @IBAction func renameButtonClicked(_ sender: Any) {
        NSLog(TAG + "renameButtonClicked: exit: userDefaultsManager?.getYourName = " + (userDefaultsManager.getYourName()))
        userDefaultsManager.saveYourName(name: nameTextField.text ?? "")
        fireBaseCloudManager.updateNameInCloudData()
        NSLog(TAG + "renameButtonClicked: exit: userDefaultsManager?.getYourName = " + (userDefaultsManager.getYourName()))
    }
    
    // MARK: кнопка выхода нажата
    @IBAction func logoutButtonClicked(_ sender: Any) {
        //  вывод alertDialog
        let alert = UIAlertController(title: NSLocalizedString("areYouSureYouWantToGetOut", comment: ""), message: nil, preferredStyle: .actionSheet)
        let logoutAction = UIAlertAction(title: NSLocalizedString("ExitInAlertDialog", comment: ""), style: .destructive) { [weak self] (_) in
            NSLog(self!.TAG + "loginAction: logoutAction: entrance")
            self!.fireBaseAuthManager.logOut()
            self!.userDefaultsManager.deleteUserInfo()
            self!.updateViewsVC()
        }
        let deleteAccountAction = UIAlertAction(title: "Delete Account", style: .destructive) { [weak self] (_) in
            NSLog(self!.TAG + "loginAction: deleteAccountAction: entrance")
            self!.fireBaseCloudManager.deleteInCloudData()
            self!.fireBaseAuthManager.deleteAccount(using: self!.deleteAccountCompletionHandler)
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancelInAlertDialog", comment: ""), style: .cancel, handler: nil)
        alert.addAction(logoutAction)
        alert.addAction(deleteAccountAction)
        alert.addAction(cancelAction)
        //  для ipad'ов
        if let popover = alert.popoverPresentationController{
            NSLog("MainViewCon: loginAction: popoverPresentationController: for ipad's")
            popover.sourceView = loginButton
        }
        present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: результат удаление аккаунта
    lazy var deleteAccountCompletionHandler: (Int, String) -> Void = { doneWorking, desc in
        NSLog(self.TAG + "loginCompletionHandler: entrance")
        switch doneWorking {
        case 0: //  удачное удаление
            NSLog(self.TAG + "loginCompletionHandler: doneWorking = 0")
            self.userDefaultsManager.deleteUserInfo()
            self.updateViewsVC()
        case 1: //  неудачное удаление
            NSLog(self.TAG + "loginCompletionHandler: doneWorking = 1")
            let alert = UIAlertController(title: "Error when deleting a user", message: nil, preferredStyle: .actionSheet)
            let okAction = UIAlertAction(title: "OK", style: .destructive) { [weak self] (_) in
                NSLog(self!.TAG + "loginCompletionHandler: UIAlertController: OK")
            }
            alert.addAction(okAction)
            //  для ipad'ов
            if let popover = alert.popoverPresentationController{
                NSLog(self.TAG + "clickClearButton: popoverPresentationController: for ipad's")
                popover.sourceView = self.loginButton
            }
            self.present(alert, animated: true, completion: nil)
        default:
            NSLog(self.TAG + "loginCompletionHandler: doneWorking = " + String(doneWorking))
        }
    
        NSLog(self.TAG + "loginCompletionHandler: exit")
    }
    
    // MARK: результат проверки на тип пользователя
//    lazy var typeUserCompletionHandler: (Int, String?) -> Void = { doneWorking, typeUser in
//        NSLog(self.TAG + "typeUserCompletionHandler: entrance")
//        switch doneWorking {
//        case 1:  //  удачная проверка
//            NSLog(self.TAG + "typeUserCompletionHandler: doneWorking = 1")
//            if typeUser == "t" {
//                self.loginButton.setTitle("logout from " + self.fireBaseAuthManager.emailUser, for: UIControl.State.normal)
//                self.loginButton.tintColor = UIColor(named: "redColor")
//                self.loginMainLabel.text = "You loggined with " + self.fireBaseAuthManager.emailUser
//                if self.fireBaseAuthManager.authWas {
//                    NSLog(self.TAG + "typeUserCompletionHandler: doneWorking = 1: authWas = true")
//                    self.fireBaseCloudManager.addUserInCloudData()
//                } else {
//                    NSLog(self.TAG + "typeUserCompletionHandler: doneWorking = 1: authWas = false")
//                    self.fireBaseCloudManager.updateNameInCloudData()
//                }
//            } else {
//                self.fireBaseAuthManager.logOut()
//                self.deleteUserInfo()
//                let alert = UIAlertController(title: "You are already registered as an sportsman", message: nil, preferredStyle: .actionSheet)
//                let okAction = UIAlertAction(title: "OK", style: .destructive) { [weak self] (_) in
//                    NSLog(self!.TAG + "typeUserCompletionHandler: UIAlertController: OK")
//                }
//                alert.addAction(okAction)
//                //  для ipad'ов
//                if let popover = alert.popoverPresentationController{
//                    NSLog(self.TAG + "clickClearButton: popoverPresentationController: for ipad's")
//                    popover.sourceView = self.loginButton
//                }
//                self.present(alert, animated: true, completion: nil)
//            }
//        case 0:
//            NSLog(self.TAG + "typeUserCompletionHandler: doneWorking = 0")
//            self.fireBaseAuthManager.logOut()
//            self.deleteUserInfo()
//            let alert = UIAlertController(title: "Unable to verify if you are a trainer", message: nil, preferredStyle: .actionSheet)
//            let okAction = UIAlertAction(title: "OK", style: .destructive) { [weak self] (_) in
//                NSLog(self!.TAG + "typeUserCompletionHandler: UIAlertController: OK")
//            }
//            alert.addAction(okAction)
//            //  для ipad'ов
//            if let popover = alert.popoverPresentationController{
//                NSLog(self.TAG + "clickClearButton: popoverPresentationController: for ipad's")
//                popover.sourceView = self.loginButton
//            }
//            self.present(alert, animated: true, completion: nil)
//        default:
//            NSLog(self.TAG + "typeUserCompletionHandler: doneWorking = default")
//        }
//    }
    
    // MARK: настройка view
    func settingsViews(){
        NSLog(TAG + "settingsViews: entrance")
        //  настройка statusBar
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = UIColor(named: "accentColor")
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
        }
        
        logoutButton.isHidden = true
        regisLoginStackView.isHidden = true
        nameStackView.isHidden = true
        yourAvatarImageView.layer.cornerRadius = yourAvatarImageView.frame.size.width/2
        yourAvatarImageView.clipsToBounds = true
        
        NSLog(TAG + "settingsViews: exit")
    }
    
    // MARK: состояние интернета
    // наблюдение за ним
    func checkingReachability() async{
        while (true){
            switch userDefaultsManager.getStateInternet(){
            case 1:
                loginButton.isEnabled = true
                logoutButton.isEnabled = true
                registrationButton.isEnabled = true
            case 0:
                loginButton.isEnabled = false
                logoutButton.isEnabled = true
                registrationButton.isEnabled = true
            default:
                loginButton.isEnabled = false
                logoutButton.isEnabled = true
                registrationButton.isEnabled = true
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }
    
}
