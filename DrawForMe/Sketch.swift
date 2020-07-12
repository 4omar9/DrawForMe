//
//  Sketch.swift
//  DrawForMe
//
//  Created by Omar on 7/11/20.
//  Copyright © 2020 DrawForMe. All rights reserved.
//

import Foundation
import PencilKit
import Realm
import RealmSwift

class Sketch: Object {

	var drawing: PKDrawing = PKDrawing() {
		didSet {
			drawingData = drawing.dataRepresentation()
		}
	}
	@objc dynamic var drawingData: Data? = nil

	init(drawing: PKDrawing) {
		self.drawing = drawing
		super.init()
	}

	required init() {}
}
