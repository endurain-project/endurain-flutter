package com.endurain.endurain.activity

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import java.util.Locale
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * Process-wide [TextToSpeech] wrapper for spoken progress announcements.
 *
 * A single engine instance is shared by every recording so announcements
 * never contend for two simultaneous TTS sessions. Utterances are queued
 * ([TextToSpeech.QUEUE_ADD]) rather than interrupting each other. While one or
 * more ducked utterances are queued, transient audio focus asks the platform
 * to lower (not pause) other playback; focus is released after the final
 * ducked utterance finishes. Failures are logged without spoken text and are
 * contained here so speech can never fail the activity recording.
 */
object AudioAnnouncer {
    private var tts: TextToSpeech? = null
    private var ready = false
    private var appliedLanguageTag: String? = null
    private var audioManager: AudioManager? = null
    private var focusRequest: AudioFocusRequest? = null
    private val focusLock = Any()
    private val duckingUtteranceIds = mutableSetOf<String>()
    private val pending = ConcurrentLinkedQueue<PendingUtterance>()

    private data class PendingUtterance(
        val text: String,
        val duck: Boolean,
        val languageTag: String,
    )

    /** Speaks [text], ducking other audio first when [duck] is true. */
    fun speak(context: Context, text: String, duck: Boolean, languageTag: String) {
        if (text.isBlank()) {
            return
        }
        try {
            val appContext = context.applicationContext
            ensureInitialized(appContext)
            val engine = tts
            if (engine == null || !ready) {
                pending.add(PendingUtterance(text, duck, languageTag))
                return
            }
            speakNow(appContext, engine, text, duck, languageTag)
        } catch (error: RuntimeException) {
            reportFailure(STAGE_SPEAK, error = error)
        }
    }

    /** Stops any in-progress or queued utterance and releases audio focus. */
    fun stop() {
        pending.clear()
        try {
            if (tts?.stop() == TextToSpeech.ERROR) {
                reportFailure(STAGE_STOP)
            }
        } catch (error: RuntimeException) {
            reportFailure(STAGE_STOP, error = error)
        }
        releaseAllAudioFocus()
    }

    /** Releases the engine entirely. Used by tests; production never calls this. */
    fun shutdown() {
        stop()
        try {
            tts?.shutdown()
        } catch (error: RuntimeException) {
            reportFailure(STAGE_SHUTDOWN, error = error)
        } finally {
            tts = null
            ready = false
            appliedLanguageTag = null
        }
    }

    private fun ensureInitialized(context: Context) {
        if (tts != null) {
            return
        }
        try {
            audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            tts = TextToSpeech(context) { status ->
                try {
                    ready = status == TextToSpeech.SUCCESS
                    if (ready) {
                        val result = tts?.setOnUtteranceProgressListener(
                            FocusReleasingListener(),
                        )
                        if (result == TextToSpeech.ERROR) {
                            reportFailure(STAGE_LISTENER_REGISTRATION, code = result)
                        }
                        flushPending(context)
                    } else {
                        reportFailure(STAGE_INITIALIZATION, code = status)
                        pending.clear()
                    }
                } catch (error: RuntimeException) {
                    ready = false
                    pending.clear()
                    reportFailure(STAGE_INITIALIZATION, error = error)
                }
            }
        } catch (error: RuntimeException) {
            tts = null
            ready = false
            pending.clear()
            reportFailure(STAGE_INITIALIZATION, error = error)
        }
    }

    private fun flushPending(context: Context) {
        val engine = tts ?: return
        while (true) {
            val next = pending.poll() ?: break
            speakNow(context, engine, next.text, next.duck, next.languageTag)
        }
    }

    private fun speakNow(
        context: Context,
        engine: TextToSpeech,
        text: String,
        duck: Boolean,
        languageTag: String,
    ) {
        val utteranceId = "announcement_${System.nanoTime()}"
        try {
            applyLanguage(engine, languageTag)
            if (duck) {
                registerDuckedUtterance(utteranceId)
            }
            val result = engine.speak(text, TextToSpeech.QUEUE_ADD, Bundle(), utteranceId)
            if (result == TextToSpeech.ERROR) {
                reportFailure(STAGE_ENQUEUE, code = result)
                releaseAudioFocus(utteranceId)
            }
        } catch (error: RuntimeException) {
            reportFailure(STAGE_ENQUEUE, error = error)
            releaseAudioFocus(utteranceId)
        }
    }

    private fun applyLanguage(engine: TextToSpeech, languageTag: String) {
        if (languageTag.isEmpty() || languageTag == appliedLanguageTag) {
            return
        }
        val locale = Locale.forLanguageTag(languageTag)
        try {
            val result = engine.setLanguage(locale)
            if (result == TextToSpeech.LANG_MISSING_DATA ||
                result == TextToSpeech.LANG_NOT_SUPPORTED
            ) {
                reportFailure(STAGE_LANGUAGE, code = result)
                // Fall back to the device default rather than losing speech.
                val fallbackResult = engine.setLanguage(Locale.getDefault())
                if (fallbackResult == TextToSpeech.LANG_MISSING_DATA ||
                    fallbackResult == TextToSpeech.LANG_NOT_SUPPORTED
                ) {
                    reportFailure(STAGE_FALLBACK_LANGUAGE, code = fallbackResult)
                }
            }
        } catch (error: RuntimeException) {
            reportFailure(STAGE_LANGUAGE, error = error)
        }
        appliedLanguageTag = languageTag
    }

    private fun registerDuckedUtterance(utteranceId: String) {
        synchronized(focusLock) {
            duckingUtteranceIds.add(utteranceId)
            if (duckingUtteranceIds.size == 1) {
                requestAudioFocus()
            }
        }
    }

    private fun requestAudioFocus() {
        val manager = audioManager
        if (manager == null) {
            reportFailure(STAGE_AUDIO_FOCUS_REQUEST)
            return
        }
        try {
            val attributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            val request = AudioFocusRequest.Builder(
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK,
            ).setAudioAttributes(attributes).build()
            val result = manager.requestAudioFocus(request)
            if (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                focusRequest = request
            } else {
                reportFailure(STAGE_AUDIO_FOCUS_REQUEST, code = result)
            }
        } catch (error: RuntimeException) {
            reportFailure(STAGE_AUDIO_FOCUS_REQUEST, error = error)
        }
    }

    private fun releaseAudioFocus(utteranceId: String?) {
        if (utteranceId == null) {
            return
        }
        synchronized(focusLock) {
            if (duckingUtteranceIds.remove(utteranceId) && duckingUtteranceIds.isEmpty()) {
                abandonAudioFocus()
            }
        }
    }

    private fun releaseAllAudioFocus() {
        synchronized(focusLock) {
            duckingUtteranceIds.clear()
            abandonAudioFocus()
        }
    }

    private fun abandonAudioFocus() {
        val manager = audioManager ?: return
        val request = focusRequest ?: return
        focusRequest = null
        try {
            val result = manager.abandonAudioFocusRequest(request)
            if (result != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                reportFailure(STAGE_AUDIO_FOCUS_RELEASE, code = result)
            }
        } catch (error: RuntimeException) {
            reportFailure(STAGE_AUDIO_FOCUS_RELEASE, error = error)
        }
    }

    private fun reportFailure(
        stage: String,
        code: Int? = null,
        error: RuntimeException? = null,
    ) {
        val message = if (code == null) {
            "TTS failure at stage=$stage"
        } else {
            "TTS failure at stage=$stage code=$code"
        }
        if (error == null) {
            Log.w(LOG_TAG, message)
        } else {
            Log.w(LOG_TAG, message, error)
        }
    }

    private class FocusReleasingListener : UtteranceProgressListener() {
        override fun onStart(utteranceId: String?) {}

        override fun onDone(utteranceId: String?) {
            releaseAudioFocus(utteranceId)
        }

        @Deprecated("Deprecated in the platform API; onError(String, int) is preferred")
        override fun onError(utteranceId: String?) {
            reportFailure(STAGE_UTTERANCE)
            releaseAudioFocus(utteranceId)
        }

        override fun onError(utteranceId: String?, errorCode: Int) {
            reportFailure(STAGE_UTTERANCE, code = errorCode)
            releaseAudioFocus(utteranceId)
        }

        override fun onStop(utteranceId: String?, interrupted: Boolean) {
            releaseAudioFocus(utteranceId)
        }
    }

    private const val LOG_TAG = "EndurainTTS"
    private const val STAGE_INITIALIZATION = "initialization"
    private const val STAGE_LISTENER_REGISTRATION = "listener_registration"
    private const val STAGE_SPEAK = "speak"
    private const val STAGE_ENQUEUE = "enqueue"
    private const val STAGE_LANGUAGE = "language"
    private const val STAGE_FALLBACK_LANGUAGE = "fallback_language"
    private const val STAGE_AUDIO_FOCUS_REQUEST = "audio_focus_request"
    private const val STAGE_AUDIO_FOCUS_RELEASE = "audio_focus_release"
    private const val STAGE_UTTERANCE = "utterance"
    private const val STAGE_STOP = "stop"
    private const val STAGE_SHUTDOWN = "shutdown"
}
