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
    @IBOutlet var goodSubtitleLabel: UILabel!
    @IBOutlet var goodSubtitleOutputLabel: UILabel!
    
    @IBOutlet var betterResultLabel: UILabel!
    @IBOutlet var betterSubtitleLabel: UILabel!
    @IBOutlet var betterSubtitleOutputLabel: UILabel!
    

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
    
    private enum AcceptedImageSize: Int {
        case good = 224
        case better = 299
    }
    
    private struct Constants {
        static let confidenceLevelText = "Confidence level:"
        static let orMaybeText = "Or maybe?..."
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Predict with one of these two options
        
//        predictWithPixelBuffer()
        predictWithVision()
    }
    
    // MARK: - Pixel Buffer
    
    private func predictWithPixelBuffer() {
        predictWithPixelBuffer(modelType: .better)
        predictWithPixelBuffer(modelType: .good)
    }
    
    private func predictWithPixelBuffer(modelType: MLModelType) {
        // There are more puppies! Try them all!
        let image = UIImage(named: Puppy.one.rawValue)

        var acceptedImageSize = 0
        switch modelType {
        case .good:
            acceptedImageSize = AcceptedImageSize.good.rawValue
        case .better:
            acceptedImageSize = AcceptedImageSize.better.rawValue
        }
        
        if let pixelBuffer = image?.pixelBuffer(width: acceptedImageSize, height: acceptedImageSize) {
            performPrediction(modelType: modelType, pixelBuffer: pixelBuffer)
        }
    }
    
    private func performPrediction(modelType: MLModelType, pixelBuffer: CVPixelBuffer) {
        switch modelType {
        case .good:
            if let prediction = try? goodObjectModel.prediction(image: pixelBuffer) {
                updateLabels(modelType: modelType, prediction: prediction.classLabel, maybe: prediction.classLabelProbs.keys.first ?? "?")
                print(prediction.classLabelProbs)
            }
        case .better:
            if let prediction = try? betterObjectModel.prediction(image: pixelBuffer) {
                updateLabels(modelType: modelType, prediction: prediction.classLabel, maybe: prediction.classLabelProbs.keys.first ?? "?")
                print(prediction.classLabelProbs)
            }
        }
    }
    
    // MARK: - Vision

    private func predictWithVision() {
        // Try ALL THE PUPPIES!
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
        updateLabels(modelType: modelType, prediction: bestPrediction, confidence: String(bestConfidence))
    }
    
    // MARK: - Private Helpers

    private func updateLabels(modelType: MLModelType,
                              prediction: String,
                              confidence: String? = nil,
                              maybe: String? = nil) {

        var subtitleText: String?
        var subtitleOutputText: String?

        if confidence != nil {
            subtitleText = Constants.confidenceLevelText
            subtitleOutputText = confidence
        } else if maybe != nil {
            subtitleText = Constants.orMaybeText
            subtitleOutputText = maybe
        }
        
        switch modelType {
        case .good:
            goodResultLabel.text = prediction
            goodSubtitleLabel.text = subtitleText
            goodSubtitleOutputLabel.text = subtitleOutputText
        case .better:
            betterResultLabel.text = prediction
            betterSubtitleLabel.text = subtitleText
            betterSubtitleOutputLabel.text = subtitleOutputText
        }
    }
}

