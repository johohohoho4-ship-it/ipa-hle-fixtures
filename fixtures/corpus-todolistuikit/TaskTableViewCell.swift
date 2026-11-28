//
//  TaskTableViewCell.swift
//  ToDoListUIkit
//
//  Created by mac on 6/7/25.
//

import UIKit

protocol TaskTableViewCellDelegate: AnyObject {
    func editTask(id: String)
    func markTask(id: String ,complete: Bool)
}

class TaskTableViewCell: UITableViewCell {
    
    static let identifier = "TaskTableViewCell"
    
    @IBOutlet weak var categoryContainerView: UIView!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var captionLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var isCompleteImageView: UIImageView!

    @IBOutlet weak var stripView: UIView!
    
    private weak var delegate: TaskTableViewCellDelegate?
    
    private var task: Task!
    
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        categoryContainerView.layer.cornerRadius = categoryContainerView.frame.height / 2
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
//        categoryLabel.font = .style(.heading1)
//        captionLabel.font = .style(.heading1)
        
    }
    
    //     •    withTask 是参数标签，显示函数的目的是什么（这里是配置任务）。
    // •    task 是你在函数内部使用的变量名称，用来引用传入的 Task 对象。
    // •    Task 是传入的参数类型，它是你传递给函数的实际数据类型。
    
    func configure(withTask task: Task , delegate: TaskTableViewCellDelegate?) {
        
        stripView.backgroundColor = task.category.color
        categoryLabel.textColor = task.category.color
        categoryContainerView.backgroundColor = task.category.secondaryColor
        
        categoryLabel.text = task.category.rawValue
        captionLabel.text = task.caption
        isCompleteImageView.image = task.isComplete ? UIImage(systemName: "checkmark.circle") :
        UIImage(systemName: "circle")
        dateLabel.text = dateFormatter.string(from: task.createdDate)
        
        selectionStyle = .none
        //     •    当用户点击 UITableViewCell 时，单元格不会显示任何选中效果，通常用来避免默认的选中背景色变化，保持单元格外观不变。
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleCompletion))
        isCompleteImageView.addGestureRecognizer(tap)
        isCompleteImageView.isUserInteractionEnabled = true
        self.task = task
        self.delegate = delegate
    }
    
    @objc func toggleCompletion() {
        task.isComplete.toggle()
        delegate?.markTask(id: task.id, complete: task.isComplete)
    }

    
    @IBAction func editTaskButtonTapped(_ sender: Any) {
        delegate?.editTask(id: task.id)
    }
    
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
