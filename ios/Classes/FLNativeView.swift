//
//  FLNativeView.swift
//  Pods
//
//  Created by Vladislav Smirnov on 17.07.25.
//

import Flutter
import UIKit
import AVKit
import AVFoundation
import os.log

// Синглтон менеджер плеера
class SkyPlayerManager {
    static let shared = SkyPlayerManager()
    var player: AVPlayer?

    private init() {}
}

class FLNativeView: NSObject, FlutterPlatformView {
    private let logger = OSLog(subsystem: "com.dadadadev.sky_player", category: "FLNativeView")

    private var _view: UIView
    private var playerViewController: AVPlayerViewController?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        super.init()
        createNativeView(view: _view, args: args)
    }

    func view() -> UIView {
        return _view
    }

    private func createNativeView(view _view: UIView, args: Any?) {
        os_log("Initting SkyPlayer resources", log: logger, type: .info)

        _view.backgroundColor = .black
        _view.clipsToBounds = true

        setupPlayerViewController(args: args)
    }

    private func setupPlayerViewController(args: Any?) {
        var urlString: String? = nil

        // Получаем url из args, если передан
        if let dict = args as? [String: Any], let urlArg = dict["url"] as? String {
            urlString = urlArg
        }

        // Инициализируем AVPlayer, если его ещё нет
        if SkyPlayerManager.shared.player == nil {
            guard let urlStr = urlString, let url = URL(string: urlStr) else {
                os_log("Invalid or missing URL for player", log: logger, type: .error)
                return
            }
            SkyPlayerManager.shared.player = AVPlayer(url: url)
        }

        let player = SkyPlayerManager.shared.player
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        playerViewController?.showsPlaybackControls = true
        playerViewController?.videoGravity = .resizeAspect

        if let playerView = playerViewController?.view {
            playerView.frame = _view.bounds
            playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            _view.addSubview(playerView)
        }

        // Если плеер уже был создан — не запускать заново автоматически
        // Если хочешь сразу запускать — раскомментируй следующую строку:
        // player?.play()
    }

    deinit {
        SkyPlayerManager.shared.player?.pause()
        SkyPlayerManager.shared.player = nil
        os_log("Disposing SkyPlayer resources", log: logger, type: .debug)
    }
}
