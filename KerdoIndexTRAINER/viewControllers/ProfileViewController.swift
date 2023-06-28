import UIKit

class ProfileViewController: UIViewController {

    //  объекты view-элементов
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var loginMainLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var passErrorLabel: UILabel!
    @IBOutlet weak var nameErrorLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var yourAvatarImageView: UIImageView!
    @IBOutlet weak var progressView: UIView!
    
    var userDefaultsManager = UserDefaultsManager()
    var emailValid = false
    var passValid = false
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
        
        NSLog("ProfileViewCon: viewWillAppear: exit")
    }
    
    // MARK: состояние интернета
    // наблюдение за ним
    func checkingReachability() async{
        while (true){
            switch userDefaultsManager.getStateInternet(){
            case 1:
                loginButton.isEnabled = true
            case 0:
                loginButton.isEnabled = false
            default:
                loginButton.isEnabled = false
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }
    
    // MARK: нажатие на кнопку входа  NSLocalizedString("resultUploadLabelErrorNoDataToSend", comment: "")
    @IBAction func loginButtonClicked(_ sender: Any) {
        NSLog(TAG + "LoginButtonClicked: entrance")
        if emailValid {
            NSLog(TAG + "LoginButtonClicked: emailValid == true")
            userDefaultsManager.saveYourEmail(emailAddress: emailTextField.text ?? "")
            userDefaultsManager.savePassword(password: sha256(passTextField.text ?? ""))
            userDefaultsManager.saveYourName(name: nameTextField.text ?? "")
            loginAction()
        } else {
            NSLog(TAG + "LoginButtonClicked: emailValid == false")
            userDefaultsManager.saveYourEmail(emailAddress: "0")
        }
    }
    
    // MARK: действия при нажатии кнопки логина
    func loginAction(){
        if fireBaseAuthManager.stateAuth() {
            NSLog(TAG + "loginAction: entrance")
            //  вывод alertDialog
            let alert = UIAlertController(title: NSLocalizedString("areYouSureYouWantToGetOut", comment: ""), message: nil, preferredStyle: .actionSheet)
            let logoutAction = UIAlertAction(title: NSLocalizedString("ExitInAlertDialog", comment: ""), style: .destructive) { [weak self] (_) in
                NSLog(self!.TAG + "loginAction: logoutAction: entrance")
                self!.fireBaseAuthManager.logOut()
                self!.loginMainLabel.text = "Log in to your kerdoIndex account:"
                self!.loginButton.setTitle("Login", for: UIControl.State.normal)//NSLocalizedString("loginButtonTextLogin", comment: "")
                self!.loginButton.tintColor = UIColor(named: "accentColor2")
                self!.deleteUserInfo()
            }
            let deleteAccountAction = UIAlertAction(title: "Delete Account", style: .destructive) { [weak self] (_) in
                NSLog(self!.TAG + "loginAction: deleteAccountAction: entrance")
                self!.fireBaseAuthManager.deleteAccount()
                self!.loginMainLabel.text = "Log in to your kerdoIndex account:"
                self!.loginButton.setTitle("Login", for: UIControl.State.normal)//NSLocalizedString("loginButtonTextLogin", comment: "")
                self!.loginButton.tintColor = UIColor(named: "accentColor2")
                self!.fireBaseCloudManager.deleteInCloudData()
                self!.deleteUserInfo()
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
        } else {
            if (emailTextField.text != ""
                && passTextField.text != ""
                && nameTextField.text != ""
                && passValid
            ){
                NSLog(TAG + "loginAction: TF is not null")
                progressView.isHidden = false
                fireBaseAuthManager.login(email: emailTextField.text!,
                                         pass: userDefaultsManager.getPassword(),
                                         using: loginCompletionHandler
                )
            } else {
                NSLog(TAG + "loginAction: TF is null!")
                if emailTextField.text == "" {
                    emailErrorLabel.isHidden = false
                }
                if passTextField.text == "" {
                    passErrorLabel.text = "Enter password"
                    passErrorLabel.isHidden = false
                }
                if nameTextField.text == "" {
                    nameErrorLabel.isHidden = false
                }
            }
        }
    }
    
    // MARK: результат авторизации
    lazy var loginCompletionHandler: (Int) -> Void = { doneWorking in   // TODO: после логина проверяем тип пользователя. Если не тот - выходим
        NSLog(self.TAG + "loginCompletionHandler: entrance")
        switch doneWorking {
        case 0:  //  неудачная авторизация
            NSLog(self.TAG + "loginCompletionHandler: doneWorking = " + String(doneWorking))
            let alert = UIAlertController(title: "Invalid Email or password", message: nil, preferredStyle: .actionSheet)
            let okAction = UIAlertAction(title: "OK", style: .destructive) { [weak self] (_) in
                self!.progressView.isHidden = true
                NSLog(self!.TAG + "loginCompletionHandler: UIAlertController: OK")
            }
            alert.addAction(okAction)
            //  для ipad'ов
            if let popover = alert.popoverPresentationController{
                NSLog(self.TAG + "clickClearButton: popoverPresentationController: for ipad's")
                popover.sourceView = self.loginButton
            }
            self.present(alert, animated: true, completion: nil)
        case 1:  //  удачная авторизация
            NSLog(self.TAG + "loginCompletionHandler: doneWorking = 1")
            if (self.fireBaseAuthManager.authWas){
                NSLog(self.TAG + "loginCompletionHandler: doneWorking = 1: authWas = true")
                self.loginButton.setTitle("logout from " + self.fireBaseAuthManager.emailUser, for: UIControl.State.normal)
                self.loginButton.tintColor = UIColor(named: "redColor")
                self.loginMainLabel.text = "You loggined with " + self.fireBaseAuthManager.emailUser
                self.fireBaseCloudManager.addUserInCloudData()
                self.progressView.isHidden = true
            } else {
                // проверка на тип пользователя
                self.fireBaseCloudManager.getTypeUser(
                    email: self.emailTextField.text!,
                    using: self.typeUserCompletionHandler
                )
            }
        default:
            NSLog(self.TAG + "loginCompletionHandler: doneWorking = " + String(doneWorking))
        }
        NSLog(self.TAG + "loginCompletionHandler: exit")
    }
    
    // MARK: результат проверки на тип пользователя
    lazy var typeUserCompletionHandler: (Int, String?) -> Void = { doneWorking, typeUser in
        NSLog(self.TAG + "typeUserCompletionHandler: entrance")
        switch doneWorking {
        case 1:  //  удачная проверка
            NSLog(self.TAG + "typeUserCompletionHandler: doneWorking = 1")
            if typeUser == "t" {
                // MARK: выставление элементов
                self.loginButton.setTitle("logout from " + self.fireBaseAuthManager.emailUser, for: UIControl.State.normal)
                self.loginButton.tintColor = UIColor(named: "redColor")
                self.loginMainLabel.text = "You loggined with " + self.fireBaseAuthManager.emailUser
                if self.fireBaseAuthManager.authWas {
                    NSLog(self.TAG + "typeUserCompletionHandler: doneWorking = 1: authWas = true")
                    self.fireBaseCloudManager.addUserInCloudData()
                } else {
                    NSLog(self.TAG + "typeUserCompletionHandler: doneWorking = 1: authWas = false")
                    self.fireBaseCloudManager.updateNameInCloudData()
                }
                self.progressView.isHidden = true
            } else {
                self.fireBaseAuthManager.logOut()
                self.deleteUserInfo()
                self.progressView.isHidden = true
                let alert = UIAlertController(title: "You are already registered as an sportsman", message: nil, preferredStyle: .actionSheet)
                let okAction = UIAlertAction(title: "OK", style: .destructive) { [weak self] (_) in
                    NSLog(self!.TAG + "typeUserCompletionHandler: UIAlertController: OK")
                }
                alert.addAction(okAction)
                //  для ipad'ов
                if let popover = alert.popoverPresentationController{
                    NSLog(self.TAG + "clickClearButton: popoverPresentationController: for ipad's")
                    popover.sourceView = self.loginButton
                }
                self.present(alert, animated: true, completion: nil)
            }
        case 0:
            NSLog(self.TAG + "typeUserCompletionHandler: doneWorking = 0")
            self.fireBaseAuthManager.logOut()
            self.deleteUserInfo()
            self.progressView.isHidden = true
            let alert = UIAlertController(title: "Unable to verify if you are a trainer", message: nil, preferredStyle: .actionSheet)
            let okAction = UIAlertAction(title: "OK", style: .destructive) { [weak self] (_) in
                NSLog(self!.TAG + "typeUserCompletionHandler: UIAlertController: OK")
            }
            alert.addAction(okAction)
            //  для ipad'ов
            if let popover = alert.popoverPresentationController{
                NSLog(self.TAG + "clickClearButton: popoverPresentationController: for ipad's")
                popover.sourceView = self.loginButton
            }
            self.present(alert, animated: true, completion: nil)
        default:
            NSLog(self.TAG + "typeUserCompletionHandler: doneWorking = default")
        }
    }
    
    // MARK: удаление всех данных
    func deleteUserInfo() {
        NSLog(TAG + "deleteUserInfo: entrance")
        userDefaultsManager.savePassword(password: "0")
        userDefaultsManager.saveYourEmail(emailAddress: "0")
        userDefaultsManager.saveYourName(name: "0")
        userDefaultsManager.saveIdUser(idUser: "")
        userDefaultsManager.saveYourImageURL(yourImageURL: "")
    }
    
    @IBAction func emailTextFieldChanged(_ sender: Any) {
        NSLog("ProfileViewCon: emailTextFieldChanged: entrance: userDefaultsManager.getYourEmail:" + userDefaultsManager.getYourEmail())
        emailErrorLabel.isHidden = true
        invalidEmail()
    }
    
    // MARK: проверка введенной почты на виладность
    func invalidEmail(){
        NSLog(TAG + "invalidEmail: entrance")
        let reqularExpression = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", reqularExpression)
        if !predicate.evaluate(with: emailTextField.text){    //  если почта невалидная
            NSLog(TAG + "invalidEmail: mail is invalid")
            emailErrorLabel.isHidden = false
            emailValid = false
            return
        }
        NSLog(TAG + "invalidEmail: exit: mail is valid")
        emailErrorLabel.isHidden = true
        emailValid = true
    }
    
    // MARK: поле ввода пароля изменено
    @IBAction func passwordTextFieldChanged(_ sender: Any) {
        NSLog("ProfileViewCon: passwordTextFieldChanged: entrance: userDefaultsManager.getPassword:" + userDefaultsManager.getPassword())
        passErrorLabel.isHidden = true
        if (!passTextField.text!.isEmpty && passTextField.text!.count >= 8){
            passValid = true
            passErrorLabel.isHidden = true
        } else {
            passValid = false
            passErrorLabel.text = "The password must be at least 8 characters"
            passErrorLabel.isHidden = false
        }
    }
    
    // MARK: поле ввода имени изменено
    @IBAction func nameTextFieldChanged(_ sender: Any) {
        NSLog(TAG + "nameTextFieldChanged: userDefaultsManager?.getYourName = " + (userDefaultsManager.getYourName()))
        userDefaultsManager.saveYourName(name: nameTextField.text ?? "")
        nameErrorLabel.isHidden = true
        if fireBaseAuthManager.stateAuth(){
            NSLog(TAG + "nameTextFieldChanged: stateAuth = true")
            fireBaseCloudManager.updateNameInCloudData()
        }
        NSLog("ProfileViewCon: nameTextFieldChanged: exit: userDefaultsManager.getYourName:" + userDefaultsManager.getYourName())
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
        
        NSLog(TAG + "settingsViews: userDefaultsManager.getYourName = " + userDefaultsManager.getYourName())
        if (userDefaultsManager.getYourName() != "0" && userDefaultsManager.getYourName() != ""){
            nameTextField.text = userDefaultsManager.getYourName()
        }
        NSLog(TAG + "settingsViews: userDefaultsManager.getPassword = " + userDefaultsManager.getPassword())
        if (userDefaultsManager.getPassword() != "0"){
            passTextField.text = ""
            passTextField.placeholder = "******** - Your password"
        }
        NSLog(TAG + "settingsViews: userDefaultsManager.getYourEmail = " + userDefaultsManager.getYourEmail())
        if (userDefaultsManager.getYourEmail() != "0"){
            emailTextField.text = userDefaultsManager.getYourEmail()
            emailValid = true
        }
        
        if fireBaseAuthManager.stateAuth() {
            NSLog(TAG + "settingsViews: stateAuth = true")
            loginButton.setTitle("logout from " + self.fireBaseAuthManager.emailUser, for: UIControl.State.normal)
            loginButton.tintColor = UIColor(named: "redColor")
            loginMainLabel.text = "You loggined with " + fireBaseAuthManager.emailUser
        } else {
            NSLog(TAG + "settingsViews: stateAuth = false")
            loginMainLabel.text = "Log in to your kerdoIndex account:"
            loginButton.setTitle("Login", for: UIControl.State.normal)//NSLocalizedString("loginButtonTextLogin", comment: "")
            loginButton.tintColor = UIColor(named: "accentColor2")
        }
        
        yourAvatarImageView.layer.cornerRadius = yourAvatarImageView.frame.size.width/2
        yourAvatarImageView.clipsToBounds = true
        
        NSLog(TAG + "settingsViews: exit")
    }
    
}
