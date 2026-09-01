package com.endurain.endurain.activity

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * JVM unit tests for the native activity-recorder serialization models.
 *
 * These models are the durability contract between the Android background
 * recorder and the Dart side: points and sessions are persisted as JSON and
 * later drained/recovered. A regression here would silently corrupt or drop a
 * user's recorded activity, so the round-trip and validation behavior is
 * locked down here. The JSON keys must stay byte-compatible with the Dart
 * models in `lib/features/activity/models/`.
 */
class ActiveRecordingModelsTest {

    // ── ActiveActivitySessionData ──────────────────────────────────────────

    @Test
    fun sessionRoundTripsThroughJsonPreservingEveryField() {
        val session = ActiveActivitySessionData(
            localSessionId = "activity_123",
            activityType = "run",
            status = ActiveActivitySessionData.STATUS_PAUSED,
            startedAt = "2026-07-15T10:00:00.000Z",
            connectionOrigin = "https://example.test",
            connectionProfileId = "42",
            heartRateDeviceId = "AA:BB:CC:DD",
            powerDeviceId = "PW:11:22:33",
            cadenceDeviceId = "CA:44:55:66",
            resumedAt = "2026-07-15T10:05:00.000Z",
            pausedAt = "2026-07-15T10:10:00.000Z",
            endedAt = "2026-07-15T10:20:00.000Z",
            elapsedDurationSeconds = 600,
            currentSegmentIndex = 3,
        )

        val decoded = ActiveActivitySessionData.fromJson(session.toJson())

        assertEquals(session, decoded)
    }

    @Test
    fun sessionOmitsNullOptionalFieldsFromJson() {
        val session = ActiveActivitySessionData(
            localSessionId = "activity_1",
            activityType = "ride",
            status = ActiveActivitySessionData.STATUS_RECORDING,
            startedAt = "2026-07-15T10:00:00.000Z",
        )

        val json = session.toJson()

        assertFalse(json.has("connectionOrigin"))
        assertFalse(json.has("connectionProfileId"))
        assertFalse(json.has("resumedAt"))
        assertFalse(json.has("pausedAt"))
        assertFalse(json.has("endedAt"))
    }

    // ── Sensor binding (drives the Android 14+ foreground-service type) ────

    @Test
    fun sessionWithoutSensorIdsHasNoSensorBinding() {
        val session = baseSession()

        assertFalse(session.hasAnySensorBinding())
    }

    @Test
    fun sessionWithEmptySensorIdsHasNoSensorBinding() {
        val session = baseSession().copy(
            heartRateDeviceId = "",
            powerDeviceId = "",
            cadenceDeviceId = "",
        )

        assertFalse(session.hasAnySensorBinding())
    }

    @Test
    fun sessionWithAnySingleSensorIdHasSensorBinding() {
        val base = baseSession()

        assertTrue(base.copy(heartRateDeviceId = "AA:BB").hasAnySensorBinding())
        assertTrue(base.copy(powerDeviceId = "CC:DD").hasAnySensorBinding())
        assertTrue(base.copy(cadenceDeviceId = "EE:FF").hasAnySensorBinding())
    }

    private fun baseSession() = ActiveActivitySessionData(
        localSessionId = "activity_1",
        activityType = "run",
        status = ActiveActivitySessionData.STATUS_RECORDING,
        startedAt = "2026-07-15T10:00:00.000Z",
    )

    @Test
    fun sessionMapCarriesSchemaVersionAndCanonicalKeys() {
        val session = ActiveActivitySessionData(
            localSessionId = "activity_1",
            activityType = "walk",
            status = ActiveActivitySessionData.STATUS_RECORDING,
            startedAt = "2026-07-15T10:00:00.000Z",
        )

        val map = session.toMap()

        assertEquals(
            ActiveActivitySessionData.SCHEMA_VERSION,
            map["schemaVersion"],
        )
        assertEquals("activity_1", map["localSessionId"])
        assertEquals("walk", map["activityType"])
        assertFalse(map.containsKey("endedAt"))
    }

    @Test
    fun sessionFromJsonReturnsNullWhenLocalSessionIdMissing() {
        val json = JSONObject()
            .put("activityType", "run")
            .put("status", ActiveActivitySessionData.STATUS_RECORDING)
            .put("startedAt", "2026-07-15T10:00:00.000Z")

        assertNull(ActiveActivitySessionData.fromJson(json))
    }

    @Test
    fun sessionFromJsonReturnsNullWhenStartedAtMissing() {
        val json = JSONObject()
            .put("localSessionId", "activity_1")
            .put("activityType", "run")
            .put("status", ActiveActivitySessionData.STATUS_RECORDING)

        assertNull(ActiveActivitySessionData.fromJson(json))
    }

    @Test
    fun sessionFromJsonDefaultsStatusToFailedWhenAbsent() {
        val json = JSONObject()
            .put("localSessionId", "activity_1")
            .put("startedAt", "2026-07-15T10:00:00.000Z")

        val decoded = ActiveActivitySessionData.fromJson(json)

        assertEquals(ActiveActivitySessionData.STATUS_FAILED, decoded?.status)
    }

    @Test
    fun sessionIsActiveOnlyWhileRecordingOrPaused() {
        fun sessionWith(status: String) = ActiveActivitySessionData(
            localSessionId = "activity_1",
            activityType = "run",
            status = status,
            startedAt = "2026-07-15T10:00:00.000Z",
        )

        assertTrue(
            sessionWith(ActiveActivitySessionData.STATUS_RECORDING).isActive,
        )
        assertTrue(
            sessionWith(ActiveActivitySessionData.STATUS_PAUSED).isActive,
        )
        assertFalse(
            sessionWith(ActiveActivitySessionData.STATUS_STOPPING).isActive,
        )
        assertFalse(
            sessionWith(ActiveActivitySessionData.STATUS_COMPLETED).isActive,
        )
        assertFalse(
            sessionWith(ActiveActivitySessionData.STATUS_FAILED).isActive,
        )
    }

    @Test
    fun sessionRequiresLocationMonitoringWhileRecordingOrAutomaticallyPaused() {
        fun sessionWith(status: String, pausedAutomatically: Boolean = false) =
            ActiveActivitySessionData(
                localSessionId = "activity_1",
                activityType = "run",
                status = status,
                startedAt = "2026-07-15T10:00:00.000Z",
                pausedAutomatically = pausedAutomatically,
            )

        assertTrue(
            sessionWith(ActiveActivitySessionData.STATUS_RECORDING)
                .requiresLocationMonitoring,
        )
        assertTrue(
            sessionWith(
                ActiveActivitySessionData.STATUS_PAUSED,
                pausedAutomatically = true,
            ).requiresLocationMonitoring,
        )
        assertFalse(
            sessionWith(ActiveActivitySessionData.STATUS_PAUSED)
                .requiresLocationMonitoring,
        )
        assertFalse(
            sessionWith(
                ActiveActivitySessionData.STATUS_COMPLETED,
                pausedAutomatically = true,
            ).requiresLocationMonitoring,
        )
    }

    @Test
    fun sessionTimingKeepsPausedElapsedTimeFrozen() {
        val session = baseSession().copy(
            status = ActiveActivitySessionData.STATUS_PAUSED,
            resumedAt = "2026-07-15T10:05:00.000Z",
            elapsedDurationSeconds = 300,
        )

        val elapsedSeconds = SessionTiming.elapsedSeconds(
            session,
            IsoTime.toEpochMillis("2026-07-15T11:00:00.000Z")!!,
        )

        assertEquals(300, elapsedSeconds)
    }

    @Test
    fun sessionTimingAddsOnlyTheCurrentResumedSegment() {
        val session = baseSession().copy(
            resumedAt = "2026-07-15T10:10:00.000Z",
            elapsedDurationSeconds = 300,
        )

        val elapsedSeconds = SessionTiming.elapsedSeconds(
            session,
            IsoTime.toEpochMillis("2026-07-15T10:12:00.000Z")!!,
        )

        assertEquals(420, elapsedSeconds)
    }

    // ── RecordedActivityPointData ──────────────────────────────────────────

    @Test
    fun pointRoundTripsThroughJsonPreservingEveryField() {
        val point = RecordedActivityPointData(
            timestamp = "2026-07-15T10:00:01.000Z",
            latitude = 38.7223,
            longitude = -9.1393,
            segmentIndex = 2,
            elevationMeters = 100.5,
            horizontalAccuracyMeters = 4.0,
            verticalAccuracyMeters = 6.0,
            headingDegrees = 180.0,
            headingAccuracyDegrees = 5.0,
            speedMetersPerSecond = 3.2,
            speedAccuracyMetersPerSecond = 0.5,
            heartRateBpm = 142,
            powerWatts = 250,
            cadenceRpm = 82,
        )

        val decoded = RecordedActivityPointData.fromJson(point.toJson())

        assertEquals(point, decoded)
    }

    @Test
    fun pointUsesShortJsonKeysMatchingTheDartParser() {
        val point = RecordedActivityPointData(
            timestamp = "2026-07-15T10:00:01.000Z",
            latitude = 1.0,
            longitude = 2.0,
            segmentIndex = 0,
            elevationMeters = 3.0,
        )

        val json = point.toJson()

        assertEquals("2026-07-15T10:00:01.000Z", json.getString("t"))
        assertEquals(1.0, json.getDouble("lat"), 0.0)
        assertEquals(2.0, json.getDouble("lon"), 0.0)
        assertEquals(0, json.getInt("seg"))
        assertEquals(3.0, json.getDouble("ele"), 0.0)
        assertFalse(json.has("spd"))
    }

    @Test
    fun pointFromJsonReturnsNullWhenCoordinatesMissing() {
        val json = JSONObject().put("t", "2026-07-15T10:00:01.000Z")

        assertNull(RecordedActivityPointData.fromJson(json))
    }

    @Test
    fun pointFromJsonReturnsNullForOutOfRangeCoordinates() {
        val latTooHigh = JSONObject()
            .put("t", "2026-07-15T10:00:01.000Z")
            .put("lat", 91.0)
            .put("lon", 0.0)
        val lonTooLow = JSONObject()
            .put("t", "2026-07-15T10:00:01.000Z")
            .put("lat", 0.0)
            .put("lon", -181.0)

        assertNull(RecordedActivityPointData.fromJson(latTooHigh))
        assertNull(RecordedActivityPointData.fromJson(lonTooLow))
    }

    @Test
    fun tryParseLineSkipsBlankAndMalformedLines() {
        assertNull(RecordedActivityPointData.tryParseLine(""))
        assertNull(RecordedActivityPointData.tryParseLine("   "))
        assertNull(RecordedActivityPointData.tryParseLine("not json"))
        assertNull(RecordedActivityPointData.tryParseLine("{\"t\":\"x\"}"))
    }

    @Test
    fun tryParseLineParsesAValidStoredLine() {
        val line = RecordedActivityPointData(
            timestamp = "2026-07-15T10:00:01.000Z",
            latitude = 10.0,
            longitude = 20.0,
            segmentIndex = 1,
        ).toJsonLine()

        val parsed = RecordedActivityPointData.tryParseLine(line)

        assertEquals(10.0, parsed?.latitude)
        assertEquals(20.0, parsed?.longitude)
        assertEquals(1, parsed?.segmentIndex)
    }

    // ── IsoTime ────────────────────────────────────────────────────────────

    @Test
    fun isoTimeFormatsUtcWithTrailingZ() {
        // 2026-07-15T10:00:00.000Z == 1_784_109_600_000 ms since epoch.
        val formatted = IsoTime.format(java.util.Date(1_784_109_600_000L))

        assertEquals("2026-07-15T10:00:00.000Z", formatted)
    }

    @Test
    fun isoTimeParsesUtcToEpochMillisAtSecondPrecision() {
        val millis = IsoTime.toEpochMillis("2026-07-15T10:00:00.000Z")

        assertEquals(1_784_109_600_000L, millis)
    }

    @Test
    fun isoTimeRoundTripsAtSecondPrecision() {
        val original = "2026-07-15T10:00:00.000Z"

        val millis = IsoTime.toEpochMillis(original)
        val formatted = IsoTime.format(java.util.Date(millis!!))

        assertEquals(original, formatted)
    }

    @Test
    fun isoTimeReturnsNullForNullOrMalformedInput() {
        assertNull(IsoTime.toEpochMillis(null))
        assertNull(IsoTime.toEpochMillis(""))
        assertNull(IsoTime.toEpochMillis("not-a-timestamp"))
    }
}
