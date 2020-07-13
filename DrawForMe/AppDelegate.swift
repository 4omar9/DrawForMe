//
//  AppDelegate.swift
//  DrawForMe
//
//  Created by Omar on 7/10/20.
//  Copyright © 2020 DrawForMe. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		initializeRealm()
		return true
	}

	private func initializeRealm() {

		do {
			let realm = try Realm()
			print(Realm.Configuration.defaultConfiguration.fileURL)
		} catch let error as NSError {
			print("[initializeRealm] \(error.localizedDescription)")
		}
	}
}
