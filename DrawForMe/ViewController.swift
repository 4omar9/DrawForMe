//
//  ViewController.swift
//  DrawForMe
//
//  Created by Omar on 7/10/20.
//  Copyright © 2020 DrawForMe. All rights reserved.
//

import UIKit
import PencilKit

class DrawingViewController: UIViewController {

	var canvasView: PKCanvasView!

	@IBOutlet private weak var drawingContainer: UIView!

	override func viewDidLoad() {
		super.viewDidLoad()

		initCanvasView()
	}

	private func initCanvasView() {
		let canvasView = PKCanvasView(frame: drawingContainer.bounds)
		self.canvasView = canvasView
		self.drawingContainer.addSubview(canvasView)

		NSLayoutConstraint.activate([
			self.canvasView.topAnchor.constraint(equalTo: drawingContainer.topAnchor),
			self.canvasView.bottomAnchor.constraint(equalTo: drawingContainer.bottomAnchor),
			self.canvasView.leadingAnchor.constraint(equalTo: drawingContainer.leadingAnchor),
			self.canvasView.trailingAnchor.constraint(equalTo: drawingContainer.trailingAnchor)
		])
		self.canvasView.backgroundColor = .lightGray
		self.canvasView.tool = PKInkingTool(.pen, color: .orange, width: 10)
		canvasView.allowsFingerDrawing = true
	}
}

