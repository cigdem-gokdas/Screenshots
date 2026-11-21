package com.example.screenshot_cehennemi

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var pickerResult: MethodChannel.Result? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val requestCode = 5208
    private val selectedDirectory get() = File(cacheDir, "selected_imports")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "screenshot_cehennemi/local_vision")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "cleanPickerCache" -> {
                        if (pickerResult != null) { result.error("picker_busy", null, null) }
                        else { worker.execute { selectedDirectory.deleteRecursively(); runOnUiThread { result.success(null) } } }
                    }
                    "pickImages" -> {
                        if (pickerResult != null) { result.error("picker_busy", null, null) }
                        else {
                            pickerResult = result
                            val intent = if (Build.VERSION.SDK_INT >= 33) Intent(MediaStore.ACTION_PICK_IMAGES).apply {
                                type = "image/*"; putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, 10)
                            } else Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                type = "image/*"; addCategory(Intent.CATEGORY_OPENABLE)
                                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                            }
                            try { startActivityForResult(intent, requestCode) }
                            catch (_: Exception) { pickerResult = null; result.error("picker_unavailable", null, null) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != this.requestCode) { super.onActivityResult(requestCode, resultCode, data); return }
        val pending = pickerResult ?: return
        if (resultCode != Activity.RESULT_OK || data == null) { pickerResult = null; pending.success(emptyList<String>()); return }
        val uris = data.clipData?.let { clip -> (0 until minOf(clip.itemCount, 10)).map { clip.getItemAt(it).uri } }
            ?: listOfNotNull(data.data)
        worker.execute {
            selectedDirectory.mkdirs()
            val paths = uris.map { uri ->
                var target: File? = null
                try {
                    val mime = contentResolver.getType(uri)
                    require(mime in setOf("image/png", "image/jpeg", "image/heic", "image/heif", "image/webp"))
                    val destination = File(selectedDirectory, "${UUID.randomUUID()}.source")
                    target = destination
                    contentResolver.openInputStream(uri).use { input ->
                        requireNotNull(input)
                        destination.outputStream().use { output ->
                            val buffer = ByteArray(32 * 1024); var total = 0
                            while (true) {
                                val count = input.read(buffer); if (count < 0) break
                                total += count; require(total <= 20 * 1024 * 1024)
                                output.write(buffer, 0, count)
                            }
                            require(total > 0)
                        }
                    }
                    destination.absolutePath
                } catch (_: Exception) { target?.delete(); "" }
            }
            runOnUiThread { pickerResult = null; pending.success(paths) }
        }
    }
}
