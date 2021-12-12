//
//  ViewController.swift
//  JawsTalk
//
//  Created by hyosup on 11/23/21.
//

import UIKit
import SnapKit
import Firebase

// Haddle remote config
class ViewController: UIViewController {

    var box = UIImageView()
    var remoteConfig : RemoteConfig!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // remote config setting
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        
        // set default value
        remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")
        
        // fetch
        remoteConfig.fetch { (status, error) -> Void in
          if status == .success {
            print("Config fetched!")
            self.remoteConfig.activate { changed, error in
              // ...
            }
          } else {
            print("Config not fetched")
            print("Error: \(error?.localizedDescription ?? "No error available.")")
          }
          self.displayFirstScene()
        }
        
        self.view.addSubview(box)
        box.snp.makeConstraints{ (make) in make.center.equalTo(self.view)
        }
        box.image = #imageLiteral(resourceName: "loading_icon")

    }

    func displayFirstScene(){
        let color = remoteConfig["splash_background"].stringValue
        let caps = remoteConfig["splash_message_caps"].boolValue
        let message = remoteConfig["splash_message"].stringValue
        
        if(caps){
            let alert = UIAlertController(title: "Notice", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Check", style: UIAlertAction.Style.default, handler: {(action) in exit(0)}))
            
            self.present(alert, animated: true, completion: nil)
        }else{
            let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            
            self.present(loginVC, animated: false, completion: nil)
        }
        
        self.view.backgroundColor = UIColor(hex: color!)
    }

}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 1
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}
