//
//  PeerConnectionViewController.swift
//  DrawForMe
//
//  Created by Omar on 7/11/20.
//  Copyright © 2020 DrawForMe. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class PeerConnectionViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate {

	var peerID: MCPeerID!
	var mcSession: MCSession!
	var mcAdvertiserAssistant: MCAdvertiserAssistant!

    override func viewDidLoad() {
        super.viewDidLoad()

		self.title = "Connect to device"

		peerID = MCPeerID(displayName: UIDevice.current.name)
		mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
		mcSession.delegate = self
	}

	deinit {
		mcAdvertiserAssistant.stop()
	}

	func sendText(text: String) {
		if mcSession.connectedPeers.count > 0 {
			if let data = text.data(using: .utf16) {
				do {
					try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
				} catch let error as NSError {
					let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
					ac.addAction(UIAlertAction(title: "OK", style: .default))
					present(ac, animated: true)
				}
			}
		}
	}

	func startHosting() {
		mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "omar-DrawForMe", discoveryInfo: nil, session: mcSession)
		mcAdvertiserAssistant.start()
	}

	func joinSession() {
		let mcBrowser = MCBrowserViewController(serviceType: "omar-DrawForMe", session: mcSession)
		mcBrowser.delegate = self
		present(mcBrowser, animated: true)
	}

	@IBAction func hostAction(_ sender: Any) {
		startHosting()
	}

	@IBAction func joinAction(_ sender: Any) {
		joinSession()
	}

	@IBAction func sendTextAction(_ sender: Any) {
		sendText(text: "TESTING TEXT")
	}

	func session(
		_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState
	) {

		switch state {
			case MCSessionState.connected:
				print("Connected: \(peerID.displayName)")

			case MCSessionState.connecting:
				print("Connecting: \(peerID.displayName)")

			case MCSessionState.notConnected:
				print("Not Connected: \(peerID.displayName)")
		}
	}

	//Receive
	func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		if let text = String(data: data, encoding: .utf16) {
			DispatchQueue.main.async { [unowned self] in
				print(text)
			}
		}
	}

	func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
		print("didReceive \(peerID)")
	}

	func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
		print("didStartReceivingResourceWithName \(peerID)")
	}

	func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
		print("didFinishReceivingResourceWithName \(peerID)")
	}

	func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
		dismiss(animated: true)
	}

	func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
		dismiss(animated: true)
	}
}
