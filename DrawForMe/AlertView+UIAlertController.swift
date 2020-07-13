//
//  AlertView.swift
//  DrawForMe
//
//  Created by Omar on 7/13/20.
//  Copyright © 2020 DrawForMe. All rights reserved.
//

import UIKit

extension UIAlertController {

	static func showAlert(title: String?, message: String?, actions: [UIAlertAction], preferredStyle: UIAlertController.Style = .alert) {
		let alert = UIAlertController(
			title: title,
			message: message,
			preferredStyle: preferredStyle
		)
		actions.forEach { alert.addAction($0) }
		DispatchQueue.main.async {
			UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
		}
	}}
