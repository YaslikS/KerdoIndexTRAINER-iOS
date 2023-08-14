import Foundation

class UserDefaultsManager {
    
    // MARK: SAVE
    // id пользователя
    func saveIdUser(idUser: String){
        UserDefaults.standard.set(idUser, forKey: "idUser")
    }
    
    // имя пользователя
    func saveYourName(name: String){
        UserDefaults.standard.set(name, forKey: "yourName")
    }
    
    // email пользователя
    func saveYourEmail(emailAddress: String){
        UserDefaults.standard.set(emailAddress, forKey: "emailAddress")
    }
    
    // пароль к аккаунту
    // TODO: под удаление - deprecated method
//    func savePassword(password: String){
//        UserDefaults.standard.set(password, forKey: "password")
//    }
    
    // ссылка на аватарку пользователя
    func saveYourImageURL(yourImageURL: String){
        UserDefaults.standard.set(yourImageURL, forKey: "yourImageURL")
    }
    
    // статус доступности интернета
    // 0 - интернета нет
    // 1 - интернет есть
    // 2 - не используется
    func saveStateInternet(state: Int){
        UserDefaults.standard.set(state, forKey: "stateInternet")
    }
    

    
    
    // MARK: GET
    // id пользователя
    func getIdUser() -> String{
        return UserDefaults.standard.string(forKey: "idUser") ?? "0"
    }
    
    // имя пользователя
    func getYourName() -> String{
        return UserDefaults.standard.string(forKey: "yourName") ?? ""
    }
    
    // email пользователя
    func getYourEmail() -> String{
        return UserDefaults.standard.string(forKey: "emailAddress") ?? ""
    }
    
    // пароль пользователя
    // TODO: под удаление - deprecated method
//    func getPassword() -> String{
//        return UserDefaults.standard.string(forKey: "password") ?? "0"
//    }
    
    // ссылка на аватарку пользователя
    func getYourImageURL() -> String{
        return UserDefaults.standard.string(forKey: "yourImageURL") ?? ""
    }
    
    // статус доступности интернета
    // 0 - интернета нет
    // 1 - интернет есть
    // 2 - не используется
    func getStateInternet() -> Int{
        return UserDefaults.standard.integer(forKey: "stateInternet")
    }
    
    
    // MARK: удаление всех данных
    func deleteUserInfo() {
        NSLog("deleteUserInfo" + "deleteUserInfo: entrance")
        //savePassword(password: "0")
        saveYourEmail(emailAddress: "0")
        saveYourName(name: "0")
        saveIdUser(idUser: "")
        saveYourImageURL(yourImageURL: "")
    }
    
}


