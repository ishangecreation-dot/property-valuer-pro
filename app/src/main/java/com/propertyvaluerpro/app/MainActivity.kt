package com.propertyvaluerpro.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.propertyvaluerpro.app.data.models.AppConstants
import com.propertyvaluerpro.app.ui.components.AdminSettingsDialog
import com.propertyvaluerpro.app.ui.components.FrozenStepContent
import com.propertyvaluerpro.app.ui.components.MonthlyLimitReachedDialog
import com.propertyvaluerpro.app.ui.components.ResponsiveWorkflowScaffold
import com.propertyvaluerpro.app.ui.screens.A3SketchingScreen
import com.propertyvaluerpro.app.ui.screens.BuildingDetailsScreen
import com.propertyvaluerpro.app.ui.screens.DashboardScreen
import com.propertyvaluerpro.app.ui.screens.DeedExtractionScreen
import com.propertyvaluerpro.app.ui.screens.FinalReviewScreen
import com.propertyvaluerpro.app.ui.screens.GenerationSuccessScreen
import com.propertyvaluerpro.app.ui.screens.InspectionScreen
import com.propertyvaluerpro.app.ui.screens.LocationScreen
import com.propertyvaluerpro.app.ui.screens.PlanExtractionScreen
import com.propertyvaluerpro.app.ui.screens.ProfileScreen
import com.propertyvaluerpro.app.ui.screens.ValuationScreen
import com.propertyvaluerpro.app.ui.theme.PropertyValuerProTheme
import com.propertyvaluerpro.app.ui.viewmodel.AppUiState
import com.propertyvaluerpro.app.ui.viewmodel.ValuationViewModel
import kotlinx.serialization.Serializable

@Serializable data object DashboardRoute
@Serializable data object ProfileRoute
@Serializable data object DeedRoute
@Serializable data object PlanRoute
@Serializable data object InspectionRoute
@Serializable data object LocationRoute
@Serializable data object SketchRoute
@Serializable data object BuildingRoute
@Serializable data object ValuationRoute
@Serializable data object ReviewRoute
@Serializable data object SuccessRoute

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            PropertyValuerProTheme {
                PropertyValuerProApp()
            }
        }
    }
}

@Composable
private fun PropertyValuerProApp(
    viewModel: ValuationViewModel = viewModel(),
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val navController = rememberNavController()

    fun navigateToStep(step: Int) {
        if (uiState.screens3To10Frozen && step >= 4) {
            viewModel.showMessage("Step $step is currently frozen. Only Screens 0 to 2 are active.")
            return
        }
        val destination: Any = when (step) {
            1 -> DashboardRoute
            2 -> ProfileRoute
            3 -> DeedRoute
            4 -> PlanRoute
            5 -> InspectionRoute
            6 -> LocationRoute
            7 -> SketchRoute
            8 -> BuildingRoute
            9 -> ValuationRoute
            10 -> ReviewRoute
            else -> DashboardRoute
        }
        if (step >= 3) {
            viewModel.ensureActiveProject()
        }
        navController.navigate(destination) {
            launchSingleTop = true
        }
    }

    NavHost(
        navController = navController,
        startDestination = DashboardRoute,
    ) {
        composable<DashboardRoute> {
            DashboardScreen(
                uiState = uiState,
                onCreateNewValuation = {
                    viewModel.createNewValuation()
                    navController.navigate(ProfileRoute) { launchSingleTop = true }
                },
                onResumeProject = { project ->
                    viewModel.selectProject(project)
                    navController.navigate(DeedRoute) { launchSingleTop = true }
                },
                onDeleteProject = viewModel::deleteProject,
                onNavigateToStep = ::navigateToStep,
                onOpenSettings = viewModel::openAdminSettings,
                onOpenLimitDialog = viewModel::openLimitDialog,
                onSnackbarDismissed = viewModel::clearSnackbar,
            )
        }

        composable<ProfileRoute> {
            ProfileScreen(
                uiState = uiState,
                onSaveProfile = viewModel::saveProfile,
                onSwitchDraft = viewModel::switchProfileDraft,
                onCreateDraft = viewModel::createNewProfileDraft,
                onUploadTemplates = viewModel::addTemplateFiles,
                onRemoveTemplate = viewModel::removeTemplateAt,
                onClearTemplates = viewModel::clearAllTemplates,
                buildDossierMarkdown = viewModel::buildCaseDossierMarkdown,
                onBack = { navController.popBackStack() },
                onNextToDeed = {
                    viewModel.ensureActiveProject()
                    navController.navigate(DeedRoute) { launchSingleTop = true }
                },
                onNavigateToStep = ::navigateToStep,
                onOpenSettings = viewModel::openAdminSettings,
                onSnackbarDismissed = viewModel::clearSnackbar,
            )
        }

        composable<DeedRoute> {
            DeedExtractionScreen(
                uiState = uiState,
                onSaveDeed = viewModel::updateDeedData,
                onExtractWithAi = viewModel::extractDeedWithAi,
                onBack = { navController.popBackStack() },
                onNext = {
                    if (uiState.screens3To10Frozen) {
                        viewModel.showMessage("Title Deed Saved! Screens 3 to 10 are currently frozen (only Screens 0 to 2 are active).")
                    } else {
                        navController.navigate(PlanRoute) { launchSingleTop = true }
                    }
                },
                onNavigateToStep = ::navigateToStep,
                onOpenSettings = viewModel::openAdminSettings,
                onSnackbarDismissed = viewModel::clearSnackbar,
            )
        }

        composable<PlanRoute> {
            FrozenAwareStep(4, uiState, navController, ::navigateToStep, viewModel) {
                PlanExtractionScreen(
                    uiState = uiState,
                    onSavePlan = viewModel::updateSurveyPlanData,
                    onExtractPlanWithAi = viewModel::extractSurveyPlanWithAi,
                    onBack = { navController.popBackStack() },
                    onNext = { navController.navigate(InspectionRoute) { launchSingleTop = true } },
                    onNavigateToStep = ::navigateToStep,
                    onOpenSettings = viewModel::openAdminSettings,
                    onSnackbarDismissed = viewModel::clearSnackbar,
                )
            }
        }

        composable<InspectionRoute> {
            FrozenAwareStep(5, uiState, navController, ::navigateToStep, viewModel) {
                InspectionScreen(
                    uiState = uiState,
                    onSaveInspection = viewModel::updateInspectionData,
                    onBack = { navController.popBackStack() },
                    onNext = { navController.navigate(LocationRoute) { launchSingleTop = true } },
                    onNavigateToStep = ::navigateToStep,
                    onOpenSettings = viewModel::openAdminSettings,
                    onSnackbarDismissed = viewModel::clearSnackbar,
                )
            }
        }

        composable<LocationRoute> {
            FrozenAwareStep(6, uiState, navController, ::navigateToStep, viewModel) {
                LocationScreen(
                    uiState = uiState,
                    onSaveLocation = viewModel::updateLocationData,
                    onPolishDirections = viewModel::polishDirectionsWithAi,
                    onShowMessage = viewModel::showMessage,
                    onBack = { navController.popBackStack() },
                    onNext = { navController.navigate(SketchRoute) { launchSingleTop = true } },
                    onNavigateToStep = ::navigateToStep,
                    onOpenSettings = viewModel::openAdminSettings,
                    onSnackbarDismissed = viewModel::clearSnackbar,
                )
            }
        }

        composable<SketchRoute> {
            FrozenAwareStep(7, uiState, navController, ::navigateToStep, viewModel) {
                A3SketchingScreen(
                    uiState = uiState,
                    onSaveSketch = viewModel::updateBuildingSketch,
                    onBack = { navController.popBackStack() },
                    onNext = { navController.navigate(BuildingRoute) { launchSingleTop = true } },
                    onNavigateToStep = ::navigateToStep,
                    onOpenSettings = viewModel::openAdminSettings,
                    onSnackbarDismissed = viewModel::clearSnackbar,
                )
            }
        }

        composable<BuildingRoute> {
            FrozenAwareStep(8, uiState, navController, ::navigateToStep, viewModel) {
                BuildingDetailsScreen(
                    uiState = uiState,
                    onSaveBuildingDetails = viewModel::updateBuildingDetails,
                    onBack = { navController.popBackStack() },
                    onNext = { navController.navigate(ValuationRoute) { launchSingleTop = true } },
                    onNavigateToStep = ::navigateToStep,
                    onOpenSettings = viewModel::openAdminSettings,
                    onSnackbarDismissed = viewModel::clearSnackbar,
                )
            }
        }

        composable<ValuationRoute> {
            FrozenAwareStep(9, uiState, navController, ::navigateToStep, viewModel) {
                ValuationScreen(
                    uiState = uiState,
                    onSaveValuation = viewModel::updateValuationData,
                    onBack = { navController.popBackStack() },
                    onNext = { navController.navigate(ReviewRoute) { launchSingleTop = true } },
                    onNavigateToStep = ::navigateToStep,
                    onOpenSettings = viewModel::openAdminSettings,
                    onSnackbarDismissed = viewModel::clearSnackbar,
                )
            }
        }

        composable<ReviewRoute> {
            FrozenAwareStep(10, uiState, navController, ::navigateToStep, viewModel) {
                FinalReviewScreen(
                    uiState = uiState,
                    onUpdatePageCount = viewModel::updateTargetPageCount,
                    onGenerateDocx = {
                        viewModel.generateDocxReport {
                            navController.navigate(SuccessRoute) { launchSingleTop = true }
                        }
                    },
                    onOpenLimitDialog = viewModel::openLimitDialog,
                    onBack = { navController.popBackStack() },
                    onNavigateToStep = ::navigateToStep,
                    onOpenSettings = viewModel::openAdminSettings,
                    onSnackbarDismissed = viewModel::clearSnackbar,
                )
            }
        }

        composable<SuccessRoute> {
            GenerationSuccessScreen(
                uiState = uiState,
                onShowMessage = viewModel::showMessage,
                onBackToReview = { navController.popBackStack() },
                onReturnToDashboard = {
                    navController.navigate(DashboardRoute) {
                        popUpTo(DashboardRoute) { inclusive = true }
                        launchSingleTop = true
                    }
                },
                onNavigateToStep = ::navigateToStep,
                onOpenSettings = viewModel::openAdminSettings,
                onSnackbarDismissed = viewModel::clearSnackbar,
            )
        }
    }

    if (uiState.showAdminSettings) {
        AdminSettingsDialog(
            viewModel = viewModel,
            onDismiss = viewModel::closeAdminSettings,
        )
    }

    if (uiState.showLimitDialog) {
        MonthlyLimitReachedDialog(
            onVerifyLicense = viewModel::verifyLicenseKey,
            onDismiss = viewModel::closeLimitDialog,
        )
    }
}

@Composable
private fun FrozenAwareStep(
    stepNumber: Int,
    uiState: AppUiState,
    navController: NavHostController,
    onNavigateToStep: (Int) -> Unit,
    viewModel: ValuationViewModel,
    content: @Composable () -> Unit,
) {
    if (uiState.screens3To10Frozen && stepNumber >= 4) {
        val stepName = AppConstants.WORKFLOW_STEPS.getOrElse(stepNumber - 1) { "Step $stepNumber" }
        ResponsiveWorkflowScaffold(
            currentStep = stepNumber,
            title = stepName,
            screens3To10Frozen = true,
            showBottomNav = false,
            onStepSelected = onNavigateToStep,
            onOpenSettings = viewModel::openAdminSettings,
            onBack = { navController.popBackStack() },
        ) {
            FrozenStepContent(
                stepNumber = stepNumber,
                stepName = stepName,
                onReturnToDeed = { navController.navigate(DeedRoute) { launchSingleTop = true } },
                onReturnToProfile = { navController.navigate(ProfileRoute) { launchSingleTop = true } },
                onReturnToDashboard = {
                    navController.navigate(DashboardRoute) {
                        popUpTo(DashboardRoute) { inclusive = true }
                        launchSingleTop = true
                    }
                },
            )
        }
    } else {
        content()
    }
}
