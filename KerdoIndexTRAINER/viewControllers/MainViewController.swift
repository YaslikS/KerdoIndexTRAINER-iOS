import UIKit


class MainViewController: UITableViewController {

    //  объекты view-элементов
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var baseEmptyView: UIView!
    @IBOutlet weak var noAuthView: UIView!
    @IBOutlet weak var addSportsmanButton: UIBarButtonItem!
    
    var userDefaultsManager = UserDefaultsManager()
    var fireBaseAuthManager = FireBaseAuthManager()
    var fireBaseCloudManager = FireBaseCloudManager()
    var coreDataManager = CoreDataManager()
    var listSportsman: [User] = []
    var rowDelete = Int()
    let TAG = "MainViewController: "
    lazy var constraint1Auth = noAuthView.heightAnchor.constraint(equalToConstant: 1)
    lazy var constraint100Auth = noAuthView.heightAnchor.constraint(equalToConstant: 100)
    lazy var constraint1Empty = baseEmptyView.heightAnchor.constraint(equalToConstant: 1)
    lazy var constraint100Empty = baseEmptyView.heightAnchor.constraint(equalToConstant: 100)
    
    // MARK: при запуске экрана...
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("MainViewCon: viewDidLoad: entrance")
        
        //settingsViews()  //  ...настройка view
        NotificationCenter.default.addObserver(self, selector: #selector(appDidUnfolded), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        NSLog("MainViewCon: viewDidLoad: exit")
    }
    
    // MARK: результат получения
    lazy var getListCompletionHandler: (Int, [User]?) -> Void = { doneWorking, list in
        NSLog(self.TAG + "getListCompletionHandler: entrance")
        switch doneWorking {
        case 0:     //  неудачное получение
            NSLog(self.TAG + "getListCompletionHandler: doneWorking = 0")
            self.visibleBaseEmptyView()
            self.listSportsman.removeAll()
            self.tableView.reloadData()
        case 1:     // удачное получение
            NSLog(self.TAG + "getListCompletionHandler: doneWorking = 1")
            self.invisibleBaseEmptyView()
            self.listSportsman = list!
            if list!.isEmpty {
                self.visibleBaseEmptyView()
            } else {
                self.invisibleBaseEmptyView()
            }
            //self.invisibleNoAuthView()
            self.tableView.reloadData()
        default:
            NSLog(self.TAG + "getListCompletionHandler: doneWorking = default")
            //  self.visibleBaseEmptyView()
        }
        
        NSLog(self.TAG + "getListCompletionHandler: doneWorking")
    }
    
    func invisibleBaseEmptyView (){
//        NSLayoutConstraint.deactivate([self.constraint100Empty])
//        NSLayoutConstraint.activate([self.constraint1Empty])
//        self.baseEmptyView.isHidden = true
    }
    func visibleBaseEmptyView (){
//        NSLayoutConstraint.deactivate([self.constraint1Empty])
//        NSLayoutConstraint.activate([self.constraint100Empty])
//        self.baseEmptyView.isHidden = false
    }
    
    func visibleNoAuthView (){
//        NSLayoutConstraint.deactivate([self.constraint1Auth])
//        NSLayoutConstraint.activate([self.constraint100Auth])
//        self.noAuthView.isHidden = false
    }
    func invisibleNoAuthView (){
//        NSLayoutConstraint.deactivate([self.constraint100Auth])
//        NSLayoutConstraint.activate([self.constraint1Auth])
//        self.noAuthView.isHidden = true
    }
    
    // MARK: попытка авторизации
    func tryAuth(){
        NSLog(TAG + "tryAuth: entrance")
        fireBaseAuthManager.reAuth(using: reAuthCompletionHandler)
        NSLog(TAG + "tryAuth: exit")
    }
    
    // MARK: результат ре-авторизации
    lazy var reAuthCompletionHandler: (Int, String) -> Void = { doneWorking, desc in
        NSLog(self.TAG + "reAuthCompletionHandler: entrance")
        switch doneWorking {
        case 0: //  удачный вход
            NSLog(self.TAG + "reAuthCompletionHandler: doneWorking = 0")
            self.addSportsmanButton.isEnabled = true
            self.fireBaseCloudManager.getCloudUserData()
            if (self.userDefaultsManager.getPassword() != "0"
                && self.userDefaultsManager.getPassword() != ""
            ){
                self.coreDataManager.savePass(pass: self.userDefaultsManager.getPassword())
                NSLog(self.TAG + "reAuthCompletionHandler: doneWorking = 0: passCD = " + self.coreDataManager.getPass()!)
            }
            self.invisibleNoAuthView()
            self.tableView.reloadData()
        case 4: //  сетевая ошибка
            NSLog(self.TAG + "reAuthCompletionHandler: doneWorking = 4")
            self.addSportsmanButton.isEnabled = false
            self.settingStatusBar(nameColor: "redColor")
            self.navigationBar.title = "You not logged in!"
            Task {
                NSLog(self.TAG + "installNameUser: Task")
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self.settingStatusBar(nameColor: "accentColor")
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                self.navigationBar.title = "KerdoIndexSPORT"
            }
            
            let alert = UIAlertController(title: "Check your internet connection", message: nil, preferredStyle: .actionSheet)
            let okAction = UIAlertAction(title: "OK", style: .destructive) { [weak self] (_) in
                NSLog(self!.TAG + "reAuthCompletionHandler: UIAlertController: OK")
            }
            alert.addAction(okAction)
            //  для ipad'ов
            if let popover = alert.popoverPresentationController{
                NSLog(self.TAG + "clickClearButton: popoverPresentationController: for ipad's")
                //popover.sourceView = self.loginButton
            }
            self.present(alert, animated: true, completion: nil)
        default:    //  НЕудачный вход
            NSLog(self.TAG + "reAuthCompletionHandler: doneWorking = " + String(doneWorking))
            
            self.listSportsman.removeAll()
            self.tableView.reloadData()
            self.addSportsmanButton.isEnabled = false
            self.settingStatusBar(nameColor: "redColor")
            self.navigationBar.title = "You not logged in!"
            Task {
                NSLog(self.TAG + "installNameUser: Task")
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self.settingStatusBar(nameColor: "accentColor")
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                self.navigationBar.title = "KerdoIndexSPORT"
            }
            
            let alert = UIAlertController(title: "Unexpected login error. Try login manually", message: nil, preferredStyle: .actionSheet)
            let okAction = UIAlertAction(title: "OK", style: .destructive) { [weak self] (_) in
                NSLog(self!.TAG + "reAuthCompletionHandler: UIAlertController: OK")
            }
            alert.addAction(okAction)
            //  для ipad'ов
            if let popover = alert.popoverPresentationController{
                NSLog(self.TAG + "clickClearButton: popoverPresentationController: for ipad's")
                //popover.sourceView = self.loginButton
            }
            self.present(alert, animated: true, completion: nil)
        }
    
        NSLog(self.TAG + "reAuthCompletionHandler: exit")
    }
    
    // MARK: работа с tableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NSLog("MainViewCon: tableView: listSportsman.count = " + String(listSportsman.count))
        return listSportsman.count
    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    // MARK: работа с tableView: настройка ячейки
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "sportsmanCellID", for: indexPath) as! NameSportmanCell
        let item = listSportsman[indexPath.row]
        cell.nameSportman.text = item.name
        cell.emailSportsman.text = item.email
        return cell
    }
    // MARK: нажатие на ячейку
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "toDetailView", sender: self)
    }
    // MARK: сдвиг ячейки
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            NSLog("MainViewCon: tableView.editingStyle: indexPath.row = " + String(indexPath.row))
            
            let alert = UIAlertController(title: NSLocalizedString("areYouSureYouWantToDeleteTheSportsman", comment: ""), message: nil, preferredStyle: .actionSheet)
            let deleteAction = UIAlertAction(title: "Удалить", style: .destructive) { [weak self] (_) in
                NSLog("MainViewCon: tableView.editingStyle: deleteAction: entrance")
                self?.rowDelete = indexPath.row
                self!.fireBaseCloudManager.deleteSportsman(id: self!.listSportsman[indexPath.row].id, using: self!.deleteCompletionHandler)
            }
            let cancelAction = UIAlertAction(title: NSLocalizedString("cancelInAlertDialog", comment: ""), style: .cancel, handler: nil)
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)
            //  для ipad'ов
            if let popover = alert.popoverPresentationController{
                NSLog("MainViewCon: tableView.editingStyle: popoverPresentationController: for ipad's")
                popover.sourceView = self.view    // по центру
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
            }
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: результат удаления
    lazy var deleteCompletionHandler: (Int) -> Void = { doneWorking in
        switch doneWorking {
        case 0:
            NSLog("DetailsViewCon: deleteCompletionHandler: doneWorking = 0")
            let alert = UIAlertController(title: "Failed to delete sportsman: Check your internet connection", message: nil, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            //  для ipad'ов
            if let popover = alert.popoverPresentationController{
                NSLog("DetailsViewCon: deleteButtonClicked: popoverPresentationController: for ipad's")
                popover.sourceView = self.view    // по центру
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
            }
            self.present(alert, animated: true, completion: nil)
        case 1:
            NSLog("DetailsViewCon: uploadCompletionHandler: doneWorking = 1")
            self.listSportsman.remove(at: self.rowDelete)
            self.tableView.reloadData()
        default:
            NSLog("DetailsViewCon: uploadCompletionHandler: doneWorking = default")
        }
    }
    
    // MARK: отображение аватарки
    func viewAvatar(avatarURL: String, cell: NameSportmanCell){
        cell.avatarSportsmanImageView.layer.cornerRadius = cell.avatarSportsmanImageView.frame.size.width/2
        cell.avatarSportsmanImageView.clipsToBounds = true
        guard let apiURL = URL(string: avatarURL) else {
            fatalError("some error")
        }
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: apiURL) { (data, response, error) in
            guard let data = data, error == nil else {return}
            DispatchQueue.main.async {
                cell.avatarSportsmanImageView.image = UIImage(data: data)
            }
        }
        task.resume()
    }
    
    // MARK: перед началом перехода
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        NSLog("MainViewCon: prepare: entrance")
        if(segue.identifier == "toDetailView"){
            let indexPath = tableView.indexPathForSelectedRow!
            let sportsmanDetail = segue.destination as? DetailsSportsmanViewController
            NSLog("MainViewCon: prepare: indexPath.row = " + String(indexPath.row))
            
            sportsmanDetail!.idSportsman = listSportsman[indexPath.row].id
            NSLog("MainViewCon: prepare: sportsmanDetail!.idSportsman = " + sportsmanDetail!.idSportsman)
            sportsmanDetail!.nameSportsman = listSportsman[indexPath.row].name

            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: после запуска экрана
    override func viewDidAppear(_ animated: Bool) {
        NSLog("MainViewCon: viewDidAppear: entrance")
        settingsViews()
        NSLog("MainViewCon: viewDidAppear: exit")
    }
    
    // MARK: разворачивание приложения
    @objc func appDidUnfolded(_ application: UIApplication) {
        NSLog("MainViewCon: appDidUnfolded: entrance")
        
        NSLog("MainViewCon: appDidUnfolded: exit")
    }
    
    // MARK: настройка statusBar
    func settingStatusBar(nameColor: String){
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = UIColor(named: nameColor)
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
        }
    }
    
    // MARK: настройка view
    func settingsViews(){
        NSLog("MainViewCon: settingsViews: entrance")
        settingStatusBar(nameColor: "accentColor")
        
        noAuthView.translatesAutoresizingMaskIntoConstraints = false
        //baseEmptyView.translatesAutoresizingMaskIntoConstraints = false
        
        tryAuth()
        fireBaseCloudManager.getCloudData(using: getListCompletionHandler)
        
        installNameUser()
        tableView.rowHeight = 80
        
        self.addSportsmanButton.isEnabled = fireBaseAuthManager.stateAuth()
        
        NSLog("MainViewCon: settingsViews: exit")
    }
    
    func installNameUser(){
        navigationBar.title = "KerdoIndexSPORT"
        if fireBaseAuthManager.stateAuth() {
            Task {
                NSLog("MainViewCon: installNameUser: Task")
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                navigationBar.title = userDefaultsManager.getYourName()
            }
        }
    }
}
