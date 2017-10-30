import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var verifiedLabel: UILabel!
    
    let mainAppScheme = "app1"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        identifierLabel.text = "identifier = \(appDelegate.identifier)"

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

