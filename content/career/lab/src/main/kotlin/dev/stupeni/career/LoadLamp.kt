package dev.stupeni.career

interface StatusRepository {
    fun fetchLampOn(): Result<Boolean>
}

class LoadLamp(private val repository: StatusRepository) {
    fun execute(state: LampState): LampState = TODO("C3: LoadLamp.execute")
}
