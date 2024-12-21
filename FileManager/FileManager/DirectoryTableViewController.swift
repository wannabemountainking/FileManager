//
//  DirectoryTableViewController.swift
//  FileManager
//
//  Created by YoonieMac on 12/20/24.
//

import UIKit

class DirectoryTableViewController: UITableViewController {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var currentDirectoryUrl: URL?
    
    var contents = [Content]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if currentDirectoryUrl == nil {
            currentDirectoryUrl = URL(fileURLWithPath: NSHomeDirectory())
        }
        
        refreshContents()
        updateNavigationTitle()
    }
    
    func updateNavigationTitle() {
        guard let url = currentDirectoryUrl else {
            navigationItem.title = "???"
            return
        }
        
        do {
            
            let nameValues = try url.resourceValues(forKeys: [.localizedNameKey])
            navigationItem.title = nameValues.localizedName
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func refreshContents() {
        contents.removeAll()
        
        defer {
            tableView.reloadData()
        }
        
        guard let url = currentDirectoryUrl else {
            fatalError("empty url")
        }
        
        do {
            
            let properties: [URLResourceKey] = [.localizedNameKey, .fileSizeKey, .isDirectoryKey, .isExcludedFromBackupKey]
            
            let currentContentsUrls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: properties, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            
            for url in currentContentsUrls {
                let content = Content(url: url)
                contents.append(content)
            }
            
            contents.sort { (lhs, rhs) -> Bool in
                if lhs.type == rhs.type {
                    return lhs.name.lowercased() < rhs.name.lowercased()
                }
                return lhs.type.rawValue < rhs.type.rawValue
            }
            
        } catch {
            print(error.localizedDescription)
        }
    }
    

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return contents.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let target = contents[indexPath.item]
        
        cell.imageView?.image = target.image
        
        switch target.type {
        case .directory:
            cell.textLabel?.text = "[\(target.name)]"
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .disclosureIndicator
        case .file:
            cell.textLabel?.text = "\(target.name)"
            cell.detailTextLabel?.text = "\(target.size)"
            cell.accessoryType = .none
        }
        
        switch target.isExcludedFromBackup {
        case true: cell.textLabel?.textColor = .label
        case false: cell.textLabel?.textColor = .secondaryLabel
        }
        
        cell.detailTextLabel?.textColor = cell.textLabel?.textColor
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
