//
//  ViewController.swift
//  RodionovEgorTestovoeArkit
//
//  Created by Егор Родионов on 25.10.22.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    private lazy var constraintForPresentationView = presentationView.leadingAnchor.constraint(equalTo: sceneView.trailingAnchor)
    @IBOutlet var sceneView: ARSCNView!
    private lazy var pulse = Pulsing(numberOfPulses: .infinity, radius: 120, position: resetButton.center)
    var nodes : [SCNNode] = []
    var lineNodes : [SCNNode] = []
    var planeGeometry:SCNPlane!
    var anchors = [ARAnchor]()
    var sceneLight:SCNLight!
    var polygonHasBeenMade = false
    var arrayOf2dPoints : [VNVector] = []
    private lazy var resetButton : UIButton = {
        let button = UIButton()
        button.backgroundColor = .blue
        button.setTitle("Reset", for: .normal)
        button.addTarget(self, action: #selector(buttonHandle(button:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 50
        return button
        
    }()
    
    private lazy var lineMakeImageView : UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.image = UIImage(named: "zoom")
        image.contentMode = .scaleAspectFit
        image.isHidden = true
        return image
        
    }()
    private lazy var formatter : NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        return nf
    }()
    private lazy var distanceLabel : UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private lazy var presentationView : PresentationView = {
        let view = PresentationView(coordinates: arrayOf2dPoints)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private func addViews(){
        sceneView.addSubview(lineMakeImageView)
        sceneView.addSubview(distanceLabel)
        sceneView.addSubview(resetButton)
        
       
        
    }
    override func viewDidLayoutSubviews() {
        self.view.layer.insertSublayer(pulse, below: resetButton.layer)
    }
    private func setConstraints(){
        lineMakeImageView.centerYAnchor.constraint(equalTo: sceneView.centerYAnchor).isActive = true
        lineMakeImageView.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor).isActive = true
        lineMakeImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        lineMakeImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        distanceLabel.bottomAnchor.constraint(equalTo: lineMakeImageView.topAnchor).isActive = true
        distanceLabel.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor).isActive = true
        distanceLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true
        distanceLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        resetButton.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor,constant: -50).isActive = true
        resetButton.centerXAnchor.constraint(equalTo: sceneView.centerXAnchor).isActive = true
        resetButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        resetButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        
    }
    func addPulse(){
        
        
        pulse.animationDuration = 0.8
        pulse.backgroundColor = UIColor.blue.cgColor
        
        
        
        
        pulse.add(pulse.animationGroup, forKey: "pulse")
        
        
    }
    @objc func buttonHandle(button : UIButton){
        let layerForAnimationRemoved = view.layer.sublayers?.first(where: { layer in
            layer == pulse
        })


        
        //clean actions
        layerForAnimationRemoved?.removeAllAnimations()
        polygonHasBeenMade = false
        cleanNodes(nodesToClean: nodes)
        distanceLabel.text = ""
        cleanNodes(nodesToClean: lineNodes)
        nodes = []
        lineNodes = []
        constraintForPresentationView.constant = 0
        UIView.animate(withDuration: 1) {
            self.sceneView.layoutIfNeeded()
        }
    }
   
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addViews()
        setConstraints()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.autoenablesDefaultLighting = false
        
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        sceneLight = SCNLight()
        sceneLight.type = .omni
        
        let lightNode = SCNNode()
        lightNode.light = sceneLight
        lightNode.position = SCNVector3(x:0, y:10, z:2)
        
        sceneView.scene.rootNode.addChildNode(lightNode)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal,.vertical]
        configuration.isLightEstimationEnabled = true
        
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !polygonHasBeenMade{
            addNodeAtLocation(location: sceneView.center)
            if self.nodes.count > 1{
                let line = SCNNode.createLineNode(fromNode: self.nodes[self.nodes.count - 2], toNode: self.nodes[self.nodes.count - 1], andColor: .red)
                let distance = self.nodes[self.nodes.count - 2].position.distance(to: self.nodes[self.nodes.count - 1].position)
                let textDistance = formatter.string(from: NSNumber(value: Float(distance)))
                self.distanceLabel.text = textDistance
                self.sceneView.scene.rootNode.addChildNode(line)
                self.lineNodes.append(line)
                
            }
            if let newLocation = getLocationOnPlane(location: sceneView.center){
                
                
                let projectionVector = sceneView.projectPoint(newLocation)
                print(projectionVector)
                let vector = VNVector(xComponent: Double(projectionVector.x), yComponent: Double(projectionVector.z))
                let ortVector = VNVector.unitVector(for: vector)
                arrayOf2dPoints.append(ortVector)
               
                
            }
        
        }
        
        
       
        
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

   
    // MARK: - ARSCNViewDelegate
    

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {

        DispatchQueue.main.async {
            if !self.polygonHasBeenMade{
                if let newLocation = self.getLocationOnPlane(location: self.sceneView.center){
                    let distanceFault = 0.02
                    if self.nodes.count > 1{
                        
                        
                        if (self.nodes[0].position.x - Float(distanceFault)) < (newLocation.x) &&
                            (self.nodes[0].position.x + Float(distanceFault)) > (newLocation.x) &&
                            (self.nodes[0].position.y - Float(distanceFault)) < (newLocation.y) &&
                            (self.nodes[0].position.y + Float(distanceFault)) > (newLocation.y) &&
                            (self.nodes[0].position.z - Float(distanceFault)) < (newLocation.z) &&
                            (self.nodes[0].position.z + Float(distanceFault)) > (newLocation.z){
                            self.addPulse()
                            let line = SCNNode.createLineNode(fromNode: self.nodes[self.nodes.count - 1], toNode: self.nodes[0], andColor: .red)
                            let distance = self.nodes[self.nodes.count - 1].position.distance(to: self.nodes[0].position)
                            
                            self.distanceLabel.text = self.formatter.string(from: NSNumber(value: Float(distance)))
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.distanceLabel.text = ""
                            }
                            self.sceneView.scene.rootNode.addChildNode(line)
                            self.lineNodes.append(line)
                            self.constraintForPresentationView.constant = -300
                            UIView.animate(withDuration: 1) {
                                self.sceneView.layoutIfNeeded()
                            }
                            
                            // add
                            self.add2dViewPresentation()
                        
                         
                            
                        }
                    }
                   
            }
           
               
                    
                    
            }
        }
       
        if let estimate = self.sceneView.session.currentFrame?.lightEstimate {
            sceneLight.intensity = estimate.ambientIntensity
        }
    }
    private func add2dViewPresentation(){
        self.sceneView.addSubview(self.presentationView)
        self.constraintForPresentationView.isActive = true
        self.presentationView.topAnchor.constraint(equalTo: self.sceneView.safeAreaLayoutGuide.topAnchor).isActive = true
        self.presentationView.heightAnchor.constraint(equalToConstant: 300).isActive = true
        self.presentationView.widthAnchor.constraint(equalToConstant: 300).isActive = true
        self.polygonHasBeenMade = true
    }
    
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        DispatchQueue.main.async {
            self.lineMakeImageView.isHidden = false
        }
        var node:SCNNode?
        
        if let planeAnchor = anchor as? ARPlaneAnchor {
            node = SCNNode()
            planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            planeGeometry.firstMaterial?.diffuse.contents = UIColor.green.withAlphaComponent(0.7)
            
            let planeNode = SCNNode(geometry: planeGeometry)
            planeNode.position = SCNVector3(x: planeAnchor.center.x, y:0, z: planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
            
            updateMaterial()
            
            node?.addChildNode(planeNode)
            anchors.append(planeAnchor)
        }
     
        return node
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            self.lineMakeImageView.isHidden = false

          
        }
        if let planeAnchor = anchor as? ARPlaneAnchor {
            
            if anchors.contains(planeAnchor) {
                if node.childNodes.count > 0 {
                    let planeNode = node.childNodes.first!
                    planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
                    
                    if let plane = planeNode.geometry as? SCNPlane {
                        plane.width = CGFloat(planeAnchor.extent.x)
                        plane.height = CGFloat(planeAnchor.extent.z)
                        updateMaterial()
                    }
                }
            }
        }
        
       
      
    }
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            self.lineMakeImageView.isHidden = true
        }
     
    }
    func updateMaterial() {
        let material = self.planeGeometry.materials.first!
        
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(self.planeGeometry.width), Float(self.planeGeometry.height), 1)
    }
    private func getLocationOnPlane(location:CGPoint) -> SCNVector3?{
        guard anchors.count > 0 else {print("anchros are not created yet"); return nil}
        
        let hitResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        
        if hitResults.count > 0 {
            let result = hitResults.first!
            let newLocation = SCNVector3(x: result.worldTransform.columns.3.x, y: result.worldTransform.columns.3.y + 0.003, z: result.worldTransform.columns.3.z)
            return newLocation
        }
        return nil
        
    }
    
    
    func addNodeAtLocation (location:CGPoint) {
        if let newLocation = getLocationOnPlane(location: location){
            
    
            let sphere = SCNSphere(radius: 0.003)
            sphere.firstMaterial?.diffuse.contents = UIColor.black
            let node = SCNNode(geometry: sphere)
            
            node.position = newLocation
            nodes.append(node)
          
            
            sceneView.scene.rootNode.addChildNode(node)
        }
        
        
    }

    func cleanNodes(nodesToClean : [SCNNode]){
        if nodesToClean.count > 0 {
            for node in nodesToClean {
                node.removeFromParentNode()
                
            }
            
            
        }
    }
    


    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
