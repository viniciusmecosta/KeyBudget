package com.vinicius.key_budget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.content.ContextWrapper
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

/** Exercises actual RemoteViews, including reflection, on Android (not a mock UI). */
class WidgetRenderingTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val target = instrumentation.targetContext
    private val fixtures by lazy {
        JSONObject(instrumentation.context.assets.open("widget_palettes.json")
            .bufferedReader().use { it.readText() })
    }

    private fun context(dark: Boolean, scale: Float = 1f): Context {
        val configuration = Configuration(target.resources.configuration)
        configuration.uiMode = (configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or
            if (dark) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO
        configuration.fontScale = scale
        configuration.densityDpi = 320
        return target.createConfigurationContext(configuration)
    }

    private fun render(
        context: Context,
        receiver: KeyBudgetWidgetReceiver,
        appearance: JSONObject,
        width: Int,
        height: Int,
        signedIn: Boolean = true,
    ): View {
        // Separate test preferences: never read or change the user's widget data.
        val preferences = target.getSharedPreferences("widget_rendering_fixtures", Context.MODE_PRIVATE)
        val date = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.ROOT).format(java.util.Date())
        preferences.edit().clear()
            .putString("widget_appearance", appearance.toString())
            .putString("widget_user_id", if (signedIn) "demo" else "")
            .putString("widget_status", if (signedIn) "active" else "logged_out")
            .putLong("widget_reveal_until_123", Long.MAX_VALUE)
            .putString("widget_snapshot", JSONObject().apply {
                put("uid", "demo"); put("date", date)
                put("spent", "R$ 1.248,90"); put("income", "R$ 4.500,00")
                put("balance", "R$ 3.251,10"); put("upcoming", "R$ 389,90")
                put("upcoming_count", 3); put("show_income", true)
            }.toString()).commit()
        val remote = receiver.createViews(context, 123, preferences, height, System.currentTimeMillis())
        val view = remote.apply(context, null)
        val density = context.resources.displayMetrics.density
        view.measure(View.MeasureSpec.makeMeasureSpec((width * density).toInt(), View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec((height * density).toInt(), View.MeasureSpec.EXACTLY))
        view.layout(0, 0, view.measuredWidth, view.measuredHeight)
        assertTrue(view.measuredWidth > 0)
        return view
    }

    @Test fun everyVariantAppliesBothPalettesAndKeepsRoundedTransparentCorners() {
        instrumentation.runOnMainSync {
            for (dark in listOf(false, true)) {
                for (color in listOf("violet", "teal")) {
                    val appearance = JSONObject(fixtures.getJSONObject(color).toString())
                    val palette = appearance.getJSONObject(if (dark) "dark" else "light")
                    val c = context(dark)
                    val variants = listOf(
                        Triple(KeyBudgetWidgetReceiver(), 180, 180),
                        Triple(KeyBudgetCompactWidgetReceiver(), 360, 64),
                        Triple(KeyBudgetOverviewWidgetReceiver(), 360, 210),
                        Triple(KeyBudgetUpcomingWidgetReceiver(), 180, 180),
                        Triple(KeyBudgetQuickWidgetReceiver(), 72, 72),
                    )
                    for ((receiver, width, height) in variants) {
                        val view = render(c, receiver, appearance, width, height)
                        val bitmap = bitmap(view)
                        assertEquals("Transparent rounded corner", 0, Color.alpha(bitmap.getPixel(0, 0)))
                        assertEquals("Theme surface", palette.getLong("background").toInt(),
                            bitmap.getPixel(bitmap.width / 2, 4))
                        view.findViewById<TextView>(R.id.tv_monthly_spent)?.let {
                            assertEquals(palette.getLong("foreground").toInt(), it.currentTextColor)
                            assertEquals("R$ 1.248,90".takeIf { receiver !is KeyBudgetUpcomingWidgetReceiver }
                                ?: "R$ 389,90", it.text.toString())
                        }
                    }
                }
            }
        }
    }

    @Test fun explicitModeOverridesSystemAndSignedOutStateSurvivesLargeText() {
        instrumentation.runOnMainSync {
            val appearance = JSONObject(fixtures.getJSONObject("teal").toString()).put("mode", "dark")
            val view = render(context(false, 2f), KeyBudgetCompactWidgetReceiver(), appearance, 280, 80, false)
            assertEquals("Entre no app", view.findViewById<TextView>(R.id.tv_monthly_spent).text.toString())
            assertEquals(appearance.getJSONObject("dark").getLong("foreground").toInt(),
                view.findViewById<TextView>(R.id.tv_monthly_spent).currentTextColor)
        }
    }

    @Test fun themePreviewIsPublishedBeforeAnyWidgetIsInstalled() {
        org.junit.Assume.assumeTrue(Build.VERSION.SDK_INT >= 35)
        instrumentation.runOnMainSync {
            val c = context(false)
            val appearance = JSONObject(fixtures.getJSONObject("violet").toString())
            render(c, KeyBudgetOverviewWidgetReceiver(), appearance, 360, 210)
            val preferences = target.getSharedPreferences("widget_rendering_fixtures", Context.MODE_PRIVATE)
            val isolated = object : ContextWrapper(c) {
                override fun getSharedPreferences(name: String, mode: Int): SharedPreferences = preferences
            }
            KeyBudgetOverviewWidgetReceiver().onReceive(isolated,
                Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf()))
            val preview = AppWidgetManager.getInstance(c).getWidgetPreview(
                ComponentName(c, KeyBudgetOverviewWidgetReceiver::class.java), null,
                AppWidgetProviderInfo.WIDGET_CATEGORY_HOME_SCREEN)
            assertNotNull("Theme preview must exist even with no installed widget", preview)
            val view = preview!!.apply(c, null)
            assertEquals("Previews must never reveal financial values", "R$ •••••",
                view.findViewById<TextView>(R.id.tv_monthly_spent).text.toString())
            assertEquals(appearance.getJSONObject("light").getLong("foreground").toInt(),
                view.findViewById<TextView>(R.id.tv_monthly_spent).currentTextColor)
        }
    }

    @Test fun savedLedgerRemainsUsableAcrossMidnightAndRejectsMalformedData() {
        val saved = JSONObject().apply {
            put("version", 2); put("uid", "demo"); put("date", "2026-12-31")
            put("daily", JSONObject("""{"2026-12-31":[30,10000,2],"2027-01-01":[1250,0,1],"2027-01-02":[2000,0,1]}"""))
        }
        val current = WidgetSnapshotData.forDate(saved, "2027-01-01")
        assertEquals("2027-01-01", current.getString("date"))
        assertTrue(current.getString("spent").contains("12,50"))
        assertTrue(current.getString("upcoming").contains("20,00"))
        assertEquals(WidgetDisplayState.VISIBLE, WidgetDisplayState.resolve(
            "demo", current.getString("uid"), current.getString("date"),
            "2027-01-01", true, 2000, 1000))
        assertEquals("2026-12-31", saved.getString("date"))
        saved.put("daily", JSONObject("""{"invalid":[1]}"""))
        assertEquals("2026-12-31", WidgetSnapshotData.forDate(saved, "2027-01-01").getString("date"))
    }

    @Test fun captureReadmeWidgetGallery() {
        if (InstrumentationRegistry.getArguments().getString("captureWidgets") != "true") return
        instrumentation.runOnMainSync {
            for (dark in listOf(false, true)) {
                val c = context(dark)
                val appearance = JSONObject(fixtures.getJSONObject("violet").toString())
                val density = c.resources.displayMetrics.density
                fun dp(value: Int) = (value * density).toInt()
                val gallery = LinearLayout(c).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(dp(20), dp(24), dp(20), dp(24))
                    setBackgroundColor(if (dark) Color.rgb(17, 18, 22) else Color.WHITE)
                }
                fun label(text: String, size: Float, top: Int = 0) {
                    gallery.addView(TextView(c).apply {
                        this.text = text; textSize = size
                        setTextColor(if (dark) Color.WHITE else Color.rgb(25, 26, 30))
                        setPadding(0, dp(top), 0, dp(12))
                    })
                }
                fun card(receiver: KeyBudgetWidgetReceiver, width: Int, height: Int): View =
                    render(c, receiver, appearance, width, height)
                label("Widgets · KeyBudget", 21f)
                label("Resumo financeiro", 13f, 8)
                gallery.addView(card(KeyBudgetOverviewWidgetReceiver(), 372, 210),
                    LinearLayout.LayoutParams(-1, dp(210)))
                label("Gastos do mês e próximos gastos", 13f, 20)
                val row = LinearLayout(c).apply { orientation = LinearLayout.HORIZONTAL }
                row.addView(card(KeyBudgetWidgetReceiver(), 180, 180), LinearLayout.LayoutParams(0, dp(180), 1f))
                row.addView(View(c), LinearLayout.LayoutParams(dp(12), 1))
                row.addView(card(KeyBudgetUpcomingWidgetReceiver(), 180, 180), LinearLayout.LayoutParams(0, dp(180), 1f))
                gallery.addView(row)
                label("Gastos compactos", 13f, 20)
                gallery.addView(card(KeyBudgetCompactWidgetReceiver(), 372, 80), LinearLayout.LayoutParams(-1, dp(80)))
                label("Nova despesa", 13f, 20)
                gallery.addView(card(KeyBudgetQuickWidgetReceiver(), 84, 84), LinearLayout.LayoutParams(dp(84), dp(84)))
                gallery.measure(View.MeasureSpec.makeMeasureSpec(dp(412), View.MeasureSpec.EXACTLY),
                    View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))
                gallery.layout(0, 0, gallery.measuredWidth, gallery.measuredHeight)
                val output = File(target.filesDir, "widget-captures").apply { mkdirs() }
                File(output, "widgets-${if (dark) "dark" else "light"}.png").outputStream().use {
                    bitmap(gallery).compress(Bitmap.CompressFormat.PNG, 100, it)
                }
            }
        }
    }

    private fun bitmap(view: View): Bitmap = Bitmap.createBitmap(
        view.measuredWidth, view.measuredHeight, Bitmap.Config.ARGB_8888,
    ).also { view.draw(Canvas(it)) }
}
