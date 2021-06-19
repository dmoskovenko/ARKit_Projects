//
//  ContentView.swift
//  ModelPicker
//
//  Created by Dmitry on 11.06.2021.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

struct ContentView : View {
  @State private var isPlacementEnabled = false
  @State private var selectedModel: Model?
  @State private var modelConfirmedForPlacement: Model?
  
  private var models: [Model] = {
    // Dynamically get model filenames
    let filemanager = FileManager.default
    guard let path = Bundle.main.resourcePath, let files = try? filemanager.contentsOfDirectory(atPath: path) else {
      return []
    }
    
    var avalibleModels: [Model] = []
    for filename in files where filename.hasSuffix("usdz") {
      let modelName = filename.replacingOccurrences(of: ".usdz", with: "")
      let model = Model(modelName: modelName)
      avalibleModels.append(model)
    }
    return avalibleModels
  }()
  
  var body: some View {
    ZStack(alignment: .bottom) {
      ARViewContainer(	modelConfirmedForPlacement: self.$modelConfirmedForPlacement)
      
      if self.isPlacementEnabled {
        PlacementButtonsView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, modelConfirmedForPlacement: self.$modelConfirmedForPlacement)
      } else {
        ModelPickerView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, models: self.models)
      }
    }
  }
}

struct ARViewContainer: UIViewRepresentable {
  @Binding var modelConfirmedForPlacement: Model?
  
  func makeUIView(context: Context) -> ARView {
    
    let arView = CustomARView(frame: .zero) //ARView(frame: .zero)

    return arView
    
  }
  
  func updateUIView(_ uiView: ARView, context: Context) {
    if let model = self.modelConfirmedForPlacement {
      
      if let modelEntity = model.modelEntity {
        print("DEBUG: Adding model to scene - \(model.modelName).")
        
        let anchorEntity = AnchorEntity(plane: .any)
        anchorEntity.addChild(modelEntity.clone(recursive: true))
        
        uiView.scene.addAnchor(anchorEntity)
      } else {
        print("DEBUG: Unable to load modelEntity for \(model.modelName).")
      }
      
      DispatchQueue.main.async {
        self.modelConfirmedForPlacement = nil
      }
    }
  }
  
}

class CustomARView: ARView {
  enum FocusStyleChoices {
    case classic
    case material
    case color
  }

  /// Style to be displayed in the example
  let focusStyle: FocusStyleChoices = .classic
  var focusEntity: FocusEntity?
  required init(frame frameRect: CGRect) {
    super.init(frame: frameRect)
    self.setupARView()

    switch self.focusStyle {
    case .color:
      self.focusEntity = FocusEntity(on: self, focus: .plane)
    case .material:
      do {
        let onColor: MaterialColorParameter = try .texture(.load(named: "Add"))
        let offColor: MaterialColorParameter = try .texture(.load(named: "Open"))
        self.focusEntity = FocusEntity(
          on: self,
          style: .colored(
            onColor: onColor, offColor: offColor,
            nonTrackingColor: offColor
          )
        )
      } catch {
        self.focusEntity = FocusEntity(on: self, focus: .classic)
        print("Unable to load plane textures")
        print(error.localizedDescription)
      }
    default:
      self.focusEntity = FocusEntity(on: self, focus: .classic)
    }
  }
  
  @objc required dynamic init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setupARView() {
    let config = ARWorldTrackingConfiguration()
    config.planeDetection = [.horizontal, .vertical]
    config.environmentTexturing = .automatic
    
    if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
      config.sceneReconstruction = .mesh
    }
    
    self.session.run(config)
  }
}

struct ModelPickerView: View {
  @Binding var isPlacementEnabled: Bool
  @Binding var selectedModel: Model?
  
  var models: [Model]
  
  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 30) {
        ForEach(0 ..< self.models.count) {
          index in
          Button(action: { print("DEBUG: Selected model with name: \(self.models[index].modelName).")
            
            self.selectedModel = self.models[index]
            
            self.isPlacementEnabled = true
          }) {
            Image(uiImage: self.models[index].image)
              .resizable()
              .frame(height: 80)
              .aspectRatio(1, contentMode: .fit)
              .background(Color.white)
              .cornerRadius(12)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
    }
    .padding(20)
    .background(Color.black.opacity(0.5))
  }
}

struct PlacementButtonsView: View {
  @Binding var isPlacementEnabled: Bool
  @Binding var selectedModel: Model?
  @Binding var modelConfirmedForPlacement: Model?
  
  var body: some View {
    HStack {
      // Cancel button
      Button(action: {
        print("DEBUG: Model placement canceled.")
        
        self.resetPlacementParameters()
      }) {
        Image(systemName: "xmark")
          .frame(width: 60, height: 60)
          .font(.title)
          .background(Color.white.opacity(0.75))
          .cornerRadius(30)
          .padding(20)
      }
      // Confirm button
      Button(action: {
        print("DEBUG: Model placement confirmed.")
        
        self.modelConfirmedForPlacement = self.selectedModel
        
        self.resetPlacementParameters()
      }) {
        Image(systemName: "checkmark")
          .frame(width: 60, height: 60)
          .font(.title)
          .background(Color.white.opacity(0.75))
          .cornerRadius(30)
          .padding(20)
      }
    }
  }
  func resetPlacementParameters() {
    self.isPlacementEnabled = false
    self.selectedModel = nil
  }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
#endif
