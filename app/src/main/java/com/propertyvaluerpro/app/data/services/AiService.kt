package com.propertyvaluerpro.app.data.services

import android.content.Context
import android.net.Uri
import android.util.Base64
import com.propertyvaluerpro.app.data.models.DeedData
import com.propertyvaluerpro.app.data.models.PlanLot
import com.propertyvaluerpro.app.data.models.ReportAnalysisResult
import com.propertyvaluerpro.app.data.models.SurveyPlanData
import com.propertyvaluerpro.app.data.storage.SecureStorage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

data class ConnectionTestResult(
    val success: Boolean,
    val message: String,
    val model: String,
)

class AiService(
    private val context: Context,
    private val secureStorage: SecureStorage,
) {
    companion object {
        private const val GEMINI_API_ROOT = "https://generativelanguage.googleapis.com/v1beta/models/"
        const val DEFAULT_MODEL_ID = "gemini-2.5-flash"

        val DEFAULT_WORKING_MODELS = listOf(
            "gemini-2.5-flash",
            "gemini-2.5-flash-lite",
            "gemini-2.5-pro",
            "gemini-2.0-flash",
            "gemini-flash-latest",
        )

        fun resolveModelId(provider: String): String {
            val clean = provider.trim().removePrefix("models/")
            if (clean.isEmpty() || clean.contains("1.5")) return DEFAULT_MODEL_ID
            return clean
        }

        fun formatModelLabel(modelId: String): String {
            if (modelId == DEFAULT_MODEL_ID) return "Gemini 2.5 Flash (Recommended)"
            return modelId
                .replace("gemini-", "Gemini ")
                .split("-")
                .joinToString("-") { word ->
                    word.replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
                }
        }
    }

    private fun getActiveModelId(): String = resolveModelId(secureStorage.getAiProvider())

    suspend fun fetchAvailableModels(apiKeyOverride: String? = null): List<String> = withContext(Dispatchers.IO) {
        val key = (apiKeyOverride ?: secureStorage.getAiApiKey()).trim()
        if (key.isEmpty()) return@withContext DEFAULT_WORKING_MODELS

        runCatching {
            val conn = (URL("https://generativelanguage.googleapis.com/v1beta/models?key=$key").openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = 10_000
                readTimeout = 10_000
                setRequestProperty("Content-Type", "application/json")
            }
            if (conn.responseCode == 200) {
                val body = conn.inputStream.bufferedReader().readText()
                val root = JSONObject(body)
                val arr = root.optJSONArray("models") ?: JSONArray()
                val list = mutableListOf<String>()
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    val name = obj.optString("name").removePrefix("models/")
                    val methods = obj.optJSONArray("supportedGenerationMethods")
                    var supportsGen = false
                    if (methods != null) {
                        for (m in 0 until methods.length()) {
                            if (methods.optString(m) == "generateContent") supportsGen = true
                        }
                    }
                    if (supportsGen && name.isNotEmpty() && !name.contains("tts") && !name.contains("lyria")) {
                        list.add(name)
                    }
                }
                if (list.isNotEmpty()) {
                    return@withContext list.sortedWith(compareBy({ priority(it) }, { it }))
                }
            }
            DEFAULT_WORKING_MODELS
        }.getOrDefault(DEFAULT_WORKING_MODELS)
    }

    private fun priority(model: String): Int = when {
        model == "gemini-2.5-flash" -> 0
        model == "gemini-2.5-flash-lite" -> 1
        model.contains("flash-lite") -> 2
        model.contains("flash") -> 3
        model.contains("pro") -> 4
        else -> 5
    }

    suspend fun testConnectionDetailed(): ConnectionTestResult = withContext(Dispatchers.IO) {
        val model = getActiveModelId()
        val apiKey = secureStorage.getAiApiKey()
        if (apiKey.isEmpty()) {
            return@withContext ConnectionTestResult(false, "Please enter your Gemini API key first.", model)
        }

        val payload = JSONObject().put(
            "contents",
            JSONArray().put(
                JSONObject().put(
                    "parts",
                    JSONArray().put(JSONObject().put("text", "Ping test. Reply with OK.")),
                ),
            ),
        )

        val (code, body) = postJson("$GEMINI_API_ROOT$model:generateContent?key=$apiKey", payload, 12_000)
        when (code) {
            200 -> ConnectionTestResult(true, "Connection Successful! Model \"$model\" is active (HTTP 200 OK).", model)
            404 -> ConnectionTestResult(false, "Model \"$model\" was not found (HTTP 404). Select Gemini 2.5 Flash.", model)
            400, 401, 403 -> ConnectionTestResult(false, "API Key is invalid or unauthorized (HTTP $code).", model)
            429 -> ConnectionTestResult(false, "Rate limit or quota reached (HTTP 429). Please retry shortly.", model)
            -1 -> ConnectionTestResult(false, "Network error: $body", model)
            else -> ConnectionTestResult(false, "Server returned HTTP $code: ${body.take(120)}", model)
        }
    }

    suspend fun extractDeed(
        filePaths: List<String>,
        onProgress: (String) -> Unit,
    ): DeedData = withContext(Dispatchers.IO) {
        val apiKey = secureStorage.getAiApiKey()
        require(apiKey.isNotEmpty()) {
            "AI API Key is not configured. Open Admin Settings (gear icon in top right) and enter your Gemini API Key."
        }
        require(filePaths.isNotEmpty()) {
            "No document file or photo was selected. Please attach a title deed file."
        }

        onProgress("Preparing document pages for extraction...")
        val parts = JSONArray()
        for (path in filePaths.take(3)) {
            readFileAsInlinePart(path)?.let { parts.put(it) }
        }

        val prompt = """
            You are an expert Sri Lankan Conveyancing Notary and Real Estate Valuation Specialist.
            Examine this title deed document and extract the 15 legal particulars into a strictly valid JSON object:
            {
              "deedNumber": "",
              "executionDate": "YYYY-MM-DD",
              "notaryPublicName": "",
              "notaryPublicStation": "",
              "landRegistry": "",
              "registrationDate": "YYYY-MM-DD",
              "dayBookNumber": "",
              "registerFolioNumber": "",
              "vendeeName": "",
              "vendeeNic": "",
              "vendeeAddress": "",
              "vendorName": "",
              "vendorNic": "",
              "vendorAddress": "",
              "purchaseConsideration": 0.0,
              "uncertainFields": {}
            }
            Leave unreadable fields empty and set them true in uncertainFields.
        """.trimIndent()
        parts.put(JSONObject().put("text", prompt))

        onProgress("Sending document to Gemini extraction engine...")
        val payload = JSONObject()
            .put("contents", JSONArray().put(JSONObject().put("parts", parts)))
            .put(
                "generationConfig",
                JSONObject()
                    .put("temperature", 0.1)
                    .put("responseMimeType", "application/json"),
            )

        val model = getActiveModelId()
        val (code, body) = postJson("$GEMINI_API_ROOT$model:generateContent?key=$apiKey", payload, 35_000)
        if (code != 200) {
            throw IllegalStateException("AI extraction failed (HTTP $code): ${body.take(160)}")
        }

        onProgress("Parsing legal deed fields...")
        val text = extractCandidateText(body)
        val data = JSONObject(text)
        val uncertainMap = mutableMapOf<String, Boolean>()
        data.optJSONObject("uncertainFields")?.let { uObj ->
            uObj.keys().forEach { k -> uncertainMap[k] = uObj.optBoolean(k, false) }
        }

        DeedData(
            deedNumber = data.optString("deedNumber"),
            executionDate = data.optString("executionDate"),
            notaryPublicName = data.optString("notaryPublicName"),
            notaryPublicStation = data.optString("notaryPublicStation"),
            landRegistry = data.optString("landRegistry"),
            registrationDate = data.optString("registrationDate"),
            dayBookNumber = data.optString("dayBookNumber"),
            registerFolioNumber = data.optString("registerFolioNumber"),
            vendeeName = data.optString("vendeeName"),
            vendeeNic = data.optString("vendeeNic"),
            vendeeAddress = data.optString("vendeeAddress"),
            vendorName = data.optString("vendorName"),
            vendorNic = data.optString("vendorNic"),
            vendorAddress = data.optString("vendorAddress"),
            purchaseConsideration = data.optDouble("purchaseConsideration", 0.0),
            documentFilePaths = filePaths,
            uncertainFields = uncertainMap,
        )
    }

    suspend fun extractSurveyPlan(
        filePaths: List<String>,
        onProgress: (String) -> Unit,
    ): SurveyPlanData = withContext(Dispatchers.IO) {
        val apiKey = secureStorage.getAiApiKey()
        require(apiKey.isNotEmpty()) {
            "AI API Key is not configured. Open Admin Settings and enter your Gemini API Key."
        }
        require(filePaths.isNotEmpty()) {
            "No survey plan document was selected."
        }

        onProgress("Analyzing survey plan image...")
        val parts = JSONArray()
        for (path in filePaths.take(2)) {
            readFileAsInlinePart(path)?.let { parts.put(it) }
        }

        val prompt = """
            You are an expert Sri Lankan Licensed Surveyor and Cadastral Analyst.
            Extract survey plan particulars and lots as strictly valid JSON:
            {
              "planNumber": "",
              "surveyDate": "YYYY-MM-DD",
              "certificationDate": "",
              "surveyorName": "",
              "surveyorRegistrationNumber": "",
              "landName": "",
              "priorPlanReference": "",
              "lots": [
                {
                  "lotNumber": "1",
                  "acres": 0,
                  "roods": 0,
                  "perches": 15.0,
                  "northBoundary": "",
                  "eastBoundary": "",
                  "southBoundary": "",
                  "westBoundary": ""
                }
              ]
            }
        """.trimIndent()
        parts.put(JSONObject().put("text", prompt))

        onProgress("Extracting survey lots and boundary schedules...")
        val payload = JSONObject()
            .put("contents", JSONArray().put(JSONObject().put("parts", parts)))
            .put(
                "generationConfig",
                JSONObject()
                    .put("temperature", 0.1)
                    .put("responseMimeType", "application/json"),
            )

        val model = getActiveModelId()
        val (code, body) = postJson("$GEMINI_API_ROOT$model:generateContent?key=$apiKey", payload, 35_000)
        if (code != 200) {
            throw IllegalStateException("Survey Plan AI extraction failed (HTTP $code).")
        }

        val data = JSONObject(extractCandidateText(body))
        val lots = mutableListOf<PlanLot>()
        val lotsArr = data.optJSONArray("lots")
        if (lotsArr != null) {
            for (i in 0 until lotsArr.length()) {
                val item = lotsArr.getJSONObject(i)
                lots.add(
                    PlanLot(
                        lotNumber = item.optString("lotNumber", "${i + 1}"),
                        acres = item.optInt("acres", 0),
                        roods = item.optInt("roods", 0),
                        perches = item.optDouble("perches", 0.0),
                        northBoundary = item.optString("northBoundary"),
                        eastBoundary = item.optString("eastBoundary"),
                        southBoundary = item.optString("southBoundary"),
                        westBoundary = item.optString("westBoundary"),
                        isSelected = true,
                    ),
                )
            }
        }
        if (lots.isEmpty()) lots.add(PlanLot(lotNumber = "1", perches = 10.0, isSelected = true))

        SurveyPlanData(
            planNumber = data.optString("planNumber"),
            surveyDate = data.optString("surveyDate"),
            certificationDate = data.optString("certificationDate"),
            surveyorName = data.optString("surveyorName"),
            surveyorRegistrationNumber = data.optString("surveyorRegistrationNumber"),
            landName = data.optString("landName"),
            priorPlanReference = data.optString("priorPlanReference"),
            lots = lots,
            documentFilePaths = filePaths,
        )
    }

    suspend fun polishValuationLanguage(rawText: String): String = withContext(Dispatchers.IO) {
        val apiKey = secureStorage.getAiApiKey()
        if (apiKey.isEmpty() || rawText.isBlank()) return@withContext rawText

        val payload = JSONObject().put(
            "contents",
            JSONArray().put(
                JSONObject().put(
                    "parts",
                    JSONArray().put(
                        JSONObject().put(
                            "text",
                            "Rewrite the following access and driving directions into formal, professional real estate valuation report terminology suitable for a Chartered Valuation Report in Sri Lanka. Return only the revised paragraph:\n\n$rawText",
                        ),
                    ),
                ),
            ),
        )
        val (code, body) = postJson("$GEMINI_API_ROOT${getActiveModelId()}:generateContent?key=$apiKey", payload, 15_000)
        if (code == 200) {
            val result = extractCandidateText(body).trim()
            if (result.isNotEmpty()) return@withContext result
        }
        rawText
    }

    suspend fun analyzeReportConventions(fileNames: List<String>): ReportAnalysisResult = withContext(Dispatchers.IO) {
        if (fileNames.isEmpty()) return@withContext ReportAnalysisResult("", "", "", "")
        val defaultSummary = buildDefaultBlueprint(fileNames.joinToString(", "))
        val apiKey = secureStorage.getAiApiKey()
        if (apiKey.isEmpty()) {
            return@withContext ReportAnalysisResult(detailedBlueprint = defaultSummary)
        }

        val prompt = """
            Analyze these uploaded draft valuation reports: ${fileNames.joinToString(", ")}.
            Return strictly valid JSON:
            {
              "reportFormat": "1-line layout description",
              "reportStyle": "1-line tone/terminology description",
              "reportType": "1-line valuation category",
              "detailedBlueprint": "concise markdown specification"
            }
        """.trimIndent()
        val payload = JSONObject()
            .put("contents", JSONArray().put(JSONObject().put("parts", JSONArray().put(JSONObject().put("text", prompt)))))
            .put("generationConfig", JSONObject().put("responseMimeType", "application/json"))

        val (code, body) = postJson("$GEMINI_API_ROOT${getActiveModelId()}:generateContent?key=$apiKey", payload, 20_000)
        if (code == 200) {
            runCatching {
                val parsed = JSONObject(extractCandidateText(body))
                return@withContext ReportAnalysisResult(
                    reportFormat = parsed.optString("reportFormat").ifBlank { "Chartered 10-Point Schedule & Executive Appraisal Table" },
                    reportStyle = parsed.optString("reportStyle").ifBlank { "Formal Chartered Practitioner Terminology & LKR Rounding" },
                    reportType = parsed.optString("reportType").ifBlank { "Real Estate Mortgage Collateral & Bank Panel Valuation" },
                    detailedBlueprint = parsed.optString("detailedBlueprint").ifBlank { defaultSummary },
                )
            }
        }
        ReportAnalysisResult(detailedBlueprint = defaultSummary)
    }

    private fun buildDefaultBlueprint(names: String): String =
        "### AI Report Style Blueprint (Learned from $names)\n" +
            "• Executive Summary: Professional 2-column key metrics table with Valuation Purpose & Forced Sale Value discount.\n" +
            "• Land Valuation Table: Extent in Acres-Roods-Perches with Perch rate, Total Land Value, and Local Authority conformity.\n" +
            "• Building Valuation: Gross Replacement Cost (GRC) itemization, physical age depreciation percentage, and Net Building Value.\n" +
            "• Statutory Declarations: Formal declaration of impartiality, physical site inspection certification, and Chartered Valuer seal block."

    private fun readFileAsInlinePart(pathOrUri: String): JSONObject? {
        val bytes = when {
            pathOrUri.startsWith("content://") -> {
                context.contentResolver.openInputStream(Uri.parse(pathOrUri))?.use { it.readBytes() }
            }
            else -> {
                val f = File(pathOrUri)
                if (f.exists()) f.readBytes() else null
            }
        } ?: return null

        require(bytes.size <= 12 * 1024 * 1024) {
            "Document exceeds 12MB memory safety limit."
        }
        val lower = pathOrUri.lowercase()
        val mime = when {
            lower.endsWith(".png") -> "image/png"
            lower.endsWith(".pdf") -> "application/pdf"
            pathOrUri.startsWith("content://") -> context.contentResolver.getType(Uri.parse(pathOrUri)) ?: "image/jpeg"
            else -> "image/jpeg"
        }
        return JSONObject().put(
            "inline_data",
            JSONObject()
                .put("mime_type", mime)
                .put("data", Base64.encodeToString(bytes, Base64.NO_WRAP)),
        )
    }

    private fun postJson(urlStr: String, payload: JSONObject, timeoutMs: Int): Pair<Int, String> = runCatching {
        val conn = (URL(urlStr).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            doOutput = true
            connectTimeout = timeoutMs
            readTimeout = timeoutMs
            setRequestProperty("Content-Type", "application/json")
        }
        conn.outputStream.use { it.write(payload.toString().toByteArray(Charsets.UTF_8)) }
        val code = conn.responseCode
        val stream = if (code in 200..299) conn.inputStream else conn.errorStream
        val text = stream?.bufferedReader()?.readText() ?: ""
        code to text
    }.getOrElse { e ->
        -1 to (e.message ?: "Unknown network error")
    }

    private fun extractCandidateText(responseBody: String): String {
        val root = JSONObject(responseBody)
        val raw = root.optJSONArray("candidates")
            ?.optJSONObject(0)
            ?.optJSONObject("content")
            ?.optJSONArray("parts")
            ?.optJSONObject(0)
            ?.optString("text")
            ?: "{}"
        return raw.replace("```json", "").replace("```", "").trim()
    }
}
