import SwiftUI
import BarcodeScanner

struct HyperScannerScreen: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    
    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let scannerVC = BarcodeScannerViewController()
        scannerVC.title = "Scan a Barcode"
        
        // Assign delegates to the Coordinator
        scannerVC.codeDelegate = context.coordinator
        scannerVC.errorDelegate = context.coordinator
        scannerVC.dismissalDelegate = context.coordinator
        
        return scannerVC
    }
    
    func updateUIViewController(_ uiViewController: BarcodeScannerViewController,
                                context: Context) {
        // Nothing needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject,
                       BarcodeScannerCodeDelegate,
                       BarcodeScannerErrorDelegate,
                       BarcodeScannerDismissalDelegate {
        
        let onScan: (String) -> Void
        
        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }
        
        // 1) Captured code
        func scanner(
            _ controller: BarcodeScannerViewController,
            didCaptureCode code: String,
            type: String
        ) {
            print("HyperOslo scanned code: \(code), type: \(type)")
            
            // Pass code back to ContentView
            onScan(code)
            
            // Dismiss to avoid being stuck on “processing”
            controller.dismiss(animated: true)
        }
        
        // 2) Error
        func scanner(
            _ controller: BarcodeScannerViewController,
            didReceiveError error: Error
        ) {
            print("HyperOslo scanner error: \(error.localizedDescription)")
        }
        
        // 3) User taps close
        func scannerDidDismiss(_ controller: BarcodeScannerViewController) {
            controller.dismiss(animated: true)
        }
    }
}
