//
//  BluetoothViewController.swift
//  practica 2
//
//  Created by Javier on 25/5/22.
//

import UIKit
import CoreMotion
import CoreBluetooth

class BluetoothViewController: UIViewController {
    
    var playerName: String?
    private var lifes = 6
    private let screenSize: CGRect = UIScreen.main.bounds
    private var playerPosition = 0.0
    private var playerWidth = 130
    private var playerHeight = 45
    private let fireSpeed = 0.7
    private let reloadFire = 0.5
    private var superFireCharges = 6
    private var fireReady = true
    
    private let motionManager = CMMotionManager()
    private var centralManager: CBCentralManager?
    private let FIRE_CHARACTERISTIC_UUID = CBUUID(string: "252E8D8D-F7C3-48F2-805D-AAD3E2CA0B09")
    private let NAME_CHARACTERISTIC_UUID = CBUUID(string: "725E3CCE-F54F-4751-AD9E-378A89ED8CE7")
    private let FIRE_SERVICE_UUID = CBUUID(string: "467CA50F-3755-4703-8C34-F2702F0F4217")
    private var peripheral: CBPeripheral?
    private var peripheralManager = CBPeripheralManager()
    private let namePeripherical = "fire_peripherical"
    private var myService: CBMutableService!
    private var myCharacteristic: CBMutableCharacteristic?
    private var centralsSubscribed = [CBCentral]()

    @IBOutlet weak var player: UIImageView!
    @IBOutlet weak var connectedLabel: UILabel!
    @IBOutlet weak var reloadBar: UIProgressView!
    @IBOutlet weak var superLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        //peripheralManager.name = "aaa"
        initUI()
    }
    
    func initUI(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.fireProyectile))
        view.addGestureRecognizer(tap)
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(superFire))
        self.view.addGestureRecognizer(longPressRecognizer)
        
        let minWidth = self.screenSize.minX
        let maxWidth = self.screenSize.maxX - (player.bounds.width) + 2
        playerPosition = screenSize.width/2
        
        reloadBar.trackTintColor = .lightGray
        reloadBar.tintColor = .magenta
        reloadBar.isHidden = true
        
        player.image = UIImage(color: .systemPurple, size: CGSize(width: playerWidth, height: playerHeight))
        
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
            let data: Data = percent.data(using: .utf8)!
            
            peripheral?.services?.forEach({(service) in
                service.characteristics?.forEach({(characteristic) in
                    if characteristic.uuid == FIRE_CHARACTERISTIC_UUID {
                        peripheral?.writeValue(data, for: characteristic, type: .withResponse)
                    }
                })
            })
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
                
                let data: Data = position.data(using: .utf8)!
                
                peripheral?.services?.forEach({(service) in
                    service.characteristics?.forEach({(characteristic) in
                        if characteristic.uuid == FIRE_CHARACTERISTIC_UUID {
                            peripheral?.writeValue(data, for: characteristic, type: .withResponse)
                        }
                    })
                })
                //sendFireService.send(text: position)
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
            let fireImage = UIImage(color: .systemPink, size: CGSize(width:6, height:20))
            let imageView = UIImageView(image: fireImage)
            imageView.frame = CGRect(x: player.frame.midX, y: player.frame.minY-10, width: 6, height: 20)
            self.view.addSubview(imageView)
            UIView.animate(withDuration: fireSpeed) {
                imageView.transform = CGAffineTransform(translationX: 0, y: -self.screenSize.maxY)
            }
        }
        else{
            let fireImage = UIImage(color: .systemPink, size: CGSize(width:6, height:20))
            let imageView = UIImageView(image: fireImage)
            imageView.frame = CGRect(x: position!, y: screenSize.minY-10, width: 6, height: 20)
            self.view.addSubview(imageView)
            UIView.animate(withDuration: fireSpeed) {
                imageView.transform = CGAffineTransform(translationX: 0, y: self.screenSize.maxY + 10)
            }
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
            let superImage = UIImageView(image: fireImage)
            superImage.frame = CGRect(x: position!, y: screenSize.minY, width: 1, height: 2)
            self.view.addSubview(superImage)
            
            var hit = false
            
            UIView.animate(withDuration: fireSpeed, delay: 0.0, options: [], animations: { [self] in
                superImage.transform = CGAffineTransform(scaleX: 1, y: self.screenSize.height )
                
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
                    superImage.transform = CGAffineTransform(translationX: 0, y: self.screenSize.maxY)
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

extension BluetoothViewController: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
                    
                case .unknown:
                    print("Bluetooth status is UNKNOWN")
                    DispatchQueue.main.async {self.connectedLabel.text="UNKNOWN" }
                    
                case .resetting:
                    print("Bluetooth status is RESETTING")
                    DispatchQueue.main.async {self.connectedLabel.text="RESETTING" }
                    
                case .unsupported:
                    print("Bluetooth status is UNSUPPORTED")
                    DispatchQueue.main.async {self.connectedLabel.text="UNSUPPORTED" }
                    
                case .unauthorized:
                    print("Bluetooth status is UNAUTHORIZED")
                    DispatchQueue.main.async {self.connectedLabel.text="UNAUTHORIZED" }
                    
                case .poweredOff:
                    print("Bluetooth status is POWERED OFF")
                    DispatchQueue.main.async {self.connectedLabel.text="POWERED OFF" }
                    
                case .poweredOn:
                    DispatchQueue.main.async {self.connectedLabel.text = "Buscando oponente..." }
                    print("Bluetooth status is POWERED ON")
                    print ("Central: empezamos a escanear periféricos")
                    self.centralManager?.scanForPeripherals(withServices: [self.FIRE_SERVICE_UUID])
            }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let advertisementName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            
            if advertisementName == namePeripherical{
                self.peripheral = peripheral
                self.peripheral?.delegate = self
                centralManager?.stopScan()
                centralManager?.connect(peripheral)
                print ("Central: paramos de escanear periféricos y conectamos con: " + advertisementName)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.peripheral?.discoverServices([FIRE_SERVICE_UUID])
        print ("Central: hemos conectado con el periférico:" + peripheral.name!)
    }
}

extension BluetoothViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            print ("Central: hemos encontrado un servicio con UUID: " + service.uuid.uuidString)
            if service.uuid == FIRE_SERVICE_UUID {
                print ("Central: hemos encontrado el servicio y procedemos a descubrir características")
                peripheral.discoverCharacteristics([FIRE_CHARACTERISTIC_UUID, NAME_CHARACTERISTIC_UUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Central: descubriendo caracteristicas")
        for characteristic in service.characteristics! {
            print("Central: Hemos encontrado caracterísitca con UUID: " + characteristic.uuid.uuidString + " del periférico:" + (characteristic.service?.peripheral?.name!)!)
            if characteristic.uuid == FIRE_CHARACTERISTIC_UUID {
                if characteristic.properties.contains(.read){
                    print("Central: Hemos encontrado caracterísitca y solicitamos lectura de su valor")
                    peripheral.readValue(for: characteristic)
                }
            }
            else if characteristic.uuid == NAME_CHARACTERISTIC_UUID {
                if characteristic.properties.contains(.read){
                    print("Central: hemos encontado caracteristica NAME y solicitamos lectura")
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Central: did update value for")
        if characteristic.uuid == FIRE_CHARACTERISTIC_UUID {
            if let value = characteristic.value {
                print ("Central: hemos conseguido leer el valor: " + String(data: value, encoding: .utf8)!)
            }
        }
        else if characteristic.uuid == NAME_CHARACTERISTIC_UUID {
            if let value = characteristic.value {
                let name = String(data: value, encoding: .utf8)
                print("Central: hemos conseguido leer el valor NAME: " + name!)
                DispatchQueue.main.async { self.connectedLabel.text = "VS: \(name!)" }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Central: did write value for")
    }

}

extension BluetoothViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            if peripheralManager.isAdvertising {
                peripheralManager.stopAdvertising()
            }
            
            let myCharacteristic = CBMutableCharacteristic(type: FIRE_CHARACTERISTIC_UUID, properties: [.read, .write], value: nil, permissions: [.readable, .writeable])
            
            let valueName = self.playerName?.data(using: .utf8)
            let nameCharacteristic = CBMutableCharacteristic(type: NAME_CHARACTERISTIC_UUID, properties: [.read], value: valueName, permissions: [.readable])
            
            myService = CBMutableService(type: FIRE_SERVICE_UUID, primary: true)
            myService.characteristics = [myCharacteristic, nameCharacteristic]
            
            peripheralManager.add(myService)
            print("Periférico: Inicializamos arbol de servicios y características")
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[FIRE_SERVICE_UUID], CBAdvertisementDataLocalNameKey: namePeripherical])
            print("Periférico: Empezamos a publicitarnos con el nombre de: " + namePeripherical)
            self.myCharacteristic = myCharacteristic
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let myError = error {
            print( "Error al publicar un servicio:" + myError.localizedDescription)
        }
        print("Periferico: servicio añadido")
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let myError = error {
            print( "Error al publicitar un servicio:" + myError.localizedDescription)
        }else{
            print("Periferico: advertising done.")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Periferico: did receive read")
        if request.characteristic.uuid == FIRE_CHARACTERISTIC_UUID {
            peripheralManager.respond(to: request, withResult: .success)
        }
        else{
            peripheralManager.respond(to: request, withResult: .attributeNotFound)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        var hasFireCharacteristic = false
        for request in requests {
            if request.characteristic.uuid == FIRE_CHARACTERISTIC_UUID {
                myCharacteristic!.value = request.value;
                hasFireCharacteristic = true
                let txtReceive = String(data: request.value!, encoding: .utf8)!
                let first = txtReceive.prefix(5)
                if first == "SUPER" {
                    let txtPosition = txtReceive.dropFirst(5)
                    let fireDouble = Double(txtPosition) ?? -100
                    print(txtPosition)
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
                }else{
                    let percentDouble = Double(txtReceive)!
                    let positionDouble = screenSize.width - (screenSize.width * percentDouble / 100)
                    createFireAnimation(orientity: false, position: positionDouble)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                       if(positionDouble >= self.playerPosition &&
                          positionDouble <= self.playerPosition + self.player.frame.width){
                            self.reduceLifes(qty: 1)
                        }
                    }
                }
            }
            else if request.characteristic.uuid == NAME_CHARACTERISTIC_UUID {
                print("periferico did receive write name")
            }
        }
        hasFireCharacteristic ?
            peripheralManager.respond(to: requests.first!, withResult: .success) :
        peripheralManager.respond(to: requests.first!, withResult: .attributeNotFound)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("did modify: ", invalidatedServices)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Periferico: suscrito a central: " + central.identifier.uuidString)
        centralsSubscribed.append(central)
        print(centralsSubscribed)
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("Periferico: envio fallido, renviar?")
    }
}
