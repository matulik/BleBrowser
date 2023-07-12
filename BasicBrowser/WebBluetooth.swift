//
//  WebBluetooth.swift
//  BleBrowser
//
//  Created by Paul Theriault on 7/03/2016.
//

import CoreBluetooth
import Foundation
import WebKit

// MARK: - BluetoothDevice
public class BluetoothDevice: NSObject, CBPeripheralDelegate {
    var deviceId: String // generated ID used instead of internal IOS name
    var peripheral: CBPeripheral
    var adData: BluetoothAdvertisingData
    var gattRequests: [CBUUID: JSRequest] = .init()

    init(deviceId: String, peripheral: CBPeripheral, advertisementData: [String: AnyObject] = [String: AnyObject](), RSSI: NSNumber = 0) {
        self.deviceId = deviceId
        self.peripheral = peripheral
        adData = BluetoothAdvertisingData(advertisementData: advertisementData, RSSI: RSSI)
        super.init()
        self.peripheral.delegate = self
    }

    func toJSON() -> String? {
        let props: [String: Any] = [
            "id": deviceId,
            "name": peripheral.name,
            "adData": adData.toDict(),
            "deviceClass": 0,
            "vendorIDSource": 0,
            "vendorID": 0,
            "productID": 0,
            "productVersion": 0,
            "uuids": []
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: props,
                                                      options: JSONSerialization.WritingOptions(rawValue: 0))
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("error converting to json: \(error)")
            return nil
        }
    }

    // connect services
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices _: Error?) {
        for service in peripheral.services! {
            print("found service:" + service.uuid.uuidString)
            if let matchedRequest = gattRequests[service.uuid] {
                matchedRequest.sendMessage(type: "response", success: true, result: service.uuid.uuidString, requestId: matchedRequest.id)
            }
        }
    }

    // connect characteristics
    public func peripheral(_: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error _: Error?) {
        service.characteristics?.forEach {
            print("found char:" + $0.uuid.uuidString)
            if let matchedRequest = gattRequests[$0.uuid] {
                matchedRequest.sendMessage(type: "response", success: true, result: "{}", requestId: matchedRequest.id)
            }
        }
    }

    // characteristic updates
    public func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error _: Error?) {
        print("Characteristic Updated:", characteristic.uuid, " ->", characteristic.value)

        if let matchedRequest = gattRequests[characteristic.uuid] {
            if let data = characteristic.value {
                let b64data = data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
                matchedRequest.sendMessage(type: "response", success: true, result: b64data, requestId: matchedRequest.id)
                return
            } else {
                matchedRequest.sendMessage(type: "response", success: false, result: "{}", requestId: matchedRequest.id)
            }
        }
    }

    func getService(uuid: CBUUID) -> CBService? {
        if peripheral.services == nil {
            return nil
        }
        for service in peripheral.services! {
            if service.uuid == uuid {
                return service
            }
        }
        return nil
    }

    func getCharacteristic(serviceUUID: CBUUID, uuid: CBUUID) -> CBCharacteristic? {
        print(peripheral)
        if peripheral.services == nil {
            return nil
        }
        var service: CBService?
        for s in peripheral.services! {
            if s.uuid == serviceUUID {
                service = s
            }
        }

        guard let chars = service?.characteristics else {
            return nil
        }

        for char in chars {
            if char.uuid == uuid {
                return char
            }
        }
        return nil
    }

    func recieve(req: JSRequest) {
        switch req.method {
        case "BluetoothRemoteGATTServer.getPrimaryService":
            let targetService: CBUUID = .init(string: req.args[0])

            // check peripherals.services first to see if we already discovered services
            if peripheral.services != nil {
                if peripheral.services!.contains(where: { $0.uuid == targetService }) {
                    req.sendMessage(type: "response", success: true, result: "{}", requestId: req.id)
                    return
                } else {
                    req.sendMessage(type: "response", success: false, result: "{}", requestId: req.id)
                    return
                }
            }

            print("Discovering service:" + targetService.uuidString)
            gattRequests[targetService] = req
            peripheral.discoverServices([targetService])

        case "BluetoothGATTService.getCharacteristic":

            let targetService: CBUUID = .init(string: req.args[0])
            let targetChar: CBUUID = .init(string: req.args[1])
            guard let service = getService(uuid: targetService) else {
                req.sendMessage(type: "response", success: false, result: "{}", requestId: req.id)
                return
            }

            if service.characteristics != nil {
                for char in service.characteristics! {
                    if char.uuid == targetChar {
                        req.sendMessage(type: "response", success: true, result: "{}", requestId: req.id)
                        return
                    } else {
                        req.sendMessage(type: "response", success: false, result: "{}", requestId: req.id)
                        return
                    }
                }
            }

            print("Discovering service:" + targetService.uuidString)
            gattRequests[targetChar] = req
            peripheral.discoverCharacteristics(nil, for: service)
        case "BluetoothGATTCharacteristic.readValue":
            let targetService: CBUUID = .init(string: req.args[0])
            let targetChar: CBUUID = .init(string: req.args[1])

            guard let char = getCharacteristic(serviceUUID: targetService, uuid: targetChar) else {
                req.sendMessage(type: "response", success: false, result: "{}", requestId: req.id)
                return
            }

            gattRequests[char.uuid] = req
            peripheral.readValue(for: char)

        default:
            print("Unrecognized method requested")
        }
    }
}

// MARK: - BluetoothAdvertisingData
class BluetoothAdvertisingData {
    var appearance: String
    var txPower: NSNumber
    var rssi: String
    var manufacturerData: String
    var serviceData: [String]

    init(advertisementData: [String: AnyObject] = [String: AnyObject](), RSSI: NSNumber = 0) {
        appearance = "fakeappearance"
        let tx = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int
        txPower = NSNumber(integerLiteral: tx ?? 0)
        rssi = "\(RSSI)"
        let data = advertisementData[CBAdvertisementDataManufacturerDataKey]
        manufacturerData = ""
        if data != nil {
            if let dataString = NSString(data: (data as! NSData) as Data, encoding: NSUTF8StringEncoding) as? String {
                manufacturerData = dataString
            } else {
                print("Error parsing advertisement data: not a valid UTF-8 sequence")
            }
        }

        var uuids = [String]()
        if advertisementData["kCBAdvDataServiceUUIDs"] != nil {
            uuids = (advertisementData["kCBAdvDataServiceUUIDs"] as! [CBUUID]).map { $0.uuidString.lowercased() }
        }
        serviceData = uuids
    }

    func toDict() -> [String: Any] {
        let dict: [String: Any] = [
            "appearance": appearance,
            "txPower": txPower,
            "rssi": rssi,
            "manufacturerData": manufacturerData,
            "serviceData": serviceData
        ]
        return dict
    }
}
