import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var backButton: UIButton!

    let mainAppScheme = "app1"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func backToMainApp(_ sender: Any) {
        guard let mainAppURL = URL(string: "\(mainAppScheme)://barfoo") else {
            return
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(mainAppURL, options: [:], completionHandler: nil)
        }
        else {
            UIApplication.shared.openURL(mainAppURL)
        }
    }
}

