//
//  Content.swift
//  FileManager
//
//  Created by YoonieMac on 12/20/24.
//

import UIKit

struct Content {
    let url: URL
    
    var name: String {
        return ""
    }
    
    var size: Int {
        return 0
    }
    
    var type: Type {
        return .file
    }
    
    var isExcludedFromBackUp: Bool {  // 백업 되지 않는지 여부
        return false
    }
    
    var image: UIImage? {
        switch type {
        case .directory: return UIImage(systemName: "folder")
        case .file:
            let ext = url.pathExtension
            switch ext {
            case "txt": return UIImage(systemName: "doc.text")
            case "jpg", "png": return UIImage(systemName: "doc.richtext")
            default: return UIImage(systemName: "doc")
            }
        }
    }
}
