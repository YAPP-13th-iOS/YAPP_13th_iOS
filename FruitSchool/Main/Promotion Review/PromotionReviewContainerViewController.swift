//
//  PromotionReviewContainerViewController.swift
//  FruitSchool
//
//  Created by Presto on 08/10/2018.
//  Copyright © 2018 YAPP. All rights reserved.
//

import UIKit

protocol PromotionReviewDelegate: class {
    func didDismissPromotionReviewViewController()
}

class PromotionReviewContainerViewController: UIViewController {

    weak var delegate: PromotionReviewDelegate?
    var answers: [String] = [] {
        didSet {
            let filtered = answers.filter { !$0.isEmpty }
            DispatchQueue.main.async {
                if filtered.count == self.quizsCount {
                    UIView.animate(withDuration: 0.5) {
                        self.submitButton.alpha = 1
                    }
                } else {
                    UIView.animate(withDuration: 0.5) {
                        self.submitButton.alpha = 0
                    }
                }
            }
        }
    }
    var grade: Int = 0
    var quizs: [Quiz] = []
    var quizsCount: Int {
        return quizs.count
    }
    var pageViewController: UIPageViewController!
    @IBOutlet weak var submitButton: QuizButton!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var containerViewCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.addTarget(self, action: #selector(didTouchUpSubmitButton(_:)), for: .touchUpInside)
        submitButton.layer.cornerRadius = 15
        submitButton.backgroundColor = .white
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        submitButton.setTitleColor(.black, for: [])
        IndicatorView.shared.showIndicator(message: "Loading...")
        API.requestExam(by: grade) { response, statusCode, error in
            IndicatorView.shared.hideIndicator()
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    UIAlertController.presentErrorAlert(to: self, error: error.localizedDescription, handler: {
                        self?.dismiss(animated: true, completion: nil)
                    })
                }
                return
            }
            guard let response = response else { return }
            for data in response.data {
                let quiz = Quiz(title: data.title, correctAnswer: data.correctAnswer, answers: [[data.correctAnswer], data.incorrectAnswers].flatMap { $0 }.shuffled())
                self.quizs.append(quiz)
                print(quiz.correctAnswer, quiz.answers)
            }
            self.answers = Array(repeating: "", count: self.quizsCount)
            DispatchQueue.main.async {
                self.setUp()
                self.containerView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    self.containerView.transform = CGAffineTransform.identity
                }, completion: { _ in
                    UIView.animate(withDuration: 0.3, animations: {
                        self.pageControl.alpha = 1
                    })
                })
            }
        }
    }
    
    func setUp() {
        containerView.layer.cornerRadius = 15
        containerView.layer.masksToBounds = true
        containerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPanContentView(_:))))
        pageControl.numberOfPages = quizs.count
        self.pageViewController = childViewControllers.first as? UIPageViewController
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.setViewControllers([makeContentViewController(at: 0) ?? UIViewController()], direction: .forward, animated: true, completion: nil)
    }
    
    @objc func didPanContentView(_ gesture: UIPanGestureRecognizer) {
        let velocityY = gesture.translation(in: view).y
        switch gesture.state {
        case .changed:
            if velocityY >= 0 {
                containerViewCenterYConstraint.constant = velocityY
            }
        case .ended:
            if gesture.velocity(in: view).y > 1000 {
                containerViewCenterYConstraint.constant = view.bounds.height
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    self.dismiss(animated: true, completion: nil)
                })
                return
            } else {
                containerViewCenterYConstraint.constant = 0
                UIView.animate(withDuration: 0.2) {
                    self.view.layoutIfNeeded()
                }
            }
        default:
            break
        }
    }
    
    @objc func didTouchUpSubmitButton(_ sender: UIButton) {
        executeScoring()
    }
    
    func makeContentViewController(at index: Int) -> PromotionReviewContentViewController? {
        guard let controller = UIViewController.instantiate(storyboard: "PromotionReview", identifier: PromotionReviewContentViewController.classNameToString) as? PromotionReviewContentViewController else { return nil }
        controller.pageIndex = index
        guard let quizView = UIView.instantiateFromXib(xibName: "QuizView") as? QuizView else { return nil }
        let quiz = quizs[index]
        quizView.numberLabel.text = "문제 \(index + 1)"
        quizView.titleLabel.text = quiz.title
        for buttonIndex in 0..<4 {
            quizView[buttonIndex].setTitle(quiz.answers[buttonIndex], for: [])
        }
        if let selectedIndex = quizs[index].answers.index(of: answers[index]) {
            quizView[selectedIndex].backgroundColor = #colorLiteral(red: 0.8666666667, green: 0.8666666667, blue: 0.8666666667, alpha: 1)
        }
        quizView.delegate = self
        controller.quizView = quizView
        return controller
    }
}

extension PromotionReviewContainerViewController {
    private func executeScoring() {
        var score = 0
        guard let alertView = UIView.instantiateFromXib(xibName: "AlertView") as? AlertView else { return }
        alertView.titleLabel.text = "승급 심사"
        alertView.messageLabel.text = "제출?"
        alertView.positiveHandler = { [weak self] in
            guard let `self` = self else { return }
            for index in 0..<self.quizsCount {
                let quiz = self.quizs[index]
                let answer = self.answers[index]
                if quiz.correctAnswer == answer {
                    score += 1
                }
            }
            guard let resultView = UIView.instantiateFromXib(xibName: "ResultView") as? ResultView else { return }
            resultView.frame = self.view.bounds
            resultView.titleLabel.text = "결과"
            let message = "\(score) / \(self.quizsCount)"
            let percent = Double(score) / Double(self.quizsCount)
            if percent > 0.7 {
                resultView.descriptionLabel.text = message + "\n통과"
                resultView.handler = {
                    guard let userRecord = UserRecord.fetch().first else { return }
                    let myGrade = userRecord.grade
                    if myGrade != 2 {
                        UserRecord.update(userRecord, keyValue: ["grade": myGrade + 1])
                        switch self.grade {
                        case 0:
                            UserRecord.update(userRecord, keyValue: ["passesDog": true])
                        case 1:
                            UserRecord.update(userRecord, keyValue: ["passesStudent": true])
                        case 2:
                            UserRecord.update(userRecord, keyValue: ["passesBoss": true])
                        default:
                            break
                        }
                    }
                    self.dismiss(animated: true, completion: {
                        self.delegate?.didDismissPromotionReviewViewController()
                    })
                }
            } else {
                resultView.descriptionLabel.text = message + "\n불통"
                resultView.handler = {
                    self.dismiss(animated: true, completion: nil)
                }
            }
            self.view.addSubview(resultView)
        }
        alertView.frame = view.bounds
        view.addSubview(alertView)
    }
}

extension PromotionReviewContainerViewController: QuizViewDelegate {
    func didTouchUpQuizButtons(_ sender: UIButton) {
        let currentPageIndex = pageControl.currentPage
        guard let quizView = (pageViewController.viewControllers?.first as? PromotionReviewContentViewController)?.quizView else { return }
        guard let title = sender.titleLabel?.text else { return }
        self.answers[currentPageIndex] = title
        for index in 0..<4 {
            UIView.animate(withDuration: 0.2) {
                quizView[index].backgroundColor = #colorLiteral(red: 0.9803921569, green: 0.9803921569, blue: 0.9803921569, alpha: 1)
            }
        }
        if let selectedIndex = quizs[currentPageIndex].answers.index(of: title) {
            UIView.animate(withDuration: 0.2) {
                quizView[selectedIndex].backgroundColor = #colorLiteral(red: 0.8666666667, green: 0.8666666667, blue: 0.8666666667, alpha: 1)
            }
        }
    }
    
    func didTouchUpCancelButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension PromotionReviewContainerViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? PromotionReviewContentViewController else { return nil }
        guard let index = viewController.pageIndex else { return nil }
        let previousIndex = index - 1
        if previousIndex < 0 {
            return nil
        }
        return makeContentViewController(at: previousIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? PromotionReviewContentViewController else { return nil }
        guard let index = viewController.pageIndex else { return nil }
        let nextIndex = index + 1
        if nextIndex >= quizs.count {
            return nil
        }
        return makeContentViewController(at: nextIndex)
    }
}

extension PromotionReviewContainerViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let pageContentViewController = pageViewController.viewControllers?.first as? PromotionReviewContentViewController else { return }
        pageControl.currentPage = pageContentViewController.pageIndex
    }
}
