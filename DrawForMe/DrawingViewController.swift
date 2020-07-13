//
//  ViewController.swift
//  DrawForMe
//
//  Created by Omar on 7/10/20.
//  Copyright © 2020 DrawForMe. All rights reserved.
//

import UIKit
import PencilKit
import RealmSwift
import MultipeerConnectivity

enum DrawingConnectionState: Int {
	case notConnected
	case host
	case connectedAsHost
	case connectedAsObserver
}

class DrawingViewController: UIViewController {

	var sketch: Sketch?
	private var canvasView: PKCanvasView!
	private var peerID: MCPeerID!
	private var mcSession: MCSession!
	private var mcAdvertiserAssistant: MCAdvertiserAssistant?
	private var connectionState: DrawingConnectionState = .notConnected

	@IBOutlet private weak var connectionIndicatorView: UIView! {
		didSet {
			connectionIndicatorView.layer.cornerRadius = 10
		}
	}
	@IBOutlet private weak var connectionIndicatorLabel: UILabel!

	override func viewDidLoad() {
		super.viewDidLoad()

		initCanvasView()
		setupToolPicker()
		initPeerConnection()
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(
			title: "Connect",
			style: .plain,
			target: self,
			action: #selector(showConnectionPrompt)
		)
	}

	private func initCanvasView() {
		let canvasView = PKCanvasView(frame: view.bounds)
		canvasView.translatesAutoresizingMaskIntoConstraints = false
		self.canvasView = canvasView
		view.addSubview(canvasView)
		view.sendSubviewToBack(canvasView)

		if let sketch = sketch {
			canvasView.drawing = sketch.drawing
		} else {
			sketch = Sketch()
		}

		NSLayoutConstraint.activate([
			self.canvasView.topAnchor.constraint(equalTo: view.topAnchor),
			self.canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			self.canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			self.canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
		])
		self.canvasView.backgroundColor = .lightGray
		self.canvasView.allowsFingerDrawing = true
		self.canvasView.delegate = self
	}

	private func setupToolPicker() {
		if let window = self.parent?.view.window,
			let toolPicker = PKToolPicker.shared(for: window),
			connectionState != .connectedAsObserver {

			toolPicker.setVisible(true, forFirstResponder: canvasView)
			toolPicker.addObserver(canvasView)
			canvasView.becomeFirstResponder()
			toolPicker.addObserver(self)
		}
	}

	private func updateSketch() {
		guard let sketch = sketch else { return }

		do {
			let realm = try Realm()
			try realm.write({
				sketch.drawing = canvasView.drawing
			})
			if connectionState == .connectedAsHost {
				sendDrawing(sketch: sketch.drawingData ?? Data())
			}
		} catch {
			print("[updateSketch] \(error.localizedDescription)")
		}
	}

	//MARK: - Connection
	private func initPeerConnection() {
		peerID = MCPeerID(displayName: UIDevice.current.name)
		mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
		mcSession.delegate = self
	}

	@objc func showConnectionPrompt() {
		let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
		ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
		ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
		ac.addAction(UIAlertAction(title: "Stop session", style: .default, handler: stopSession))
		ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		present(ac, animated: true)
	}

	func startHosting(action: UIAlertAction) {
		if connectionState == .host {
			UIAlertController
				.showAlert(
					title: "You are already hosting a session",
					message: "",
					actions: [UIAlertAction(title: "Okay", style: .default, handler: nil)]
			)
		}
		mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "omar-DrawForMe", discoveryInfo: nil, session: mcSession)
		mcAdvertiserAssistant?.start()
		connectionState = .host
		self.connectionIndicatorLabel.text = "Hosting..."
	}

	func joinSession(action: UIAlertAction) {
		if connectionState == .host {
			UIAlertController
				.showAlert(
					title: "You are hosting a session",
					message: "Disconnect so you can join a session",
					actions: [UIAlertAction(title: "Okay", style: .default, handler: nil)]
			)
			return
		}
		let mcBrowser = MCBrowserViewController(serviceType: "omar-DrawForMe", session: mcSession)
		mcBrowser.delegate = self
		present(mcBrowser, animated: true)
	}

	func stopSession(action: UIAlertAction) {
		guard let mcAdvertiserAssistant = mcAdvertiserAssistant,
			connectionState != .notConnected else {
				if mcSession.connectedPeers.count >= 1 {
					mcSession.disconnect()
					connectionIndicatorLabel.text = "Not Connected"
				} else {
			UIAlertController
				.showAlert(
					title: "You don't have any running Session",
					message: "",
					actions: [UIAlertAction(title: "Okay", style: .default, handler: nil)]
			)
				}
			return
		}
		mcAdvertiserAssistant.session.disconnect()
		mcAdvertiserAssistant.stop()
		connectionIndicatorLabel.text = "Not Connected"
		connectionState = .notConnected
	}

	func sendDrawing(sketch: Data) {
		if mcSession.connectedPeers.count > 0 {
			do {
				try mcSession.send(sketch, toPeers: mcSession.connectedPeers, with: .reliable)
			} catch let error as NSError {
				let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
				ac.addAction(UIAlertAction(title: "OK", style: .default))
				present(ac, animated: true)
			}
		}
	}

	func changeConnectionIndicator(
		session: MCSession,
		state: MCSessionState,
		peerID: MCPeerID
	) {
		DispatchQueue.main.async { [weak self] in
			guard let self = self else { return }

			switch state {
			case MCSessionState.connected:
				if self.connectionState == .host {
					self.connectionState = .connectedAsHost
					self.connectionIndicatorLabel.text = "Hosting \(peerID.displayName)"
					self.canvasView.isUserInteractionEnabled = true
				} else {
					self.connectionIndicatorLabel.text = "Observing \(peerID.displayName)"
					self.connectionState = .connectedAsObserver
					self.canvasView.isUserInteractionEnabled = false
				}

			case MCSessionState.connecting:
				self.connectionIndicatorLabel.text = "Connecting to \(peerID.displayName)"

			case MCSessionState.notConnected:
				self.connectionIndicatorLabel.text = "Not Connected"
				self.connectionState = .notConnected
				self.canvasView.isUserInteractionEnabled = true
				self.setupToolPicker()

			@unknown default:
				self.connectionIndicatorLabel.text = "status unknown"
			}
		}
	}
}

extension DrawingViewController: PKToolPickerObserver {

	func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {}

	func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {}

	func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {}

	func toolPickerIsRulerActiveDidChange(_ toolPicker: PKToolPicker) {}
}

extension DrawingViewController: PKCanvasViewDelegate {

	func canvasViewDrawingDidChange(
		_ canvasView: PKCanvasView
	) {
		updateSketch()
		print("[CanvasViewDrawingDidChange] with new canvasView: \(canvasView)")
	}
}

// MARK: - MCSessionDelegate
extension DrawingViewController: MCSessionDelegate {

	func session(
		_ session: MCSession,
		peer peerID: MCPeerID,
		didChange state: MCSessionState
	) {
		self.changeConnectionIndicator(session: session, state: state, peerID: peerID)
	}

	//Receive
	func session(
		_ session: MCSession,
		didReceive data: Data,
		fromPeer peerID: MCPeerID
	) {

		if let drawing = try? PKDrawing(data: data) {
			DispatchQueue.main.async { [weak self] in
				guard let self = self else { return }
				if self.connectionState == .connectedAsObserver {
					self.canvasView.drawing = drawing
				}
			}
		}
	}

	func session(
		_ session: MCSession,
		didReceive stream: InputStream,
		withName streamName: String,
		fromPeer peerID: MCPeerID
	) {
		print("didReceive \(peerID)")
	}

	func session(
		_ session: MCSession,
		didStartReceivingResourceWithName resourceName: String,
		fromPeer peerID: MCPeerID,
		with progress: Progress
	) {
		print("didStartReceivingResourceWithName \(peerID)")
	}

	func session(
		_ session: MCSession,
		didFinishReceivingResourceWithName resourceName: String,
		fromPeer peerID: MCPeerID,
		at localURL: URL?,
		withError error: Error?
	) {
		print("didFinishReceivingResourceWithName \(peerID)")
	}
}

// MARK: - MCBrowserViewControllerDelegate
extension DrawingViewController: MCBrowserViewControllerDelegate {

	func browserViewControllerDidFinish(
		_ browserViewController: MCBrowserViewController
	) {
		dismiss(animated: true, completion: { [weak self] in
			self?.setupToolPicker()
		})
	}

	func browserViewControllerWasCancelled(
		_ browserViewController: MCBrowserViewController
	) {
		dismiss(animated: true, completion: { [weak self] in
			self?.setupToolPicker()
		})
	}
}
