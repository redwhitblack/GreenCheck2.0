import SwiftUI
import VisionKit

struct ScannerControllerView: UIViewControllerRepresentable {
    @Binding var scannerController: DataScannerViewController?
    
    let onBarcodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scannerVC = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(symbologies: [
                    .qr, .ean8, .ean13, .pdf417, .code128, .code39, .upce
                ])
            ],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scannerVC.delegate = context.coordinator
        
        // We do NOT start scanning automatically
        scannerController = scannerVC
        return scannerVC
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController,
                                context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeScanned: onBarcodeScanned)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onBarcodeScanned: (String) -> Void
        
        init(onBarcodeScanned: @escaping (String) -> Void) {
            self.onBarcodeScanned = onBarcodeScanned
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRecognize items: [RecognizedItem]) {
            if items.isEmpty {
                print("ScannerControllerView: No items recognized.")
            }
            for item in items {
                if case .barcode(let barcode) = item,
                   let codeString = barcode.payloadStringValue {
                    print("ScannerControllerView recognized: \(codeString)")
                    onBarcodeScanned(codeString)
                }
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController,
                         didTapOn item: RecognizedItem) {
            // Not used
        }
    }
}
