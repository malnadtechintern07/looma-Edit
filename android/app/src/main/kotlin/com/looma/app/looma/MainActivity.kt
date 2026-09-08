package com.looma.app.looma

import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "looma/gallery_saver"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    val mimeType = call.argument<String>("mimeType")
                    if (path != null) {
                        val mimeTypes = if (mimeType != null) arrayOf(mimeType) else null
                        MediaScannerConnection.scanFile(
                            context,
                            arrayOf(path),
                            mimeTypes
                        ) { scannedPath, uri ->
                            runOnUiThread {
                                result.success(uri?.toString() ?: scannedPath)
                            }
                        }
                    } else {
                        result.error("INVALID_PATH", "Path cannot be null", null)
                    }
                }
                "saveImageToGallery" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val fileName = call.argument<String>("fileName") ?: "looma_${System.currentTimeMillis()}.png"
                    val isPng = fileName.lowercase().endsWith(".png")
                    val mimeType = if (isPng) "image/png" else "image/jpeg"
                    if (sourcePath == null) {
                        result.error("INVALID_PATH", "Source path cannot be null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val sourceFile = File(sourcePath)
                        if (!sourceFile.exists()) {
                            result.error("FILE_NOT_FOUND", "Source file does not exist: $sourcePath", null)
                            return@setMethodCallHandler
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val values = ContentValues().apply {
                                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                                put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/Looma")
                                put(MediaStore.Images.Media.IS_PENDING, 1)
                            }

                            val resolver = contentResolver
                            val collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                            val itemUri = resolver.insert(collection, values)

                            if (itemUri != null) {
                                resolver.openOutputStream(itemUri)?.use { out ->
                                    FileInputStream(sourceFile).use { input ->
                                        input.copyTo(out)
                                    }
                                }
                                values.clear()
                                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                                resolver.update(itemUri, values, null, null)

                                MediaScannerConnection.scanFile(
                                    context,
                                    arrayOf(sourceFile.absolutePath),
                                    arrayOf(mimeType),
                                    null
                                )
                                result.success(itemUri.toString())
                            } else {
                                result.error("INSERT_FAILED", "Failed to create MediaStore image entry", null)
                            }
                        } else {
                            val picturesDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "Looma")
                            if (!picturesDir.exists()) picturesDir.mkdirs()
                            val destFile = File(picturesDir, fileName)
                            sourceFile.copyTo(destFile, overwrite = true)

                            MediaScannerConnection.scanFile(
                                context,
                                arrayOf(destFile.absolutePath),
                                arrayOf(mimeType)
                            ) { _, uri ->
                                runOnUiThread {
                                    result.success(destFile.absolutePath)
                                }
                            }
                        }
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                }
                "saveVideoToGallery" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val fileName = call.argument<String>("fileName") ?: "looma_export.mp4"
                    if (sourcePath == null) {
                        result.error("INVALID_PATH", "Source path cannot be null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val sourceFile = File(sourcePath)
                        if (!sourceFile.exists()) {
                            result.error("FILE_NOT_FOUND", "Source file does not exist: $sourcePath", null)
                            return@setMethodCallHandler
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            // Android 10+ (API 29+) Scoped Storage via MediaStore
                            val values = ContentValues().apply {
                                put(MediaStore.Video.Media.DISPLAY_NAME, fileName)
                                put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                                put(MediaStore.Video.Media.RELATIVE_PATH, Environment.DIRECTORY_MOVIES + "/Looma")
                                put(MediaStore.Video.Media.IS_PENDING, 1)
                            }

                            val resolver = contentResolver
                            val collection = MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                            val itemUri = resolver.insert(collection, values)

                            if (itemUri != null) {
                                resolver.openOutputStream(itemUri)?.use { out ->
                                    FileInputStream(sourceFile).use { input ->
                                        input.copyTo(out)
                                    }
                                }
                                values.clear()
                                values.put(MediaStore.Video.Media.IS_PENDING, 0)
                                resolver.update(itemUri, values, null, null)

                                MediaScannerConnection.scanFile(
                                    context,
                                    arrayOf(sourceFile.absolutePath),
                                    arrayOf("video/mp4"),
                                    null
                                )
                                result.success(itemUri.toString())
                            } else {
                                result.error("INSERT_FAILED", "Failed to create MediaStore video entry", null)
                            }
                        } else {
                            // Android 9 and below
                            val moviesDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES), "Looma")
                            if (!moviesDir.exists()) moviesDir.mkdirs()
                            val destFile = File(moviesDir, fileName)
                            sourceFile.copyTo(destFile, overwrite = true)

                            MediaScannerConnection.scanFile(
                                context,
                                arrayOf(destFile.absolutePath),
                                arrayOf("video/mp4")
                            ) { _, uri ->
                                runOnUiThread {
                                    result.success(destFile.absolutePath)
                                }
                            }
                        }
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        val COMPOSER_CHANNEL = "looma/video_composer"
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COMPOSER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "renderProject" -> {
                    @Suppress("UNCHECKED_CAST")
                    val params = call.arguments as? Map<String, Any>
                    if (params == null) {
                        result.error("INVALID_ARGS", "Params cannot be null", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        LoomaVideoComposer.renderProject(context, params) { success, outputPath, error ->
                            runOnUiThread {
                                if (success && outputPath != null) {
                                    result.success(mapOf("success" to true, "outputPath" to outputPath))
                                } else {
                                    result.error("RENDER_FAILED", error ?: "Unknown error", null)
                                }
                            }
                        }
                    }.start()
                }
                "getRenderProgress" -> {
                    result.success(mapOf(
                        "progress" to LoomaVideoComposer.currentProgress,
                        "currentFrame" to LoomaVideoComposer.currentFrame,
                        "totalFrames" to LoomaVideoComposer.totalFrames,
                        "stage" to LoomaVideoComposer.currentStage
                    ))
                }
                else -> result.notImplemented()
            }
        }

        val ACTIONS_CHANNEL = "looma/app_actions"
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACTIONS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openPlayStore" -> {
                    val packageName = call.argument<String>("packageName") ?: context.packageName
                    try {
                        val marketIntent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName")).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        context.startActivity(marketIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$packageName")).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            context.startActivity(webIntent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("OPEN_STORE_FAILED", e2.message, null)
                        }
                    }
                }
                "shareApp" -> {
                    val text = call.argument<String>("text")
                        ?: "Create cinematic videos & aesthetic reels with Looma Video Editor! Download on Google Play: https://play.google.com/store/apps/details?id=${context.packageName}"
                    val subject = call.argument<String>("subject") ?: "Looma Video Editor"
                    val title = call.argument<String>("title") ?: "Share Looma via"

                    try {
                        val sendIntent = Intent().apply {
                            action = Intent.ACTION_SEND
                            putExtra(Intent.EXTRA_TEXT, text)
                            putExtra(Intent.EXTRA_SUBJECT, subject)
                            type = "text/plain"
                        }
                        val chooser = Intent.createChooser(sendIntent, title).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        context.startActivity(chooser)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SHARE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
