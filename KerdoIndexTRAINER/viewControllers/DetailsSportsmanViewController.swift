import UIKit
import Charts

class DetailsSportsmanViewController: UIViewController, ChartViewDelegate, UITextFieldDelegate, UIScrollViewDelegate, UITextViewDelegate {
    
    //  объекты view-элементов
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var deleteSportsmanButton: UIButton!
    @IBOutlet weak var addressEmailSportsmanLabel: UILabel!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var deleteSuccessView: UIView!
    @IBOutlet weak var kedroView: UIView!
    @IBOutlet weak var pulseView: UIView!
    @IBOutlet weak var dadView: UIView!
    @IBOutlet weak var infoMeasuringView: UIView!
    @IBOutlet weak var firstMeasuringInfoView: UIView!
    @IBOutlet weak var firstMeasuringInfoLabel: UILabel!
    @IBOutlet weak var secondMeasuringInfoView: UIView!
    @IBOutlet weak var secondMeasuringInfoLabel: UILabel!
    @IBOutlet weak var dateTimeMeasuringInfoLabel: UILabel!
    @IBOutlet weak var kedroViewHeight: NSLayoutConstraint!
    @IBOutlet weak var pulseViewHeight: NSLayoutConstraint!
    @IBOutlet weak var dadViewHeight: NSLayoutConstraint!
    @IBOutlet weak var mainViewHeight: NSLayoutConstraint!
    @IBOutlet weak var lastUpdateLabel: UILabel!
    @IBOutlet weak var offlineModeButton: UIButton!
    @IBOutlet weak var jsonIsEmptyView: UIView!
    
    var userDefaultsManager = UserDefaultsManager()
    var fireBaseAuthManager = FireBaseAuthManager()
    var fireBaseCloudManager = FireBaseCloudManager()
    var barKedroChart = BarChartView()
    var barPulseChart = BarChartView()
    var barDadChart = BarChartView()
    var idSportsman = String()
    var nameSportsman = String()
    var measures1: [MeasureNew] = []
    var measures2: [MeasureNew] = []
    let TAG = "DetailsSportsmanViewController: "
    
    // MARK: при запуске экрана...
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("DetailsViewCon: viewDidLoad: entrance")

        settingsViews()         //  ...настройка view
        uploadData()
        
        NSLog("DetailsViewCon: viewDidLoad: exit")
    }
    
    // MARK: запуск загрузки
    func uploadData(){
        NSLog("DetailsViewCon: startUploadMessages: entrance")
        
        fireBaseCloudManager.getSportsmanData(id: idSportsman, using: uploadCompletionHandler)

        NSLog("DetailsViewCon: startUploadMessages: exit")
    }
    
    // MARK: результат загрузки
    lazy var uploadCompletionHandler: (Int, User?) -> Void = { doneWorking, sportsman in
        NSLog("DetailsViewCon: uploadCompletionHandler: entrance")
        switch doneWorking {
        case 0:
            NSLog("DetailsViewCon: uploadCompletionHandler: doneWorking = 0")
            
        case 1:
            NSLog("DetailsViewCon: uploadCompletionHandler: doneWorking = 1: \(sportsman!)")
            self.displayData(sportsman: sportsman!)
        default:
            NSLog("DetailsViewCon: uploadCompletionHandler: doneWorking = " + String(doneWorking))
        }
        self.displayStartState()
        NSLog("DetailsViewCon: uploadCompletionHandler: exit")
    }
    
    func displayData(sportsman: User){
        displayEmail(email: sportsman.email)
        displayMeasure(json: sportsman.json)
        displayLastDate(lastDate: sportsman.lastDate)
    }
    
    func displayEmail(email: String){
        NSLog("DetailsViewCon: displayEmail: entrance")
        addressEmailSportsmanLabel.text = "Sportsman's email address: " + email
    }
    
    func displayMeasure(json: String){
        NSLog("DetailsViewCon: displayMeasure: entrance")
        if !json.isEmpty {
            NSLog("DetailsViewCon: displayMeasure: jsonIsNotEmpty")
            kedroViewHeight.constant = 300
            pulseViewHeight.constant = 300
            dadViewHeight.constant = 300
            mainViewHeight.constant = 1125
            jsonIsEmptyView.isHidden = true
            let js = parcingJson(json: json)
            measures1 = js!.measures1
            measures2 = js!.measures2
            createKedroChart()  // график кедро
            createPulseChart()  // график пульса
            createDadChart()    // график ДАД
        } else {
            NSLog("DetailsViewCon: displayMeasure: jsonIsEmpty")
            kedroViewHeight.constant = 1
            pulseViewHeight.constant = 1
            dadViewHeight.constant = 1
            mainViewHeight.constant = 500
            jsonIsEmptyView.isHidden = false
        }
        
    }
    
    func displayLastDate(lastDate: String){
        NSLog("DetailsViewCon: displayLastDate: entrance")
        lastUpdateLabel.text = "Last Update: " + lastDate
    }
    
    // MARK: показать начальную шапку
    func displayStartState(){
        NSLog("DetailsViewCon: displayStartState: entrance")
        Task {
            NSLog("DetailsViewCon: displayStartState: Task")
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            settingStatusBar(nameColor: "accentColor")
        }
        NSLog("DetailsViewCon: displayStartState: exit")
    }
    
    // MARK: кнопка удаления спортсмена нажата
    @IBAction func deleteButtonClicked(_ sender: Any) {
        NSLog("DetailsViewCon: deleteButtonClicked: entrance")

        let alert = UIAlertController(title: NSLocalizedString("areYouSureYouWantToDeleteTheSportsman", comment: ""), message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: NSLocalizedString("DeleteInAlertDialog", comment: ""), style: .destructive) { [weak self] (_) in
            NSLog("DetailsViewCon: deleteButtonClicked: deleteAction: entrance")
            self!.fireBaseCloudManager.deleteSportsman(id: self!.idSportsman, using: self!.deleteCompletionHandler)
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancelInAlertDialog", comment: ""), style: .cancel, handler: nil)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        //  для ipad'ов
        if let popover = alert.popoverPresentationController{
            NSLog("DetailsViewCon: deleteButtonClicked: popoverPresentationController: for ipad's")
            popover.sourceView = deleteSportsmanButton
        }
        present(alert, animated: true, completion: nil)

        NSLog("DetailsViewCon: deleteButtonClicked: exit")
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
                popover.sourceView = self.deleteSportsmanButton
            }
            self.present(alert, animated: true, completion: nil)
        case 1:
            NSLog("DetailsViewCon: uploadCompletionHandler: doneWorking = 1")
            self.deleteSuccessView.isHidden = false
            Task{
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                self.deleteSuccessView.isHidden = true
                self.navigationController?.popViewController(animated: true)
            }
        default:
            NSLog("DetailsViewCon: uploadCompletionHandler: doneWorking = default")
        }
    }
    
    // MARK: состояние интернета
    // наблюдение за ним
    func checkingReachabilityAndStateEmailTrainer() async{
        NSLog("MainViewCon: checkingReachabilityAndStateEmailTrainer: entrance")
        while (true){
            switch userDefaultsManager.getStateInternet(){
            case 1:
                offlineModeButton.isHidden = true
            case 0:
                offlineModeButton.isHidden = false
            default:
                offlineModeButton.isHidden = false
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }
    
    // MARK: нажатие на столбец
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        NSLog("DetailsViewCon: chartValueSelected: entrance")
        firstMeasuringInfoLabel.text = String(NSString(format: "%.2f", Double(measures1[Int(entry.x - 1)].KerdoIndex)!))
        secondMeasuringInfoLabel.text = String(NSString(format: "%.2f", Double(measures2[Int(entry.x - 1)].KerdoIndex)!))
        dateTimeMeasuringInfoLabel.text = measures1[Int(entry.x - 1)].date
        //  лог
        NSLog("column: " + String(entry.x))
        NSLog("kerdoIndex1: " + String(measures1[Int(entry.x - 1)].KerdoIndex))
        NSLog("kerdoIndex2: " + String(measures2[Int(entry.x - 1)].KerdoIndex))
        NSLog("date: " + measures1[Int(entry.x - 1)].date)

        if Double(measures1[Int(entry.x - 1)].KerdoIndex)! < -15{
            firstMeasuringInfoView.backgroundColor = UIColor(named: "greenColor")
        } else if 15 < Double(measures1[Int(entry.x - 1)].KerdoIndex)! {
            firstMeasuringInfoView.backgroundColor = UIColor(named: "redColor")
        } else {
            firstMeasuringInfoView.backgroundColor = UIColor(named: "yellowColor")
        }

        if Double(measures2[Int(entry.x - 1)].KerdoIndex)! < -15{
            secondMeasuringInfoView.backgroundColor = UIColor(named: "greenColor")
        } else if 15 < Double(measures2[Int(entry.x - 1)].KerdoIndex)! {
            secondMeasuringInfoView.backgroundColor = UIColor(named: "redColor")
        } else {
            secondMeasuringInfoView.backgroundColor = UIColor(named: "yellowColor")
        }
        
        infoMeasuringView.isHidden = false
        NSLog("DetailsViewCon: chartValueSelected: exit")
    }
    
    // MARK: заполнение графика кедро
    func createKedroChart(){
        //  заполнение массива с данными для графика
        var entriesKedroChart = [BarChartDataEntry]()
        for index in measures1.indices {
            entriesKedroChart.append(
                BarChartDataEntry(
                    x: Double(index + 1),
                    y: Double(measures1[index].KerdoIndex)!
                )
            )
            entriesKedroChart.append(
                BarChartDataEntry(
                    x: Double(index + 1),
                    y: Double(measures2[index].KerdoIndex)!
                )
            )
        }
        //  заполнение массива с цветами
        var colors = [NSUIColor]()
        for i in entriesKedroChart {
            if i.y < -15{
                colors.append(NSUIColor(cgColor: UIColor(named: "greenColor")!.cgColor))
            } else if 15 < i.y {
                colors.append(NSUIColor(cgColor: UIColor(named: "redColor")!.cgColor))
            } else {
                colors.append(NSUIColor(cgColor: UIColor(named: "yellowColor")!.cgColor))
            }
        }
        //  настройка данных графика
        let set = BarChartDataSet(entries: entriesKedroChart)
        set.valueFont = UIFont(name: "Verdana", size: 12.0)!
        set.colors = colors
        //  настройка отображения графика
        let data = BarChartData(dataSet: set)
        barKedroChart.data = data
        barKedroChart.dragYEnabled = false
        barKedroChart.legend.enabled = false
        barKedroChart.doubleTapToZoomEnabled = false
        barKedroChart.xAxis.granularityEnabled = true
        barKedroChart.xAxis.granularity = 1.0
        barKedroChart.setVisibleXRangeMaximum(12)
        barKedroChart.moveViewToX(Double(measures1.count))
        barKedroChart.barData?.barWidth = 0.5
        NSLog("DetailsViewCon: createKedroChart: exit")
    }

    // MARK: заполнение графика пульса
    func createPulseChart(){
        NSLog("DetailsViewCon: createPulseChart: entrance")
        //  заполнение массива с данными для графика
        var entriesPulseChart = [BarChartDataEntry]()
        for index in measures1.indices {
            entriesPulseChart.append(
                BarChartDataEntry(
                    x: Double(index + 1),
                    y: Double(measures1[index].Pulse)!
                )
            )
            entriesPulseChart.append(
                BarChartDataEntry(
                    x: Double(index + 1),
                    y: Double(measures2[index].Pulse)!
                )
            )
        }
        //  настройка данных графика
        let set = BarChartDataSet(entries: entriesPulseChart)
        set.valueFont = UIFont(name: "Verdana", size: 12.0)!
        //  настройка отображения графика
        set.addColor(NSUIColor(cgColor: UIColor.systemBlue.cgColor))
        let data = BarChartData(dataSet: set)
        barPulseChart.data = data
        barPulseChart.dragYEnabled = false
        barPulseChart.legend.enabled = false
        barPulseChart.doubleTapToZoomEnabled = false
        barPulseChart.xAxis.granularityEnabled = true
        barPulseChart.xAxis.granularity = 1.0
        barPulseChart.setVisibleXRangeMaximum(12)
        barPulseChart.moveViewToX(Double(measures1.count))
        barPulseChart.barData?.barWidth = 0.5
        NSLog("DetailsViewCon: createPulseChart: exit")
    }
    
    // MARK: заполнение графика дад
    func createDadChart(){
        NSLog("DetailsViewCon: createDadChart: entrance")
        //  заполнение массива с данными для графика
        var entriesDadChart = [BarChartDataEntry]()
        for index in measures1.indices {
            entriesDadChart.append(
                BarChartDataEntry(
                    x: Double(index + 1),
                    y: Double(measures1[index].DAD)!
                )
            )
            entriesDadChart.append(
                BarChartDataEntry(
                    x: Double(index + 1),
                    y: Double(measures2[index].DAD)!
                )
            )
        }
        //  настройка данных графика
        let set = BarChartDataSet(entries: entriesDadChart)
        set.valueFont = UIFont(name: "Verdana", size: 12.0)!
        //  настройка отображения графика
        set.addColor(NSUIColor(cgColor: UIColor.systemBlue.cgColor))
        let data = BarChartData(dataSet: set)
        barDadChart.data = data
        barDadChart.dragYEnabled = false
        barDadChart.legend.enabled = false
        barDadChart.doubleTapToZoomEnabled = false
        barDadChart.xAxis.granularityEnabled = true
        barDadChart.xAxis.granularity = 1.0
        barDadChart.setVisibleXRangeMaximum(12)
        barDadChart.moveViewToX(Double(measures1.count))
        barDadChart.barData?.barWidth = 0.5
        NSLog("DetailsViewCon: createDadChart: exit")
    }
    
    // MARK: настройка statusBar
    func settingStatusBar(nameColor: String){
        NSLog("DetailsViewCon: settingStatusBar: entrance")
        if #available(iOS 13.0, *) {
            NSLog("DetailsViewCon: displayEmptyState: if #available(iOS 13.0, *)")
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = UIColor(named: nameColor)
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
        }
        NSLog("DetailsViewCon: settingStatusBar: exit")
    }
    
    // MARK: настройка view
    func settingsViews(){
        NSLog("DetailsViewCon: settingsViews: entrance")
        settingStatusBar(nameColor: "accentColor")
        navigationBar.title = nameSportsman
        
        //  сглаживание углов
        self.view.bringSubviewToFront(infoMeasuringView)
        infoMeasuringView.layer.cornerRadius = 20
        firstMeasuringInfoView.layer.cornerRadius = 10
        secondMeasuringInfoView.layer.cornerRadius = 10
        deleteSuccessView.layer.cornerRadius = 10
        
        //  настройка графиков
        barKedroChart.delegate = self
        barKedroChart.translatesAutoresizingMaskIntoConstraints = false
        mainScrollView.translatesAutoresizingMaskIntoConstraints = false
        mainScrollView.shouldIgnoreScrollingAdjustment = true

        kedroView.addSubview(barKedroChart)
        let topAnchorKedro = barKedroChart.topAnchor.constraint(equalTo: kedroView.topAnchor, constant: 5)
        let bottomAnchorKedro = barKedroChart.bottomAnchor.constraint(equalTo: kedroView.bottomAnchor, constant: -5)
        let leftAnchorKedro = barKedroChart.leftAnchor.constraint(equalTo: kedroView.leftAnchor, constant: 5)
        let rightAnchorKedro = barKedroChart.rightAnchor.constraint(equalTo: kedroView.rightAnchor, constant: -5)
        NSLayoutConstraint.activate([topAnchorKedro, bottomAnchorKedro, leftAnchorKedro, rightAnchorKedro])
        
        barPulseChart.translatesAutoresizingMaskIntoConstraints = false
        mainScrollView.translatesAutoresizingMaskIntoConstraints = false
        pulseView.addSubview(barPulseChart)
        let topAnchorPulse = barPulseChart.topAnchor.constraint(equalTo: pulseView.topAnchor, constant: 5)
        let bottomAnchorPulse = barPulseChart.bottomAnchor.constraint(equalTo: pulseView.bottomAnchor, constant: -5)
        let leftAnchorPulse = barPulseChart.leftAnchor.constraint(equalTo: pulseView.leftAnchor, constant: 5)
        let rightAnchorPulse = barPulseChart.rightAnchor.constraint(equalTo: pulseView.rightAnchor, constant: -5)
        NSLayoutConstraint.activate([topAnchorPulse, bottomAnchorPulse, leftAnchorPulse, rightAnchorPulse])
        
        barDadChart.translatesAutoresizingMaskIntoConstraints = false
        mainScrollView.translatesAutoresizingMaskIntoConstraints = false
        dadView.addSubview(barDadChart)
        let topAnchorDad = barDadChart.topAnchor.constraint(equalTo: dadView.topAnchor, constant: 5)
        let bottomAnchorDad = barDadChart.bottomAnchor.constraint(equalTo: dadView.bottomAnchor, constant: -5)
        let leftAnchorDad = barDadChart.leftAnchor.constraint(equalTo: dadView.leftAnchor, constant: 5)
        let rightAnchorDad = barDadChart.rightAnchor.constraint(equalTo: dadView.rightAnchor, constant: -5)
        NSLayoutConstraint.activate([topAnchorDad, bottomAnchorDad, leftAnchorDad, rightAnchorDad])
        
        Task {
            NSLog("MainViewCon: viewDidAppear: Task")
            await checkingReachabilityAndStateEmailTrainer()
        }
        
        NSLog("DetailsViewCon: settingsViews: exit")
    }
    
    @IBAction func clickCloseInfoMeasuring(_ sender: Any) {
        NSLog("DetailsViewCon: clickCloseInfoMeasuring: entrance")
        infoMeasuringView.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NSLog("DetailsViewCon: viewDidDisappear: entrance")
        NSLog("DetailsViewCon: viewDidDisappear: exit")
    }
}

// MARK: округлые столбцы
// Для округлых столбцов в файле BarChartRenderer.swift :

//if !isSingleColor
//{
//    // Set the color for the currently drawn value. If the index is out of bounds, reuse colors.
//    context.setFillColor(dataSet.color(atIndex: j).cgColor)
//}
//
//context.fill(barRect) <-- это заменить на...
//  ...это:
//let bezierPath = UIBezierPath(roundedRect: barRect, cornerRadius:10)
//context.addPath(bezierPath.cgPath)
//context.drawPath(using: .fill)
//
//if drawBorder
//{
//    context.setStrokeColor(borderColor.cgColor)
//    context.setLineWidth(borderWidth)
//    context.stroke(barRect)
//}
