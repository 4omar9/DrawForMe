//
//  DrawingConnectionState.swift
//  DrawForMe
//
//  Created by Omar on 7/13/20.
//  Copyright © 2020 DrawForMe. All rights reserved.
//

import Foundation

enum DrawingConnectionState: Int {

	case notConnected
	case host
	case connectedAsHost
	case connectedAsObserver

	func stateTitle(with peerID: String) -> String {

		switch self {
			case .notConnected:
				return "Not Connected"

			case .host:
				return "Hosting..."

			case .connectedAsHost:
				return "Connected to \(peerID)"

			case .connectedAsObserver:
				return "Observing to \(peerID)"
		}
	}

	var isHost: Bool {
		return self == .host || self == .connectedAsHost
	}

	var isConnectedHost: Bool {
		return self == .connectedAsHost
	}

	var isConnectedAsObserver: Bool {
		return self == .connectedAsObserver
	}

	var isConnected: Bool {
		return self != .notConnected
	}

	var isNotObserver: Bool {
		return self != .connectedAsObserver
	}
}
