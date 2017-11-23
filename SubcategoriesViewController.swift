//
//  SubcategoriesViewController.swift
//  FiveBucks
//
//  Created by Roma Osiychuk on 09.10.17.
//  Copyright © 2017 Roma Osiychuk. All rights reserved.
//

import Foundation
import UIKit

struct Subcategories {
    var id: String = ""
    var name: String = ""
}

class SubcategoriesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var subcategoriesTableView: UITableView!
    @IBOutlet weak var SubcategoryNameLabel: UILabel!
    
    @IBOutlet weak var mySearchTextField: SearchTextField!
    @IBOutlet weak var searchCancelButton: UIButton!
    
    var subcategories = [Subcategories]()
    var parentCategory = Categories()
    
    var autocompleetResults = [SearchTextFieldItem]()
    var isSearch = true
    // MARK: - Main
    override func viewDidLoad() {
        SubcategoryNameLabel.text = parentCategory.name
        downloadSubcategories()
        initSearchTextView()
    }
    override func viewWillAppear(_ animated: Bool) {
        isSearch = true
    }
    // MARK: - UITableViewDataSource protocol
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subcategories.count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SubcategoriesTableViewCell
        
        let subcategory = subcategories[indexPath.row]
        cell.subcategoryHeaderLabel.text = subcategory.name
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        isSearch = false
         self.performSegue(withIdentifier: "ShowSearchVC", sender: subcategories[indexPath.row])
    }
    // MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSearchVC" {
            let newVC = segue.destination as! SearchViewController
            if !isSearch {
                newVC.category = sender as! Subcategories
            } else {
                newVC.searchText = sender as! String
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func searchButtonTapped(_ sender: Any) {
        mySearchTextField.isHidden = false
        
        mySearchTextField.becomeFirstResponder()
        mySearchTextField.filterItems(autocompleetResults)
        searchCancelButton.isHidden = false
    }
    
    @IBAction func searchCancelButtonTapped(_ sender: Any) {
        mySearchTextField.filterItems([SearchTextFieldItem]())
        mySearchTextField.text = ""
        mySearchTextField.resignFirstResponder()
        mySearchTextField.isHidden = true
        searchCancelButton.isHidden = true
    }
    
    // MARK: - Additional functions
    func downloadSubcategories() -> Void {
        ReciveData.getData(dataType: ApiModel.get_subcategories(parentCategory.id), completion: { data in
            if Int(data["res"]["code"].stringValue)! > 0 {
                let categories = data["categories"].arrayValue
                let count = categories.count
                for i in stride(from: 0, to: count, by: 1)  {
                    self.subcategories.append(Subcategories(id: categories[i]["id"].stringValue,
                                                      name: categories[i]["name"].stringValue))
                }
                self.subcategoriesTableView.reloadData()
            } else if Int(data["res"]["code"].stringValue)! < 0 {
                print (data["res"]["msg"].stringValue)
                GlobalFunctions.alertWithTitle(title: "Помилка", message: data["res"]["msg"].stringValue, ViewController: self)
            }
            
        })
    }
    func initSearchTextView() -> Void {
        mySearchTextField.setLeftPaddingPoints(20.0)
        mySearchTextField.theme.placeholderColor = UIColor.white
        mySearchTextField.userStoppedTypingHandler = {
            if let criteria = self.mySearchTextField.text {
                if criteria.characters.count > 1 {
                    self.autocompleetResults.removeAll()
                    GlobalFunctions.downloadAutocompleeteResults(search: criteria, completion: { (result) in
                        self.autocompleetResults = result
                        self.mySearchTextField.filterItems(self.autocompleetResults)
                    })
                }
            }
        }
        
        // Handle item selection - Default behaviour: item title set to the text field
        mySearchTextField.itemSelectionHandler = { filteredResults, itemPosition in
            if itemPosition == -1 {
                let title = self.mySearchTextField.text!
                self.searchCancelButtonTapped(self.searchCancelButton)
                self.performSegue(withIdentifier: "ShowSearchVC", sender: title)
                return
            }
            // Just in case you need the item position
            let item = filteredResults[itemPosition]
            print("Item at position \(itemPosition): \(item.title)")
            
            // Do whatever you want with the picked item
            
            self.mySearchTextField.text = item.title
            self.searchCancelButtonTapped(self.searchCancelButton)
            self.performSegue(withIdentifier: "ShowSearchVC", sender: item.title)
        }
    }
}
