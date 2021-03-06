//
//  ViewController.swift
//  ReCaptcha
//
//  Created by Flávio Caetano on 03/22/17.
//  Copyright © 2017 ReCaptcha. All rights reserved.
//

import ReCaptcha
import Result
import RxCocoa
import RxSwift
import UIKit


class ViewController: UIViewController {
    private struct Constants {
        static let webViewTag = 123
    }

    private var recaptcha: ReCaptcha!
    private var disposeBag = DisposeBag()
    private let isLoading = Variable<Bool>(true)


    @IBOutlet weak var popView: UIView!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var closeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.popView.isHidden = true
        setupReCaptcha(endpoint: .default)
    }
    
    @IBAction func didPressSegmentedControl(_ sender: UISegmentedControl) {
        label.text = ""
        switch sender.selectedSegmentIndex {
        case 0: setupReCaptcha(endpoint: .default)
        case 1: setupReCaptcha(endpoint: .alternate)
        default: assertionFailure("invalid index")
        }
    }

    @IBAction private func didPressButton(button: UIButton) {
        disposeBag = DisposeBag()

        let validate = recaptcha.rx.validate(on: popView)
            .debug("validate")
            .share()
        
        validate
            .map { _ in false }
            .startWith(true)
            .bind(to: isLoading)
            .disposed(by: disposeBag)

        closeButton.rx.tap.map { _ in false }
            .bind(to: isLoading)
            .disposed(by: disposeBag)
        closeButton.rx.tap.asDriver().drive(onNext: { [weak self] in
            self?.view.viewWithTag(Constants.webViewTag)?.removeFromSuperview()
            self?.setupReCaptcha(endpoint: .default)
        }).disposed(by: disposeBag)

        isLoading.asObservable()
            .bind(to: spinner.rx.isAnimating)
            .disposed(by: disposeBag)

        let isEnabled = isLoading.asObservable()
            .map { !$0 }
            .catchErrorJustReturn(false)
            .share(replay: 1)
        
        isEnabled
            .bind(to: popView.rx.isHidden)
            .disposed(by: disposeBag)

        isEnabled
            .bind(to: button.rx.isEnabled)
            .disposed(by: disposeBag)

        isEnabled
            .bind(to: segmentedControl.rx.isEnabled)
            .disposed(by: disposeBag)

        validate
            .map { [weak self] _ in
                self?.view.viewWithTag(Constants.webViewTag)
            }
            .subscribe(onNext: { subview in
                subview?.removeFromSuperview()
            })
            .disposed(by: disposeBag)

        validate
            .map {
                try $0.dematerialize()
            }
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)
    }

    private func setupReCaptcha(endpoint: ReCaptcha.Endpoint) {
        // swiftlint:disable:next force_try
        recaptcha = try! ReCaptcha(endpoint: endpoint)

        recaptcha.configureWebView { [weak self] webview in
            webview.frame = self?.popView.bounds ?? CGRect.zero
            webview.tag = Constants.webViewTag
        }
    }
}
