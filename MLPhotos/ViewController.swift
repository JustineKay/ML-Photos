//
//  ViewController.swift
//  MLPhotos
//
//  Created by Justine Kay on 2/11/18.
//  Copyright © 2018 Justine Kay. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {

    @IBOutlet var goodResultLabel: UILabel!
    @IBOutlet var goodConfidenceLabel: UILabel!
    
    @IBOutlet var betterResultsLabel: UILabel!
    @IBOutlet var betterConfidenceLabel: UILabel!


    private let placesModel = GoogLeNetPlaces()
    private let goodObjectModel = Resnet50()
    private let betterObjectModel = Inceptionv3()
    
    private enum MLModelType {
        case good, better
    }
    
    private enum Puppy: String {
        case one = "puppy"
        case two = "puppy2"
        case three = "puppy3"
        case four = "puppy4"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Try all the puppies!
        if let path = Bundle.main.path(forResource: Puppy.one.rawValue, ofType: "jpg") {
            performRequest(with: goodObjectModel.model, modelType: .good, path: path)
            performRequest(with: betterObjectModel.model, modelType: .better, path: path)
        }
    }
    
    private func performRequest(with mlModel: MLModel, modelType: MLModelType, path: String) {
        let vnModel = try! VNCoreMLModel(for: mlModel)
        let handler = VNImageRequestHandler(url: NSURL.fileURL(withPath: path), options: [:])
        let request = VNCoreMLRequest(model: vnModel) { [weak self] (request, error) in
            self?.handleModelRequestResults(modelType: modelType, request: request, error: error)
        }
        
        try! handler.perform([request])
    }

    private func handleModelRequestResults(modelType: MLModelType, request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else {
            fatalError("No results from ML Vision request")
        }
        
        var bestPrediction = ""
        var bestConfidence: VNConfidence = 0
        
        results.forEach { classification in
            let confidence = classification.confidence
            if  confidence > bestConfidence {
                bestConfidence = confidence
                bestPrediction = classification.identifier
            }
        }
        switch modelType {
        case .good:
            goodResultLabel.text = bestPrediction
            goodConfidenceLabel.text = String(bestConfidence)
        case .better:
            betterResultsLabel.text = bestPrediction
            betterConfidenceLabel.text = String(bestConfidence)
        }
        print("Predicted: \(bestPrediction) with best confidence: \(bestConfidence) out of 1")
    }
}

