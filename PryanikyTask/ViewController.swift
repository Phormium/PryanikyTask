//
//  ViewController.swift
//  PryanikyTask
//
//  Created by Leonid Safronov on 29.01.2021.
//

import UIKit
import Alamofire
import Combine
import Kingfisher

class ViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var jsonTextField: UITextField!
    @IBOutlet weak var statusLable: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    private var viewModel:ViewModel = ViewModel()
    private var cancellable = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        jsonTextField.text = viewModel.jsonUrl
        binding()
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        jsonTextField.delegate = self
    }
    
    func binding() {
        jsonTextField.textPublisher
            .assign(to: \.jsonUrl, on: viewModel)
            .store(in: &cancellable)
        
        viewModel.$data
            .sink(receiveValue: { [weak self] data in
                self?.updateView(viewData: data)
            })
            .store(in: &cancellable)
        
        viewModel.$status
            .sink(receiveValue: {[weak self] status in
                self?.updateStatus(status: status)
            })
            .store(in: &cancellable)
            
    }
    
    @objc func rotated() {
        updateView(viewData: viewModel.data)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    func updateStatus(status: Status) {
        statusLable.text = status.rawValue
        switch status {
        case .success:
            statusLable.textColor = .green
        case .fail:
            statusLable.textColor = .red
        case .epmty:
            statusLable.textColor = .black
        }
    }
    
    func updateView(viewData: ViewData) {
        for view in scrollView.subviews {
            view.removeFromSuperview()
        }
        scrollView.contentSize.height = 0
        guard viewData.view.count != 0 else {
            return
        }
        
        var currentTopConstraint = scrollView.topAnchor
        
        for (id, name) in (viewData.view).enumerated() {
            let currentData = viewData.data[viewData.data.firstIndex(where: {$0.name == name}) ?? 0].data
            if let text = currentData.text, let url = currentData.url {
                addImageView(
                    topConstraint: &currentTopConstraint,
                    name: name,
                    url: url,
                    text: text,
                    id: id
                )
            } else if let selectedID = currentData.selectedID, let variants = currentData.variants {
                addSegmentView(
                    topConstraint: &currentTopConstraint,
                    name: name,
                    selectedID: selectedID,
                    variants: variants,
                    id: id
                )
            } else if let text = currentData.text {
                addTextView(
                    topConstraint: &currentTopConstraint,
                    name: name,
                    text: text,
                    id: id
                )
            }
        }
    }
    
    @objc func showInfo(_ sender:UITapGestureRecognizer) {
        let alert = UIAlertController(
            title: "Информация об объекте",
            message: sender.view?.accessibilityIdentifier ?? "Информация отсутствует.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Закрыть", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    @objc func segmentedValueChanged(_ sender:UISegmentedControl!) {
        var message = ""
        if let ms = sender.accessibilityIdentifier {
            message = ms + "\nВыбранный вариант: \(sender.selectedSegmentIndex + 1)"
        } else {
            message = "Информация отсутствует."
        }
        let alert = UIAlertController(
            title: "Информация об объекте",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Закрыть", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    func addTextView(topConstraint: inout NSLayoutYAxisAnchor, name: String, text: String, id:Int) {
        let textView = UITextView()
        textView.text = text
        textView.textAlignment = .center
        textView.accessibilityIdentifier = "Имя: \(name)\nID: \(id)\nТекст: \(text)"
        textView.isEditable = false

        textView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            textView.topAnchor.constraint(equalTo: topConstraint, constant: 10),
            textView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            textView.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.showInfo (_:)))
        textView.addGestureRecognizer(gesture)
        
        topConstraint = textView.bottomAnchor
        scrollView.contentSize.height += 42
    }

    func addImageView(topConstraint: inout NSLayoutYAxisAnchor, name: String, url: String, text: String, id:Int) {
        let imageView = UIImageView()
        imageView.kf.setImage(with: URL(string: url)){
            result in
            switch result {
            case .success(let value):
                let aspectRatio = value.image.size.height / value.image.size.width
                NSLayoutConstraint.activate([imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: aspectRatio)])
                self.scrollView.contentSize.height += self.view.frame.size.width * aspectRatio * 0.96 + 10
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        }
        imageView.accessibilityIdentifier = "Имя: \(name)\nID: \(id)\nURL: \(url)\nТекст: \(text)"
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: topConstraint, constant: 10),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
        
        imageView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.showInfo (_:)))
        imageView.addGestureRecognizer(gesture)
        
        topConstraint = imageView.bottomAnchor
        
        let subTextView = UITextView()
        subTextView.text = text
        subTextView.textAlignment = .center
        subTextView.isEditable = false
        subTextView.layer.cornerRadius = 16
        subTextView.backgroundColor = UIColor(displayP3Red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        
        subTextView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(subTextView)
        
        NSLayoutConstraint.activate([
            subTextView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            subTextView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -10),
            subTextView.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.6),
            subTextView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    func addSegmentView(topConstraint: inout NSLayoutYAxisAnchor, name: String, selectedID: Int, variants:[Variant], id:Int) {
        let segmentedControl = UISegmentedControl (items: variants.sorted(by: {$0.id < $1.id}).map({$0.text}))
        segmentedControl.selectedSegmentIndex = id - 1
        segmentedControl.accessibilityIdentifier = "Имя: \(name)\nID: \(id)\nВарианты: \(variants)"

        
        segmentedControl.addTarget(self, action: #selector(self.segmentedValueChanged (_:)), for: .valueChanged)
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(segmentedControl)
        
        NSLayoutConstraint.activate([
            segmentedControl.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            segmentedControl.topAnchor.constraint(equalTo: topConstraint, constant: 10),
            segmentedControl.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        topConstraint = segmentedControl.bottomAnchor
        scrollView.contentSize.height += 42
    }
}

extension UITextField {
    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: self)
            .compactMap { $0.object as? UITextField }
            .map { $0.text ?? "" }
            .eraseToAnyPublisher()
    }
}

