//
//  FruitBookViewController.swift
//  FruitSchool
//
//  Created by Presto on 2018. 9. 9..
//  Copyright © 2018년 YAPP. All rights reserved.
//

import UIKit
import FSPagerView
import GaugeKit
import EFCountingLabel
import SnapKit

class BookViewController: UIViewController {

    // MARK: - Properties
    private let cellIdentifier = "bookCell"
    
    lazy private var chapterRecord = ChapterRecord.fetch()
    
    lazy private var userRecord: UserRecord! = UserRecord.fetch().first
    
    var currentIndex: Int {
        return pagerView.currentIndex
    }
    
    lazy private var percentLabel: EFCountingLabel! = {
        let label = EFCountingLabel()
        label.format = "%d%%"
        label.method = .easeInOut
        label.textColor = .main
        label.font = UIFont.systemFont(ofSize: 12)
        view.addSubview(label)
        return label
    }()
    
    lazy private var descriptionLabel: UILabel! = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .main
        view.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.centerX.equalTo(view.snp.centerX)
            maker.top.equalTo(percentLabel.snp.bottom).offset(8)
        }
        return label
    }()
    
    lazy private var promotionReviewButton: UIButton! = {
        let button = UIButton(type: .system)
        button.setTitle("승급 심사", for: [])
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        button.clipsToBounds = true
        button.layer.borderColor = UIColor.main.cgColor
        button.layer.borderWidth = 2
        button.addTarget(self, action: #selector(touchUpPromotionReviewButton(_:)), for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.top.equalTo(percentLabel.snp.bottom).offset(40)
            maker.width.equalTo(view.snp.width).multipliedBy(0.6)
            maker.centerX.equalTo(view.snp.centerX)
            maker.height.equalTo(40)
        }
        button.layer.cornerRadius = 20
        return button
    }()
    
    lazy private var pageControl: FSPageControl = {
        let pageControl = FSPageControl(frame: .zero)
        pageControl.currentPage = 0
        pageControl.numberOfPages = 3
        pageControl.setFillColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.19), for: .normal)
        pageControl.setFillColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.68), for: .selected)
        pagerView.addSubview(pageControl)
        pageControl.snp.makeConstraints { maker in
            maker.bottom.equalTo(pagerView.snp.bottom).offset(-8)
            maker.centerX.equalTo(view.snp.centerX)
            maker.height.equalTo(20)
        }
        return pageControl
    }()
    
    @IBOutlet private weak var pagerView: FSPagerView! {
        didSet {
            pagerView.register(UINib(nibName: "BookCell", bundle: nil), forCellWithReuseIdentifier: cellIdentifier)
            pagerView.transformer = FSPagerViewTransformer(type: .linear)
            pagerView.interitemSpacing = 6
            let width = UIScreen.main.bounds.width * 0.83
            pagerView.itemSize = CGSize(width: width, height: width * 398 / 312)
            pagerView.delegate = self
            pagerView.dataSource = self
        }
    }
    
    @IBOutlet weak var gaugeView: Gauge!
    
    // MARK: - View Controler Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        makeBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetViews()
    }
    
    private func makeBackButton() {
        let backBarButtonItem = UIBarButtonItem()
        backBarButtonItem.title = "교과서"
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: UIImageView(image: #imageLiteral(resourceName: "logo_noncircle")))
        navigationItem.backBarButtonItem = backBarButtonItem
    }
}
// MARK: - Button Touch Event
private extension BookViewController {
    // 승급심사 버튼을 누르면 승급심사 뷰컨트롤러로 넘어감
    @objc func touchUpPromotionReviewButton(_ sender: UIButton) {
        guard let next = UIViewController.instantiate(storyboard: "PromotionReview", identifier: PromotionReviewContainerViewController.classNameToString) as? PromotionReviewContainerViewController else { return }
        next.delegate = self
        next.grade = currentIndex
        present(next, animated: true, completion: nil)
    }
}
// MARK: - PromotionReviewContainerViewController Custom Delegate Implementation
extension BookViewController: PromotionReviewDelegate {
    // 승급심사 종료 후 교과서로 돌아왔을 때의 인터렉션 정의
    func didDismissPromotionReviewViewController(_ grade: Int) {
        let title: String
        if grade == 2 {
            title = "축하합니다!\n모든 승급심사를 통과했습니다."
        } else {
            title = "축하합니다!\n당신은 이제 \(Grade(rawValue: grade + 1)?.expression ?? "")입니다."
        }
        UIAlertController
            .alert(title: title, message: nil)
            .action(title: "확인", handler: { _ in
                self.resetViews()
            })
            .present(to: self)
    }
}

extension BookViewController: FSPagerViewDataSource {
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        guard let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "bookCell", at: index) as? BookCell else { return FSPagerViewCell() }
        let fruitsInBook = chapterRecord.filter { $0.grade == index }
        let passedFruitsInBook = fruitsInBook.filter { $0.isPassed }
        cell.setProperties(at: index, isPassed: fruitsInBook.count == passedFruitsInBook.count, isPassedCompletely: userRecord[index])
        return cell
    }
    
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return 3
    }
}

extension BookViewController: FSPagerViewDelegate {
    func pagerViewDidEndDecelerating(_ pagerView: FSPagerView) {
        resetViews()
    }
    
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        pagerView.deselectItem(at: index, animated: true)
        // 현재 등급과 교과서 등급을 비교하여 접근 제한
        let myGrade = UserRecord.fetch().first?.grade ?? 0
        if !(0...myGrade).contains(index) {
            UIAlertController.presentErrorAlert(to: self, error: "당신은 아직 \(Grade(rawValue: myGrade)?.expression ?? "")예요!")
            return
        }
        guard let next = UIViewController.instantiate(storyboard: "Chapter", identifier: ChapterViewController.classNameToString) as? ChapterViewController else { return }
        next.grade = index
        navigationController?.pushViewController(next, animated: true)
    }
}
// MARK: - Making Dynamic Views
private extension BookViewController {
    func resetViews() {
        let percent = accomplishment()
        changePageControlStatus()
        changeGaugeViewValue(percent)
        makePercentLabel(percent)
        changeDescriptionLabelText()
        decideIfShowingPromotionReviewButton(percent)
        pagerView.reloadData()
        view.layoutIfNeeded()
    }
    
    func changePageControlStatus() {
        pageControl.currentPage = pagerView.currentIndex
    }
    
    func changeGaugeViewValue(_ percent: CGFloat) {
        gaugeView.rate = percent
    }

    func makePercentLabel(_ percent: CGFloat) {
        percentLabel.countFromCurrentValueTo(percent * 100, withDuration: 0.2)
        //percentLabel.text = "\(Int(percent * 100))%"
        let leading = gaugeView.frame.origin.x
        if percent == 0 {
            percentLabel.snp.remakeConstraints { maker in
                maker.top.equalTo(gaugeView.snp.bottom).offset(6)
                maker.centerX.equalTo(gaugeView.snp.leading)
            }
        } else {
            percentLabel.snp.remakeConstraints { maker in
                maker.top.equalTo(gaugeView.snp.bottom).offset(6)
                maker.centerX.equalTo(gaugeView.snp.trailing)
                    .offset(leading - leading * percent)
                    .multipliedBy(percent)
            }
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    // 화면을 비어보이지 않게 하는 레이블 만들기
    func changeDescriptionLabelText() {
        descriptionLabel.text = descriptionLabelText()
    }
    // 승급심사 버튼 만들기
    func decideIfShowingPromotionReviewButton(_ percent: CGFloat) {
        let passesCurrentBook = UserRecord.fetch().first?[pagerView.currentIndex] ?? false
        if percent == 1 && !passesCurrentBook {
            promotionReviewButton.isHidden = false
        } else {
            promotionReviewButton.isHidden = true
        }
    }
}

private extension BookViewController {
    func accomplishment() -> CGFloat {
        let filtered = chapterRecord.filter("grade = %d", currentIndex)
        let count = filtered.count
        var passedCount = 0
        for element in filtered where element.isPassed {
            passedCount += 1
        }
        return CGFloat(passedCount) / CGFloat(count)
    }
    
    func descriptionLabelText() -> String? {
        guard let userInfo = UserRecord.fetch().first else { return nil }
        let userGrade = userInfo.grade
        switch accomplishment() {
        case 0 where userGrade == currentIndex:
            return "자, 지금부터 과일 카드를 모아볼까?"
        case 0 where userGrade < currentIndex:
            return "아직 당신에겐 수련이 필요하오."
        case 0.5:
            return "벌써 반이나 모았다고? 조금만 더 힘을 내게!"
        case 0..<0.5 where userGrade == 0, 0.5..<1 where userGrade == 0:
            return "훈장님이 되고싶개"
        case 0..<0.5 where userGrade == 1, 0.5..<1 where userGrade == 1:
            return "훈장이 되고 싶소"
        case 0..<0.5 where userGrade == 2, 0.5..<1 where userGrade == 2:
            return "나는 훈장이오 만렙이슈"
        case 1 where currentIndex == 0 && userInfo.passesDog:
            return "드디어 사람이 되었개! 서당개 인생은 이제 안녕."
        case 1 where currentIndex == 0 && !userInfo.passesDog:
            return "당신은 이제 학도가 되기에 충분하개!"
        case 1 where currentIndex == 1 && userInfo.passesStudent:
            return "나도 어디서 꿀리지 않는 과일인이 되었소."
        case 1 where currentIndex == 1 && !userInfo.passesStudent:
            return "나는 훈장님이 되러 떠나겠어!"
        case 1 where currentIndex == 2 && userInfo.passesBoss:
            return "과일학당 훈장이오. 무엇이든 물어보시오."
        case 1 where currentIndex == 2 && !userInfo.passesBoss:
            return "앞으로도 많이 업데이트 할 예정이니 아직 지우지 말아주세요!"
        default:
            return nil
        }
    }
}
