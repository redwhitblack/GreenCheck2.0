import SwiftUI
import VisionKit
import AVFoundation

/// A screen that hosts the camera feed and a "Start Scan" button, then calls back with recognized barcodes.
struct ManualScannerScreen: View {
    /// Called when a barcode is recognized
    let onBarcodeScanned: (String) -> Void
    
    /// Holds a reference to the DataScannerViewController
    @State private var scannerController: DataScannerViewController?
    
    /// Whether scanning has started
    @State private var didStartScanning = false
    
    /// Optional torch/flashlight state
    @State private var isTorchOn = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // The VisionKit camera feed
            ScannerControllerView(
                scannerController: $scannerController,
                onBarcodeScanned: { code in
                    DispatchQueue.main.async {
                        onBarcodeScanned(code)
                        dismiss() // close after first recognized code
                    }
                }
            )
            .ignoresSafeArea()
            
            // UI Overlay: Close, Flashlight, Start
            VStack {
                HStack {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    // Flashlight toggle
                    Button(isTorchOn ? "Light Off" : "Light On") {
                        toggleFlashlight()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(isTorchOn ? Color.gray : Color.yellow)
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Button(didStartScanning ? "Scanning..." : "Start Scan") {
                        guard let scanner = scannerController else { return }
                        startScanning(in: scanner)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(didStartScanning ? Color.gray : Color.blue)
                    .cornerRadius(8)
                }
                .padding()
                
                Spacer()
            }
        }
    }
    
    private func startScanning(in scanner: DataScannerViewController) {
        DispatchQueue.main.async {
            if !scanner.isScanning {
                do {
                    try scanner.startScanning()
                    print("ManualScannerScreen: started scanning.")
                    didStartScanning = true
                } catch {
                    print("ManualScannerScreen: could not start scanning: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else {
            print("No torch available.")
            return
        }
        do {
            try device.lockForConfiguration()
            if isTorchOn {
                device.torchMode = .off
            } else {
                try device.setTorchModeOn(level: 1.0)
            }
            device.unlockForConfiguration()
            DispatchQueue.main.async {
                self.isTorchOn.toggle()
            }
        } catch {
            print("Failed toggling flashlight: \(error.localizedDescription)")
        }
    }
}
