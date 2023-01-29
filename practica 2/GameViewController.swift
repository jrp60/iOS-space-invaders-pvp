//
//  GameViewController.swift
//  practica 2
//
//  Created by Javier on 17/5/22.
//

import UIKit
import CoreMotion

class GameViewController: UIViewController {
    
    var playerName: String?
    private var enemyName: String?
    
    private let sendFireService = SendService()
    private let motionManager = CMMotionManager()
    
    private let screenSize: CGRect = UIScreen.main.bounds
    private var lifes = 6
    private var playerPosition = 0.0
    private var playerWidth = 130
    private var playerHeight = 45
    private let fireSpeed = 0.7
    private let fireSpeedSuper = 1.0
    private let reloadFire = 0.5
    private var fireReady = true
    private var superFireCharges = 6
    private var superImage: UIImageView?
    
    @IBOutlet weak var connectionsLabel: UILabel!
    @IBOutlet weak var textRecievedLabel: UILabel!
    @IBOutlet weak var player: UIImageView!
    @IBOutlet weak var reloadBar: UIProgressView!
    @IBOutlet weak var superLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendFireService.delegate =  self
        sendFireService.name = playerName!
        initUI()
    }
    
    func initUI(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.fireProyectile))
        self.view.addGestureRecognizer(tap)
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(superFire))
        self.view.addGestureRecognizer(longPressRecognizer)

        let minWidth = self.screenSize.minX
        let maxWidth = self.screenSize.maxX - (player.bounds.width) + 2
        playerPosition = screenSize.width/2
        player.image = UIImage(color: .systemPurple, size: CGSize(width: playerWidth, height: playerHeight))
        reloadBar.trackTintColor = .lightGray
        reloadBar.tintColor = .magenta
        reloadBar.isHidden = true
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (motion, error) in
                let translation = (motion?.gravity.y ?? 0) * 15
                if(self.playerPosition + translation > minWidth
                   && self.playerPosition + translation < maxWidth){
                    self.playerPosition += translation
                }
                self.player.transform = CGAffineTransform(translationX: self.playerPosition, y: 0)
            }
        }
    }
    
    @objc func fireProyectile() {
        if(fireReady){
            let percent = String(Int(player.frame.midX / screenSize.width * 100))
            createFireAnimation(orientity: true)
            sendFireService.send(text: percent)
            startFireCadence()
        }
    }
    
    @objc func superFire(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            if(superFireCharges > 0){
                superFireCharges -= 1
                let txt =  String(superFireCharges)
                self.superLabel.text = "Laser: \(txt)"
                var position = String(Int(player.frame.midX / screenSize.width * 100))
                createSuperFireAnimation(orientity: true)
                position = "SUPER\(position)"
                sendFireService.send(text: position)
                
            }
        } else {
        }
    }
    
    func startFireCadence(){
        fireReady = false
        reloadBar.isHidden = false
        
        var runCount: Float = 0.0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            runCount += 0.02
            self.reloadBar.progress = runCount / Float(self.reloadFire)
            if runCount >= Float(self.reloadFire) {
                timer.invalidate()
                self.reloadBar.isHidden = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + reloadFire) {
            self.fireReady = true
        }
    }
    
    func createFireAnimation(orientity: Bool, position: Double? = nil) {
        if(orientity){
            let fireImage = UIImage(color: .magenta, size: CGSize(width:6, height:20))
            let imageView = UIImageView(image: fireImage)
            imageView.frame = CGRect(x: player.frame.midX, y: player.frame.minY-10, width: 6, height: 20)
            self.view.addSubview(imageView)
            UIView.animate(withDuration: fireSpeed) {
                imageView.transform = CGAffineTransform(translationX: 0, y: -self.screenSize.maxY)
            }
        }
        else{
            let fireImage = UIImage(color: .magenta, size: CGSize(width:6, height:20))
            let imageView = UIImageView(image: fireImage)
            imageView.frame = CGRect(x: position!, y: screenSize.minY-10, width: 6, height: 20)
            self.view.addSubview(imageView)
            
            UIView.animate(withDuration: fireSpeed, delay: 0.0, options: [], animations: {
                imageView.transform = CGAffineTransform(translationX: 0, y: self.screenSize.maxY-1)
            }, completion: { (finished: Bool) in
                imageView.isHidden = true
            })
        }
    }
    func createSuperFireAnimation(orientity: Bool, position: Double? = nil){
        if(orientity){
            let fireImage = UIImage(color: .init(displayP3Red: 0.2, green: 0.9, blue: 0.8, alpha: 1), size: CGSize(width: 1, height: 2))
            let imageView = UIImageView(image: fireImage)
            imageView.frame = CGRect(x: player.frame.midX, y: player.frame.maxY, width: 1, height: 2)
            self.view.addSubview(imageView)
            
            UIView.animate(withDuration: fireSpeed, delay: 0.0, options: [], animations: {
                imageView.transform = CGAffineTransform(scaleX: 1, y: self.screenSize.maxY)
            }, completion: {_ in
                UIView.animate(withDuration: self.fireSpeed, delay: 0.0, options: [], animations: {
                    imageView.transform = CGAffineTransform(translationX: 0, y: -self.screenSize.maxY)
                }, completion: {_ in
                })
            })
        }
        else{
            let fireImage = UIImage(color: .init(displayP3Red: 0.2, green: 0.9, blue: 0.8, alpha: 1), size: CGSize(width: 1, height: 2))
            superImage = UIImageView(image: fireImage)
            superImage!.frame = CGRect(x: position!, y: screenSize.minY, width: 1, height: 2)
            self.view.addSubview(superImage!)
            
            var hit = false
            
            UIView.animate(withDuration: fireSpeed, delay: 0.0, options: [], animations: { [self] in
                superImage!.transform = CGAffineTransform(scaleX: 1, y: self.screenSize.height )
                
                var runCount: Double = 0.0
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [self] timer in
                        runCount += 0.01
                        if !hit {
                            if runCount >= (self.fireSpeed) {
                                timer.invalidate()
                            }
                            if(position! >= self.playerPosition && position! <= self.playerPosition + self.player.frame.width) {
                                hit = true
                                timer.invalidate()
                                self.reduceLifes(qty: 1)
                            }
                        }
                    }
                }
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: self.fireSpeed, delay: 0.0, options: [], animations: { [self] in
                    superImage!.transform = CGAffineTransform(translationX: 0, y: self.screenSize.maxY)
                }, completion: {_ in
                })
            })
        }
    }
    
    func reduceLifes(qty lifes: Int){
        self.lifes -= lifes
        changePlayerColor()
        if(self.lifes == 0){
            gameOver()
        }
    }
    
    func gameOver(){
        let alert = UIAlertController(title: "Alert", message: "You lose", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Play again", style: .default, handler: { (action: UIAlertAction!) in
            self.lifes = 6
            self.superFireCharges = 6
            self.superLabel.text = "Laser: \(self.superFireCharges)"
            self.changePlayerColor()
        }))
        alert.addAction(UIAlertAction(title: "Close game", style: .cancel, handler: { (action: UIAlertAction!) in
            exit(-1)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func changePlayerColor(){
        switch lifes {
        case 0:
            player.image = UIImage(color: .black, size: CGSize(width: playerWidth, height: playerHeight))
            break
        case 1:
            player.image = UIImage(color: .systemRed, size: CGSize(width: playerWidth, height: playerHeight))
            break
        case 2:
            player.image = UIImage(color: .systemOrange, size: CGSize(width: playerWidth, height: playerHeight))
            break
        case 3:
            player.image = UIImage(color: .systemYellow, size: CGSize(width: playerWidth, height: playerHeight))
            break
        case 4:
            player.image = UIImage(color: .systemGreen, size: CGSize(width: playerWidth, height: playerHeight))
            break
        case 5:
            player.image = UIImage(color: .systemBlue, size: CGSize(width: playerWidth, height: playerHeight))
            break
        case 6:
            player.image = UIImage(color: .systemPurple, size: CGSize(width: playerWidth, height: playerHeight))
            break
        default:
            player.image = UIImage(color: .black, size: CGSize(width: playerWidth, height: playerHeight))
            break
        }
    }

}

extension GameViewController: SendServiceDelegate {
    
    func connectedDevicesChanged(manager: SendService, connectedDevices: String) {
        OperationQueue.main.addOperation {
            self.connectionsLabel.text = "VS: \(connectedDevices)"
        }
    }
    func sendFireService(didReceive firePositionPercentage: String) {
        let first = String(firePositionPercentage.prefix(5))
        if first == "SUPER" {
            let txtPosition = firePositionPercentage.dropFirst(5)
            let fireDouble = Double(txtPosition) ?? -100
            let fireP = screenSize.width - (screenSize.width * fireDouble / 100)
            OperationQueue.main.addOperation {
                self.createSuperFireAnimation(orientity: false, position: fireP)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
               if(fireP >= self.playerPosition &&
                   fireP <= self.playerPosition + self.player.frame.width){
                    self.reduceLifes(qty: 1)
                }
            }
        }else {
            let fireDouble = Double(firePositionPercentage) ?? -100
            let fireP = screenSize.width - (screenSize.width * fireDouble / 100)
            OperationQueue.main.addOperation {
                self.createFireAnimation(orientity: false, position: fireP)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
               if(fireP >= self.playerPosition &&
                   fireP <= self.playerPosition + self.player.frame.width){
                    self.reduceLifes(qty: 1)
                }
            }
        }
    }
}

public extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
