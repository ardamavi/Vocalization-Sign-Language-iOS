//
//  ViewController.swift
//  Sesgoritma
//
//  Created by Arda Mavi on 21.03.2018.
//  Copyright © 2018 Sesgoritma. All rights reserved.
//

import UIKit
import AVKit
import Vision
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let captureSession = AVCaptureSession()
    let synth = AVSpeechSynthesizer()
    var utterance = AVSpeechUtterance(string: "")
    var old_char = ""
    
    @IBOutlet var predictLabel: UILabel!
    @IBAction func stop_captureSession(_ sender: UIButton) {
        captureSession.stopRunning()
        synth.stopSpeaking(at: AVSpeechBoundary.immediate)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {return}
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.insertSublayer(previewLayer, at: 0)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}

        guard let model = try? VNCoreMLModel(for: Sesgoritma().model) else {return}
        let request = VNCoreMLRequest(model: model){ (fineshedReq, err) in
            
            guard let results = fineshedReq.results as? [VNClassificationObservation] else {return}
            guard let firstObservation = results.first else {return}
            
            
            // print(firstObservation.identifier, firstObservation.confidence)
            DispatchQueue.main.async {
                if firstObservation.confidence < 0.4{
                    
                    // For secondary vocalization
                    self.old_char = "Sesgoritma"
                    self.predictLabel.text = self.old_char
                    
                }else if self.old_char != String(firstObservation.identifier) && firstObservation.confidence > 0.6{
                    
                    self.predictLabel.text =  String(firstObservation.identifier)
                    
                    self.utterance = AVSpeechUtterance(string: String(firstObservation.identifier))
                    self.utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
                    self.synth.speak(self.utterance)
                    self.old_char = String(firstObservation.identifier)
                    
                }
            }
            
        }
        
        request.imageCropAndScaleOption = .centerCrop
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

