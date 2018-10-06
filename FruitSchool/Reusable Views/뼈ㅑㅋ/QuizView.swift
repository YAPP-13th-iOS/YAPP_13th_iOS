//
//  QuizView.swift
//  FruitSchool
//
//  Created by Presto on 2018. 9. 19..
//  Copyright © 2018년 YAPP. All rights reserved.
//

import UIKit

protocol QuizViewDelegate: class {
    func didTouchUpQuizButtons(_ sender: UIButton)
}

class QuizView: UIView {
    
    weak var delegate: QuizViewDelegate?
    var buttons: [UIButton] {
        return [answer1Button, answer2Button, answer3Button, answer4Button]
    }
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var answer1Button: QuizButton!
    @IBOutlet weak var answer2Button: QuizButton!
    @IBOutlet weak var answer3Button: QuizButton!
    @IBOutlet weak var answer4Button: QuizButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderWidth = 3
        layer.borderColor = UIColor.black.cgColor
        buttons.forEach { button in
            button.addTarget(self, action: #selector(didTouchUpQuizButtons(_:)), for: .touchUpInside)
        }
    }

    subscript(_ index: Int) -> UIButton {
        if !(0...3).contains(index) {
            fatalError("IndexOutOfBoundsException")
        }
        switch index {
        case 0:
            return answer1Button
        case 1:
            return answer2Button
        case 2:
            return answer3Button
        case 3:
            return answer4Button
        default:
            return UIButton()
        }
    }
    
    @objc func didTouchUpQuizButtons(_ sender: UIButton) {
        for button in buttons {
            button.isSelected = false
        }
        delegate?.didTouchUpQuizButtons(sender)
    }
}
