import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var startButton: UIButton!
    
    let helperAppScheme = "app2"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startButton.isEnabled = isSchemeAvailable(helperAppScheme)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startHelperApp(_ sender: Any) {
        guard let helperAppURL = URL(string: "\(helperAppScheme)://foobar") else {
            return
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(helperAppURL, options: [:], completionHandler: nil)
        }
        else {
            UIApplication.shared.openURL(helperAppURL)
        }
    }
    
}

