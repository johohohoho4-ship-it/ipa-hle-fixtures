//
//  NewTaskModelView.swift
//  ToDoListUIkit
//
//  Created by mac on 6/8/25.
//

//  This class defines the custom view that represents the modal view for adding a new task.
//  It includes all the UI components such as a description text view, category picker, and submit button.
//  This view also handles the layout and interactions within the modal view, as well as passing data and actions to the NewTaskViewController via a delegate.
//
//  The main purpose of this view is to manage the user interface for creating a new task, with appropriate interactions
//  such as clearing the placeholder text, handling picker view data, and delegating close actions to the controller.

import UIKit
import os

class NewTaskModelView: UIView {

    @IBOutlet private weak var descriptionTextView: UITextView!
    @IBOutlet private weak var categoryPickerView: UIPickerView!
   
    @IBOutlet weak var submitButton: ShadowButton!
    
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var captionLabel: UILabel!
    
    
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet var contentView: UIView!
    
    var      newTaskViewController : NewTaskViewController?
    weak var delegate: NewTaskDelegate?
    private var task: Task?
    
    var caption: String {
        
        get {
            return descriptionTextView.text
        }
        set {
            descriptionTextView.text = newValue
        }
    }
    
    init(frame: CGRect, task: Task?) {
        super.init(frame: frame)
        self.task = task
        initSubviews()
    }
    
    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        initSubviews()
//    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initSubviews()
    }
    
    func initSubviews() {
        let nib = UINib(nibName: "NewTaskModelView", bundle: nil)
        nib.instantiate(withOwner: self)
        
        titleLabel.font = UIFont.style(.heading1)
        captionLabel.font = UIFont.style(.caption)
        categoryLabel.font = UIFont.style(.secondaryText)
        
        
        // descriptionTextView
        descriptionTextView.layer.borderWidth = 0.5
        descriptionTextView.layer.borderColor = UIColor.lightGray.cgColor
        descriptionTextView.layer.cornerRadius = 8
        
        
        descriptionTextView.delegate = self
        
        categoryPickerView.dataSource = self
        categoryPickerView.delegate = self
        
        // categoryPickerView middleRow
        let middleRow = Category.allCases.count / 2
           categoryPickerView.selectRow(middleRow, inComponent: 0, animated: false)
        categoryPickerView.selectRow(1, inComponent: 0, animated: false)
        
        if let task = task {
            descriptionTextView.text = task.caption
            descriptionTextView.textColor = UIColor.label
            if let rowIndex = Category.allCases.firstIndex(of: task.category) {
                categoryPickerView.selectRow(rowIndex, inComponent: 0, animated: false)
            }
        } else {
            descriptionTextView.text = "Add caption"
            descriptionTextView.textColor = UIColor.placeholderText
        }
        
        
        
        contentView.frame = bounds
        addSubview(contentView)
        
        print("✅ contentView is:", contentView!)
        
        
    }
    
    override func layoutSubviews() {
        contentView.layer.cornerRadius = 5
        
    }
    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        print("test to see if this is called")
//        
//    }
    
    
    @IBAction func submitButtonTapped(_ sender: Any) {
        os_log("Task creation has started. Submit button tapped", type: .info)
        // Validate user input before allowing a submission
        guard let caption = descriptionTextView.text,
                  descriptionTextView.textColor != UIColor.placeholderText,
                  caption.count >= 4 else {
            delegate?.presentErrorAlert(
                title: "Caption Error",
                message: "You need to provide a description with 4 or more characters")
                  return
        }
        os_log("Validation of task suceeded", type: .info)
        let selectedRow = categoryPickerView.selectedRow(inComponent: 0)
        let category = Category.allCases[selectedRow]
        if let task = task {
            let task = Task(id: task.id, category: category, caption: caption, createdDate: task.createdDate, isComplete: task.isComplete)
            let userInfo: [String : Task] = ["updateTask" : task]
            NotificationCenter.default.post(
                name: NSNotification.Name("com.fullstacktuts.editTask"),
                object: nil,
                userInfo: userInfo)
        } else {
            let taskId = UUID().uuidString
            let task = Task(id:taskId ,category: category, caption: caption, createdDate: Date(), isComplete: false)
            let userInfo: [String : Task] = ["newTask" : task]
            os_log("Task posted as port of notification", type: .info)
            NotificationCenter.default.post(
                name: NSNotification.Name("com.fullstacktuts.createTask"),
                object: nil,
                userInfo: userInfo)
        }
        
        delegate?.closeView()
        
        /*
         let userInfo: [String : Task] = ["newTask" : task] 这一行代码的作用是创建一个字典（userInfo），该字典将新创建的 task 对象包装起来，以便通过 NotificationCenter 发送通知时传递给观察者。

         具体来说：
             •    字典键值对：字典的键是一个字符串 "newTask"，值是一个 Task 对象。Task 是你应用中的任务模型（包含任务的相关信息，如类别、描述、创建日期等）。
             •    用途：userInfo 字典被用作通知的一部分，将其包含在 NSNotification 中，这样接收到该通知的对象就能从通知中提取到这个任务对象。通过 userInfo，其他组件可以获取到 newTask 键对应的任务数据。
         */
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        delegate?.closeView()
    }
    
}

// placeholder
extension NewTaskModelView: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.placeholderText {
            textView.text = nil
            textView.textColor = UIColor.label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Add caption..."
            textView.textColor = UIColor.placeholderText
        }
    }
}

extension NewTaskModelView: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Category.allCases.count
    }
}

extension NewTaskModelView: UIPickerViewDelegate {
    
    // titleForRow
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        let category = Category.allCases[row]
        return category.rawValue
        
//        switch category {
//        case .excercise:
//            return "Excercise"
//        case .study:
//            return "Study"
//        case .work:
//            return "Work"
//        }
        
    }
    
    // titleForRow
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var pickerLabel: UILabel? = view as? UILabel
        
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
                    pickerLabel?.textAlignment = .center
        }
        
        let category = Category.allCases[row]
            pickerLabel?.text = category.rawValue

            return pickerLabel!
    }
    
    
}

