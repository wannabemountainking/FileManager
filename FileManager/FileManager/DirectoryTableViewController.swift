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
        setupMenu()
    }
    
    // TODO: 1. 메뉴 설정 메서드 작성 2. 메뉴 - textfield 있는 alert 창 작성 3. directory 추가 버튼 시 작동하는 메서드 작성 4. 텍스트파일 추가 5. 이미지 파일 추가
    func addImageFile() {
        let number = Int.random(in: 1...30)
        guard let imageUrl = URL(string: "https://kxcodingblob.blob.core.windows.net/mastering-ios/\(number).jpg") else {return}
        guard let targetUrl = currentDirectoryUrl?.appendingPathComponent("\(number)").appendingPathExtension("jpg") else {return}
        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: imageUrl)
                try data.write(to: targetUrl, options: .atomic)
            } catch {
                print(error.localizedDescription)
            }
            DispatchQueue.main.async {
                self.refreshContents()
            }
        }

    }
    
    func addTextFile() {
        let content = Date.now.description
        guard let targetUrl = currentDirectoryUrl?.appendingPathComponent("current-time").appendingPathExtension("txt") else {return}
        do {
            try content.write(to: targetUrl, atomically: true, encoding: .utf8)
        } catch {
            print(error.localizedDescription)
        }
        refreshContents()
    }
    
    func addDirectory(name: String) {
        guard let currentUrl = currentDirectoryUrl?.appendingPathComponent(name, isDirectory: true) else {return}
        do {
            try FileManager.default.createDirectory(at: currentUrl, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error.localizedDescription)
        }
        refreshContents()
    }
    
    func showNameInputAlert() {
        let nameAlert = UIAlertController(title: "디렉토리 입력", message: nil, preferredStyle: .alert)
        nameAlert.addTextField { textField in
            textField.placeholder = "디렉토리 이름을 입력하세요"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.clearButtonMode = .whileEditing
            textField.keyboardAppearance = .dark
        }

        let createAction = UIAlertAction(title: "추가", style: .default) { action in
            guard let name = nameAlert.textFields?.first?.text else {return}
            self.addDirectory(name: name)
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        nameAlert.addAction(createAction)
        nameAlert.addAction(cancelAction)
        
        present(nameAlert, animated: true)
    }
    
    func setupMenu() {
        menuButton.menu = UIMenu(children: [
            UIAction(title: "새 디렉토리", image: UIImage(systemName: "folder"), handler: { action in
                self.showNameInputAlert()
            }),
            UIAction(title: "새 텍스트 파일", image: UIImage(systemName: "doc.text"), handler: { action in
                self.addTextFile()
            }),
            UIAction(title: "새 이미지 파일", image: UIImage(systemName: "photo"), handler: { action in
                self.addImageFile()
            }),
        ])
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
        
        if contents.isEmpty {
            let label = UILabel(frame: .zero)
            label.text = "빈 디렉토리"
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let cell = sender as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell),
              let vc = segue.destination as? DirectoryTableViewController else {return}
        vc.currentDirectoryUrl = contents[indexPath.item].url
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "directorySegue" {
            if let cell = sender as? UITableViewCell,
               let indexPath = tableView.indexPath(for: cell) {
                
                do {
                    let url = contents[indexPath.item].url
                    let reachable = try url.checkResourceIsReachable()
                    if !reachable {
                        return false
                    }
                } catch {
                    print(error.localizedDescription)
                }
                
                return contents[indexPath.item].type == .directory
            }
        }
        return true
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
            cell.detailTextLabel?.text = target.sizeString
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.

            
        }
    }
    */

}
