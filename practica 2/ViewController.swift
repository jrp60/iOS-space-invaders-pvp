//
//  ViewController.swift
//  practica 2
//
//  Created by Javier on 13/5/22.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var playerNameInput: UITextField!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playBluetooth: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        playButton.isEnabled = false
        playBluetooth.isEnabled = false
        self.playerNameInput.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    @IBAction func startPlayingWifi(_ sender: UIButton) {
        
    }
    
    @IBAction func startPlayingBluetooth(_ sender: Any) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (!playerNameInput.text!.isEmpty){
            self.playButton.isEnabled = true
            self.playBluetooth.isEnabled = true
        }else{
            self.playButton.isEnabled = false
            self.playBluetooth.isEnabled = false
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let gameViewController = segue.destination as? GameViewController{
            if let text = playerNameInput.text {
                gameViewController.playerName = text
            }
        }
        if let gameViewController = segue.destination as? BluetoothViewController{
            if let text = playerNameInput.text {
                gameViewController.playerName = text
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
}

