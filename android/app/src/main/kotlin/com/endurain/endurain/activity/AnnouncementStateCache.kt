package com.endurain.endurain.activity

/** Keeps live announcement progress in memory between durable checkpoints. */
internal class AnnouncementStateCache(
    private val checkpointIntervalMillis: Long = DEFAULT_CHECKPOINT_INTERVAL_MILLIS,
) {
    private var persistedState: AnnouncementStateData? = null
    private var lastCheckpointUptimeMillis: Long? = null

    var state: AnnouncementStateData? = null
        private set

    init {
        require(checkpointIntervalMillis > 0)
    }

    fun restore(state: AnnouncementStateData, uptimeMillis: Long) {
        this.state = state
        persistedState = state
        lastCheckpointUptimeMillis = uptimeMillis
    }

    fun update(state: AnnouncementStateData) {
        this.state = state
    }

    fun stateToPersist(
        uptimeMillis: Long,
        force: Boolean = false,
    ): AnnouncementStateData? {
        val current = state ?: return null
        if (current == persistedState) {
            return null
        }
        val lastCheckpoint = lastCheckpointUptimeMillis ?: return current
        return if (force || uptimeMillis - lastCheckpoint >= checkpointIntervalMillis) {
            current
        } else {
            null
        }
    }

    fun markPersisted(uptimeMillis: Long) {
        persistedState = state
        lastCheckpointUptimeMillis = uptimeMillis
    }

    fun reset() {
        state = null
        persistedState = null
        lastCheckpointUptimeMillis = null
    }

    companion object {
        const val DEFAULT_CHECKPOINT_INTERVAL_MILLIS = 60_000L
    }
}