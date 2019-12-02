//
//  ViewController.swift
//  RAC from Github
//
//  Created by michael isbell on 11/30/19.
//  Copyright © 2019 Advanced Mobile Development. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import enum Result.NoError

class ViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var nameTextField2: UITextField!
    
    @IBOutlet weak var nameTextField3: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var cityTextField: UITextField!
    
    @IBOutlet weak var womanButton: UIButton!
    
    @IBOutlet weak var manButton: UIButton!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var checkButton: UIButton!
    
    
    // used in third example
    private let textFieldValuePipe = Signal<String, NoError>.pipe()
    var textFieldValueSignal: Signal<String?, NoError>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // first method...this works programmatically
        // but not when you're typing characters in the textfield UI
        
        let signal = nameTextField.reactive.signal(forKeyPath: #keyPath(UITextField.text)).map { $0 as? String }
        signal.observeValues { print($0!) }
        nameTextField.text = "Hello World"
        nameTextField.text = "and another one"
        
        // let's try the second method now
        var characters = MutableProperty("")
        nameTextField2.reactive.text <~ characters
        // so we've bound it to characters
        nameTextField2.reactive.continuousTextValues.observeValues {
            [weak characters = characters] (text)  in
            characters?.value = text
            print(text)
        }
        nameTextField2.reactive.textValues.observeValues {
            [weak characters = characters] (text)  in
            characters?.value = text
            //            print("tv") does nothing
            //            print(text)
        }
        
        characters.producer.skip(while: { $0.isEmpty }).startWithValues { (text) in
            print("text = \(text)")
        }
        
        characters.value = "shaw"
        characters.value = "barns"
        

        // and now the third method, using a signal pipe
        
        
        // Bind the text of the text field to the signal pipe's output
        nameTextField3.reactive.text <~ textFieldValuePipe.output
        
        // A signal of text values emitted by the text field upon end of editing.
        let textFieldValuesSignal = nameTextField3.reactive.textValues
        
        // A signal of text values emitted by the text field upon any changes.
        let textFieldContinuousValuesSignal = nameTextField3.reactive.continuousTextValues
        
        // broken
        //         Merge the relevant signals
        //         problem with output
        
        let twoSignalsMerged  = Signal.merge(textFieldValuesSignal, textFieldContinuousValuesSignal)
        
        let threeSignalsMerged  = Signal.merge(textFieldValuesSignal, textFieldContinuousValuesSignal, textFieldValuePipe.output)
        
        textFieldValuePipe.output.observeValues {value in
            print ("pipe")
            print(value ?? "nil")
        }
        textFieldValuePipe.input.send(value: "we're good")
        
        textFieldContinuousValuesSignal.observeValues { value in
            print ("continuous")
            print(value ?? "nil")
        }
        twoSignalsMerged.observeValues {value in
            print("twoSignalsMerged")
            print(value ?? nil)
        }
        threeSignalsMerged.observeValues {value in
            print("threeSignalsMerged")
            print(value ?? nil)
        }
        
        let nameSignal = textFieldContinuousValuesSignal.map {
            (text) -> Bool in
            return DataValidator.validName(name: text as! String)
             
        }
        
        nameSignal.observeValues { valid in
            if valid as Bool {
                print ("valid")
            } else {
                print ("invalid")
            }
        }
            

        nameSignal.map { (valid) -> UIColor in
            if valid {
                return UIColor.green
            } else {
                return UIColor.red
            }
        }.observeValues {
            (color) in
            self.nameTextField3.layer.borderWidth = 1
            self.nameTextField3.layer.borderColor = color.cgColor
        }
        
    }
    // Use this to change the text field's value programmatically
    func setTextFieldText(_ text: String?) {
        textFieldValuePipe.input.send(value: text ?? "nil")
    }
    
}

