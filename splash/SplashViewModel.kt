package com.bamabin.app.ui.screen.splash

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bamabin.app.data.local.TempDB
import com.bamabin.app.data.remote.model.app.AppVersion
import com.bamabin.app.repo.AppRepository
import com.bamabin.app.repo.UserRepository
import com.bamabin.app.repo.VideosRepository
import com.bamabin.app.utils.ApkUpdateHelper
import com.bamabin.app.utils.DataResult
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.File
import javax.inject.Inject

sealed interface UpdateDownloadUiState {
    data object Idle : UpdateDownloadUiState
    data class Downloading(
        val downloadedBytes: Long,
        val totalBytes: Long,
    ) : UpdateDownloadUiState {
        val percent: Int
            get() = if (totalBytes > 0) {
                ((downloadedBytes * 100) / totalBytes).toInt().coerceIn(0, 100)
            } else {
                0
            }
    }

    data class ReadyToInstall(val file: File) : UpdateDownloadUiState
    data class Error(val message: String) : UpdateDownloadUiState
}

@HiltViewModel
class SplashViewModel @Inject constructor(
    @ApplicationContext private val appContext: Context,
    private val repository: AppRepository,
    private val videosRepository: VideosRepository,
    private val userRepository: UserRepository
) : ViewModel() {

    private val _result = MutableStateFlow<DataResult<AppVersion>>(DataResult.DataLoading())
    val result: StateFlow<DataResult<AppVersion>> = _result

    private val _downloadState =
        MutableStateFlow<UpdateDownloadUiState>(UpdateDownloadUiState.Idle)
    val downloadState: StateFlow<UpdateDownloadUiState> = _downloadState.asStateFlow()

    private var downloadJob: Job? = null

    init {
        ApkUpdateHelper.cleanupLeftoverApks(appContext)
        viewModelScope.launch {
            val isSetup = repository.isSetupNewApp()
            if (!isSetup) {
                userRepository.logout(false)
                repository.setupNewApp()
            }
            fetchData()
        }
    }

    fun fetchData() = viewModelScope.launch {
        val r0 = setBaseUrl(false)
        if (r0 is DataResult.DataError) {
            _result.value = DataResult.DataError(r0.message)
            return@launch
        }

        _result.value = DataResult.DataLoading()
        var r1 = repository.getStartupData()
        if (r1 is DataResult.DataError) {
            setBaseUrl(true)
            r1 = repository.getStartupData()
        }
        if (r1 is DataResult.DataError) {
            _result.value = r1
            return@launch
        }

        val r2 = videosRepository.getHomeSections()
        if (r2 is DataResult.DataError) {
            _result.value = DataResult.DataError(r2.message)
            return@launch
        }
        TempDB.setHomeSections(r2.data!!)

        repository.getSearchTaxonomies()

        _result.value = r1
    }

    fun startApkDownload(url: String) {
        if (url.isBlank()) {
            _downloadState.value = UpdateDownloadUiState.Error("لینک دانلود معتبر نیست")
            return
        }
        if (downloadJob?.isActive == true) return

        downloadJob = viewModelScope.launch {
            _downloadState.value = UpdateDownloadUiState.Downloading(0L, 0L)
            try {
                var lastReportedPercent = -1
                val file = ApkUpdateHelper.downloadApk(
                    context = appContext,
                    url = url,
                    onProgress = { downloaded, total ->
                        val reportKey = if (total > 0) {
                            ((downloaded * 100) / total).toInt().coerceIn(0, 100)
                        } else {
                            // update roughly every 256KB when size is unknown
                            -1 - (downloaded / (256 * 1024)).toInt()
                        }
                        if (reportKey != lastReportedPercent) {
                            lastReportedPercent = reportKey
                            _downloadState.value =
                                UpdateDownloadUiState.Downloading(downloaded, total)
                        }
                    }
                )
                _downloadState.value = UpdateDownloadUiState.ReadyToInstall(file)
            } catch (e: Exception) {
                ApkUpdateHelper.cleanupLeftoverApks(appContext)
                _downloadState.value = UpdateDownloadUiState.Error(
                    e.message?.takeIf { it.isNotBlank() } ?: "دانلود با خطا مواجه شد"
                )
            }
        }
    }

    fun resetDownloadState() {
        downloadJob?.cancel()
        downloadJob = null
        _downloadState.value = UpdateDownloadUiState.Idle
    }

    private suspend fun setBaseUrl(forceNew: Boolean): DataResult<Any> {
        if (!forceNew) {
            if (repository.setBaseUrl()) return DataResult.DataSuccess("")
        }

        val r = repository.getBaseUrl()
        if (r is DataResult.DataError) return DataResult.DataError(r.message)

        return DataResult.DataSuccess("")
    }
}
