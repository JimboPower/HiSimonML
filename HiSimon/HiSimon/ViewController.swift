import UIKit
import CoreML
import CoreMotion

class GestureViewController: UIViewController {
    
    // MARK:- Properties
    
    private var gestureAI = GestureAI()
    private let queue = OperationQueue.init()
    private let motionManager = CMMotionManager()
    private lazy var timer: Timer = {
        Timer.scheduledTimer(timeInterval: 1.0, target: self,
                             selector: #selector(self.updateTimer(tm:)), userInfo: nil, repeats: true)
    }()
    let userDefaults = UserDefaults.standard
    
    private let timeMax: Int = 5
    private var cntTimer: Int = 0
    private let inputDim: Int = 3
    private let lengthMax: Int = 40
    private var sequenceTarget: [Double] = []
    
    // MARK:- Outlets
    
    @IBOutlet weak var gaBtn: UIButton!
    @IBOutlet weak var gaArea: UILabel!
    
    
    // MARK:- UIViewControllers
    
    override func viewDidLoad() {
        super.viewDidLoad()
        motionManager.accelerometerUpdateInterval = 0.1

        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK:- Events
    
    @IBAction func gaBtnTouchDown(_ sender: Any) {
        gaBtn.backgroundColor = GAColor.btnSensing
        self.sequenceTarget = []
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimer(tm:)), userInfo: nil, repeats: true)
        timer.fire()
        
        motionManager.startAccelerometerUpdates(to: queue, withHandler: {
            (accelerometerData, error) in
            if let e = error {
                fatalError(e.localizedDescription)
            }
            guard let data = accelerometerData else { return }
            self.sequenceTarget.append(data.acceleration.x)
            self.sequenceTarget.append(data.acceleration.y)
            self.sequenceTarget.append(data.acceleration.z)
        })
    }
    
    
    @IBAction func gaBtnTouchUpInside(_ sender: Any) {
        gaBtn.backgroundColor = GAColor.btnNormal
        motionManager.stopAccelerometerUpdates()
        
        timer.invalidate()
        cntTimer = 0
        
        let cnt = self.sequenceTarget.count
        if cnt >= lengthMax*inputDim {
            cntTimer = 0
            return
        }
        
        // Pay attention to input dimension for RNN
        for _ in cnt..<lengthMax*inputDim {
            self.sequenceTarget.append(0.0)
        }
        
        let output = predict(self.sequenceTarget)
        // Find a maximum likelihood
        var max = Double(truncating: output.output1[0])
        var index_max: Int = 0
        let end = output.output1.count
        for i in 1..<end {
            let t = Double(truncating: output.output1[i])
            if t >= max {
                max = t
                index_max = i
            }
        }
        
        gestureAI = GestureAI()
        guard let symbol = GASymbol.map[index_max] else {
            return
        }
        gaArea.text = symbol
    }
    
    // MARK:- Utils
    
    @objc private func updateTimer(tm: Timer) {
        if cntTimer >= timeMax {
            gaBtn.backgroundColor = GAColor.btnWarning
            timer.invalidate()
            cntTimer = 0
            return
        }
        cntTimer += 1
    }
    
    /// Convert double array type into MLMultiArray
    ///
    /// - Parameters:
    /// - arr: double array
    /// - Returns: MLMultiArray
    private func toMLMultiArray(_ arr: [Double]) -> MLMultiArray {
        guard let sequence = try? MLMultiArray(shape:[120], dataType:MLMultiArrayDataType.double) else {
            fatalError("Unexpected runtime error. MLMultiArray")
        }
        let size = Int(truncating: sequence.shape[0])
        for i in 0..<size {
            sequence[i] = NSNumber(floatLiteral: arr[i])
        }
        return sequence
    }
    
    /// Predict class label
    ///
    /// - Parameters:
    /// - arr: Sequence
    /// - Returns: Likelihood
    private func predict(_ arr: [Double]) -> GestureAIOutput {
        guard let output = try? gestureAI.prediction(input:
            GestureAIInput(input1: toMLMultiArray(arr))) else {
                fatalError("Unexpected runtime error.")
        }
        return output
    }
    
    
    var leafView: LeafView?
    
    var shapes = ["EmptyOvalFall", "EmptyTriangleFall", "EmptySquareFall"]
    func setupConfetti() {
        leafView = LeafView(frame: self.view.frame)
        leafView?.layer.zPosition = -1
        leafView!.direction = .top
        leafView!.intensity = 0.05
        self.view.addSubview((leafView)!)
        leafView!.isUserInteractionEnabled = false
        leafView?.setImageForLeaf(imageLeaf: UIImage(named: "EmptyOvalFall")!)
        
    }
    
}

///Controllare come utilizzare bottone
///Animazione delle figure
///Colletion view che aggiunge figure nel bottone
///Controllo del livello
///Breve tutorial iniziale    ?


