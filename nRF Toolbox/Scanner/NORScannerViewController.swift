//
//  NORScannerViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 28/04/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class NORScannerViewController: UIViewController, CBCentralManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    required init?(coder aDecoder: NSCoder) {
        delegate = nil
        super.init(coder: aDecoder)
    }

    let dfuServiceUUIDString  = "00001530-1212-EFDE-1523-785FEABCD123"
    let ANCSServiceUUIDString = "7905F431-B5CE-4E99-A40F-4B1E122D00D0"

    //MARK: - ViewController Properties
    var bluetoothManager : CBCentralManager?
    var delegate         : NORScannerDelegate?
    var filterUUID       : CBUUID?
    var peripherals      : NSMutableArray?
    var timer            : Timer?
    
    @IBOutlet weak var devicesTable: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBAction func cancelButtonTapped(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func timerFire() {
        if peripherals?.count > 0 {
            emptyView.isHidden = true
            devicesTable.reloadData()
        }
    }
    
    func getRSSIImage(RSSI anRSSIValue: Int32) -> UIImage {
        
        var image: UIImage
        
        if (anRSSIValue < -90) {
            image = UIImage(named: "Signal_0")!
        }else if (anRSSIValue < -70) {
            image = UIImage(named: "Signal_1")!
        }else if (anRSSIValue < -50) {
            image = UIImage(named: "Signal_2")!
        }else{
            image = UIImage(named: "Signal_3")!
        }
        
        return image
    }
    
    func getConnectedPeripherals() -> NSArray {
        var retreivedPeripherals : NSArray

        if filterUUID == nil {
            let dfuServiceUUID       = CBUUID(string: dfuServiceUUIDString)
            let ancsServiceUUID      = CBUUID(string: ANCSServiceUUIDString)
            retreivedPeripherals     = (bluetoothManager?.retrieveConnectedPeripherals(withServices: [dfuServiceUUID, ancsServiceUUID]))! as NSArray
        } else {
            retreivedPeripherals     = (bluetoothManager?.retrieveConnectedPeripherals(withServices: [filterUUID!]))! as NSArray
        }

        return retreivedPeripherals
    }
    
    /*!
     * @brief Starts scanning for peripherals with rscServiceUUID
     * @param enable If YES, this method will enable scanning for bridge devices, if NO it will stop scanning
     * @return true if success, false if Bluetooth Manager is not in CBCentralManagerStatePoweredOn state.
     */
    func scanForPeripherals(_ enable:Bool) -> Bool {
        guard bluetoothManager?.state == .poweredOn else {
            return false
        }
        
        DispatchQueue.main.async {
            if enable == true {
                let options: NSDictionary = NSDictionary(objects: [NSNumber(value: true as Bool)], forKeys: [CBCentralManagerScanOptionAllowDuplicatesKey as NSCopying])
                if self.filterUUID != nil {
                    self.bluetoothManager?.scanForPeripherals(withServices: [self.filterUUID!], options: options as? [String : AnyObject])
                } else {
                    self.bluetoothManager?.scanForPeripherals(withServices: nil, options: options as? [String : AnyObject])
                }
                self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.timerFire), userInfo: nil, repeats: true)
            } else {
                self.timer?.invalidate()
                self.timer = nil
                self.bluetoothManager?.stopScan()
            }
        }
        
        return true
    }
    
    //MARK: - ViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        peripherals = NSMutableArray(capacity: 8)
        devicesTable.delegate = self
        devicesTable.dataSource = self
        
        let activityIndicatorView              = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activityIndicatorView.hidesWhenStopped = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicatorView)
        
        activityIndicatorView.startAnimating()
        
        let centralQueue = DispatchQueue(label: "no.nordicsemi.nRFToolBox", attributes: [])
        bluetoothManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.default, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let success = self.scanForPeripherals(false)
        if !success {
            print("Bluetooth is powered off!")
        }

        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
        super.viewWillDisappear(animated)
    }

    //MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard peripherals != nil else {
            return 0
        }

        return peripherals!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        //Update cell content
        let scannedPeripheral = peripherals?.object(at: indexPath.row) as! NORScannedPeripheral
        aCell?.textLabel?.text = scannedPeripheral.name()
        if scannedPeripheral.isConnected == true {
            aCell?.imageView?.image = UIImage(named: "Connected")
        }else{
            let RSSIImage = self.getRSSIImage(RSSI: scannedPeripheral.RSSI)
            aCell?.imageView?.image = RSSIImage
        }
        
        return aCell!
    }

    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        bluetoothManager?.stopScan()
        self.dismiss(animated: true, completion: nil)
        // Call delegate method
        let peripheral = (peripherals?.object(at: indexPath.row) as? NORScannedPeripheral)?.peripheral
        self.delegate?.centralManagerDidSelectPeripheral(withManager: bluetoothManager!, andPeripheral: peripheral!)

    }
    
    //MARK: - CBCentralManagerDelgate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            print("Bluetooth is porewed off")
            return
        }

        peripherals = NSMutableArray(array: self.getConnectedPeripherals())
        let success = self.scanForPeripherals(true)
        if !success {
            print("Bluetooth is powered off!")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Scanner uses other queue to send events. We must edit UI in the main queue        
        DispatchQueue.main.async(execute: {
            var sensor = NORScannedPeripheral(withPeripheral: peripheral, andRSSI: RSSI.int32Value, andIsConnected: false)
            if ((self.peripherals?.contains(sensor)) == false) {
                self.peripherals?.add(sensor)
            }else{
                sensor = (self.peripherals?.object(at: (self.peripherals?.index(of: sensor))!))! as! NORScannedPeripheral
                sensor.RSSI = RSSI.int32Value
            }
        })
    }
}
