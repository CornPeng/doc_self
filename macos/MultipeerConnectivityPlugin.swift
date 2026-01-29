import FlutterMacOS
import MultipeerConnectivity

public class MultipeerConnectivityPlugin: NSObject, FlutterPlugin {
    private var multipeerService: MultipeerService?
    private var eventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "multipeer_connectivity", binaryMessenger: registrar.messenger)
        let eventChannel = FlutterEventChannel(name: "multipeer_connectivity/events", binaryMessenger: registrar.messenger)
        
        let instance = MultipeerConnectivityPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            guard let args = call.arguments as? [String: Any],
                  let displayName = args["displayName"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "displayName is required", details: nil))
                return
            }
            multipeerService = MultipeerService(displayName: displayName)
            multipeerService?.delegate = self
            result(nil)
            
        case "startAdvertising":
            multipeerService?.startAdvertising()
            result(nil)
            
        case "stopAdvertising":
            multipeerService?.stopAdvertising()
            result(nil)
            
        case "startBrowsing":
            multipeerService?.startBrowsing()
            result(nil)
            
        case "stopBrowsing":
            multipeerService?.stopBrowsing()
            result(nil)
            
        case "stopAll":
            multipeerService?.stopAll()
            result(nil)
            
        case "invitePeer":
            guard let args = call.arguments as? [String: Any],
                  let peerId = args["peerId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "peerId is required", details: nil))
                return
            }
            let pairingCode = args["pairingCode"] as? String ?? ""
            let timeout = args["timeout"] as? Double ?? 30.0
            multipeerService?.invitePeer(withId: peerId, pairingCode: pairingCode, timeout: timeout)
            result(nil)
            
        case "acceptInvitation":
            multipeerService?.acceptInvitation()
            result(nil)
            
        case "rejectInvitation":
            multipeerService?.rejectInvitation()
            result(nil)
            
        case "sendData":
            guard let args = call.arguments as? [String: Any],
                  let peerId = args["peerId"] as? String,
                  let data = (args["data"] as? FlutterStandardTypedData)?.data else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "peerId and data are required", details: nil))
                return
            }
            let success = multipeerService?.sendData(data, toPeer: peerId) ?? false
            result(success)
            
        case "sendDataToAll":
            guard let args = call.arguments as? [String: Any],
                  let data = (args["data"] as? FlutterStandardTypedData)?.data else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "data is required", details: nil))
                return
            }
            let success = multipeerService?.sendDataToAllPeers(data) ?? false
            result(success)
            
        case "getConnectedPeers":
            let peers = multipeerService?.getConnectedPeers() ?? []
            result(peers)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - FlutterStreamHandler
extension MultipeerConnectivityPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// MARK: - MultipeerServiceDelegate
extension MultipeerConnectivityPlugin: MultipeerServiceDelegate {
    func didFindPeer(_ peer: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?([
                "type": "peerFound",
                "peerId": peer.displayName,
                "peerName": peer.displayName
            ])
        }
    }
    
    func didLosePeer(_ peer: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?([
                "type": "peerLost",
                "peerId": peer.displayName,
                "peerName": peer.displayName
            ])
        }
    }
    
    func didReceiveInvitation(from peer: MCPeerID, pairingCode: String, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("🔌 [Plugin] 准备发送邀请事件到 Dart")
        print("🔌 [Plugin] PeerId: \(peer.displayName)")
        print("🔌 [Plugin] 配对码: '\(pairingCode)' (长度: \(pairingCode.count))")

        DispatchQueue.main.async { [weak self] in
            self?.eventSink?([
                "type": "invitationReceived",
                "peerId": peer.displayName,
                "peerName": peer.displayName,
                "pairingCode": pairingCode
            ])
            print("🔌 [Plugin] 事件已发送")
        }
    }
    
    func peerDidChangeState(_ peer: MCPeerID, state: MCSessionState) {
        let stateString: String
        switch state {
        case .notConnected:
            stateString = "notConnected"
        case .connecting:
            stateString = "connecting"
        case .connected:
            stateString = "connected"
        @unknown default:
            stateString = "unknown"
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?([
                "type": "peerStateChanged",
                "peerId": peer.displayName,
                "peerName": peer.displayName,
                "state": stateString
            ])
        }
    }
    
    func didReceiveData(_ data: Data, from peer: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?([
                "type": "dataReceived",
                "peerId": peer.displayName,
                "peerName": peer.displayName,
                "data": FlutterStandardTypedData(bytes: data)
            ])
        }
    }
}
