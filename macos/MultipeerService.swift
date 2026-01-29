import Foundation
import MultipeerConnectivity

protocol MultipeerServiceDelegate: AnyObject {
    func didFindPeer(_ peer: MCPeerID)
    func didLosePeer(_ peer: MCPeerID)
    func didReceiveInvitation(from peer: MCPeerID, pairingCode: String, invitationHandler: @escaping (Bool, MCSession?) -> Void)
    func peerDidChangeState(_ peer: MCPeerID, state: MCSessionState)
    func didReceiveData(_ data: Data, from peer: MCPeerID)
}

class MultipeerService: NSObject {
    
    private let serviceType = "soulnote-sync"
    private var myPeerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    
    weak var delegate: MultipeerServiceDelegate?
    
    private var foundPeers: [String: MCPeerID] = [:]
    private var pendingInvitationHandler: ((Bool, MCSession?) -> Void)?
    
    init(displayName: String) {
        super.init()
        
        myPeerID = MCPeerID(displayName: displayName)
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: ["appId": "com.soulnote.app"], serviceType: serviceType)
        advertiser.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser.delegate = self
        
        print("✅ MultipeerService 初始化完成: \(displayName)")
    }
    
    func startAdvertising() {
        advertiser.startAdvertisingPeer()
        print("📢 开始广播设备...")
    }
    
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        print("🛑 停止广播设备")
    }
    
    func startBrowsing() {
        browser.startBrowsingForPeers()
        print("🔍 开始搜索设备...")
    }
    
    func stopBrowsing() {
        browser.stopBrowsingForPeers()
        print("🛑 停止搜索设备")
    }
    
    func stopAll() {
        stopAdvertising()
        stopBrowsing()
        session.disconnect()
        foundPeers.removeAll()
        print("🛑 停止所有 Multipeer 服务")
    }
    
    func invitePeer(withId peerId: String, pairingCode: String, timeout: TimeInterval = 30) {
        guard let peer = foundPeers[peerId] else {
            print("❌ 未找到设备: \(peerId)")
            return
        }

        // 将配对码转为 Data 并发送
        let context = pairingCode.data(using: .utf8)
        print("📤 [发送方] 邀请设备: \(peer.displayName)")
        print("📤 [发送方] 配对码: '\(pairingCode)' (长度: \(pairingCode.count))")
        print("📤 [发送方] Context 数据: \(context?.count ?? 0) bytes")
        browser.invitePeer(peer, to: session, withContext: context, timeout: timeout)
    }
    
    func acceptInvitation() {
        pendingInvitationHandler?(true, session)
        pendingInvitationHandler = nil
    }
    
    func rejectInvitation() {
        pendingInvitationHandler?(false, nil)
        pendingInvitationHandler = nil
    }
    
    func sendData(_ data: Data, toPeer peerId: String) -> Bool {
        guard let peer = foundPeers[peerId] else {
            print("❌ 未找到目标设备: \(peerId)")
            return false
        }
        
        if !session.connectedPeers.contains(peer) {
            print("❌ 设备未连接: \(peer.displayName)")
            return false
        }
        
        do {
            try session.send(data, toPeers: [peer], with: .reliable)
            print("✅ 数据发送成功: \(data.count) bytes -> \(peer.displayName)")
            return true
        } catch {
            print("❌ 数据发送失败: \(error.localizedDescription)")
            return false
        }
    }
    
    func sendDataToAllPeers(_ data: Data) -> Bool {
        let connectedPeers = session.connectedPeers
        guard !connectedPeers.isEmpty else {
            print("❌ 没有已连接的设备")
            return false
        }
        
        do {
            try session.send(data, toPeers: connectedPeers, with: .reliable)
            print("✅ 数据广播成功: \(data.count) bytes -> \(connectedPeers.count) 个设备")
            return true
        } catch {
            print("❌ 数据广播失败: \(error.localizedDescription)")
            return false
        }
    }
    
    func getConnectedPeers() -> [String] {
        return session.connectedPeers.map { $0.displayName }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // 解析配对码
        print("📥 [接收方] 收到邀请来自: \(peerID.displayName)")
        print("📥 [接收方] Context 是否为 nil: \(context == nil)")
        print("📥 [接收方] Context 数据: \(context?.count ?? 0) bytes")

        var pairingCode = ""
        if let context = context, let code = String(data: context, encoding: .utf8) {
            pairingCode = code
            print("📥 [接收方] 配对码: '\(pairingCode)' (长度: \(pairingCode.count))")
        } else {
            print("📥 [接收方] 无法解析配对码")
        }

        pendingInvitationHandler = invitationHandler
        foundPeers[peerID.displayName] = peerID
        delegate?.didReceiveInvitation(from: peerID, pairingCode: pairingCode, invitationHandler: invitationHandler)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ 广播失败: \(error.localizedDescription)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        print("✅ 发现设备: \(peerID.displayName)")
        foundPeers[peerID.displayName] = peerID
        delegate?.didFindPeer(peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("⚠️ 设备离线: \(peerID.displayName)")
        foundPeers.removeValue(forKey: peerID.displayName)
        delegate?.didLosePeer(peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ 搜索失败: \(error.localizedDescription)")
    }
}

// MARK: - MCSessionDelegate
extension MultipeerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let stateString: String
        switch state {
        case .notConnected:
            stateString = "未连接"
        case .connecting:
            stateString = "连接中"
        case .connected:
            stateString = "已连接"
        @unknown default:
            stateString = "未知状态"
        }
        
        print("🔄 设备状态变化: \(peerID.displayName) -> \(stateString)")
        delegate?.peerDidChangeState(peerID, state: state)
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("📨 收到数据: \(data.count) bytes <- \(peerID.displayName)")
        delegate?.didReceiveData(data, from: peerID)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // 不需要处理流
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // 不需要处理资源
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // 不需要处理资源
    }
}
