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
        const val DEFAULT_MODEL_ID = "gemini-3.1-flash-lite"
        const val SECONDARY_DEFAULT_MODEL_ID = "gemini-3.5-flash-lite"

        val DEFAULT_WORKING_MODELS = listOf(
            "gemini-3.1-flash-lite",
            "gemini-3.5-flash-lite",
            "gemini-3.1-flash-lite-preview",
            "gemini-flash-lite-latest",
            "gemini-2.5-flash-lite",
            "gemini-2.5-flash",
            "gemini-flash-latest",
        )

        fun resolveModelId(provider: String): String {
            val clean = provider.trim().removePrefix("models/")
            val lower = clean.lowercase()
            if (lower == "3.1-flash-lite" || lower == "3.1" || lower == "flash-lite-3.1") return "gemini-3.1-flash-lite"
            if (lower == "3.5-flash-lite" || lower == "3.5" || lower == "flash-lite-3.5") return "gemini-3.5-flash-lite"
            if (clean.isEmpty() || clean.contains("1.5") || clean == "gemini-2.0-flash" || clean == "gemini-2.5-flash") return DEFAULT_MODEL_ID
            return clean
        }

        fun formatModelLabel(modelId: String): String {
            if (modelId == "gemini-3.1-flash-lite") return "Gemini 3.1 Flash-Lite (Recommended Default)"
            if (modelId == "gemini-3.5-flash-lite") return "Gemini 3.5 Flash-Lite (Default Option)"
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
        model == "gemini-3.1-flash-lite" -> 0
        model == "gemini-3.5-flash-lite" -> 1
        model == "gemini-3.1-flash-lite-preview" -> 2
        model == "gemini-flash-lite-latest" -> 3
        model.contains("3.1") && model.contains("flash-lite") -> 4
        model.contains("3.5") && model.contains("flash-lite") -> 5
        model.contains("flash-lite") -> 6
        model.contains("flash") -> 7
        model.contains("pro") -> 8
        else -> 9
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
        analyzeUploadedReports(fileNames.map { "" to it })
    }

    /**
     * Analyzes the valuer's uploaded draft reports with the configured Gemini API key.
     * Each entry is (contentUriOrBlank, filePathOrName). Files are read from app-private
     * storage or the content URI, base64-encoded, and sent to Gemini so the model can learn
     * the valuer's real report format, style, content and features. The result includes a
     * reusable Markdown style spec used to drive final .docx report creation.
     */
    suspend fun analyzeUploadedReports(
        files: List<Pair<String, String>>,
        onProgress: (String) -> Unit = {},
    ): ReportAnalysisResult = withContext(Dispatchers.IO) {
        val nonEmpty = files.filter { it.second.isNotBlank() }
        if (nonEmpty.isEmpty()) return@withContext ReportAnalysisResult("", "", "", "", "", "", "", "")

        val names = nonEmpty.map { it.second.substringAfterLast('/').substringAfterLast('\\') }
        val defaultSpec = buildDefaultStyleSpec(names.joinToString(", "))

        val apiKey = secureStorage.getAiApiKey()
        if (apiKey.isEmpty()) {
            return@withContext ReportAnalysisResult(
                reportFormat = "Chartered 10-Point Schedule & Executive Appraisal Table",
                reportStyle = "Formal Chartered Practitioner Terminology & LKR Rounding",
                reportType = "Real Estate Mortgage Collateral & Bank Panel Valuation",
                detailedBlueprint = defaultSpec,
                contentFeatures = "Executive summary, land & building valuation tables, SWOC annexure",
                sectionOrder = defaultSpec,
                sampleClauses = "",
                styleSpecMd = defaultSpec,
            )
        }

        onProgress("Reading uploaded draft reports...")
        val parts = JSONArray()
        val attachedNames = mutableListOf<String>()
        for ((uri, path) in nonEmpty.take(3)) {
            val part = readFileAsInlinePart(if (uri.isBlank()) path else uri)
            if (part != null) {
                parts.put(part)
                attachedNames.add(path.substringAfterLast('/').substringAfterLast('\\'))
            }
        }
        if (parts.length() == 0) {
            return@withContext ReportAnalysisResult(
                reportFormat = "Chartered 10-Point Schedule & Executive Appraisal Table",
                reportStyle = "Formal Chartered Practitioner Terminology & LKR Rounding",
                reportType = "Real Estate Mortgage Collateral & Bank Panel Valuation",
                detailedBlueprint = defaultSpec,
                contentFeatures = "Executive summary, land & building valuation tables, SWOC annexure",
                sectionOrder = defaultSpec,
                sampleClauses = "",
                styleSpecMd = defaultSpec,
            )
        }

        val fileListText = attachedNames.joinToString(", ")
        val prompt = buildStyleAnalysisPrompt(fileListText)
        parts.put(JSONObject().put("text", prompt))

        onProgress("Gemini AI analyzing report format, style, content & features...")
        val payload = JSONObject()
            .put("contents", JSONArray().put(JSONObject().put("parts", parts)))
            .put(
                "generationConfig",
                JSONObject()
                    .put("temperature", 0.2)
                    .put("responseMimeType", "application/json"),
            )

        val model = getActiveModelId()
        val (code, body) = postJson("$GEMINI_API_ROOT$model:generateContent?key=$apiKey", payload, 45_000)
        if (code != 200) {
            throw IllegalStateException("AI report style analysis failed (HTTP $code). Please check your Gemini API key and retry.")
        }

        onProgress("Compiling reusable report style specification...")
        val text = extractCandidateText(body)
        val parsed = runCatching { JSONObject(text) }.getOrNull() ?: JSONObject()

        val styleSpecMd = parsed.optString("styleSpecMd").ifBlank {
            parsed.optString("detailedBlueprint")
        }.ifBlank { defaultSpec }

        ReportAnalysisResult(
            reportFormat = parsed.optString("reportFormat").ifBlank { "Chartered 10-Point Schedule & Executive Appraisal Table" },
            reportStyle = parsed.optString("reportStyle").ifBlank { "Formal Chartered Practitioner Terminology & LKR Rounding" },
            reportType = parsed.optString("reportType").ifBlank { "Real Estate Mortgage Collateral & Bank Panel Valuation" },
            detailedBlueprint = styleSpecMd,
            contentFeatures = parsed.optString("contentFeatures").ifBlank { "Executive summary, land & building valuation tables, SWOC annexure" },
            sectionOrder = parsed.optString("sectionOrder").ifBlank { styleSpecMd },
            sampleClauses = parsed.optString("sampleClauses"),
            styleSpecMd = styleSpecMd,
        )
    }

    private fun buildStyleAnalysisPrompt(fileListText: String): String = """
        You are an expert Sri Lankan Chartered Real Estate Valuer and technical document analyst.
        The user has uploaded their own draft valuation report(s): $fileListText.

        Carefully examine the uploaded documents (read every page/image/OCR-able text) and reverse-engineer the EXACT report conventions the valuer uses. Then return ONE strictly valid JSON object with these fields:

        {
          "reportFormat": "one-line description of the physical layout (tables, headings, columns, page structure)",
          "reportStyle": "one-line description of tone, terminology, language formality and number/LKR formatting",
          "reportType": "one-line valuation category (e.g. mortgage security, bank panel, market value)",
          "contentFeatures": "comma-separated list of the distinctive content features the drafts always contain (e.g. SWOC, GRC itemization, FSV %, statutory declarations, photo register)",
          "sectionOrder": "the exact numbered section order used in the drafts, as a single line",
          "sampleClauses": "up to 3 short verbatim signature clauses / declaration wording snippets that define the house style",
          "styleSpecMd": "a complete Markdown style specification (use ## headings and bullet lines) covering: title block, section order, table layout, terminology, LKR rounding rule, FSV discount rule, declaration wording, and a 'Do / Do Not' list. This spec will be reused to generate future reports that must look identical to the drafts."
        }

        Rules:
        - Base every field only on what the uploaded drafts actually contain; do not invent generic valuation boilerplate.
        - If a field cannot be determined, use a sensible chartered-valuation default for Sri Lanka.
        - The styleSpecMd must be detailed enough that another system could reproduce the report format and style from it alone.
        - Return ONLY the JSON object, no prose, no markdown fences.
    """.trimIndent()

    private fun buildDefaultStyleSpec(names: String): String =
        "### AI Report Style Blueprint (Learned from $names)\n" +
            "• Executive Summary: Professional 2-column key metrics table with Valuation Purpose & Forced Sale Value discount.\n" +
            "• Land Valuation Table: Extent in Acres-Roods-Perches with Perch rate, Total Land Value, and Local Authority conformity.\n" +
            "• Building Valuation: Gross Replacement Cost (GRC) itemization, physical age depreciation percentage, and Net Building Value.\n" +
            "• Statutory Declarations: Formal declaration of impartiality, physical site inspection certification, and Chartered Valuer seal block."

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
