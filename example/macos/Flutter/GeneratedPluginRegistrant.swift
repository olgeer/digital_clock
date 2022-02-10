//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import package_info_plus_macos
import path_provider_macos
import soundpool_macos
import wakelock_macos

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  FLTPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FLTPackageInfoPlusPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  SwiftSoundpoolPlugin.register(with: registry.registrar(forPlugin: "SwiftSoundpoolPlugin"))
  WakelockMacosPlugin.register(with: registry.registrar(forPlugin: "WakelockMacosPlugin"))
}
