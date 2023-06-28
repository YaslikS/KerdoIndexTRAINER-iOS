import UIKit

class AddSportsmanViewController: UIViewController {
    
    //  объекты view-элементов
    @IBOutlet weak var sportsmanEmailTextField: UITextField!
    @IBOutlet weak var sportsmanEmailErrorLabel: UILabel!
    @IBOutlet weak var addSportsmanButton: UIButton!
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var sportsmanSavedLabel: UILabel!
    
    var fireBaseCloudManager = FireBaseCloudManager()
    var emailValid = false
    let TAG = "AddSportsmanViewController: "
    
    // MARK: при запуске экрана...
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("AddSportsmanView: viewDidLoad: entrance")

        settingsViews()  //  ...настройка view
        
        NSLog("AddSportsmanView: viewDidLoad: exit")
    }
    
    @IBAction func addSportsmanButtonClicked(_ sender: Any) {
        NSLog("AddSportsmanView: addSportsmanButtonClicked: entrance")
        fireBaseCloudManager.saveSportsman(
            sportsman: sportsmanEmailTextField.text!,
            using: saveCompletionHandler
        )
        
        NSLog("AddSportsmanView: addSportsmanButtonClicked: exit")
    }
    
    lazy var saveCompletionHandler: (Int) -> Void = { doneWorking in
        switch doneWorking {
        case 0:
            NSLog("ProfileViewCon: saveCompletionHandler: doneWorking = 0")
            self.sportsmanEmailErrorLabel.text = "Couldn't find such sportsman"
            self.sportsmanEmailErrorLabel.isHidden = false
        case 1:
            NSLog("ProfileViewCon: saveCompletionHandler: doneWorking = 1")
            self.sportsmanEmailErrorLabel.isHidden = true
            self.sportsmanSavedLabel.isHidden = false
            Task {
                NSLog("ProfileViewCon: saveCompletionHandler: doneWorking = 1: TASK")
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                self.sportsmanSavedLabel.isHidden = true
                self.navigationController?.popViewController(animated: true)
            }
        default:
            NSLog("ProfileViewCon: saveCompletionHandler: default")
            self.sportsmanEmailErrorLabel.text = "Unknown error"
            self.sportsmanEmailErrorLabel.isHidden = false
        }
    }
    
    // MARK: изменение textField почты спортсменаNSLog("ProfileViewCon: myEmailChanged: entrance")
    @IBAction func sportsmanEmailChanged(_ sender: Any) {
        if let email = sportsmanEmailTextField.text{
            NSLog("ProfileViewCon: myEmailChanged: entered mail " + email)
            if invalidEmail(){    //  если почта невалидная
                NSLog("ProfileViewCon: myEmailChanged: invalidEmail = false")
                sportsmanEmailErrorLabel.isHidden = true
                addSportsmanButton.isEnabled = true
            }else{
                NSLog("ProfileViewCon: myEmailChanged: invalidEmail = true")
                sportsmanEmailErrorLabel.text = "Wrong address"
                sportsmanEmailErrorLabel.isHidden = false
                addSportsmanButton.isEnabled = false
            }
            
        }
    }
    
    // MARK: проверка введенной почты на виладность
    func invalidEmail() -> Bool{
        NSLog(TAG + "invalidEmail: entrance")
        let reqularExpression = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", reqularExpression)
        if !predicate.evaluate(with: sportsmanEmailTextField.text){    //  если почта невалидная
            NSLog(TAG + "invalidEmail: mail is invalid")
            return false
        }
        NSLog(TAG + "invalidEmail: exit: mail is valid")
        return true
    }
    
    // MARK: настройка view
    func settingsViews(){
        NSLog("AddSportsmanView: settingsViews: entrance")
        //  настройка statusBar
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = UIColor(named: "accentColor")
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
        }
        
        sportsmanEmailErrorLabel.isHidden = true
        sportsmanEmailTextField.text = ""
        addSportsmanButton.isEnabled = false
        
        NSLog("AddSportsmanView: settingsViews: exit")
    }
}
