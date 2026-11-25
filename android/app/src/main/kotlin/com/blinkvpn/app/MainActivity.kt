package com.blinkvpn.app

// Psiphon 应急模式（代理模式，第 1 阶段），Kotlin 侧。
//
// 不复制上游 PsiphonTunnel.java：那份文件在本次任务中被执行风险检查拦截，
// 不能直接复制进仓库。这里改为直接调用官方 AAR 里的 psi.Psi（gomobile 绑定），
// 接口经 pkg.go.dev 的 psi 包文档核对：
//   Psi.start(configJson, embeddedServerEntryList, embeddedServerEntryListFilename,
//             provider, useDeviceBinder, useIPv6Synthesizer, useHasIPv6RouteGetter)
//   Psi.stop()
//   PsiphonProvider: notice(String), onAccessToken(String),
//     bindToDevice(long): String, hasNetworkConnectivity(): long,
//     getNetworkID(): String, iPv6Synthesize(String): String,
//     hasIPv6Route(): long, getDNSServersAsString(): String
// 通知类型经 psiphon/notice.go 核对：Tunnels(count)、ListeningSocksProxyPort(port)、
// ListeningHttpProxyPort(port)、ClientRegion(region)、ConnectedServerRegion(region)、
// EstablishTunnelTimeout。
//
// 注意：这仍是代理模式，不是全设备 VPN。VpnService + tun2socks 全设备路由是第 2 阶段，未做。
// 代码来源：Kilo nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free 起草，
// Bike 审阅后重写：修正了原稿不存在的 getHttpProxyPort() / tunnel.connected、
// startTunneling 立即报成功、每次回调新建 MethodChannel、
// 以及 configureFlutterEngine 未调 super 的问题。
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import psi.Psi
import psi.PsiphonProvider
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private var socksPort: Int = 0
    private var httpPort: Int = 0
    private var region: String = ""
    @Volatile
    private var started: Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "blink_vpn/psiphon"
        )
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startPsiphon" -> {
                    executor.execute {
                        try {
                            startPsiphon()
                            // start() 只表示已开始启动，连通以 Tunnels 通知为准。
                            runOnUiThread {
                                result.success(
                                    mapOf(
                                        "started" to true,
                                        "socksPort" to socksPort,
                                        "httpPort" to httpPort
                                    )
                                )
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error(
                                    "START_ERROR",
                                    e.message ?: e.toString(),
                                    null
                                )
                            }
                        }
                    }
                }
                "stopPsiphon" -> {
                    executor.execute {
                        try {
                            Psi.stop()
                        } catch (_: Exception) {
                            // 停止失败也不阻塞 Dart 侧复位。
                        }
                        started = false
                        socksPort = 0
                        httpPort = 0
                        region = ""
                        runOnUiThread { result.success(null) }
                    }
                }
                "psiphonStatus" -> {
                    result.success(
                        mapOf(
                            "started" to started,
                            "socksPort" to socksPort,
                            "httpPort" to httpPort,
                            "region" to region
                        )
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startPsiphon() {
        if (started) return
        val configJson = buildPsiphonConfig()
        val embedded = assets.open("psiphon_serverlist.txt")
            .bufferedReader().use { it.readText() }
        Psi.start(
            configJson,
            embedded,
            "",
            PsiphonProviderShim(),
            false, // useDeviceBinder：代理模式不做 VpnService 绑定
            false, // useIPv6Synthesizer
            true   // useHasIPv6RouteGetter
        )
        started = true
    }

    // 从 res/raw/psiphon_config.json 读配置，并补齐 Psiphon 要求的运行期字段。
    // SponsorId / PropagationChannelId 必须是 Blink 自己向 Psiphon Inc. 申请的，
    // 占位值填在这里时隧道会启动失败，见该 JSON 文件头的 TODO。
    private fun buildPsiphonConfig(): String {
        val raw = resources.openRawResource(R.raw.psiphon_config)
            .bufferedReader().use { it.readText() }
        val json = JSONObject(raw)
        val dataDir = File(filesDir, "ca.psiphon.PsiphonTunnel.tunnel-core")
        if (!dataDir.exists()) dataDir.mkdirs()
        if (!json.has("DataRootDirectory")) {
            json.put("DataRootDirectory", dataDir.absolutePath)
        }
        if (!json.has("EstablishTunnelTimeoutSeconds")) {
            json.put("EstablishTunnelTimeoutSeconds", 0)
        }
        if (!json.has("LocalSocksProxyPort") || json.optInt("LocalSocksProxyPort") == 0) {
            json.put("LocalSocksProxyPort", 1080)
        }
        if (!json.has("LocalHttpProxyPort") || json.optInt("LocalHttpProxyPort") == 0) {
            json.put("LocalHttpProxyPort", 8080)
        }
        json.put("DeviceRegion", java.util.Locale.getDefault().country)
        json.put("ClientVersion", "1")
        return json.toString()
    }

    private fun postNotice(message: String, extra: Map<String, Any?> = emptyMap()) {
        val payload = mutableMapOf<String, Any?>("message" to message)
        payload.putAll(extra)
        runOnUiThread { channel?.invokeMethod("onPsiphonNotice", payload) }
    }

    private fun postConnected() {
        runOnUiThread {
            channel?.invokeMethod(
                "onPsiphonConnected",
                mapOf(
                    "socksPort" to socksPort,
                    "httpPort" to httpPort,
                    "region" to region
                )
            )
        }
    }

    private fun postError(message: String) {
        runOnUiThread {
            channel?.invokeMethod("onPsiphonError", mapOf("message" to message))
        }
    }

    // psi.PsiphonProvider 的 Kotlin 实现（gomobile 绑定接口）。
    private inner class PsiphonProviderShim : PsiphonProvider {
        override fun notice(noticeJSON: String) {
            try {
                val obj = JSONObject(noticeJSON)
                val type = obj.optString("noticeType")
                val data = obj.optJSONObject("data")
                when (type) {
                    "ListeningSocksProxyPort" -> {
                        socksPort = data?.optInt("port") ?: socksPort
                        postNotice("SOCKS 代理已监听：$socksPort", mapOf("socksPort" to socksPort))
                    }
                    "ListeningHttpProxyPort" -> {
                        httpPort = data?.optInt("port") ?: httpPort
                        postNotice("HTTP 代理已监听：$httpPort", mapOf("httpPort" to httpPort))
                    }
                    "Tunnels" -> {
                        val count = data?.optInt("count") ?: 0
                        if (count > 0) {
                            postNotice("隧道已建立：$count 条")
                            postConnected()
                        } else {
                            postNotice("隧道已断开")
                        }
                    }
                    "ClientRegion", "ConnectedServerRegion" -> {
                        region = data?.optString("region") ?: region
                        postNotice("出口地区：$region", mapOf("region" to region))
                    }
                    "EstablishTunnelTimeout" -> {
                        postError("建立隧道超时，请重试")
                    }
                    "Info", "Warning" -> {
                        val msg = data?.optString("message") ?: return
                        postNotice(msg)
                    }
                    else -> {
                        // 其他通知只转发原文，Dart 侧可见，便于排障。
                        postNotice("$type：${data?.toString() ?: ""}")
                    }
                }
            } catch (_: Exception) {
                postNotice(noticeJSON)
            }
        }

        override fun onAccessToken(token: String) {
            // 应急模式不做推送注册，忽略。
        }

        override fun bindToDevice(fileDescriptor: Long): String {
            throw IllegalStateException("bindToDevice 未实现（代理模式不需要）")
        }

        override fun hasNetworkConnectivity(): Long {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val net = cm.activeNetwork
                val caps = net?.let { cm.getNetworkCapabilities(it) }
                if (caps != null &&
                    (caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                        caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR))
                ) 1L else 0L
            } else {
                @Suppress("DEPRECATION")
                if (cm.activeNetworkInfo?.isConnected == true) 1L else 0L
            }
        }

        override fun getNetworkID(): String = "UNKNOWN"

        override fun iPv6Synthesize(iPv4Addr: String): String = ""

        override fun hasIPv6Route(): Long = 0L

        override fun getDNSServersAsString(): String = ""
    }

    override fun onResume() {
        super.onResume()
        if (started) {
            executor.execute {
                try {
                    Psi.reconnectTunnel()
                } catch (_: Exception) {
                }
            }
        }
    }

    override fun onDestroy() {
        executor.execute {
            try {
                Psi.stop()
            } catch (_: Exception) {
            }
        }
        super.onDestroy()
    }
}
