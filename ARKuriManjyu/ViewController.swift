//
//  ViewController.swift
//  ARKuriManjyu
//
//  Created by Sosuke Okubo on 2018/12/02.
//  Copyright © 2018 Sosuke Okubo. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var countLabel: UILabel!
    
    var kuriNode: SCNNode!
    var count = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showFeaturePoints]

        let scene = SCNScene()

        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)

        sceneView.scene = scene

        let kuriScene = SCNScene(named: "art.scnassets/kuri.scn")!
        kuriNode = kuriScene.rootNode.childNodes.first!

        let gesture = UITapGestureRecognizer(target: self, action: #selector(onTapSceneView))
        sceneView.addGestureRecognizer(gesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]

        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { fatalError() }

        let geometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))

        let material = geometry.materials.first
        material?.diffuse.contents = UIColor.blue.withAlphaComponent(0.3)

        let planeNode = SCNNode(geometry: geometry)
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.y)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)

        let shape = SCNPhysicsShape(geometry: geometry, options: nil)
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
        planeNode.physicsBody?.categoryBitMask = 2

        DispatchQueue.main.async(execute: {
            node.addChildNode(planeNode)
        })
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        guard let planeNode = findPlaneNode(on: node) else { return }
        guard let geometry = planeNode.geometry as? SCNPlane else { return }

        DispatchQueue.main.async(execute: {
            geometry.width = CGFloat(planeAnchor.extent.x)
            geometry.height = CGFloat(planeAnchor.extent.z)
            let shape = SCNPhysicsShape(geometry: geometry, options: nil)
            planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
            planeNode.physicsBody?.categoryBitMask = 2
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.y)
        })
    }

    @objc func onTapSceneView(sender: UITapGestureRecognizer) {
        if (count > 0) {
            return
        }

        let location = sender.location(in: sceneView)

        let hitTestResult = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        if let result = hitTestResult.first {
            let position = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y + 0.05, result.worldTransform.columns.3.z)
            let add = SCNAction.run { (node) in
                if self.count > 0 {
                    for _ in 0..<self.count {
                        self.addKuriNode(parentNode: node, position: position)
                    }
                    self.count += self.count
                } else {
                    self.addKuriNode(parentNode: node, position: position)
                    self.count += 1
                }
                print("count: \(self.count)")
                DispatchQueue.main.async {
                    self.countLabel.text = "\(self.count)"
                }
            }
            let wait = SCNAction.wait(duration: 5)
            let repeatForever = SCNAction.repeatForever(SCNAction.sequence([add, wait]))
            sceneView.scene.rootNode.runAction(repeatForever)
        }
    }

    private func addKuriNode(parentNode: SCNNode, position: SCNVector3) {
        let cloneNode = self.kuriNode.clone()
        cloneNode.position = position
        DispatchQueue.main.async {
            parentNode.addChildNode(cloneNode)
        }
    }

    private func findPlaneNode(on node: SCNNode) -> SCNNode? {
        for childNode in node.childNodes {
            if childNode.geometry as? SCNPlane != nil {
                return childNode
            }
        }
        return nil
    }
}
