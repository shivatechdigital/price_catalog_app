package com.shrianandeshwartraders

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val exitChannel = "price_catalog_app/app_exit"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, exitChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"exitApp" -> {
						runOnUiThread {
							finishAndRemoveTask()
						}
						result.success(null)
					}
					else -> result.notImplemented()
				}
			}
	}
}
