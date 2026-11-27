package com.endurain.endurain.wear

import android.annotation.SuppressLint
import android.content.Context
import android.os.SystemClock
import androidx.core.content.ContextCompat
import androidx.health.services.client.ExerciseClient
import androidx.health.services.client.ExerciseUpdateCallback
import androidx.health.services.client.HealthServices
import androidx.health.services.client.data.Availability
import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.DataTypeAvailability
import androidx.health.services.client.data.DeltaDataType
import androidx.health.services.client.data.ExerciseConfig
import androidx.health.services.client.data.ExerciseLapSummary
import androidx.health.services.client.data.ExerciseState
import androidx.health.services.client.data.ExerciseTrackedStatus
import androidx.health.services.client.data.ExerciseType
import androidx.health.services.client.data.ExerciseUpdate
import androidx.health.services.client.data.LocationAccuracy
import androidx.health.services.client.data.LocationAvailability
import androidx.health.services.client.data.WarmUpConfig
import com.endurain.endurain.watchlink.WatchActivityType
import kotlinx.coroutines.guava.await
import java.time.Instant
import kotlin.math.roundToInt

/** A GPS fix of an [ExerciseSnapshot], already in wall-clock time. */
data class GatewayLocation(
    val timestampMillis: Long,
    val latitude: Double,
    val longitude: Double,
    val altitude: Double,
    val bearing: Double,
    val horizontalErrorMeters: Double?,
    val verticalErrorMeters: Double?,
)

/** Where the exercise is in its life, reduced to what the recorder acts on. */
enum class GatewayExerciseState { ACTIVE, PAUSED, ENDED, OTHER }

/** One Health Services update, free of Health Services types so the recorder is testable on the JVM. */
data class ExerciseSnapshot(
    val state: GatewayExerciseState,
    val heartRateBpm: Int? = null,
    val heartRateAtMillis: Long? = null,
    val distanceTotalMeters: Double? = null,
    val activeDurationMillis: Long? = null,
    val locations: List<GatewayLocation> = emptyList(),
)

/** How well a sensor delivers right now. */
enum class SensorStatus { UNKNOWN, AVAILABLE, ACQUIRING, UNAVAILABLE }

interface ExerciseListener {
    fun onUpdate(snapshot: ExerciseSnapshot)

    fun onAvailabilityChanged(
        metric: WorkoutMetric,
        status: SensorStatus,
    )

    fun onRegistrationFailed(error: Throwable)
}

/**
 * The part of Health Services the recorder depends on. The real
 * implementation wraps [ExerciseClient]; tests use a fake.
 */
interface ExerciseGateway {
    /** The metrics this watch can record for [type], or null when it cannot record it at all. */
    suspend fun supportedMetrics(type: WatchActivityType): Set<WorkoutMetric>?

    /** Warms the sensors up for a countdown. */
    suspend fun prepare(
        type: WatchActivityType,
        metrics: Set<WorkoutMetric>,
    )

    suspend fun start(
        type: WatchActivityType,
        metrics: Set<WorkoutMetric>,
    )

    suspend fun pause()

    suspend fun resume()

    suspend fun end()

    /** Whether this app owns the exercise Health Services is running. Throws when it cannot tell. */
    suspend fun ownsRunningExercise(): Boolean

    /**
     * Whether another app is recording an exercise, which starting ours
     * would end. Throws when it cannot tell.
     */
    suspend fun otherAppHasExercise(): Boolean

    fun setListener(listener: ExerciseListener)

    suspend fun clearListener()
}

class HealthServicesExerciseGateway(context: Context) : ExerciseGateway {
    // Updates are delivered on the main thread, where the recorder keeps its
    // state; the recorder moves the file writes off it. Passed explicitly so
    // the callback does not depend on the client's default executor.
    private val callbackExecutor = ContextCompat.getMainExecutor(context.applicationContext)
    private val client: ExerciseClient by lazy { HealthServices.getClient(context.applicationContext).exerciseClient }
    private var registered: ExerciseUpdateCallback? = null

    override suspend fun supportedMetrics(type: WatchActivityType): Set<WorkoutMetric>? {
        val exerciseType = exerciseType(type)
        val capabilities = client.getCapabilitiesAsync().await()
        if (exerciseType !in capabilities.supportedExerciseTypes) return null
        val supported = capabilities.getExerciseTypeCapabilities(exerciseType).supportedDataTypes
        return WorkoutMetric.entries.filter { dataType(it) in supported }.toSet()
    }

    override suspend fun prepare(
        type: WatchActivityType,
        metrics: Set<WorkoutMetric>,
    ) {
        val warmUpTypes = metrics.map(Companion::dataType).filterIsInstance<DeltaDataType<*, *>>().toSet()
        client.prepareExerciseAsync(WarmUpConfig(exerciseType(type), warmUpTypes)).await()
    }

    override suspend fun start(
        type: WatchActivityType,
        metrics: Set<WorkoutMetric>,
    ) {
        val dataTypes = metrics.map(Companion::dataType).toSet()
        val config =
            ExerciseConfig.builder(exerciseType(type))
                .setDataTypes(dataTypes)
                .setIsAutoPauseAndResumeEnabled(false)
                .setIsGpsEnabled(DataType.LOCATION in dataTypes)
                .build()
        client.startExerciseAsync(config).await()
    }

    override suspend fun pause() {
        client.pauseExerciseAsync().await()
    }

    override suspend fun resume() {
        client.resumeExerciseAsync().await()
    }

    override suspend fun end() {
        client.endExerciseAsync().await()
    }

    // The ExerciseTrackedStatus constants are public API; lint misreads the
    // library's restriction on their companion object.
    @SuppressLint("RestrictedApi")
    override suspend fun ownsRunningExercise(): Boolean =
        trackedStatus() == ExerciseTrackedStatus.OWNED_EXERCISE_IN_PROGRESS

    @SuppressLint("RestrictedApi")
    override suspend fun otherAppHasExercise(): Boolean =
        trackedStatus() == ExerciseTrackedStatus.OTHER_APP_IN_PROGRESS

    private suspend fun trackedStatus(): Int = client.getCurrentExerciseInfoAsync().await().exerciseTrackedStatus

    override fun setListener(listener: ExerciseListener) {
        val callback =
            object : ExerciseUpdateCallback {
                override fun onExerciseUpdateReceived(update: ExerciseUpdate) {
                    listener.onUpdate(snapshot(update))
                }

                override fun onLapSummaryReceived(lapSummary: ExerciseLapSummary) {}

                override fun onRegistered() {}

                override fun onRegistrationFailed(throwable: Throwable) {
                    listener.onRegistrationFailed(throwable)
                }

                override fun onAvailabilityChanged(
                    dataType: DataType<*, *>,
                    availability: Availability,
                ) {
                    val metric = metric(dataType) ?: return
                    listener.onAvailabilityChanged(metric, status(availability))
                }
            }
        registered = callback
        client.setUpdateCallback(callbackExecutor, callback)
    }

    override suspend fun clearListener() {
        val callback = registered ?: return
        registered = null
        client.clearUpdateCallbackAsync(callback).await()
    }

    private fun snapshot(update: ExerciseUpdate): ExerciseSnapshot {
        val bootInstant = Instant.ofEpochMilli(System.currentTimeMillis() - SystemClock.elapsedRealtime())
        val metrics = update.latestMetrics
        val heartRate = metrics.getData(DataType.HEART_RATE_BPM).lastOrNull()
        val state = update.exerciseStateInfo.state
        return ExerciseSnapshot(
            state =
                when {
                    state.isEnded -> GatewayExerciseState.ENDED
                    state.isPaused -> GatewayExerciseState.PAUSED
                    state == ExerciseState.ACTIVE -> GatewayExerciseState.ACTIVE
                    else -> GatewayExerciseState.OTHER
                },
            heartRateBpm = heartRate?.value?.roundToInt(),
            heartRateAtMillis = heartRate?.getTimeInstant(bootInstant)?.toEpochMilli(),
            distanceTotalMeters = metrics.getData(DataType.DISTANCE_TOTAL)?.total,
            activeDurationMillis = update.activeDurationCheckpoint?.activeDuration?.toMillis(),
            locations =
                metrics.getData(DataType.LOCATION).map { sample ->
                    val accuracy = sample.accuracy as? LocationAccuracy
                    GatewayLocation(
                        timestampMillis = sample.getTimeInstant(bootInstant).toEpochMilli(),
                        latitude = sample.value.latitude,
                        longitude = sample.value.longitude,
                        // Unavailable values are NaN, which the mapper drops.
                        altitude = sample.value.altitude,
                        bearing = sample.value.bearing,
                        horizontalErrorMeters = accuracy?.horizontalPositionErrorMeters,
                        verticalErrorMeters = accuracy?.verticalPositionErrorMeters,
                    )
                },
        )
    }

    private fun status(availability: Availability): SensorStatus =
        when (availability) {
            DataTypeAvailability.AVAILABLE,
            LocationAvailability.ACQUIRED_TETHERED,
            LocationAvailability.ACQUIRED_UNTETHERED,
            -> SensorStatus.AVAILABLE
            DataTypeAvailability.ACQUIRING, LocationAvailability.ACQUIRING -> SensorStatus.ACQUIRING
            DataTypeAvailability.UNAVAILABLE,
            DataTypeAvailability.UNAVAILABLE_DEVICE_OFF_BODY,
            LocationAvailability.NO_GNSS,
            LocationAvailability.UNAVAILABLE,
            -> SensorStatus.UNAVAILABLE
            else -> SensorStatus.UNKNOWN
        }

    private fun metric(dataType: DataType<*, *>): WorkoutMetric? =
        when (dataType) {
            DataType.HEART_RATE_BPM -> WorkoutMetric.HEART_RATE
            DataType.LOCATION -> WorkoutMetric.LOCATION
            DataType.DISTANCE_TOTAL -> WorkoutMetric.DISTANCE
            else -> null
        }

    companion object {
        fun dataType(metric: WorkoutMetric): DataType<*, *> =
            when (metric) {
                WorkoutMetric.HEART_RATE -> DataType.HEART_RATE_BPM
                WorkoutMetric.LOCATION -> DataType.LOCATION
                WorkoutMetric.DISTANCE -> DataType.DISTANCE_TOTAL
            }

        fun exerciseType(type: WatchActivityType): ExerciseType =
            when (type) {
                WatchActivityType.RUN -> ExerciseType.RUNNING
                WatchActivityType.RIDE -> ExerciseType.BIKING
                WatchActivityType.WALK -> ExerciseType.WALKING
                WatchActivityType.HIKE -> ExerciseType.HIKING
            }
    }
}
