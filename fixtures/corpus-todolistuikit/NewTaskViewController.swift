//
//  NewTaskViewController.swift
//  ToDoListUIkit
//
//  Created by mac on 6/8/25.
//

//  This class represents the view controller responsible for presenting the "New Task" modal.
//  It handles the lifecycle of the modal, including setting up the modal view, adding it to the view hierarchy,
//  and dismissing the modal when the user taps the close button.
//
//  The NewTaskViewController also acts as the delegate for the NewTaskModelView, listening for close actions
//  from the modal view. It handles the dismissal of the modal when the close action is triggered.


import UIKit

//TODO: - Move to seperate protocol class

/*

NewTaskDelegate links the NewTaskViewController and the NewTaskViewController konw when to dismiss
 when the x button is tapped on the NewTaskModalView
 and to present an error alert when a user enters invaild input

 */

protocol NewTaskDelegate: AnyObject {
    ///Dismiss the NewTaskViewController. Called when x button is tapped on NewTaskModalView
    func closeView()
    /**
     This presents an error alert when the user enters invalid input.

     - Parameters:
       - title: This is the title of the error alert
       - message: A short description of what went wrong
     */
    
    func presentErrorAlert(title: String, message: String)
}
///  This class is responsable for creating a new task or editing a new task
class NewTaskViewController: UIViewController {
    
    // modelView instantiate
    lazy var modelView: NewTaskModelView = {
        
        let modelWidth = view.frame.width - 30
        let modelHeight: CGFloat = 430
        let frame = CGRect(x: 15, y: view.center.y - (modelHeight / 2), width: modelWidth, height: modelHeight)
        // 正确创建 modelView 实例
        let modelView = NewTaskModelView(frame: frame, task: task)
        // 返回 modelView 实例，动画应在 addSubview 之后另写
        
        modelView.delegate = self
        return modelView
    }()
    
    private var task: Task?
    
    /**
      This creates the NewTaskViewController
     
      - Parameters:
        - task: If a task is being edited, task should be passed. If a new task is being created, task shoould be nil
        - Returns: NewTaskViewController with a NewTaskModalview for the user to edit or create a task
     */
    init(task: Task? = nil) {
        super.init(nibName: nil, bundle: nil)
        
        self.task = task
        modalTransitionStyle   = .crossDissolve
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        modelView.transform = CGAffineTransform(scaleX: 0, y: 0)
        // modelView frame
        view.addSubview(modelView)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 5,options: [.curveEaseOut]) {
            self.modelView.transform = CGAffineTransform.identity
        }
        
    }

}


//MARK: - Conformance to New Task Delegate
extension NewTaskViewController: NewTaskDelegate {
    func closeView() {
        dismiss(animated: true)
    }
    
    func presentErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }
    
}
