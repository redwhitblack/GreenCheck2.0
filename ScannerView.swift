import SwiftUI
import VisionKit

/// A more generic VisionKit scanner approach with optional autoStart/manual start/stop
struct ScannerView: UIViewControllerRepresentable {
    let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
    let onScan: (String) -> Void
    let recognizesMultipleItems: Bool
    let qualityLevel: DataScannerViewController.QualityLevel
    let autoStart: Bool
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scannerVC = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: qualityLevel,
            recognizesMultipleItems: recognizesMultipleItems,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scannerVC.delegate = context.coordinator
        return scannerVC
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if autoStart,
           uiViewController.isViewLoaded,
           uiViewController.view.window != nil,
           !uiViewController.isScanning {
            do {
                try uiViewController.startScanning()
                print("ScannerView: auto-start scanning.")
            } catch {
                print("ScannerView: could not start scanning: \(error.localizedDescription)")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }
    
    func startScanning(_ uiViewController: DataScannerViewController) {
        do {
            if !uiViewController.isScanning {
                try uiViewController.startScanning()
                print("ScannerView: manually started scanning.")
            }
        } catch {
            print("ScannerView: error starting scan: \(error.localizedDescription)")
        }
    }
    
    func stopScanning(_ uiViewController: DataScannerViewController) {
        uiViewController.stopScanning()
        print("ScannerView: stopped scanning.")
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        
        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRecognize items: [RecognizedItem]) {
            if items.isEmpty {
                print("ScannerView: no items recognized in this frame.")
            }
            for item in items {
                if case .barcode(let barcode) = item,
                   let codeString = barcode.payloadStringValue {
                    print("ScannerView recognized: \(codeString)")
                    onScan(codeString)
                }
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController,
                         didTapOn item: RecognizedItem) { }
    }
}
