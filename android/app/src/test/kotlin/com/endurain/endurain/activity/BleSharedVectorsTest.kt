package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Runs the BLE wire-format vectors in test/fixtures/ble_*_vectors.json, which
 * the Dart parser tests also run, so both decoders agree on the wire format.
 */
class BleSharedVectorsTest {

    @Test
    fun heartRateVectors() {
        val cases = SharedFixtures.load("ble_heart_rate_vectors.json").getJSONArray("cases")
        assertTrue(cases.length() > 0)
        for (i in 0 until cases.length()) {
            val spec = cases.getJSONObject(i)
            val actual = HeartRateGattClient.parseHeartRate(
                SharedFixtures.hexToBytes(spec.getString("hex")),
            )
            assertEquals(spec.getString("name"), expectedInt(spec, "bpm"), actual)
        }
    }

    @Test
    fun cyclingSpeedCadenceCrankVectors() {
        val cases = SharedFixtures.load("ble_cycling_speed_cadence_vectors.json")
            .getJSONArray("cases")
        assertTrue(cases.length() > 0)
        for (i in 0 until cases.length()) {
            val spec = cases.getJSONObject(i)
            val name = spec.getString("name")
            val actual = CadenceGattClient.parseCscCrank(
                SharedFixtures.hexToBytes(spec.getString("hex")),
            )
            assertEquals(name, expectedInt(spec, "crankRevolutions"), actual?.first)
            assertEquals(name, expectedInt(spec, "lastCrankEventTime"), actual?.second)
        }
    }

    @Test
    fun cyclingPowerVectors() {
        val cases = SharedFixtures.load("ble_cycling_power_vectors.json").getJSONArray("cases")
        assertTrue(cases.length() > 0)
        for (i in 0 until cases.length()) {
            val spec = cases.getJSONObject(i)
            val actual = CyclingPowerGattClient.parsePowerWatts(
                SharedFixtures.hexToBytes(spec.getString("hex")),
            )
            assertEquals(spec.getString("name"), expectedInt(spec, "watts"), actual)
        }
    }

    @Test
    fun heartRateRejectsTruncatedEnergyField() {
        assertNull(HeartRateGattClient.parseHeartRate(SharedFixtures.hexToBytes("083C00")))
    }

    private fun expectedInt(spec: org.json.JSONObject, key: String): Int? =
        if (spec.isNull(key)) null else spec.getInt(key)
}
