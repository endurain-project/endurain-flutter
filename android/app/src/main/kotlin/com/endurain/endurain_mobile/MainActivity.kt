package com.endurain.endurain

import com.endurain.endurain.activity.ActivityRecorderChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var recorderChannel: ActivityRecorderChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        recorderChannel = ActivityRecorderChannel(applicationContext).also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        recorderChannel?.unregister()
        recorderChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
