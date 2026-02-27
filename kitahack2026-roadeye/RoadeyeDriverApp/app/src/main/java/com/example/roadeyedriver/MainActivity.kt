package com.example.roadeyedriver

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import com.example.roadeyedriver.ui.theme.RoadeyeDriverTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            RoadeyeDriverTheme {
                RoadEyeApp()
            }
        }
    }
}

@Composable
fun RoadEyeApp() {
    val context = LocalContext.current
    var showPermissionDialog by remember { mutableStateOf(false) }
    var isRoadEyeStarted by remember { mutableStateOf(false) }

    val permissionsLauncher =
        rememberLauncherForActivityResult(
            ActivityResultContracts.RequestMultiplePermissions()
        ) { permissions ->
            val cameraGranted = permissions[Manifest.permission.CAMERA] ?: false
            val locationGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] ?: false
            
            if (!cameraGranted || !locationGranted) {
                showPermissionDialog = true
            }
        }

    fun checkAndStartRoadEye() {
        val cameraGranted = ContextCompat.checkSelfPermission(
            context, Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
        
        val locationGranted = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        
        if (cameraGranted && locationGranted) {
            isRoadEyeStarted = !isRoadEyeStarted // Toggle state for now
        } else {
            permissionsLauncher.launch(arrayOf(
                Manifest.permission.CAMERA,
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ))
        }
    }

    Scaffold { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Camera Feed Area (Top 60%)
            Box(
                modifier = Modifier
                    .weight(0.6f)
                    .fillMaxWidth()
            ) {
                if (isRoadEyeStarted) {
                    CameraPreviewView(modifier = Modifier.fillMaxSize())
                } else {
                    // Optional dark background to fill space when off
                    Surface(
                        modifier = Modifier.fillMaxSize(),
                        color = MaterialTheme.colorScheme.surfaceVariant
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Text("Camera is off")
                        }
                    }
                }
            }

            // Map & Controls Area (Bottom 40%) - Fixed size so it doesn't move
            Box(
                modifier = Modifier
                    .weight(0.4f)
                    .fillMaxWidth()
            ) {
                OsmMapView(
                    modifier = Modifier.fillMaxSize()
                )

                // Start RoadEye Button
                Button(
                    onClick = {
                        checkAndStartRoadEye()
                    },
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(bottom = 32.dp)
                        .fillMaxWidth(0.6f)
                ) {
                    Text(if (isRoadEyeStarted) "Stop RoadEye" else "Start RoadEye")
                }
            }
        }

        // Permission Denial Dialog
        if (showPermissionDialog) {
            AlertDialog(
                onDismissRequest = { showPermissionDialog = false },
                title = { Text("Camera Permission Required") },
                text = { Text("Camera permission is required for RoadEye to analyze the road and detect potholes. Please enable it in your phone's settings.") },
                confirmButton = {
                    TextButton(
                        onClick = {
                            showPermissionDialog = false
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.fromParts("package", context.packageName, null)
                            }
                            context.startActivity(intent)
                        }
                    ) {
                        Text("Go to Settings")
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showPermissionDialog = false }) {
                        Text("Cancel")
                    }
                }
            )
        }
    }

    // Request permissions immediately when the app opens
    LaunchedEffect(Unit) {
        val cameraGranted = ContextCompat.checkSelfPermission(
            context, Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
        
        val locationGranted = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (!cameraGranted || !locationGranted) {
            permissionsLauncher.launch(arrayOf(
                Manifest.permission.CAMERA,
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ))
        }
    }
}
