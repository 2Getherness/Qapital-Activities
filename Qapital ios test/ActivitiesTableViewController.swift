//
//  ActivitiesTableViewController.swift
//  Qapital ios test
//
//  Created by erica palm on 2019-08-07.
//  Copyright © 2019 upgradingmachine. All rights reserved.
//

import UIKit
import Foundation


// användar struct med Decodable för att göra det enkelt matcha data typer rätt till JSON data. Och åter använda model senare i appen
struct wholeJSON: Decodable {
    let oldest: String?
    let activities: [activitiesInfo]
}
struct activitiesInfo: Decodable {
    let message: String?
    let amount: Double?
    let userId: Int?
    let timestamp: String?
}

// Users används av helt ny api anrop som körs en gån för att vi har ett antal användaren i den där api anropet
struct Users: Decodable {
    let userId: Int?
    let displayName: String?
    let avatarUrl: URL
}



class ActivitiesTableViewController: UITableViewController {
    
    @IBOutlet weak var ActivityIndicatorView: UIView!
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var activitiesTableView: UITableView!
    
    var activitiesArray = [activitiesInfo]()
    var usersArray = [Users]()
    var detectTwoWeeks = 2
    
    var fromDate = ""
    var toDate = ""
    
    var yearfromDate = 0
    var currentMonthOftheYear = 0
    var scrolled = false
    
    
    var count = 0
    var alertView = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
                self.activitiesTableView.delegate = self
        self.activitiesTableView.dataSource = self
        
        self.yearfromDate = Calendar.current.component(.year, from: Date())
        self.currentMonthOftheYear = Calendar.current.component(.weekOfYear, from: Date())
        
        self.ActivityIndicatorView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 100.0)
        self.ActivityIndicator.color = UIColor.blue
        self.ActivityIndicatorView.isHidden = true
        
        self.timestamp()
        if self.fromDate != "", self.toDate != "" {
        self.downloadJSON(fromDate: self.fromDate, toDate: self.toDate)
        } else { return }

    }
    
// här kollar appen på scrollView varje gång man scrollar. I fall scroll kommer till sista cellen så körs metoden downloadJSON() och visa activityindicator samt ändra från-datum och till-datum för att hämta rätt periodsdata.
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        print("ScrollViewDidEndDragging")
        //print("tableView: UITableView, willDisplay cell")
        self.toDate = ""
        self.toDate = self.fromDate
        self.ActivityIndicatorView.isHidden = false
        self.ActivityIndicator.startAnimating()
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= 60.0 {
            print("tableView: UITableView, willDisplay cell")
            self.detectTwoWeeks += 2
            self.fromDate = self.formateDate(yearString: self.yearfromDate, weekString: self.currentMonthOftheYear - self.detectTwoWeeks)
            print("scrolled to last row! \n toDate = \(self.toDate) \n fromDate = \(self.fromDate) \n DetectWeeks = \(self.detectTwoWeeks)")

            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (timer) in
                self.downloadJSON(fromDate: self.fromDate, toDate: self.toDate)
                self.ActivityIndicator.stopAnimating()
                self.ActivityIndicatorView.isHidden = true
            }
        }
    }
    
// timestamp() fillar från och till datum första innan downloadJSON() metod ska köras.
    func timestamp() {
        self.toDate = self.formateDate(yearString: self.yearfromDate, weekString: self.currentMonthOftheYear)
        print(self.toDate)
        self.fromDate = self.formateDate(yearString: self.yearfromDate, weekString: self.currentMonthOftheYear - self.detectTwoWeeks)
        print(self.fromDate)
    }
    
// Här gör appen att hämta nuvarande datum och sedan konvertera den till rätt format. Sedan retunera den datum
    func formateDate(yearString: Int, weekString: Int) -> String {
        var dateString = ""
        let yearString = "\(yearString)"
        let weekOfYearString = "\(weekString)"
        if let year = Int(yearString), let weekOfYear = Int(weekOfYearString) {
            let components = DateComponents(weekOfYear: weekOfYear, yearForWeekOfYear: year)
            if let date = Calendar.current.date(from: components) {
                
                let df = DateFormatter()
                df.timeZone = TimeZone.current
                df.dateFormat = "yyyy-MM-dd"
                dateString = df.string(from: date)
                //print(dateString)
            }
        }
        return dateString
    }

// visar hur många sektion finns i TableView
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

// Gå igenom alla activies i activitiesArray och filla listView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        //print("Activitiest.lenght : \(self.activitiesArray.count)")
        return self.activitiesArray.count
    }
// Inte nödvändig men den gör att när man trycker på en cell i listView så tar den bort selection efter när man lämnar cellen
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.activitiesTableView.deselectRow(at: indexPath, animated: true)
    }

// Här blir mer jobb för appen att gämföra värden och sedan köra flera metoder för att konvertera värden samt konvertera html taggar i texten till bold osv.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "activitiesCell"
        guard let cell = self.activitiesTableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ActivitiesTableCell else {
            fatalError("The dequeued cell is not an instance of ")
        }
        let activity = self.activitiesArray[indexPath.row]
        //print(self.usersArray)
        for item in self.usersArray {
            if item.userId == activity.userId {
                //print(item)
                if let imageUrl = URL(string: "\(item.avatarUrl)") {
// global trod används för att appen körs något i backgrunden
                    DispatchQueue.global().async {
                        let data = try? Data(contentsOf: imageUrl)
                        if let data = data {
                            let image = UIImage(data: data)
// när global är klar då vill jag visa data på skärmen, och därför använder jag main trod här nedan
                            OperationQueue.main.addOperation {
                            cell.avatorImageView.image = image
                            if let name = item.displayName {
                            cell.username.text = "\(name)"
                            if let amount = activity.amount, let time = activity.timestamp, let message = activity.message {
                                cell.message.attributedText = self.convertHTML( message: message)
                                cell.amount.text = self.formatCurrency(amount: amount)
                                cell.time.text = "Date: \(String(describing: time))"
                                cell.fromDate.text = "This scroll showing data until: \(self.toDate)"
                                }}
                            }
                        }
                    }
                }
            }
        }
        return cell
    }

// Formatering av valuta
    func formatCurrency(amount: Double) -> String {
        let numberFormatter = NumberFormatter()
        var nsNumber = String()
        numberFormatter.usesGroupingSeparator = true
//        numberFormatter.locale = Locale.current
        numberFormatter.locale = Locale(identifier: "en_US")
        numberFormatter.numberStyle = .currency
        if let formatedTipAmount = numberFormatter.string(from: amount as NSNumber) {
            nsNumber = formatedTipAmount
        }
        return nsNumber
    }
// Formatera message texten att konvertera <strong> till bold t.ex
    func convertHTML(message: String) -> NSAttributedString {
        let data = Data(message.utf8)
        var attributedMsg = NSAttributedString()
        if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            attributedMsg = attributedString
        }
        return attributedMsg
    }
    
// Appen kör denna metod i viewDidLoad för att hämta första veckans activities sedan anråpas den varje gång man scrollar upp åt i metoden scrollViewDidEndDragging
    func downloadJSON(fromDate: String, toDate: String) {
        let jsonURL = "http://qapital-ios-testtask.herokuapp.com/activities?from=%3C"+fromDate+"T00:00:00+00:00%3E&to=%3C"+toDate+"T00:00:00+00:00%3E"
        if self.usersArray.count == 0 {
            self.downUserInfo()
        }
        guard let url = URL(string: jsonURL) else { return }
        if self.alertView == false {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                if let error = error { print("Kan inte hämta data from url'n", error)
                }
            guard let data = data else {
                print("No data found")
                return }
            do {
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode(wholeJSON.self, from: data)
                print("JsonData.Activities length = \(jsonData.activities.count)")
                    guard jsonData.activities.count != 0 else {
                        self.detectTwoWeeks += 2
                        self.downloadJSON(fromDate: self.fromDate, toDate: self.toDate)
                        self.toDate = self.fromDate
                        self.fromDate = self.formateDate(yearString: self.yearfromDate, weekString: self.currentMonthOftheYear - self.detectTwoWeeks)
                        self.count += 1
                        print("Count value is: \(self.count)")
                        if jsonData.activities.count == 0 && self.count > 20 {
                            self.alertView = true
                            self.showAlert()
                            return
                        }
                        return
                    }
                DispatchQueue.global(qos: .background).async {
                    for item in jsonData.activities {
                        self.activitiesArray.append(item)
                        //print(self.activitiesArray)
                    }
                    //OperationQueue.main.addOperation {
                    DispatchQueue.main.async {
                        self.activitiesTableView.reloadData()
                    }
                }
                print("ActivitiesArray lenght: \(self.activitiesArray.count)")
            } catch let jsonError {
                print("error while fetching data", jsonError)
                }

            }
            }.resume()
            
        } else {
            self.showAlert()
            
        }
        
    }
    
// Visar Alert vju ifall det inte finns några data att hämta
    func showAlert() {
        let alert = UIAlertController(title: "Maybe no more data?", message: "You have fetched  \(self.activitiesArray.count)  activities and we can't fetch more activities probably because the api doesn't have more data to serve.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    
    
// Hämta alla användaren en gång
    func downUserInfo() {
        DispatchQueue.main.async {
        guard self.activitiesArray.count != 0 else {
            return
        }
        }
            
            let usersURL = "http://qapital-ios-testtask.herokuapp.com/users"
            guard let userUrl = URL(string: usersURL) else { return }
            URLSession.shared.dataTask(with: userUrl) { (userUrlData, userurlResponse, userUrlError) in
                DispatchQueue.main.async {
                    if let error = userUrlError {
                        print("Kan inte hämta data from url'n", error)
                    }
                    //                    print("UserUrlData: \(userUrlData)")
                    let decoder = JSONDecoder()
                    guard let userData = userUrlData else { return }
                    do {
                        let userJsonData = try decoder.decode([Users].self, from: userData)
//                        print("UserUrlData: \(userJsonData)")
                        for item in userJsonData {
                            self.usersArray.append(item)
                        }
                    } catch let userUrlError {
                        print("error while fetching user data", userUrlError)
                    }
                    //print(self.usersArray)
                }
                }.resume()
    }
    
}
