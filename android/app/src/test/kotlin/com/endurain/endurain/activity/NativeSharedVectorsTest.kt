package com.endurain.endurain.activity

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Runs the cross-platform vectors in test/fixtures (geo_distance, announcement_*
 * and session_timing). The Swift tests in ios/RunnerTests/NativeSharedVectorsTests.swift
 * run the same files, so the duplicated native logic cannot drift.
 */
class NativeSharedVectorsTest {

    private fun JSONArray.objects(): List<JSONObject> =
        (0 until length()).map { getJSONObject(it) }

    private fun JSONObject.intOrNull(key: String): Int? =
        if (isNull(key)) null else getInt(key)

    private fun JSONObject.stringOrNull(key: String): String? =
        if (isNull(key)) null else getString(key)

    private fun JSONObject.longOrNull(key: String): Long? =
        if (isNull(key)) null else getLong(key)

    private fun stateFrom(config: JSONObject, initial: JSONObject?): AnnouncementStateData {
        val base = AnnouncementStateData(
            enabled = config.getBoolean("enabled"),
            duckOtherAudio = true,
            intervalUnit = config.getString("intervalUnit"),
            distanceIntervalMeters = config.getDouble("distanceIntervalMeters"),
            timeIntervalSeconds = config.getInt("timeIntervalSeconds"),
            useImperialUnits = config.getBoolean("useImperialUnits"),
            metric = config.getString("metric"),
            languageTag = config.getString("languageTag"),
            distanceUnitTemplate = config.getString("distanceUnitTemplate"),
            metricUnitTemplate = config.getString("metricUnitTemplate"),
            metricLabel = config.getString("metricLabel"),
            messageTemplate = config.getString("messageTemplate"),
        )
        if (initial == null) {
            return base
        }
        return base.copy(
            cumulativeDistanceMeters =
                initial.optDouble("cumulativeDistanceMeters", base.cumulativeDistanceMeters),
            lastAnnouncedDistanceIndex =
                initial.optInt("lastAnnouncedDistanceIndex", base.lastAnnouncedDistanceIndex),
            lastAnnouncedTimeIndex =
                initial.optInt("lastAnnouncedTimeIndex", base.lastAnnouncedTimeIndex),
            lastLatitude = initial.optDoubleOrNull("lastLatitude"),
            lastLongitude = initial.optDoubleOrNull("lastLongitude"),
            lastElapsedSeconds = initial.optInt("lastElapsedSeconds", base.lastElapsedSeconds),
            lastAnnouncementDistanceMeters = initial.optDouble(
                "lastAnnouncementDistanceMeters",
                base.lastAnnouncementDistanceMeters,
            ),
            lastAnnouncementElapsedSeconds = initial.optInt(
                "lastAnnouncementElapsedSeconds",
                base.lastAnnouncementElapsedSeconds,
            ),
        )
    }

    @Test
    fun geoDistanceVectors() {
        val json = SharedFixtures.load("geo_distance_vectors.json")
        val tolerance = json.getDouble("toleranceMeters")
        val cases = json.getJSONArray("cases").objects()
        assertTrue(cases.isNotEmpty())
        for (spec in cases) {
            val actual = GeoDistance.haversineMeters(
                spec.getDouble("lat1"),
                spec.getDouble("lon1"),
                spec.getDouble("lat2"),
                spec.getDouble("lon2"),
            )
            assertEquals(spec.getString("name"), spec.getDouble("meters"), actual, tolerance)
        }
    }

    @Test
    fun thresholdCalculatorVectors() {
        val cases = SharedFixtures.load("announcement_threshold_vectors.json")
            .getJSONArray("cases").objects()
        assertTrue(cases.isNotEmpty())
        for (spec in cases) {
            val name = spec.getString("name")
            val actual = AnnouncementThresholdCalculator.latestCrossing(
                intervalValue = spec.getDouble("intervalValue"),
                previousCumulative = spec.getDouble("previousCumulative"),
                newCumulative = spec.getDouble("newCumulative"),
                lastAnnouncedIndex = spec.getInt("lastAnnouncedIndex"),
            )
            if (spec.isNull("expect")) {
                assertNull(name, actual)
                continue
            }
            val expect = spec.getJSONObject("expect")
            assertNotNull(name, actual)
            assertEquals(name, expect.getInt("thresholdIndex"), actual!!.thresholdIndex)
            assertEquals(name, expect.getDouble("thresholdValue"), actual.thresholdValue, 1e-9)
            assertEquals(
                name,
                expect.getDouble("interpolationFraction"),
                actual.interpolationFraction,
                1e-9,
            )
        }
    }

    @Test
    fun speechBuilderVectors() {
        val cases = SharedFixtures.load("announcement_speech_vectors.json")
            .getJSONArray("cases").objects()
        assertTrue(cases.isNotEmpty())
        for (spec in cases) {
            val name = spec.getString("name")
            val state = stateFrom(spec.getJSONObject("config"), null)
            val actual = if (spec.optBoolean("preview", false)) {
                AnnouncementSpeechBuilder.buildPreview(state)
            } else {
                AnnouncementSpeechBuilder.build(
                    state.copy(
                        lastAnnouncementDistanceMeters =
                            spec.getDouble("lastAnnouncementDistanceMeters"),
                        lastAnnouncementElapsedSeconds =
                            spec.getInt("lastAnnouncementElapsedSeconds"),
                    ),
                    spec.getDouble("distanceMeters"),
                    spec.getInt("elapsedSeconds"),
                )
            }
            assertEquals(name, spec.getString("expect"), actual)
        }
    }

    @Test
    fun schedulerVectors() {
        val cases = SharedFixtures.load("announcement_scheduler_vectors.json")
            .getJSONArray("cases").objects()
        assertTrue(cases.isNotEmpty())
        for (spec in cases) {
            val name = spec.getString("name")
            var state = stateFrom(spec.getJSONObject("config"), spec.optJSONObject("initial"))
            for ((index, step) in spec.getJSONArray("steps").objects().withIndex()) {
                val label = "$name: step $index"
                val result = if (step.getString("type") == "fix") {
                    AnnouncementScheduler.onFix(
                        state = state,
                        latitude = step.getDouble("latitude"),
                        longitude = step.getDouble("longitude"),
                        elapsedSeconds = step.getInt("elapsedSeconds"),
                        isNewSegment = step.getBoolean("isNewSegment"),
                    )
                } else {
                    AnnouncementScheduler.onElapsedTime(state, step.getInt("elapsedSeconds"))
                }
                state = result.state
                val expected = step.getJSONArray("expectAnnouncements")
                assertEquals(
                    label,
                    (0 until expected.length()).map { expected.getString(it) },
                    result.announcements,
                )
                val expectState = step.getJSONObject("expectState")
                assertEquals(
                    label,
                    expectState.getDouble("cumulativeDistanceMeters"),
                    state.cumulativeDistanceMeters,
                    1e-6,
                )
                assertEquals(
                    label,
                    expectState.getInt("lastAnnouncedDistanceIndex"),
                    state.lastAnnouncedDistanceIndex,
                )
                assertEquals(
                    label,
                    expectState.getInt("lastAnnouncedTimeIndex"),
                    state.lastAnnouncedTimeIndex,
                )
                assertEquals(
                    label,
                    expectState.getInt("lastElapsedSeconds"),
                    state.lastElapsedSeconds,
                )
                assertEquals(
                    label,
                    expectState.getDouble("lastAnnouncementDistanceMeters"),
                    state.lastAnnouncementDistanceMeters,
                    1e-6,
                )
                assertEquals(
                    label,
                    expectState.getInt("lastAnnouncementElapsedSeconds"),
                    state.lastAnnouncementElapsedSeconds,
                )
            }
        }
    }

    private fun sessionFrom(spec: JSONObject) = ActiveActivitySessionData(
        localSessionId = "vector",
        activityType = "run",
        status = spec.getString("status"),
        startedAt = spec.getString("startedAt"),
        resumedAt = spec.stringOrNull("resumedAt"),
        pausedAt = spec.stringOrNull("pausedAt"),
        endedAt = spec.stringOrNull("endedAt"),
        elapsedDurationSeconds = spec.getInt("elapsedDurationSeconds"),
    )

    @Test
    fun sessionTimingElapsedVectors() {
        val cases = SharedFixtures.load("session_timing_vectors.json")
            .getJSONArray("elapsedCases").objects()
        assertTrue(cases.isNotEmpty())
        for (spec in cases) {
            val actual = SessionTiming.elapsedSeconds(
                sessionFrom(spec.getJSONObject("session")),
                spec.getLong("referenceMillis"),
            )
            assertEquals(spec.getString("name"), spec.getInt("elapsedSeconds"), actual)
        }
    }

    @Test
    fun sessionTimingInterruptionVectors() {
        val cases = SharedFixtures.load("session_timing_vectors.json")
            .getJSONArray("interruptionCases").objects()
        assertTrue(cases.isNotEmpty())
        for (spec in cases) {
            val name = spec.getString("name")
            val actual = SessionTiming.afterInterruption(
                sessionFrom(spec.getJSONObject("session")),
                spec.longOrNull("lastPointMillis"),
                spec.getLong("nowMillis"),
            )
            val expect = spec.getJSONObject("expect")
            assertEquals(name, expect.getString("status"), actual.status)
            assertEquals(name, expect.stringOrNull("resumedAt"), actual.resumedAt)
            assertEquals(name, expect.stringOrNull("pausedAt"), actual.pausedAt)
            assertEquals(name, expect.stringOrNull("endedAt"), actual.endedAt)
            assertEquals(
                name,
                expect.getInt("elapsedDurationSeconds"),
                actual.elapsedDurationSeconds,
            )
        }
    }
}
