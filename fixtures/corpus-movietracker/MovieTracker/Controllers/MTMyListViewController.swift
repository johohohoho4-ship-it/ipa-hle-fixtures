import UIKit

final class MTMyListViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("my_list_screen_title", comment: "My list screen title")
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemRed
    }
}
