package com.bamabin.app.ui.screen.splash

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ElevatedButton
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.TextUnitType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import coil.ImageLoader
import coil.compose.AsyncImage
import coil.decode.GifDecoder
import coil.request.ImageRequest
import com.bamabin.app.BuildConfig
import com.bamabin.app.R
import com.bamabin.app.data.remote.model.app.AppVersion
import com.bamabin.app.ui.theme.RedColor
import com.bamabin.app.ui.theme.YellowColor
import com.bamabin.app.utils.ApkUpdateHelper
import com.bamabin.app.utils.DataResult
import com.bamabin.app.utils.Routes
import java.io.File
import kotlin.system.exitProcess

private val UpdateAccent = Color(0xFF2BB4F4)
private val UpdateDialogBg = Color(0xFF191919)
private val UpdateOverlay = Color(0xCC0D0D0D)
private val UpdateTitle = Color(0xFFF5EFE6)
private val UpdateBody = Color.White.copy(alpha = 0.6f)
private val UpdateBorder = Color.White.copy(alpha = 0.06f)
private val ProgressTrack = Color(0xFF2E2E2E)

@Composable
fun SplashScreen(
    modifier: Modifier,
    navHostController: NavHostController,
    viewModel: SplashViewModel = hiltViewModel()
) {
    val result by viewModel.result.collectAsState()
    val downloadState by viewModel.downloadState.collectAsState()
    val context = LocalContext.current
    val permissionLauncher =
        rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { }
    val urlLauncher =
        rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { }
    var showUpdateAlert by remember { mutableStateOf(false) }
    var pendingInstallFile by remember { mutableStateOf<File?>(null) }

    val installPermissionLauncher =
        rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) {
            val file = pendingInstallFile
            if (file != null && ApkUpdateHelper.canInstallPackages(context)) {
                ApkUpdateHelper.installApk(context, file)
            }
        }

    val imageLoader = ImageLoader.Builder(context)
        .components {
            add(GifDecoder.Factory())
        }
        .build()

    LaunchedEffect(Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && context.checkSelfPermission(
                Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    LaunchedEffect(result) {
        if (result is DataResult.DataSuccess) {
            if (!result.data!!.needUpdate) {
                navHostController.popBackStack()
                navHostController.navigate(Routes.MAIN.name)
            } else {
                showUpdateAlert = true
            }
        }
    }

    LaunchedEffect(downloadState) {
        when (val state = downloadState) {
            is UpdateDownloadUiState.ReadyToInstall -> {
                pendingInstallFile = state.file
                if (ApkUpdateHelper.canInstallPackages(context)) {
                    ApkUpdateHelper.installApk(context, state.file)
                } else {
                    installPermissionLauncher.launch(
                        ApkUpdateHelper.createUnknownSourcesIntent(context)
                    )
                }
            }

            is UpdateDownloadUiState.Error -> {
                Toast.makeText(context, state.message, Toast.LENGTH_LONG).show()
                viewModel.resetDownloadState()
            }

            else -> Unit
        }
    }

    Box(
        modifier = modifier.fillMaxSize()
    ) {
        if (result is DataResult.DataLoading) {
            AsyncImage(
                model = ImageRequest.Builder(LocalContext.current)
                    .data(R.drawable.splash)
                    .build(),
                contentDescription = null,
                imageLoader = imageLoader,
                contentScale = ContentScale.FillBounds,
                modifier = Modifier.fillMaxSize()
            )
            Text(
                text = "نسخه ${BuildConfig.VERSION_NAME}",
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 24.dp)
                    .background(
                        color = Color(0xFF3D352F).copy(alpha = 0.85f),
                        shape = RoundedCornerShape(8.dp)
                    )
                    .padding(all = 8.dp),
                color = Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = TextUnit(14f, TextUnitType.Sp)
            )
            CircularProgressIndicator(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 96.dp),
                color = YellowColor
            )
        }
    }

    if (showUpdateAlert && result.data != null) {
        val appVersion = result.data!!
        when (val state = downloadState) {
            is UpdateDownloadUiState.Downloading -> {
                UpdateProgressDialog(
                    appVersion = appVersion,
                    downloadedBytes = state.downloadedBytes,
                    totalBytes = state.totalBytes,
                    percent = state.percent,
                )
            }

            is UpdateDownloadUiState.ReadyToInstall -> {
                UpdateProgressDialog(
                    appVersion = appVersion,
                    downloadedBytes = state.file.length(),
                    totalBytes = state.file.length(),
                    percent = 100,
                )
            }

            else -> {
                UpdateAlertDialog(
                    appVersion = appVersion,
                    onUpdateClick = {
                        viewModel.startApkDownload(appVersion.directLink)
                    },
                    onDismissClick = {
                        if (!appVersion.isRequires) {
                            showUpdateAlert = false
                            viewModel.resetDownloadState()
                            navHostController.popBackStack()
                            navHostController.navigate(Routes.MAIN.name)
                        }
                    },
                )
            }
        }
    }

    if (result is DataResult.DataError) {
        ErrorAlert(
            message = result.message,
            onRetryClick = {
                viewModel.fetchData()
            },
            onSupportClick = {
                urlLauncher.launch(
                    Intent(Intent.ACTION_VIEW, Uri.parse("https://t.me/Bamabin_Support"))
                )
            },
            onExitClick = {
                exitProcess(0)
            }
        )
    }
}

@Composable
private fun UpdateAlertDialog(
    appVersion: AppVersion,
    onUpdateClick: () -> Unit,
    onDismissClick: () -> Unit,
) {
    Dialog(
        onDismissRequest = {
            if (!appVersion.isRequires) onDismissClick()
        },
        properties = DialogProperties(
            dismissOnBackPress = !appVersion.isRequires,
            dismissOnClickOutside = false,
            usePlatformDefaultWidth = false,
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(UpdateOverlay),
            contentAlignment = Alignment.Center
        ) {
            UpdateDialogCard {
                UpdateDialogHeader(appVersion)

                if (appVersion.isRequires) {
                    Text(
                        text = "این بروز رسانی اجباریست.",
                        color = UpdateBody,
                        fontSize = TextUnit(14f, TextUnitType.Sp),
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth()
                    )
                }

                if (appVersion.isRequires) {
                    UpdatePrimaryButton(
                        text = "بروزرسانی",
                        onClick = onUpdateClick,
                        modifier = Modifier.fillMaxWidth()
                    )
                } else {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        UpdatePrimaryButton(
                            text = "بروزرسانی",
                            onClick = onUpdateClick,
                            modifier = Modifier.weight(1f)
                        )
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(38.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .clickable(onClick = onDismissClick),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "بی خیالش!",
                                color = Color.White,
                                fontWeight = FontWeight.Bold,
                                fontSize = TextUnit(12.5f, TextUnitType.Sp)
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun UpdateProgressDialog(
    appVersion: AppVersion,
    downloadedBytes: Long,
    totalBytes: Long,
    percent: Int,
) {
    Dialog(
        onDismissRequest = {},
        properties = DialogProperties(
            dismissOnBackPress = false,
            dismissOnClickOutside = false,
            usePlatformDefaultWidth = false,
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(UpdateOverlay),
            contentAlignment = Alignment.Center
        ) {
            UpdateDialogCard {
                UpdateDialogHeader(appVersion)

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(ProgressTrack)
                ) {
                    val fraction = if (totalBytes > 0) {
                        (downloadedBytes.toFloat() / totalBytes.toFloat()).coerceIn(0f, 1f)
                    } else {
                        0f
                    }
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(fraction.coerceAtLeast(0.02f))
                            .height(4.dp)
                            .clip(RoundedCornerShape(999.dp))
                            .background(UpdateAccent)
                    )
                }

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 4.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    val sizeLabel = if (totalBytes > 0) {
                        "${percent}% (${ApkUpdateHelper.formatBytes(downloadedBytes)} از ${ApkUpdateHelper.formatBytes(totalBytes)})"
                    } else {
                        "${ApkUpdateHelper.formatBytes(downloadedBytes)}"
                    }
                    Text(
                        text = sizeLabel,
                        color = Color.White,
                        fontSize = TextUnit(12f, TextUnitType.Sp),
                        modifier = Modifier.weight(1f)
                    )
                    Text(
                        text = "درحال دانلود ...",
                        color = Color.White,
                        fontSize = TextUnit(12f, TextUnitType.Sp),
                        textAlign = TextAlign.End,
                        modifier = Modifier.weight(1f)
                    )
                }

                UpdatePrimaryButton(
                    text = "درحال دانلود",
                    onClick = {},
                    enabled = false,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}

@Composable
private fun UpdateDialogCard(content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 40.dp)
            .border(1.dp, UpdateBorder, RoundedCornerShape(20.dp))
            .background(UpdateDialogBg, RoundedCornerShape(20.dp))
            .padding(17.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        Box(
            modifier = Modifier
                .size(68.dp)
                .shadow(11.dp, CircleShape, ambientColor = UpdateAccent.copy(alpha = 0.3f))
                .background(UpdateAccent, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Filled.Refresh,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(38.dp)
            )
        }
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            content()
        }
    }
}

@Composable
private fun UpdateDialogHeader(appVersion: AppVersion) {
    Text(
        text = "بروزرسانی اپلیکیشن",
        color = UpdateTitle,
        fontWeight = FontWeight.Bold,
        fontSize = TextUnit(16f, TextUnitType.Sp),
        textAlign = TextAlign.Center,
        modifier = Modifier.fillMaxWidth()
    )
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = "نسخه جدید اپلیکیشن آماده است.",
            color = UpdateBody,
            fontSize = TextUnit(14f, TextUnitType.Sp),
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
        Text(
            text = "نسخه: ${appVersion.versionName}",
            color = UpdateBody,
            fontSize = TextUnit(14f, TextUnitType.Sp),
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
    }
    if (appVersion.description.isNotBlank()) {
        Text(
            text = appVersion.description,
            color = UpdateBody,
            fontSize = TextUnit(14f, TextUnitType.Sp),
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

@Composable
private fun UpdatePrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    Box(
        modifier = modifier
            .height(38.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(UpdateAccent.copy(alpha = if (enabled) 1f else 0.5f))
            .then(if (enabled) Modifier.clickable(onClick = onClick) else Modifier),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            color = Color.White,
            fontWeight = FontWeight.Bold,
            fontSize = TextUnit(12.5f, TextUnitType.Sp)
        )
    }
}

@Composable
private fun ErrorAlert(
    message: String,
    onRetryClick: () -> Unit,
    onSupportClick: () -> Unit,
    onExitClick: () -> Unit,
) {
    AlertDialog(
        shape = RoundedCornerShape(8.dp),
        containerColor = Color(0xFF2B2B2B),
        onDismissRequest = {},
        confirmButton = {},
        text = {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    message,
                    fontWeight = FontWeight.SemiBold,
                    textAlign = TextAlign.Center
                )

                Spacer(Modifier.height(16.dp))

                ElevatedButton(
                    colors = ButtonDefaults.buttonColors(
                        contentColor = Color.Black,
                        containerColor = YellowColor
                    ),
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier.fillMaxWidth(),
                    onClick = onRetryClick
                ) {
                    Text("تلاش مجدد", fontWeight = FontWeight.SemiBold)
                }

                Spacer(Modifier.height(16.dp))

                ElevatedButton(
                    colors = ButtonDefaults.buttonColors(
                        contentColor = Color.Black,
                        containerColor = YellowColor
                    ),
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier.fillMaxWidth(),
                    onClick = onSupportClick
                ) {
                    Text("ارتباط با پشتیبانی", fontWeight = FontWeight.SemiBold)
                }

                Spacer(Modifier.height(16.dp))

                TextButton(
                    modifier = Modifier.fillMaxWidth(),
                    onClick = onExitClick
                ) {
                    Text("خروج", color = RedColor)
                }
            }
        }
    )
}
