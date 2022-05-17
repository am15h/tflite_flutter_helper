package com.tfliteflutter.tflite_flutter_helper

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.media.*
import android.media.AudioRecord.OnRecordPositionUpdateListener
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.ShortBuffer

enum class SoundStreamErrors {
	FailedToRecord,
	FailedToPlay,
	FailedToStop,
	FailedToWriteBuffer,
	Unknown,
}

enum class SoundStreamStatus {
	Unset,
	Initialized,
	Playing,
	Stopped,
}

const val METHOD_CHANNEL_NAME = "com.tfliteflutter.tflite_flutter_helper:methods"

/** TfliteFlutterHelperPlugin */
class TfliteFlutterHelperPlugin : FlutterPlugin,
		MethodCallHandler,
		PluginRegistry.RequestPermissionsResultListener,
		ActivityAware {


	private val LOG_TAG = "TfLiteFlutterHelperPlugin"
	private val AUDIO_RECORD_PERMISSION_CODE = 14887
	private val DEFAULT_SAMPLE_RATE = 16000
	private val DEFAULT_BUFFER_SIZE = 8192
	private val DEFAULT_PERIOD_FRAMES = 8192

	private lateinit var methodChannel: MethodChannel
	private var currentActivity: Activity? = null
	private var pluginContext: Context? = null
	private var permissionToRecordAudio: Boolean = false
	private var activeResult: Result? = null
	private var debugLogging: Boolean = false

	private val mRecordFormat = AudioFormat.ENCODING_PCM_16BIT
	private var mRecordSampleRate = DEFAULT_SAMPLE_RATE
	private var mRecorderBufferSize = DEFAULT_BUFFER_SIZE
	private var mPeriodFrames = DEFAULT_PERIOD_FRAMES
	private var audioData: ShortArray? = null
	private var mRecorder: AudioRecord? = null
	private var mListener: OnRecordPositionUpdateListener? = null


	override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
		pluginContext = flutterPluginBinding.applicationContext
		methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
		methodChannel.setMethodCallHandler(this)
	}

	override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
		try {
			when (call.method) {
				"hasPermission" -> hasPermission(result)
				"initializeRecorder" -> initializeRecorder(call, result)
				"startRecording" -> startRecording(result)
				"stopRecording" -> stopRecording(result)
				else -> result.notImplemented()
			}
		} catch (e: Exception) {
			Log.e(LOG_TAG, "Unexpected exception", e)
			// TODO: implement result.error
		}
	}

	override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
		methodChannel.setMethodCallHandler(null)
		mListener?.onMarkerReached(null)
		mListener?.onPeriodicNotification(null)
		mListener = null
		mRecorder?.stop()
		mRecorder?.release()
		mRecorder = null
	}

	override fun onDetachedFromActivity() {
//        currentActivity
	}

	override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
		currentActivity = binding.activity
		binding.addRequestPermissionsResultListener(this)
	}

	override fun onAttachedToActivity(binding: ActivityPluginBinding) {
		currentActivity = binding.activity
		binding.addRequestPermissionsResultListener(this)
	}

	override fun onDetachedFromActivityForConfigChanges() {
//        currentActivity = null
	}

	private fun hasRecordPermission(): Boolean {
		if (permissionToRecordAudio) return true

		val localContext = pluginContext
		permissionToRecordAudio = localContext != null && ContextCompat.checkSelfPermission(localContext,
				Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
		return permissionToRecordAudio

	}

	private fun hasPermission(result: Result) {
		result.success(hasRecordPermission())
	}

	private fun requestRecordPermission() {
		val localActivity = currentActivity
		if (!hasRecordPermission() && localActivity != null) {
			debugLog("requesting RECORD_AUDIO permission")
			ActivityCompat.requestPermissions(localActivity,
					arrayOf(Manifest.permission.RECORD_AUDIO), AUDIO_RECORD_PERMISSION_CODE)
		}
	}

	override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>,
											grantResults: IntArray): Boolean {
		when (requestCode) {
			AUDIO_RECORD_PERMISSION_CODE -> {

				permissionToRecordAudio = grantResults.isNotEmpty() &&
						grantResults[0] == PackageManager.PERMISSION_GRANTED

				completeInitializeRecorder()
				return true
			}
		}
		return false
	}

	private fun initializeRecorder(@NonNull call: MethodCall, @NonNull result: Result) {
		mRecordSampleRate = call.argument<Int>("sampleRate") ?: mRecordSampleRate
		debugLogging = call.argument<Boolean>("showLogs") ?: false
		mPeriodFrames = AudioRecord.getMinBufferSize(mRecordSampleRate, AudioFormat.CHANNEL_IN_MONO, mRecordFormat)
		mRecorderBufferSize = mPeriodFrames * 2
		audioData = ShortArray(mPeriodFrames)
		activeResult = result

		val localContext = pluginContext
		if (null == localContext) {
			completeInitializeRecorder()
			return
		}
		permissionToRecordAudio = ContextCompat.checkSelfPermission(localContext,
				Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
		if (!permissionToRecordAudio) {
			requestRecordPermission()
		} else {
			debugLog("has permission, completing")
			completeInitializeRecorder()
		}
		debugLog("leaving initializeIfPermitted")
	}

	private fun initRecorder() {
		if (mRecorder?.state == AudioRecord.STATE_INITIALIZED) {
			return
		}
		mRecorder = AudioRecord(MediaRecorder.AudioSource.MIC, mRecordSampleRate, AudioFormat.CHANNEL_IN_MONO, mRecordFormat, mRecorderBufferSize)
		if (mRecorder != null) {
			mListener = createRecordListener()
			mRecorder?.positionNotificationPeriod = mPeriodFrames
			mRecorder?.setRecordPositionUpdateListener(mListener)
		}
	}

	private fun completeInitializeRecorder() {

		debugLog("completeInitialize")
		val initResult: HashMap<String, Any> = HashMap()

		if (permissionToRecordAudio) {
			mRecorder?.release()
			initRecorder()
			initResult["isMeteringEnabled"] = true
			sendRecorderStatus(SoundStreamStatus.Initialized)
		}

		initResult["success"] = permissionToRecordAudio
		debugLog("sending result")
		activeResult?.success(initResult)
		debugLog("leaving complete")
		activeResult = null
	}

	private fun sendEventMethod(name: String, data: Any) {
		val eventData: HashMap<String, Any> = HashMap()
		eventData["name"] = name
		eventData["data"] = data
		methodChannel.invokeMethod("platformEvent", eventData)
	}

	private fun debugLog(msg: String) {
		if (debugLogging) {
			Log.d(LOG_TAG, msg)
		}
	}

	private fun startRecording(result: Result) {
		try {
			if (mRecorder!!.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
				result.success(true)
				return
			}
			initRecorder()
			mRecorder!!.startRecording()
			sendRecorderStatus(SoundStreamStatus.Playing)
			result.success(true)
		} catch (e: IllegalStateException) {
			debugLog("record() failed")
			result.error(SoundStreamErrors.FailedToRecord.name, "Failed to start recording", e.localizedMessage)
		}
	}

	private fun stopRecording(result: Result) {
		try {
			if (mRecorder!!.recordingState == AudioRecord.RECORDSTATE_STOPPED) {
				result.success(true)
				return
			}
			mRecorder!!.stop()
			sendRecorderStatus(SoundStreamStatus.Stopped)
			result.success(true)
		} catch (e: IllegalStateException) {
			debugLog("record() failed")
			result.error(SoundStreamErrors.FailedToRecord.name, "Failed to start recording", e.localizedMessage)
		}
	}

	private fun sendRecorderStatus(status: SoundStreamStatus) {
		sendEventMethod("recorderStatus", status.name)
	}

	private fun createRecordListener(): OnRecordPositionUpdateListener? {
		return object : OnRecordPositionUpdateListener {
			override fun onMarkerReached(recorder: AudioRecord) {
				recorder.read(audioData!!, 0, mRecorderBufferSize)
			}

			override fun onPeriodicNotification(recorder: AudioRecord) {
				val data = audioData!!
				val shortOut = recorder.read(data, 0, mPeriodFrames)
				// https://flutter.io/platform-channels/#codec
				// convert short to int because of platform-channel's limitation
				val byteBuffer = ByteBuffer.allocate(shortOut * 2)
				byteBuffer.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().put(data)

				sendEventMethod("dataPeriod", byteBuffer.array())
			}
		}
	}
}
