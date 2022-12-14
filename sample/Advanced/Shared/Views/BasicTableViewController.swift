//
//  Copyright © 2017년 INKA ENTWORKS INC. All rights reserved.
//
//  PallyCon Team (http://www.pallycon.com)
//
//  BasicTableViewController class is main view in sample.
//


import UIKit
import AVFoundation
import AVKit
#if os(iOS)
     import PallyConFPSSDK
     import GoogleCast
#else
     import PallyConFPSSDKTV
#endif

import MediaPlayer

class BasicTableViewController: UITableViewController {
     // MARK: UIViewController
     static let presentPlayerViewControllerSegueIdentifier = "PresentPlayerViewControllerSegueIdentifier"
     static let fpsPlayerViewController = "fpsPlayerViewController"
     var isShowFailedAlertMessage = false
     
     fileprivate var playerViewController: AVPlayerViewController?
     var avPlayer: AVPlayer?
     
     var registeredObserver = [String:BasicTableViewCell]()
     
     override func viewDidLoad() {
          super.viewDidLoad()
          
          // Set BasicListTableViewController as the delegate for FPSPlaybackManager to recieve playback information
          FPSPlaybackManager.sharedManager.delegate = self
          #if os(iOS)
               // Set ChromeCast Button
               let castButton: GCKUICastButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
               castButton.tintColor = UIColor.black
               self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: castButton)
          #endif
     }
     
     override func viewWillAppear(_ animated: Bool) {
          super.viewWillAppear(animated)
          
          if playerViewController != nil {
               // The view reappeared as a results of dismissing an AVPlayerViewController.
               // Perform cleanup.
               FPSPlaybackManager.sharedManager.setFpsContentForPlayback(nil)
               playerViewController?.player = nil
               playerViewController = nil
          }
     }
     
     // MARK: - Table view data source
     override func numberOfSections(in tableView: UITableView) -> Int {
          #if os(iOS)
               return 2
          #elseif os(tvOS)
               return 1
          #endif
     }
     
     override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
          if section == 0 {
               return "Streaming"
          } else {
               return "Download"
          }
     }
     
     override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          return FPSListManager.sharedManager.numberOfContent(section: section)
     }
     
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          let cell = tableView.dequeueReusableCell(withIdentifier: BasicTableViewCell.reuseIdentifier, for: indexPath) as! BasicTableViewCell
          
          if indexPath.section == 0 {
               cell.accessoryType = .none
          }
          
          let fpsContent = FPSListManager.sharedManager.fpsContent(section: indexPath.section, index: indexPath.row)
          
          if let basicCell = registeredObserver[fpsContent.contentId] {
               basicCell.removeObservers()
          }
          
          cell.fpsContent = fpsContent
          cell.delegate = self
          cell.addObservers()
          registeredObserver[fpsContent.contentId] = cell
          
          return cell
     }
     
     override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
          #if os(iOS)
               return 54
          #elseif os(tvOS)
               return 70
          #endif
     }
     
     override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
          guard let cell = tableView.cellForRow(at: indexPath) as? BasicTableViewCell,
               let fpsContent = cell.fpsContent else {
                    return
          }
          
          #if os(iOS)
               if #available(iOS 11.0, *) {
                    let downloadState = PallyConSDKManager.sharedManager.downloadState(for: fpsContent)
                    
                    let alertAction: UIAlertAction
                    var alertAction2: UIAlertAction?
                    
                    switch downloadState {
                    case .pause:
                         alertAction = UIAlertAction(title: "Download", style: .default) { _ in
                              // you have to connect on the online for the content download.
                              if (Recharbility.isConnectedToNetwork()) {
                                   PallyConSDKManager.sharedManager.downloadStream(for: fpsContent)
                                   
                              } else {
                                   let alert = UIAlertController(title: "Download Failed", message: "network connect failed", preferredStyle: .alert)
                                   alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { Void in
                                        self.tableView.reloadData()
                                   }))
                                   UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                              }
                         }
                         
                         alertAction2 = UIAlertAction(title: "Cancel", style: .default) { _ in
                              PallyConSDKManager.sharedManager.cancelDownload(for: fpsContent)
                         }
                    case .notDownloaded:
                         alertAction = UIAlertAction(title: "Download", style: .default) { _ in
                              // you have to connect on the online for the content download.
                              if (Recharbility.isConnectedToNetwork()) {
                                   PallyConSDKManager.sharedManager.downloadStream(for: fpsContent)
                                   
                              } else {
                                   let alert = UIAlertController(title: "Download Failed", message: "network connect failed", preferredStyle: .alert)
                                   alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { Void in
                                        self.tableView.reloadData()
                                   }))
                                   UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                              }
                         }
                    case .downloading:
                         alertAction = UIAlertAction(title: "Pause", style: .default) { _ in
                              PallyConSDKManager.sharedManager.pauseDownload(for: fpsContent)
                         }
                    case .downloaded:
                         alertAction = UIAlertAction(title: "Delete", style: .default) { _ in
                              PallyConSDKManager.sharedManager.deleteFPSContent(for: fpsContent)
                         }
                    }
                    
                    let alertRemoveLicenseAction = UIAlertAction(title: "Remove License", style: .default) { _ in
                         do {
                              try PallyConSDKManager.sharedManager.pallyConFPSSDK?.removeLicense(contentId: fpsContent.contentId)
                         } catch {
                              print("Error: \(error). Failed remove license")
                         }
                    }
                    
                    let alertExistLicenseAction = UIAlertAction(title: "Exsit License", style: .default) { _ in
                         do {
                              var message: String
                              let expireDate = try PallyConSDKManager.sharedManager.pallyConFPSSDK?.getOfflineLicenseExpireDate(contentId: fpsContent.contentId)
                              if expireDate == String() {
                                   message = "No Offline License"
                              } else {
                                   message = "Expire Date : " + expireDate!
                              }
                              let alert = UIAlertController(title: "Offline License", message: message, preferredStyle: .alert)
                              alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { Void in
                                   self.tableView.reloadData()
                              }))
                              UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                         } catch {
                              print("Error: \(error). Failed remove license")
                         }
                    }
                    
                    let alertHLSSizeAction = UIAlertAction(title: "HLS Size", style: .default) { _ in
                         do {
                              let urlString = fpsContent.urlAsset.url.absoluteString
                              let m3u8Size = PallyConHLSInfo(urlString)
                              try m3u8Size.extractPallyConHLSInfo()
                              let resolution = m3u8Size.getVideoResolutionSize()
                              let bitrate = m3u8Size.getVideoBitrateSiz()

                              let message = resolution + "\n ------------------ \n" + bitrate
                              let alert = UIAlertController(title: "m3u8 Size", message: message, preferredStyle: .alert)
                              alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { Void in
                                   self.tableView.reloadData()
                              }))
                              UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                         } catch {
                              print("Error: \(error). Failed remove license")
                         }
                    }
                    
                    let alertController = UIAlertController(title: fpsContent.contentName, message: "Select from the following options:", preferredStyle: .actionSheet)
                    alertController.addAction(alertAction)
                    alertController.addAction(alertExistLicenseAction)
                    alertController.addAction(alertHLSSizeAction)
                    if let action = alertAction2 {
                         alertController.addAction(action)
                    }
                    if downloadState == .downloaded {
                         alertController.addAction(alertRemoveLicenseAction)
                    }
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                    
                    if UIDevice.current.userInterfaceIdiom == .pad {
                         guard let popoverController = alertController.popoverPresentationController else {
                              return
                         }
                         
                         popoverController.sourceView = cell
                         popoverController.sourceRect = cell.bounds
                    }
                    
                    present(alertController, animated: true, completion: nil)
               }
          #endif
     }
     
     override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
          #if os(iOS)
               // When you want to play through chrome cast.
               if let castSession = GCKCastContext.sharedInstance().sessionManager.currentCastSession,
                    let cell = tableView.cellForRow(at: indexPath) as? BasicTableViewCell,
                    let fpsContent = cell.fpsContent,
                    !fpsContent.chromcastPlayUrlPath.isEmpty {
                    
                    let mediaInfo = self.buildMediaInformation(fpsContent: fpsContent)
                    castSession.remoteMediaClient?.loadMedia(mediaInfo)
                    self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                    if let isEnabled = appDelegate?.castControlBarsEnabled(), isEnabled {
                         appDelegate?.setCastControlBarsEnabled(notificationsEnabled: false)
                    }
                    GCKCastContext.sharedInstance().presentDefaultExpandedMediaControls()
               } else {
                    self.performSegue(withIdentifier: BasicTableViewController.presentPlayerViewControllerSegueIdentifier, sender: self)
               }
          #else
               self.performSegue(withIdentifier: BasicTableViewController.presentPlayerViewControllerSegueIdentifier, sender: self)
          #endif
     }
     
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
          super.prepare(for: segue, sender: sender)
          
          if segue.identifier == BasicTableViewController.presentPlayerViewControllerSegueIdentifier {
               guard let indexPath = self.tableView.indexPathForSelectedRow,
                    let cell = tableView.cellForRow(at: indexPath) as? BasicTableViewCell,
                    let playerViewController = segue.destination as? AVPlayerViewController,
                    var fpsContent = cell.fpsContent else {
                         return
               }
               
               if let contentURL = fpsContent.urlAsset.url.absoluteURL.scheme, contentURL.hasPrefix("http")  {
                    // you have to connect on the online for the streaming content play.
                    if (Recharbility.isConnectedToNetwork() == false) {
                         let alert = UIAlertController(title: "Play Failed", message: "network connect failed", preferredStyle: .alert)
                         alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { Void in
                              self.tableView.reloadData()
                         }))
                         UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                         return
                    }
               } else {
                    // this source is process when local file playing.
                    // AVUrlAsset is initialize when play the fps local contents.
                    fpsContent.urlAsset = AVURLAsset(url: fpsContent.urlAsset.url)
               }
               
               // Grab a reference for the destinationViewController to use in later delegate callbacks from FPSPlaybackManager.
               self.playerViewController = playerViewController
               
               if fpsContent.token.count > 0 {
                    // Prepare a content info to playback into PallyConFPSSDK. for Token
                    PallyConSDKManager.sharedManager.pallyConFPSSDK?.prepare(urlAsset: fpsContent.urlAsset, token: fpsContent.token)
                    // or 
                    //PallyConSDKManager.sharedManager.pallyConFPSSDK?.prepare(urlAsset: fpsContent.urlAsset, userId: pallyConUserId, contentId: fpsContent.contentId, token: fpsContent.token, liveKeyRotation: fpsContent.liveKeyRotation)
               } else {
                    // Prepare a content info to playback into PallyConFPSSDK. for Gateway
                    PallyConSDKManager.sharedManager.pallyConFPSSDK?.prepare(urlAsset: fpsContent.urlAsset, userId: pallyConUserId, contentId: fpsContent.contentId, optionalId: fpsContent.optionalId, liveKeyRotation: fpsContent.liveKeyRotation)
               }
               
               // Load the new FpsContent to playback into FPSPlaybackManager.
               FPSPlaybackManager.sharedManager.setFpsContentForPlayback(fpsContent)
          }
     }
}

/**
 Extend `BasicTableViewController` to conform to the `BasicTableViewCellDelegate` protocol.
 */
extension BasicTableViewController: BasicTableViewCellDelegate {
     func basicListTableViewCell(_ cell: BasicTableViewCell, downloadStateDidChange newState: FPSContent.DownloadState) {
          guard let indexPath = tableView.indexPath(for: cell) else {
               return
          }
          
          tableView.reloadRows(at: [indexPath], with: .automatic)
     }
     
     func basicListTableViewCell(_ cell: BasicTableViewCell, avPlayerAssetDidChange asset: AVURLAsset) {
          guard let indexPath = tableView.indexPath(for: cell) else {
               return
          }
          
          FPSListManager.sharedManager.setUrlAsset(for: indexPath.section, index: indexPath.row, urlAsset: asset)
          tableView.reloadRows(at: [indexPath], with: .automatic)
     }
}

/**
 Extend `BasicTableViewController` to conform to the `FPSPlaybackDelegate` protocol.
 */
extension BasicTableViewController: FPSPlaybackDelegate {
     
     func playbackManager(_ playbackManager: FPSPlaybackManager, playerReadyToPlay player: AVPlayer) {
          player.play()
     }
     
     func playbackManager(_ playbackManager: FPSPlaybackManager, playerCurrentItemDidChange player: AVPlayer) {
          guard let playerViewController = playerViewController , player.currentItem != nil else { return }
          
          player.usesExternalPlaybackWhileExternalScreenIsActive = true
          playerViewController.player = player
     }
     
     func playbackManager(_ playbackManager: FPSPlaybackManager, playerFail player: AVPlayer, fpsContent: FPSContent?, error: Error?) {
          guard let playerViewController = playerViewController , player.currentItem != nil else { return }
          
          var message = ""
          if error != nil {
               print("Error: \(error!)\n Could play the fps content")
               
               let nsErr: NSError = error! as NSError
               if let underlyingError = nsErr.userInfo[NSUnderlyingErrorKey] as? NSError, underlyingError.domain == NSOSStatusErrorDomain {
                    /// underlyingError.code == -42799 : This error code is returned when a security update is issued and the existing persistent key format is no loger supported. In this case, the application must request a new persistent key from server.
                    /// underlyingError.code == -42800 : This error code is returned when persistent key is expired.
                    switch underlyingError.code {
                    case -42800:
                         message = "license is expired"
                    case -42799:
                         if fpsContent != nil {
                              let pallyConFpsSdk = PallyConSDKManager.sharedManager.pallyConFPSSDK
                              do {
                                   try pallyConFpsSdk?.removeLicense(contentId: fpsContent!.contentId)
                              } catch {
                                   print("Error: \(error). Failed remove license")
                              }
                         }
                         message = "you have to re-try acquire license"
                    default:
                         break
                    }
               }
          }
          
          
          let alert = UIAlertController(title: "Play Failed", message: message, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { Void in
               playerViewController.dismiss(animated: true, completion: nil)
               self.isShowFailedAlertMessage = false
          }))
          
          if !isShowFailedAlertMessage {
               playerViewController.present(alert, animated: true, completion: nil)
               isShowFailedAlertMessage = true
          }
     }
}

/**
 Extend `BasicTableViewController` to conform for play the chromcast.
 */
#if os(iOS)
     extension BasicTableViewController {
          // Get mediaInfo for play the chromcast
          func buildMediaInformation(fpsContent: FPSContent) -> GCKMediaInformation {
               let metadata = GCKMediaMetadata(metadataType: .movie)
               metadata.setString(fpsContent.contentName, forKey: kGCKMetadataKeyTitle)
               metadata.setString(fpsContent.chromcastPlayUrlPath, forKey: "posterUrl")
               
               var customData: Any?
               
               if fpsContent.token.count > 0 {
                    // the getting customdata used in chromcast. for Token
                    customData = PallyConSDKManager.sharedManager.pallyConFPSSDK?.getCustomDataForChromcast(token: fpsContent.token)
               } else {
                    // the getting customdata used in chromcast. for Gateway
                    customData = try? PallyConSDKManager.sharedManager.pallyConFPSSDK?.getCustomDataForChromcast(userId: pallyConUserId, contentId: fpsContent.contentId, optionalId: fpsContent.optionalId) as Any
               }
               
               let mediaInfo = GCKMediaInformation(contentID: fpsContent.chromcastPlayUrlPath,
                                                   streamType: GCKMediaStreamType.buffered,
                                                   contentType: "application/dash+xml",
                                                   metadata: metadata,
                                                   streamDuration: 0.0,
                                                   mediaTracks: nil,
                                                   textTrackStyle: nil,
                                                   customData: customData)
               return mediaInfo
          }
     }
#endif
