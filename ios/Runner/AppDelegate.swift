import Flutter
import UIKit
import Vision
import ImageIO
import PhotosUI
import Photos
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, PHPickerViewControllerDelegate {
  private var pickedAssetIds: [String: String] = [:]
  private var pickerLimit = 10
  private var pickerResult: FlutterResult?
  private var localVisionChannel: FlutterMethodChannel?
  private let imageQueue = DispatchQueue(label: "local.screenshot.processing", qos: .userInitiated)

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "screenshot_cehennemi/local_vision",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    localVisionChannel = channel
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "selectedAssetId":
        let path = (call.arguments as? [String: Any])?["path"] as? String ?? ""
        result(self.pickedAssetIds.removeValue(forKey: path))
      case "googleCallbackReady":
        let expected = (call.arguments as? [String: Any])?["scheme"] as? String ?? ""
        let entries = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? []
        let schemes = entries.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        result(!expected.isEmpty && schemes.contains(expected))
      case "cleanPickerCache":
        guard self.pickerResult == nil else { result(FlutterError(code: "picker_busy", message: nil, details: nil)); return }
        self.imageQueue.async {
          do { if FileManager.default.fileExists(atPath: Self.selectedDirectory.path) { try FileManager.default.removeItem(at: Self.selectedDirectory) }; DispatchQueue.main.async { result(nil) } }
          catch { DispatchQueue.main.async { result(FlutterError(code: "cache_cleanup_failed", message: nil, details: nil)) } }
        }
      case "pickImages":
        guard self.pickerResult == nil else { result(FlutterError(code: "picker_busy", message: nil, details: nil)); return }
        let root = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }.first(where: { $0.isKeyWindow })?.rootViewController
        guard var presenter = root else { result(FlutterError(code: "picker_unavailable", message: nil, details: nil)); return }
        while let presented = presenter.presentedViewController { presenter = presented }
        self.pickedAssetIds.removeAll()
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        configuration.filter = .images
        self.pickerLimit = min(50, max(1, (call.arguments as? [String: Any])?["limit"] as? Int ?? 10))
        configuration.selectionLimit = self.pickerLimit
        configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.pickerResult = result
        presenter.present(picker, animated: true)
      case "normalizeImage":
        guard let arguments = call.arguments as? [String: Any], let path = arguments["path"] as? String, let url = Self.sandboxURL(path) else {
          result(FlutterError(code: "invalid_local_image", message: nil, details: nil)); return
        }
        self.imageQueue.async {
          do {
            let source = try Self.boundedSource(url)
            let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
            let width = (props?[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue ?? 0
            let height = (props?[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue ?? 0
            let scale = min(1.0, min(1600.0 / width, 2400.0 / height))
            let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
              kCGImageSourceCreateThumbnailWithTransform: true, kCGImageSourceShouldCacheImmediately: true,
              kCGImageSourceThumbnailMaxPixelSize: Int(ceil(max(width, height) * scale))]
            guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
                  let jpeg = UIImage(cgImage: image).jpegData(compressionQuality: 0.9), jpeg.count <= 8 * 1024 * 1024 else { throw CocoaError(.fileReadCorruptFile) }
            DispatchQueue.main.async { result(FlutterStandardTypedData(bytes: jpeg)) }
          } catch { DispatchQueue.main.async { result(FlutterError(code: "invalid_local_image", message: nil, details: nil)) } }
        }
      case "recognizeText":
        guard let arguments = call.arguments as? [String: Any],
              let path = arguments["path"] as? String,
              let url = Self.sandboxURL(path) else {
          result(FlutterError(code: "invalid_local_image", message: nil, details: nil))
          return
        }
        self.imageQueue.async {
          do {
            _ = try Self.boundedSource(url)
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            let supported = try request.supportedRecognitionLanguages()
            request.recognitionLanguages = ["tr-TR", "en-US"].filter { supported.contains($0) }
            if #available(iOS 16.0, *) { request.automaticallyDetectsLanguage = true }
            try VNImageRequestHandler(url: url, options: [:]).perform([request])
            let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            DispatchQueue.main.async { result(text) }
          } catch {
            // Never log OCR text, file paths, identifiers or native error details.
            DispatchQueue.main.async {
              result(FlutterError(code: "local_ocr_failed", message: nil, details: nil))
            }
          }
        }
      case "protectFile":
        guard let path = (call.arguments as? [String: Any])?["path"] as? String, let url = Self.sandboxURL(path) else {
          result(FlutterError(code: "invalid_storage", message: nil, details: nil))
          return
        }
        do {
          try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
          result(nil)
        } catch {
          result(FlutterError(code: "storage_protection_failed", message: nil, details: nil))
        }
      case "protectStorage":
        guard let arguments = call.arguments as? [String: Any], let paths = arguments["paths"] as? [String] else {
          result(FlutterError(code: "invalid_storage", message: nil, details: nil))
          return
        }
        do {
          for path in paths {
            guard var url = Self.sandboxURL(path) else { throw CocoaError(.fileWriteNoPermission) }
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try url.setResourceValues(values)
            // The Documents directory holds the SQLite DB: .completeUnlessOpen keeps open handles
            // writable if the device locks mid-sync. Image directories stay .complete.
            let documents = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "").resolvingSymlinksInPath().path
            let protection: FileProtectionType = url.path == documents ? .completeUnlessOpen : .complete
            try FileManager.default.setAttributes([.protectionKey: protection], ofItemAtPath: url.path)
            if let children = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isSymbolicLinkKey], options: [.skipsPackageDescendants]) {
              for case let child as URL in children {
                if try child.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true { children.skipDescendants(); continue }
                guard let safeChild = Self.sandboxURL(child.path) else { throw CocoaError(.fileWriteNoPermission) }
                try FileManager.default.setAttributes([.protectionKey: protection], ofItemAtPath: safeChild.path)
              }
            }
          }
          result(nil)
        } catch {
          result(FlutterError(code: "storage_protection_failed", message: nil, details: nil))
        }
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  private static var selectedDirectory: URL { URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("selected_imports", isDirectory: true) }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    guard let pending = pickerResult else { return }
    if results.isEmpty { pickerResult = nil; pending([]); return }
    let group = DispatchGroup()
    let lock = NSLock()
    var paths: [String] = []
    var assetIds: [String: String] = [:]
    for selected in results.prefix(pickerLimit) {
      group.enter()
      selected.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, _ in
        var path = ""
        defer { lock.lock(); paths.append(path); if !path.isEmpty, let id = selected.assetIdentifier { assetIds[path] = id }; lock.unlock(); group.leave() }
        guard let url = url else { return }
        do {
          _ = try Self.boundedSource(url) // Check encoded size, MIME and dimensions BEFORE decoding.
          var directory = Self.selectedDirectory
          try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
          var values = URLResourceValues(); values.isExcludedFromBackup = true
          try directory.setResourceValues(values)
          let target = directory.appendingPathComponent(UUID().uuidString + ".source")
          try FileManager.default.copyItem(at: url, to: target)
          try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: target.path)
          path = target.path
        } catch { /* No identifiers, file paths or native errors are logged. */ }
      }
    }
    group.notify(queue: .main) { self.pickedAssetIds = assetIds; self.pickerResult = nil; pending(paths) }
  }

  private static func boundedSource(_ url: URL) throws -> CGImageSource {
    let info = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
    guard info.isRegularFile == true, let size = info.fileSize, size > 0, size <= 20 * 1024 * 1024,
          let source = CGImageSourceCreateWithURL(url as CFURL, nil), CGImageSourceGetCount(source) == 1,
          let type = CGImageSourceGetType(source) as String?, ["public.png", "public.jpeg", "public.heic", "public.heif"].contains(type),
          let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = (props[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
          let height = (props[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
          width > 0, height > 0, width <= 80000000 / height else { throw CocoaError(.fileReadCorruptFile) }
    return source
  }

  private static func sandboxURL(_ path: String) -> URL? {
    let url = URL(fileURLWithPath: path).resolvingSymlinksInPath()
    let home = URL(fileURLWithPath: NSHomeDirectory()).resolvingSymlinksInPath().path
    return url.path.hasPrefix(home + "/") ? url : nil
  }
}
