//
//  ViewController.swift
//  EditorTest
//
//  Created by ITHPNB04248 on 2025/11/5.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var canvasView: CanvasView!
    let imagePickerController = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView = CanvasView(frame: CGRect(x: 0, y: 200, width: self.view.bounds.width, height: 200))
        canvasView.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        self.view.addSubview(canvasView)
        
        let addImageButton = UIButton(type: .system)
        self.view.addSubview(addImageButton)
        addImageButton.addTarget(self, action: #selector(addImage), for: .touchUpInside)
        addImageButton.setTitle("Add Image", for: .normal)
        addImageButton.setTitleColor(.white, for: .normal)
        addImageButton.backgroundColor = .systemBlue
        addImageButton.layer.cornerRadius = 10
        addImageButton.layer.masksToBounds = true
        addImageButton.frame = CGRect(x: 100, y: self.view.frame.height - 100, width: 100, height: 50)


        let addTextButton = UIButton(type: .system)
        self.view.addSubview(addTextButton)
        addTextButton.addTarget(self, action: #selector(addText), for: .touchUpInside)
        addTextButton.setTitle("Add Text", for: .normal)
        addTextButton.setTitleColor(.white, for: .normal)
        addTextButton.backgroundColor = .systemBlue
        addTextButton.layer.cornerRadius = 10
        addTextButton.layer.masksToBounds = true
        addTextButton.frame = CGRect(x: 300, y: self.view.frame.height - 100, width: 100, height: 50)
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        // Do any additional setup after loading the view.
    }

    @objc func addImage() {
        self.present(imagePickerController, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        picker.dismiss(animated: true, completion: nil)
        canvasView.addImage(image: image!)
    }
    @objc func addText() {
        canvasView.addText(text: "Hello, World!")
    }


}

