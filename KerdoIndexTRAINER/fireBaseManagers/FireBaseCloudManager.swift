import Foundation
import FirebaseFirestore

class FireBaseCloudManager {
    
    var userDefaultsManager = UserDefaultsManager()
    var db: Firestore!
    let TAG = "FireBaseCloudManager: "
    
    init(){
        db = Firestore.firestore()
    }
    
    // MARK: создание пользователя
    func addUserInCloudData(){
        NSLog(TAG + "addUserInCloudData: entrance")
        
        let idUser = userDefaultsManager.getIdUser()
        let yourName = userDefaultsManager.getYourName()
        let yourEmail = userDefaultsManager.getYourEmail()
        let yourUrl = userDefaultsManager.getYourImageURL()
        NSLog(TAG + "addUserInCloudData: userDefaultsManager.getIdUser = " + idUser)
        
        db.collection(Strings.usersTableStr.rawValue).document(idUser).setData([
            "id": idUser,
            "type": "t",
            "name": yourName,
            "email": yourEmail,
            "iconUrl": yourUrl,
            "trainerId": "",
            "lastDate": "",
            "json": "",
            "settings": "",
            "f1": "",
            "f2": "",
            "f3": "",
            "f4": "",
            "f5": ""
        ])
        NSLog(TAG + "addUserInCloudData: exit")
    }
    
    // MARK: обновление имени
    func updateNameInCloudData(){
        NSLog(TAG + "updateNameInCloudData: entrance: userDefaultsManager.getYourName = " + userDefaultsManager.getYourName())
        NSLog(TAG + "updateNameInCloudData: entrance: userDefaultsManager.getIdUser = " + userDefaultsManager.getIdUser())
        db.collection(Strings.usersTableStr.rawValue).document(userDefaultsManager.getIdUser())
            .updateData([Strings.nameFieldStr.rawValue: userDefaultsManager.getYourName()]){ error in
                if let error = error {
                    NSLog(self.TAG + "updateNameInCloudData: Error updating document: \(error.localizedDescription)")
                } else {
                    NSLog(self.TAG + "updateNameInCloudData: Document successfully updated")
                }
            }
    }
    
    // MARK: обновление url иконки
    func updateUrlIconInCloudData(){
        NSLog(TAG + "updateUrlIconInCloudData: entrance: userDefaultsManager.getYourImageURL = " + userDefaultsManager.getYourImageURL())
        NSLog(TAG + "updateUrlIconInCloudData: entrance: userDefaultsManager.getIdUser = " + userDefaultsManager.getIdUser())
        db.collection(Strings.usersTableStr.rawValue)
            .document(userDefaultsManager.getIdUser())
            .updateData([Strings.iconUrlFieldStr.rawValue: userDefaultsManager.getYourImageURL()]){ error in
                if let error = error {
                    NSLog(self.TAG + "updateUrlIconInCloudData: Error updating document: \(error.localizedDescription)")
                } else {
                    NSLog(self.TAG + "updateUrlIconInCloudData: Document successfully updated")
                }
            }
    }
    
    // MARK: удаление пользователя
    func deleteInCloudData(){
        NSLog(TAG + "deleteInCloudData: entrance: userDefaultsManager.getIdUser = " + userDefaultsManager.getIdUser())
        db.collection(Strings.usersTableStr.rawValue).document(userDefaultsManager.getIdUser())
            .delete(){ error in
                if error != nil {
                    NSLog(self.TAG + "deleteInCloudData: error = " + error!.localizedDescription)
                }
            }
        NSLog(TAG + "deleteInCloudData: exit")
    }
    
    // MARK: прикрепление тренера за спорстменом
    func saveSportsman(sportsman: String, using completionHandler: @escaping (Int) -> Void){
        NSLog(self.TAG + "saveSportsman: entrance")
        db.collection(Strings.usersTableStr.rawValue).whereField(
            Strings.emailFieldStr.rawValue, isEqualTo: sportsman
        ).getDocuments{ (documents, error) in
            if let error = error {
                NSLog(self.TAG + "saveSportsman: Error getting documents: \(error)")
                completionHandler(2)
            } else {
                if (documents!.isEmpty) {
                    NSLog(self.TAG + "saveSportsman: documents?.isEmpty")
                    completionHandler(0)
                } else {
                    let gettedSportsman: QueryDocumentSnapshot = (documents?.documents[0])!
                    NSLog(self.TAG + gettedSportsman.documentID)
                    
                    self.db.collection(Strings.usersTableStr.rawValue).document(gettedSportsman.documentID)
                        .updateData(["trainerId": self.userDefaultsManager.getIdUser()]){ error in
                            if let error = error {
                                NSLog(self.TAG + "saveSportsman: Error saving sportsman: \(error.localizedDescription)")
                                completionHandler(2)
                            } else {
                                NSLog(self.TAG + "saveSportsman: sportsman successfully saved")
                                completionHandler(1)
                            }
                        }
                }
            }
        }
    }
    
    // MARK:  получение данных пользователя
    func getCloudUserData(){
        db.collection(Strings.usersTableStr.rawValue).document(userDefaultsManager.getIdUser())
            .getDocument{ (document, error) in
            if let document = document, document.exists {
                let name = document.get(Strings.nameFieldStr.rawValue) as! String
                self.userDefaultsManager.saveYourName(name: name)
            } else {
                NSLog(self.TAG + "getCloudData: Document does not exist")
            }
        }
    }
    
    // MARK: получение списка пользователей
    func getCloudData(using completionHandler: @escaping (Int, [User]?) -> Void){        
        var list: [User] = []
        db.collection(Strings.usersTableStr.rawValue).whereField(
            "trainerId", isEqualTo: userDefaultsManager.getIdUser()
        ).getDocuments{ (documents, error) in
            if let error = error {
                NSLog(self.TAG + "getCloudData: Error getting documents: \(error)")
                completionHandler(0, [])
            } else {
                if (documents!.isEmpty) {
                    NSLog(self.TAG + "getCloudData: documents?.isEmpty")
                    completionHandler(0, [])
                } else {
                    for document in documents!.documents {
                        NSLog(self.TAG + "document: \(document.documentID) => \(document.data())")
                        let sportsman = User(
                            id: document.documentID,
                            type: "",
                            name: document.get(Strings.nameFieldStr.rawValue) as! String,
                            email: document.get(Strings.emailFieldStr.rawValue) as! String,
                            iconUrl: "", trainerId: "", lastDate: "",
                            json: "", settings: "", f1: "",
                            f2: "", f3: "", f4: "", f5: ""
                        )
                        list.append(sportsman)
                    }
                    completionHandler(1, list)
                }
            }
        }
    }
    
    // MARK: получение данных спортсмена
    func getSportsmanData(id: String, using completionHandler: @escaping (Int, User?) -> Void){
        db.collection(Strings.usersTableStr.rawValue).document(id).getDocument{ (document, error) in
            if let error = error {
                NSLog(self.TAG + "getSportsmanData: Error getting documents: \(error)")
                completionHandler(0, nil)
            } else {
                if (!document!.exists) {
                    NSLog(self.TAG + "getSportsmanData: document?.isEmpty")
                    completionHandler(0, nil)
                } else {
                    NSLog(self.TAG + "getSportsmanData: document : \(document!.documentID) | \(document!.get(Strings.emailFieldStr.rawValue) as! String)")
                    let sportsman = User(
                        id: document!.documentID,
                        type: "",
                        name: document!.get(Strings.nameFieldStr.rawValue) as! String,
                        email: document!.get(Strings.emailFieldStr.rawValue) as! String,
                        iconUrl: "", trainerId: "",
                        lastDate: document?.get(Strings.lastDateFieldStr.rawValue) as! String,
                        json: document!.get(Strings.jsonFieldStr.rawValue) as! String,
                        settings: "", f1: "", f2: "", f3: "", f4: "", f5: ""
                    )
                    completionHandler(1, sportsman)
                }
            }
        }
    }
    
    // MARK: открепление спортсмена от тренера
    func deleteSportsman(id: String, using completionHandler: @escaping (Int) -> Void){
        db.collection(Strings.usersTableStr.rawValue).document(id)
            .updateData(["trainerId": ""]){ error in
                if let error = error {
                    NSLog(self.TAG + "updateNameInCloudData: Error updating document: \(error.localizedDescription)")
                    completionHandler(0)
                } else {
                    NSLog(self.TAG + "updateNameInCloudData: Document successfully updated")
                    completionHandler(1)
                }
            }
    }
    
    // MARK: получение типа пользователя
    func getTypeUser(email: String, using completionHandler: @escaping (Int, String?) -> Void){
        db.collection(Strings.usersTableStr.rawValue).whereField(
            Strings.emailFieldStr.rawValue, isEqualTo: email
        ).getDocuments{ (documents, error) in
            if let error = error {
                NSLog(self.TAG + "getCloudData: Error getting documents: \(error)")
                completionHandler(0, nil)
            } else {
                if (documents!.isEmpty) {
                    NSLog(self.TAG + "getCloudData: documents?.isEmpty")
                    completionHandler(0, nil)
                } else {
                    NSLog(self.TAG + "getCloudData: type user = \(documents!.documents[0].get(Strings.typeFieldStr.rawValue) as! String)")
                    let typeStr = documents!.documents[0].get(Strings.typeFieldStr.rawValue) as! String
                    completionHandler(1, typeStr)
                }
            }
        }
    }
    
}
