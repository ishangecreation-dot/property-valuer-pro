package com.propertyvaluerpro.app.ui.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.propertyvaluerpro.app.data.models.AppConstants
import com.propertyvaluerpro.app.data.models.BuildingDetails
import com.propertyvaluerpro.app.data.models.BuildingSketch
import com.propertyvaluerpro.app.data.models.DeedData
import com.propertyvaluerpro.app.data.models.InspectionData
import com.propertyvaluerpro.app.data.models.LocationData
import com.propertyvaluerpro.app.data.models.MonthlyUsageState
import com.propertyvaluerpro.app.data.models.SurveyPlanData
import com.propertyvaluerpro.app.data.models.ValuationData
import com.propertyvaluerpro.app.data.models.ValuationProject
import com.propertyvaluerpro.app.data.models.ValuerProfile
import com.propertyvaluerpro.app.data.services.AiService
import com.propertyvaluerpro.app.data.services.ConnectionTestResult
import com.propertyvaluerpro.app.data.services.DocxService
import com.propertyvaluerpro.app.data.services.DossierMarkdownService
import com.propertyvaluerpro.app.data.storage.SecureStorage
import com.propertyvaluerpro.app.data.storage.ValuationRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class AppUiState(
    val profile: ValuerProfile = ValuerProfile(),
    val profileDrafts: List<ValuerProfile> = emptyList(),
    val projects: List<ValuationProject> = emptyList(),
    val activeProject: ValuationProject? = null,
    val usageState: MonthlyUsageState = MonthlyUsageState(),
    val adsEnabled: Boolean = false,
    val adProvider: String = AppConstants.AD_PROVIDER_META,
    val metaInterstitialId: String = AppConstants.DEFAULT_META_INTERSTITIAL_ID,
    val screens3To10Frozen: Boolean = true,
    val showAdminSettings: Boolean = false,
    val showLimitDialog: Boolean = false,
    val isExtracting: Boolean = false,
    val extractionStatus: String = "",
    val isAnalyzingTemplates: Boolean = false,
    val isPolishingText: Boolean = false,
    val isGeneratingDocx: Boolean = false,
    val generationProgress: String = "",
    val snackbarMessage: String? = null,
    val snackbarIsError: Boolean = false,
)

class ValuationViewModel(application: Application) : AndroidViewModel(application) {
    private val appContext = application.applicationContext
    val secureStorage = SecureStorage(appContext)
    val repository = ValuationRepository(appContext)
    val aiService = AiService(appContext, secureStorage)

    private val _uiState = MutableStateFlow(AppUiState())
    val uiState: StateFlow<AppUiState> = _uiState.asStateFlow()

    init {
        refreshAll()
    }

    fun refreshAll() {
        val profile = repository.loadProfile()
        val drafts = repository.loadProfileDrafts()
        val projects = repository.loadProjects()
        val activeId = repository.loadActiveProjectId()
        val active = projects.firstOrNull { it.id == activeId } ?: projects.firstOrNull()
        val usage = repository.getMonthlyUsage()

        _uiState.update {
            it.copy(
                profile = profile,
                profileDrafts = drafts,
                projects = projects,
                activeProject = active,
                usageState = usage,
                adsEnabled = repository.isAdsEnabled(),
                adProvider = repository.getAdProvider(),
                metaInterstitialId = repository.getMetaInterstitialId(),
                screens3To10Frozen = repository.areScreens3To10Frozen(),
            )
        }
    }

    fun clearSnackbar() {
        _uiState.update { it.copy(snackbarMessage = null, snackbarIsError = false) }
    }

    fun showMessage(message: String, isError: Boolean = false) {
        _uiState.update { it.copy(snackbarMessage = message, snackbarIsError = isError) }
    }

    fun openAdminSettings() = _uiState.update { it.copy(showAdminSettings = true) }
    fun closeAdminSettings() {
        _uiState.update { it.copy(showAdminSettings = false) }
        refreshAll()
    }

    fun openLimitDialog() = _uiState.update { it.copy(showLimitDialog = true) }
    fun closeLimitDialog() {
        _uiState.update { it.copy(showLimitDialog = false) }
        refreshAll()
    }

    fun createNewValuation(): ValuationProject {
        val count = _uiState.value.projects.size + 1
        val newProject = ValuationProject(
            id = System.currentTimeMillis().toString(),
            projectName = "Valuation Dossier #$count",
        )
        val updatedList = repository.saveActiveProject(newProject)
        DossierMarkdownService.persistDossierFile(appContext, _uiState.value.profile, newProject)
        _uiState.update { it.copy(projects = updatedList, activeProject = newProject) }
        return newProject
    }

    fun selectProject(project: ValuationProject) {
        val updatedList = repository.saveActiveProject(project)
        _uiState.update { it.copy(projects = updatedList, activeProject = project) }
    }

    fun deleteProject(projectId: String) {
        val remaining = repository.deleteProject(projectId)
        val nextActive = if (_uiState.value.activeProject?.id == projectId) remaining.firstOrNull() else _uiState.value.activeProject
        _uiState.update { it.copy(projects = remaining, activeProject = nextActive) }
        showMessage("Valuation project removed.")
    }

    fun ensureActiveProject(): ValuationProject {
        return _uiState.value.activeProject ?: createNewValuation()
    }

    fun saveProfile(profile: ValuerProfile, showSuccess: Boolean = true): Boolean {
        if (profile.valuerName.isBlank()) {
            showMessage("Please enter your Valuer Name.", isError = true)
            return false
        }
        if (profile.qualifications.isBlank()) {
            showMessage("Please enter your Qualifications.", isError = true)
            return false
        }
        if (profile.registrationNumber.isBlank()) {
            showMessage("Please enter your Registration Number.", isError = true)
            return false
        }
        if (profile.officeAddress.isBlank()) {
            showMessage("Please enter your Office Address.", isError = true)
            return false
        }
        if (profile.contactNumber.isBlank()) {
            showMessage("Please enter Contact Number 1.", isError = true)
            return false
        }

        val drafts = repository.saveProfileDraft(profile)
        val savedProfile = drafts.firstOrNull { it.id == profile.id } ?: profile
        DossierMarkdownService.persistDossierFile(appContext, savedProfile, _uiState.value.activeProject)
        _uiState.update { it.copy(profile = savedProfile, profileDrafts = drafts) }
        if (showSuccess) showMessage("Profile saved successfully. Dossier updated.")
        return true
    }

    fun switchProfileDraft(draft: ValuerProfile) {
        repository.saveProfile(draft)
        _uiState.update { it.copy(profile = draft) }
        showMessage("Switched to profile draft: \"${draft.draftName}\"")
    }

    fun createNewProfileDraft() {
        val draft = ValuerProfile(
            id = "draft_${System.currentTimeMillis()}",
            draftName = "Chambers Profile ${_uiState.value.profileDrafts.size + 1}",
        )
        _uiState.update { it.copy(profile = draft, profileDrafts = it.profileDrafts + draft) }
        showMessage("New profile draft created. Enter details and save.")
    }

    fun addTemplateFiles(uris: List<android.net.Uri>) {
        val current = _uiState.value.profile
        val isPaid = repository.isPaidTier()
        val maxAllowed = if (isPaid) 99 else AppConstants.FREE_TIER_TEMPLATE_LIMIT

        if (uris.isEmpty()) {
            showMessage("No draft report files were selected.", isError = true)
            return
        }
        if (current.uploadedTemplates.size >= maxAllowed) {
            showMessage("Template limit reached ($maxAllowed max). Clear existing drafts first.", isError = true)
            return
        }

        // Copy picked files into app-private storage so URI read permissions survive.
        val saved = mutableListOf<Pair<String, String>>() // (contentUri, app-private path)
        for (uri in uris.take(maxAllowed - current.uploadedTemplates.size)) {
            runCatching {
                val name = appContext.contentResolver.query(
                    uri,
                    arrayOf(android.provider.OpenableColumns.DISPLAY_NAME),
                    null,
                    null,
                    null,
                )?.use { c ->
                    if (c.moveToFirst()) {
                        val idx = c.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                        if (idx >= 0) c.getString(idx) else null
                    } else null
                } ?: uri.lastPathSegment
                val safeName = (name ?: "draft_report").take(80).replace(Regex("[^a-zA-Z0-9._-]"), "_")
                val dir = java.io.File(appContext.filesDir, "templates").apply { mkdirs() }
                val target = java.io.File(dir, "${System.currentTimeMillis()}_${safeName}")
                appContext.contentResolver.openInputStream(uri)?.use { input ->
                    target.outputStream().use { output -> input.copyTo(output) }
                } ?: throw IllegalStateException("Could not read the selected file.")
                saved.add(uri.toString() to target.absolutePath)
            }.onFailure {
                showMessage("Failed to import a draft report: ${it.message}", isError = true)
            }
        }

        if (saved.isEmpty()) {
            showMessage("No draft reports could be imported. Please try again.", isError = true)
            return
        }

        val mergedNames = (current.uploadedTemplates + saved.map { it.second.substringAfterLast('/').substringAfterLast('\\') })
            .distinct()
            .take(maxAllowed)
        val mergedPaths = (current.templateFilePaths + saved.map { it.second }).distinct().take(maxAllowed)

        val updated = current.copy(uploadedTemplates = mergedNames, templateFilePaths = mergedPaths)
        repository.saveProfile(updated)
        _uiState.update { it.copy(profile = updated, isAnalyzingTemplates = true) }

        viewModelScope.launch {
            try {
                val analysis = aiService.analyzeUploadedReports(
                    mergedPaths.map { "" to it },
                ) { status ->
                    _uiState.update { it.copy(extractionStatus = status) }
                }
                val analyzed = _uiState.value.profile.copy(
                    reportFormat = analysis.reportFormat,
                    reportStyle = analysis.reportStyle,
                    reportType = analysis.reportType,
                    reportStyleSummary = analysis.detailedBlueprint,
                    reportContentFeatures = analysis.contentFeatures,
                    reportSectionOrder = analysis.sectionOrder,
                    reportSampleClauses = analysis.sampleClauses,
                    reportStyleSpecMd = analysis.styleSpecMd,
                )
                repository.saveProfile(analyzed)
                DossierMarkdownService.persistDossierFile(appContext, analyzed, _uiState.value.activeProject)
                persistStyleSpecMd(analyzed.reportStyleSpecMd)
                _uiState.update { it.copy(profile = analyzed, isAnalyzingTemplates = false, extractionStatus = "") }
                showMessage("Uploaded ${saved.size} draft report(s). Format, style, content & features analyzed; style spec saved.")
            } catch (e: Exception) {
                _uiState.update { it.copy(isAnalyzingTemplates = false, extractionStatus = "") }
                showMessage(e.message ?: "Report style analysis failed.", isError = true)
            }
        }
    }

    fun removeTemplateAt(index: Int) {
        val current = _uiState.value.profile
        if (index !in current.uploadedTemplates.indices) return
        // Delete the backing app-private copy when present.
        current.templateFilePaths.getOrNull(index)?.let { path ->
            runCatching { java.io.File(path).delete() }
        }
        val nextNames = current.uploadedTemplates.toMutableList().apply { removeAt(index) }
        val nextPaths = current.templateFilePaths.toMutableList().apply { if (index < size) removeAt(index) }
        val updated = if (nextNames.isEmpty()) {
            current.copy(
                uploadedTemplates = emptyList(),
                templateFilePaths = emptyList(),
                reportFormat = "",
                reportStyle = "",
                reportType = "",
                reportStyleSummary = "",
                reportContentFeatures = "",
                reportSectionOrder = "",
                reportSampleClauses = "",
                reportStyleSpecMd = "",
            )
        } else {
            current.copy(uploadedTemplates = nextNames, templateFilePaths = nextPaths)
        }
        repository.saveProfile(updated)
        if (updated.reportStyleSpecMd.isBlank()) persistStyleSpecMd("")
        _uiState.update { it.copy(profile = updated) }
    }

    fun clearAllTemplates() {
        _uiState.value.profile.templateFilePaths.forEach { path ->
            runCatching { java.io.File(path).delete() }
        }
        val updated = _uiState.value.profile.copy(
            uploadedTemplates = emptyList(),
            templateFilePaths = emptyList(),
            reportFormat = "",
            reportStyle = "",
            reportType = "",
            reportStyleSummary = "",
            reportContentFeatures = "",
            reportSectionOrder = "",
            reportSampleClauses = "",
            reportStyleSpecMd = "",
        )
        repository.saveProfile(updated)
        persistStyleSpecMd("")
        _uiState.update { it.copy(profile = updated) }
        showMessage("All draft reports cleared.")
    }

    /** Persist the learned Markdown style spec to app storage for reuse by the .docx generator. */
    fun persistStyleSpecMd(md: String) {
        runCatching {
            val file = java.io.File(appContext.filesDir, "REPORT_STYLE_SPEC.md")
            if (md.isBlank()) file.delete() else file.writeText(md, Charsets.UTF_8)
        }
    }

    /** Read back the persisted style spec (empty string when none saved). */
    fun loadStyleSpecMd(): String = runCatching {
        java.io.File(appContext.filesDir, "REPORT_STYLE_SPEC.md").readText(Charsets.UTF_8)
    }.getOrDefault("")

    /** Rebuild the active dossier .md so the style spec section stays in sync. */
    fun refreshDossierFile() {
        DossierMarkdownService.persistDossierFile(appContext, _uiState.value.profile, _uiState.value.activeProject)
    }

    fun updateDeedData(deedData: DeedData) {
        val proj = ensureActiveProject().copy(
            deedData = deedData,
            status = if (_uiState.value.activeProject?.status == AppConstants.STATUS_COMPLETED) {
                AppConstants.STATUS_COMPLETED
            } else {
                AppConstants.STATUS_IN_PROGRESS
            },
        )
        persistProject(proj)
    }

    fun extractDeedWithAi(paths: List<String>, onExtracted: (DeedData) -> Unit) {
        if (paths.isEmpty()) {
            showMessage("Please attach or capture a title deed document first.", isError = true)
            return
        }
        _uiState.update { it.copy(isExtracting = true, extractionStatus = "Starting AI document extraction...") }
        viewModelScope.launch {
            runCatching {
                aiService.extractDeed(paths) { status ->
                    _uiState.update { it.copy(extractionStatus = status) }
                }
            }.onSuccess { extracted ->
                updateDeedData(extracted)
                onExtracted(extracted)
                _uiState.update { it.copy(isExtracting = false, extractionStatus = "") }
                showMessage("AI Deed Details extracted. Please review and verify.")
            }.onFailure { err ->
                _uiState.update { it.copy(isExtracting = false, extractionStatus = "") }
                showMessage(err.message ?: "Deed extraction failed.", isError = true)
            }
        }
    }

    fun updateSurveyPlanData(planData: SurveyPlanData) {
        val proj = ensureActiveProject().copy(surveyPlanData = planData)
        persistProject(proj)
    }

    fun extractSurveyPlanWithAi(paths: List<String>, onExtracted: (SurveyPlanData) -> Unit) {
        if (paths.isEmpty()) {
            showMessage("Please attach or capture a survey plan document first.", isError = true)
            return
        }
        _uiState.update { it.copy(isExtracting = true, extractionStatus = "Analyzing survey plan & extracting lots...") }
        viewModelScope.launch {
            runCatching {
                aiService.extractSurveyPlan(paths) { status ->
                    _uiState.update { it.copy(extractionStatus = status) }
                }
            }.onSuccess { extracted ->
                updateSurveyPlanData(extracted)
                onExtracted(extracted)
                _uiState.update { it.copy(isExtracting = false, extractionStatus = "") }
                showMessage("Survey Plan & Lots extracted successfully.")
            }.onFailure { err ->
                _uiState.update { it.copy(isExtracting = false, extractionStatus = "") }
                showMessage(err.message ?: "Survey plan extraction failed.", isError = true)
            }
        }
    }

    fun updateInspectionData(inspectionData: InspectionData) {
        val proj = ensureActiveProject().copy(
            inspectionData = inspectionData,
            clientOrBank = inspectionData.targetInstitution,
        )
        persistProject(proj)
    }

    fun updateLocationData(locationData: LocationData) {
        val proj = ensureActiveProject().copy(locationData = locationData)
        persistProject(proj)
    }

    fun polishDirectionsWithAi(rawText: String, onPolished: (String) -> Unit) {
        if (rawText.isBlank()) return
        _uiState.update { it.copy(isPolishingText = true) }
        viewModelScope.launch {
            val polished = aiService.polishValuationLanguage(rawText)
            _uiState.update { it.copy(isPolishingText = false) }
            onPolished(polished)
            showMessage("Directions converted to formal valuation language.")
        }
    }

    fun updateBuildingSketch(sketch: BuildingSketch) {
        val proj = ensureActiveProject().copy(buildingSketch = sketch)
        persistProject(proj)
    }

    fun updateBuildingDetails(details: BuildingDetails) {
        val proj = ensureActiveProject().copy(buildingDetails = details)
        persistProject(proj)
    }

    fun updateValuationData(valuationData: ValuationData) {
        val proj = ensureActiveProject().copy(valuationData = valuationData)
        persistProject(proj)
    }

    fun updateTargetPageCount(pages: Int) {
        val proj = ensureActiveProject().copy(targetPageCount = pages)
        persistProject(proj)
    }

    fun buildCaseDossierMarkdown(): String =
        DossierMarkdownService.buildDossierMarkdown(_uiState.value.profile, _uiState.value.activeProject)

    fun generateDocxReport(onSuccess: () -> Unit) {
        val state = _uiState.value
        if (state.isGeneratingDocx) return
        val usage = repository.getMonthlyUsage()
        if (usage.isLimitReached) {
            _uiState.update { it.copy(usageState = usage, showLimitDialog = true) }
            return
        }

        val updatedUsage = repository.incrementMonthlyUsage()
        val project = ensureActiveProject()
        _uiState.update {
            it.copy(
                usageState = updatedUsage,
                isGeneratingDocx = true,
                generationProgress = "Validating valuation metrics & tables...",
            )
        }

        viewModelScope.launch {
            runCatching {
                DocxService.generateValuationDocx(
                    context = appContext,
                    project = project,
                    profile = _uiState.value.profile,
                ) { status ->
                    _uiState.update { it.copy(generationProgress = status) }
                }
            }.onSuccess { docxPath ->
                val completed = project.copy(
                    generatedDocxPath = docxPath,
                    status = AppConstants.STATUS_COMPLETED,
                )
                persistProject(completed)
                _uiState.update {
                    it.copy(
                        isGeneratingDocx = false,
                        generationProgress = "",
                        usageState = repository.getMonthlyUsage(),
                    )
                }
                onSuccess()
            }.onFailure { err ->
                _uiState.update { it.copy(isGeneratingDocx = false, generationProgress = "") }
                showMessage("Error generating report: ${err.message}", isError = true)
            }
        }
    }

    fun verifyLicenseKey(key: String): Boolean {
        val ok = repository.verifyAndApplyLicense(key)
        if (ok) {
            refreshAll()
            showMessage("Paid Version Activated! Unlimited monthly reports unlocked.")
        }
        return ok
    }

    suspend fun testApiConnection(): ConnectionTestResult = aiService.testConnectionDetailed()
    suspend fun fetchModels(apiKey: String): List<String> = aiService.fetchAvailableModels(apiKey)

    private fun persistProject(project: ValuationProject) {
        val list = repository.saveActiveProject(project)
        DossierMarkdownService.persistDossierFile(appContext, _uiState.value.profile, project)
        _uiState.update { it.copy(projects = list, activeProject = project) }
    }
}
