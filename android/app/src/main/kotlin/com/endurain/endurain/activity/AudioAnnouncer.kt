package com.endurain.endurain.activity

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
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
 * ducked utterance finishes.
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
        val appContext = context.applicationContext
        ensureInitialized(appContext)
        val engine = tts
        if (engine == null || !ready) {
            pending.add(PendingUtterance(text, duck, languageTag))
            return
        }
        speakNow(appContext, engine, text, duck, languageTag)
    }

    /** Stops any in-progress or queued utterance and releases audio focus. */
    fun stop() {
        pending.clear()
        tts?.stop()
        releaseAllAudioFocus()
    }

    /** Releases the engine entirely. Used by tests; production never calls this. */
    fun shutdown() {
        stop()
        tts?.shutdown()
        tts = null
        ready = false
        appliedLanguageTag = null
    }

    private fun ensureInitialized(context: Context) {
        if (tts != null) {
            return
        }
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        tts = TextToSpeech(context) { status ->
            ready = status == TextToSpeech.SUCCESS
            if (ready) {
                tts?.setOnUtteranceProgressListener(FocusReleasingListener())
                flushPending(context)
            } else {
                pending.clear()
            }
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
        applyLanguage(engine, languageTag)
        val utteranceId = "announcement_${System.nanoTime()}"
        if (duck) {
            registerDuckedUtterance(utteranceId)
        }
        val result = engine.speak(text, TextToSpeech.QUEUE_ADD, Bundle(), utteranceId)
        if (result == TextToSpeech.ERROR) {
            releaseAudioFocus(utteranceId)
        }
    }

    private fun applyLanguage(engine: TextToSpeech, languageTag: String) {
        if (languageTag.isEmpty() || languageTag == appliedLanguageTag) {
            return
        }
        val locale = Locale.forLanguageTag(languageTag)
        val result = engine.setLanguage(locale)
        if (result == TextToSpeech.LANG_MISSING_DATA ||
            result == TextToSpeech.LANG_NOT_SUPPORTED
        ) {
            // Fall back to the device default rather than silently failing to
            // speak at all; better to announce in the wrong accent than not
            // to announce.
            engine.setLanguage(Locale.getDefault())
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
        val manager = audioManager ?: return
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
            .build()
        val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
            .setAudioAttributes(attributes)
            .build()
        manager.requestAudioFocus(request)
        focusRequest = request
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
        manager.abandonAudioFocusRequest(request)
        focusRequest = null
    }

    private class FocusReleasingListener : UtteranceProgressListener() {
        override fun onStart(utteranceId: String?) {}

        override fun onDone(utteranceId: String?) {
            releaseAudioFocus(utteranceId)
        }

        @Deprecated("Deprecated in the platform API; onError(String, int) is preferred")
        override fun onError(utteranceId: String?) {
            releaseAudioFocus(utteranceId)
        }

        override fun onError(utteranceId: String?, errorCode: Int) {
            releaseAudioFocus(utteranceId)
        }

        override fun onStop(utteranceId: String?, interrupted: Boolean) {
            releaseAudioFocus(utteranceId)
        }
    }
}
