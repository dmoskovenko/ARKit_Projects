//
//  ViewController.swift
//  ARShots
//
//  Created by Dmitry on 06.06.2021.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
  
    var hoopAdded = false
  
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
      
        sceneView.autoenablesDefaultLighting = true
      
//        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Create a new scene
//        let scene = SCNScene(named: "art.scnassets/hoop.scn")!
        
        // Set the scene to the view
//        sceneView.scene = scene
      
//        let ball = createBall()
//        sceneView.scene.rootNode.addChildNode(ball)
      
        let text = createText()
        sceneView.scene.rootNode.addChildNode(text)
    }
    
    func createCircle(planeAnchor: ARPlaneAnchor) -> SCNNode {
      print("wall finded")
      let circleNode = SCNNode()
      
      let circle = SCNPlane(width: CGFloat(0.03), height: CGFloat(0.03))
//      let circle = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
      circle.cornerRadius = 0.2
      circle.materials.first?.diffuse.contents = UIColor.white
      circleNode.geometry = circle
      circleNode.position = SCNVector3(0.0, 0.0, -0.01)
      circleNode.eulerAngles.x = -Float.pi / 2
      circleNode.opacity = 0.7
      
      return circleNode
    }
  
    func createText() -> SCNNode {
      let textNode = SCNNode()
      let text = SCNText(string: "Vertical planes detecting...", extrusionDepth: CGFloat(0.05))
      text.materials.first?.diffuse.contents = UIColor.white
      textNode.geometry = text
      textNode.name = "text"
      textNode.position = SCNVector3(-0.3, +0.3, -1.0)
      textNode.scale = SCNVector3(0.005, 0.005, 0.005)
//      node.eulerAngles.x = -Float.pi / 2
      
      return textNode
    }
    
//    func createHoop(planeAnchor: ARPlaneAnchor) -> SCNNode {
//      let node = SCNScene(named: "art.scnassets/hoop.scn")!.rootNode.clone()
//      node.position = SCNVector3(planeAnchor.center.x, planeAnchor.extent.z, planeAnchor.center.z)
//      node.eulerAngles.x = -Float.pi / 2
//      return node
//    }
  
    func addHoop(result: ARHitTestResult) {
      let hoopScene = SCNScene(named: "art.scnassets/hoop.scn")
      
      guard let hoopNode = hoopScene?.rootNode.childNode(withName: "Hoop", recursively: false) else {
        return
      }
      
      let planePositions = result.worldTransform.columns.3
      hoopNode.position = SCNVector3(planePositions.x, planePositions.y, planePositions.z)
      
      let physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: hoopNode, options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.concavePolyhedron]))
      hoopNode.physicsBody = physicsBody
      
      sceneView.scene.rootNode.addChildNode(hoopNode)
    }
  
    func createBall() {
      guard let currentFrame = sceneView.session.currentFrame else { return }
      
      let ball = SCNSphere(radius: 0.24)
      ball.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/ball.jpg")
        ball.firstMaterial?.normal.contents = UIImage(named: "art.scnassets/ballNormalMap.jpg")
      ball.segmentCount = 36
      ball.firstMaterial?.normal.intensity = 0.35
      ball.firstMaterial?.lightingModel = .physicallyBased
      ball.firstMaterial?.metalness.contents = 0.23
      ball.firstMaterial?.roughness.contents = 0.63
//      ball.firstMaterial?.selfIllumination.contents = 0.3
      
      let ballNode = SCNNode(geometry: ball)
//      ballNode.name = "sphere"
//      ballNode.position = SCNVector3(0, -0.29, -0.38)
//      ballNode.scale = SCNVector3(0.5, 0.5, 0.5)
//      ballNode.eulerAngles.z = -Float.pi / 8
//      ballNode.eulerAngles.x = -Float.pi / 53
      
      let cameraTransform = SCNMatrix4(currentFrame.camera.transform)
      ballNode.transform = cameraTransform
      
      ballNode.scale = SCNVector3(0.5, 0.5, 0.5)
      ballNode.eulerAngles.x = -Float.pi / (Float(arc4random_uniform(10)) + 2.0)
      ballNode.eulerAngles.y = -Float.pi / (Float(arc4random_uniform(10)) + 2.0)
      ballNode.eulerAngles.z = -Float.pi / (Float(arc4random_uniform(10)) + 2.0)
      
      let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ballNode, options: [SCNPhysicsShape.Option.collisionMargin : 0.01]))
      ballNode.physicsBody = physicsBody
      
      let power = Float(10.0)
      let force = SCNVector3(-cameraTransform.m31 * power, -cameraTransform.m32 * power, -cameraTransform.m33 * power)
      
      ballNode.physicsBody?.applyForce(force, asImpulse: true)
      
      sceneView.scene.rootNode.addChildNode(ballNode)
    }
  
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        configuration.planeDetection = [.vertical]
      
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
  
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
      if !hoopAdded {
        let tochLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(tochLocation, types: [.existingPlane])
        
        if let result = hitTestResult.first {
          addHoop(result: result)
          hoopAdded = true
        }
      } else {
        createBall()
      }
    }
  
  // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
      guard let planeAnchor = anchor as? ARPlaneAnchor else {
        return
      }
      
      if planeAnchor.alignment == .vertical {
        let target = createCircle(planeAnchor: planeAnchor)
        target.name = "target"
        node.addChildNode(target)
      }
      
//      if sceneView.scene.rootNode.childNode(withName: "hoop", recursively: false) == nil {
//        let hoop = createHoop(planeAnchor: planeAnchor)
//        hoop.name = "hoop"
//        node.addChildNode(hoop)
//      }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
      guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
      if let text = sceneView.scene.rootNode.childNode(withName: "text", recursively: true) {
        text.isHidden = true
      }
      if hoopAdded == true {
        for node in node.childNodes {
          node.isHidden = true
        }
      }
//        node.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
//        if let plane = node.geometry as? SCNPlane {
//          plane.width = CGFloat(planeAnchor.extent.x)
//          plane.height = CGFloat(planeAnchor.extent.z)
//        }
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
