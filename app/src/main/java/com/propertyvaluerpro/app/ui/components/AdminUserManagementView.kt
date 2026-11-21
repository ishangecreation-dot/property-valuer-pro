package com.propertyvaluerpro.app.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AdminPanelSettings
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Key
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Save
import androidx.compose.material.icons.filled.Security
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.propertyvaluerpro.app.data.models.FirebaseUserProfile
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.viewmodel.ValuationViewModel
import java.text.DecimalFormat

@Composable
fun AdminUserManagementView(
    viewModel: ValuationViewModel,
    modifier: Modifier = Modifier,
) {
    val uiState = viewModel.uiState.value
    val users = uiState.allUsers
    val allowedAdmins = uiState.allowedAdminEmails
    val isLoading = uiState.isUserManagementLoading

    var showAddUserDialog by remember { mutableStateOf(false) }
    var editingUser by remember { mutableStateOf<FirebaseUserProfile?>(null) }
    var deletingUser by remember { mutableStateOf<FirebaseUserProfile?>(null) }

    var newAdminEmailInput by remember { mutableStateOf("") }

    LaunchedEffect(Unit) {
        viewModel.loadAllUsers()
    }

    Column(modifier = modifier.fillMaxWidth()) {
        // Billing & Token Metrics Summary Card
        BillingMetricsSummaryCard(users = users, onRefresh = { viewModel.loadAllUsers() })

        Spacer(Modifier.height(14.dp))

        // Super Admin & Allowed Admins Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = Color(0xFFF8FAFC)),
            border = BorderStroke(1.dp, Color(0xFFE2E8F0)),
            shape = RoundedCornerShape(12.dp),
        ) {
            Column(modifier = Modifier.padding(14.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Security, contentDescription = null, tint = AppColors.PrimaryNavy, modifier = Modifier.size(20.dp))
                    Spacer(Modifier.width(8.dp))
                    Text("Admin Access Control", fontWeight = FontWeight.Bold, color = AppColors.PrimaryNavy, fontSize = 15.sp)
                }
                Spacer(Modifier.height(6.dp))
                Text(
                    "Super Admin: ${FirebaseUserProfile.SUPER_ADMIN_EMAIL}",
                    fontWeight = FontWeight.SemiBold,
                    color = AppColors.PrimaryActionTeal,
                    fontSize = 13.sp,
                )
                Text(
                    "The Super Admin has full authority to add or revoke admin status for any email.",
                    color = AppColors.NeutralGray,
                    fontSize = 11.5.sp,
                )

                Spacer(Modifier.height(10.dp))

                // Allowed Admins List
                Text("Authorized Admin Emails:", fontWeight = FontWeight.SemiBold, color = AppColors.TextDark, fontSize = 12.5.sp)
                Spacer(Modifier.height(4.dp))
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    allowedAdmins.forEach { email ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(Color.White, RoundedCornerShape(6.dp))
                                .padding(horizontal = 10.dp, vertical = 6.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(email, fontSize = 12.5.sp, color = AppColors.TextDark, fontWeight = FontWeight.Medium)
                            if (!email.trim().equals(FirebaseUserProfile.SUPER_ADMIN_EMAIL, ignoreCase = true)) {
                                IconButton(
                                    onClick = { viewModel.removeAllowedAdminEmail(email) },
                                    modifier = Modifier.size(24.dp),
                                ) {
                                    Icon(Icons.Default.Close, contentDescription = "Remove admin", tint = Color(0xFFDC2626), modifier = Modifier.size(16.dp))
                                }
                            } else {
                                Text("(Primary)", fontSize = 11.sp, color = AppColors.PrimaryActionTeal, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }

                Spacer(Modifier.height(10.dp))

                // Add allowed admin email row
                Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    OutlinedTextField(
                        value = newAdminEmailInput,
                        onValueChange = { newAdminEmailInput = it },
                        modifier = Modifier.weight(1f).height(48.dp),
                        placeholder = { Text("email@example.com", fontSize = 12.sp) },
                        singleLine = true,
                        shape = RoundedCornerShape(8.dp),
                    )
                    Spacer(Modifier.width(8.dp))
                    Button(
                        onClick = {
                            if (newAdminEmailInput.isNotBlank()) {
                                viewModel.addAllowedAdminEmail(newAdminEmailInput) {
                                    newAdminEmailInput = ""
                                }
                            }
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryNavy),
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.height(48.dp),
                    ) {
                        Text("Add Admin", fontSize = 12.5.sp)
                    }
                }
            }
        }

        Spacer(Modifier.height(16.dp))

        // Users Management Header & Add User button
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column {
                Text("Firestore Users Collection", fontWeight = FontWeight.Bold, color = AppColors.PrimaryNavy, fontSize = 16.sp)
                Text("${users.size} Registered Users", fontSize = 12.sp, color = AppColors.NeutralGray)
            }
            Button(
                onClick = { showAddUserDialog = true },
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryActionTeal),
                shape = RoundedCornerShape(8.dp),
            ) {
                Icon(Icons.Default.PersonAdd, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(6.dp))
                Text("Add User", fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold)
            }
        }

        Spacer(Modifier.height(10.dp))

        if (isLoading) {
            Box(modifier = Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = AppColors.PrimaryActionTeal)
            }
        } else if (users.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFFF1F5F9), RoundedCornerShape(10.dp))
                    .padding(24.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text("No users found in Firestore 'users' collection.", color = AppColors.NeutralGray, fontSize = 13.sp)
            }
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                users.forEach { user ->
                    UserCardItem(
                        user = user,
                        onEdit = { editingUser = user },
                        onDelete = { deletingUser = user },
                    )
                }
            }
        }
    }

    // Add User Dialog
    if (showAddUserDialog) {
        UserEditDialog(
            user = FirebaseUserProfile(
                uid = "usr_${System.currentTimeMillis()}",
                role = FirebaseUserProfile.ROLE_USER,
                generatedReport = FirebaseUserProfile.DEFAULT_QUOTA,
                apiModel = "gemini-3.1-flash-lite",
            ),
            isNewUser = true,
            onDismiss = { showAddUserDialog = false },
            onSave = { newUser ->
                viewModel.addUser(newUser) {
                    showAddUserDialog = false
                }
            },
        )
    }

    // Edit User Dialog
    editingUser?.let { user ->
        UserEditDialog(
            user = user,
            isNewUser = false,
            onDismiss = { editingUser = null },
            onSave = { updatedUser ->
                viewModel.updateUser(updatedUser) {
                    editingUser = null
                }
            },
        )
    }

    // Delete Confirmation Dialog
    deletingUser?.let { user ->
        AlertDialog(
            onDismissRequest = { deletingUser = null },
            title = { Text("Delete User Document?", fontWeight = FontWeight.Bold) },
            text = { Text("Are you sure you want to delete '${user.name}' (${user.email}) from Firestore? This action cannot be undone.") },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.deleteUser(user.uid) {
                            deletingUser = null
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFDC2626)),
                ) {
                    Text("Delete")
                }
            },
            dismissButton = {
                TextButton(onClick = { deletingUser = null }) {
                    Text("Cancel")
                }
            },
        )
    }
}

@Composable
private fun BillingMetricsSummaryCard(
    users: List<FirebaseUserProfile>,
    onRefresh: () -> Unit,
) {
    val totalInTokens = users.sumOf { it.apiTokenUsageIn }
    val totalOutTokens = users.sumOf { it.apiTokenUsageOut }
    val totalTokens = totalInTokens + totalOutTokens
    val totalRequests = users.sumOf { it.totalRequests }
    val avgSystemTokens = if (totalRequests > 0L) totalTokens.toDouble() / totalRequests else 0.0

    val df = DecimalFormat("#,###")
    val dfAvg = DecimalFormat("#,##0.0")

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = AppColors.PrimaryNavy),
        shape = RoundedCornerShape(12.dp),
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.BarChart, contentDescription = null, tint = AppColors.PrimaryActionTeal, modifier = Modifier.size(20.dp))
                    Spacer(Modifier.width(8.dp))
                    Text("API Token Usage & Billing Insight", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 14.sp)
                }
                IconButton(onClick = onRefresh, modifier = Modifier.size(28.dp)) {
                    Icon(Icons.Default.Refresh, contentDescription = "Refresh", tint = Color.White, modifier = Modifier.size(16.dp))
                }
            }

            Spacer(Modifier.height(10.dp))

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                MetricItem(label = "Prompt (In) Tokens", value = df.format(totalInTokens))
                MetricItem(label = "Output (Gen) Tokens", value = df.format(totalOutTokens))
                MetricItem(label = "Total Tokens", value = df.format(totalTokens))
            }

            Spacer(Modifier.height(8.dp))
            HorizontalDivider(color = Color.White.copy(alpha = 0.15f))
            Spacer(Modifier.height(8.dp))

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                MetricItem(label = "Total AI Inferences", value = df.format(totalRequests))
                MetricItem(label = "Avg Tokens / Request", value = dfAvg.format(avgSystemTokens))
                MetricItem(label = "Active User Count", value = users.size.toString())
            }
        }
    }
}

@Composable
private fun MetricItem(label: String, value: String) {
    Column {
        Text(label, fontSize = 10.5.sp, color = Color.White.copy(alpha = 0.7f))
        Text(value, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.White)
    }
}

@Composable
private fun UserCardItem(
    user: FirebaseUserProfile,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
) {
    val df = DecimalFormat("#,###")
    val dfAvg = DecimalFormat("#,##0.0")

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        border = BorderStroke(1.dp, Color(0xFFE2E8F0)),
        shape = RoundedCornerShape(10.dp),
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            // Header: Avatar, Name, Email, Role Tag & Actions
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(if (user.isAdmin) AppColors.PrimaryNavy else AppColors.PrimaryActionTeal.copy(alpha = 0.2f)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            text = user.name.take(1).uppercase().ifBlank { "U" },
                            fontWeight = FontWeight.Bold,
                            color = if (user.isAdmin) Color.White else AppColors.PrimaryActionTeal,
                            fontSize = 15.sp,
                        )
                    }
                    Spacer(Modifier.width(10.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = user.name.ifBlank { "User" },
                                fontWeight = FontWeight.Bold,
                                color = AppColors.TextDark,
                                fontSize = 14.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                            )
                            Spacer(Modifier.width(6.dp))
                            Surface(
                                color = if (user.isAdmin) AppColors.PrimaryNavy else Color(0xFFE2E8F0),
                                shape = RoundedCornerShape(4.dp),
                            ) {
                                Text(
                                    text = user.role.uppercase(),
                                    color = if (user.isAdmin) Color.White else Color(0xFF475569),
                                    fontSize = 9.sp,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                )
                            }
                        }
                        Text(
                            text = user.email.ifBlank { "No email recorded" },
                            fontSize = 12.sp,
                            color = AppColors.NeutralGray,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                }

                Row {
                    IconButton(onClick = onEdit, modifier = Modifier.size(32.dp)) {
                        Icon(Icons.Default.Edit, contentDescription = "Edit User", tint = AppColors.PrimaryActionTeal, modifier = Modifier.size(18.dp))
                    }
                    if (!user.email.trim().equals(FirebaseUserProfile.SUPER_ADMIN_EMAIL, ignoreCase = true)) {
                        IconButton(onClick = onDelete, modifier = Modifier.size(32.dp)) {
                            Icon(Icons.Default.Delete, contentDescription = "Delete User", tint = Color(0xFFDC2626), modifier = Modifier.size(18.dp))
                        }
                    }
                }
            }

            Spacer(Modifier.height(10.dp))
            HorizontalDivider(color = Color(0xFFF1F5F9))
            Spacer(Modifier.height(8.dp))

            // User Specific Metrics: Quota, Model, In/Out tokens, Avg
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Column {
                    Text("Generated Report", fontSize = 10.5.sp, color = AppColors.NeutralGray)
                    Text(user.generatedReport, fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold, color = AppColors.TextDark)
                }
                Column {
                    Text("API Model in App", fontSize = 10.5.sp, color = AppColors.NeutralGray)
                    Text(user.apiModel, fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold, color = AppColors.PrimaryActionTeal)
                }
                Column {
                    Text("Total Tokens", fontSize = 10.5.sp, color = AppColors.NeutralGray)
                    Text(df.format(user.apiTokenUsageIn + user.apiTokenUsageOut), fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold, color = AppColors.TextDark)
                }
                Column {
                    Text("Avg Token / Req", fontSize = 10.5.sp, color = AppColors.NeutralGray)
                    Text(dfAvg.format(user.avgApiTokenUsage), fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold, color = AppColors.PrimaryNavy)
                }
            }
        }
    }
}

/**
 * Dialog allowing Admin to add or edit ALL fields of a user document in Firestore.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun UserEditDialog(
    user: FirebaseUserProfile,
    isNewUser: Boolean,
    onDismiss: () -> Unit,
    onSave: (FirebaseUserProfile) -> Unit,
) {
    var uid by remember { mutableStateOf(user.uid) }
    var name by remember { mutableStateOf(user.name) }
    var email by remember { mutableStateOf(user.email) }
    var role by remember { mutableStateOf(user.role) }
    var generatedReport by remember { mutableStateOf(user.generatedReport) }
    var apiKey by remember { mutableStateOf(user.apiKey) }
    var apiModel by remember { mutableStateOf(user.apiModel) }
    var tokenIn by remember { mutableStateOf(user.apiTokenUsageIn.toString()) }
    var tokenOut by remember { mutableStateOf(user.apiTokenUsageOut.toString()) }
    var avgToken by remember { mutableStateOf(user.avgApiTokenUsage.toString()) }

    var roleDropdownExpanded by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                if (isNewUser) "Add New Firestore User" else "Edit User: ${user.name}",
                fontWeight = FontWeight.Bold,
                fontSize = 17.sp,
            )
        },
        text = {
            LazyColumn(modifier = Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                if (isNewUser) {
                    item {
                        OutlinedTextField(
                            value = uid,
                            onValueChange = { uid = it },
                            label = { Text("UID (Document ID)") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                        )
                    }
                }

                item {
                    OutlinedTextField(
                        value = name,
                        onValueChange = { name = it },
                        label = { Text("Name") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                    )
                }

                item {
                    OutlinedTextField(
                        value = email,
                        onValueChange = { email = it },
                        label = { Text("Email") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                    )
                }

                item {
                    // Role dropdown
                    ExposedDropdownMenuBox(
                        expanded = roleDropdownExpanded,
                        onExpandedChange = { roleDropdownExpanded = it },
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        OutlinedTextField(
                            value = role.uppercase(),
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Role") },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = roleDropdownExpanded) },
                            modifier = Modifier.fillMaxWidth().menuAnchor(),
                        )
                        ExposedDropdownMenu(
                            expanded = roleDropdownExpanded,
                            onDismissRequest = { roleDropdownExpanded = false },
                        ) {
                            DropdownMenuItem(
                                text = { Text("USER") },
                                onClick = {
                                    role = FirebaseUserProfile.ROLE_USER
                                    roleDropdownExpanded = false
                                },
                            )
                            DropdownMenuItem(
                                text = { Text("ADMIN") },
                                onClick = {
                                    role = FirebaseUserProfile.ROLE_ADMIN
                                    roleDropdownExpanded = false
                                },
                            )
                        }
                    }
                }

                item {
                    OutlinedTextField(
                        value = generatedReport,
                        onValueChange = { generatedReport = it },
                        label = { Text("Generated Report Quota (e.g. 0/10)") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                    )
                }

                item {
                    OutlinedTextField(
                        value = apiModel,
                        onValueChange = { apiModel = it },
                        label = { Text("API Model in App") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                    )
                }

                item {
                    OutlinedTextField(
                        value = apiKey,
                        onValueChange = { apiKey = it },
                        label = { Text("Assigned API Key (Optional)") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                    )
                }

                item {
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedTextField(
                            value = tokenIn,
                            onValueChange = { tokenIn = it },
                            label = { Text("Token Usage In") },
                            modifier = Modifier.weight(1f),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            singleLine = true,
                        )
                        OutlinedTextField(
                            value = tokenOut,
                            onValueChange = { tokenOut = it },
                            label = { Text("Token Usage Out") },
                            modifier = Modifier.weight(1f),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            singleLine = true,
                        )
                    }
                }

                item {
                    OutlinedTextField(
                        value = avgToken,
                        onValueChange = { avgToken = it },
                        label = { Text("AVG Token Usage (Billing)") },
                        modifier = Modifier.fillMaxWidth(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        singleLine = true,
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val inVal = tokenIn.toLongOrNull() ?: 0L
                    val outVal = tokenOut.toLongOrNull() ?: 0L
                    val avgVal = avgToken.toDoubleOrNull() ?: 0.0
                    val finalUser = user.copy(
                        uid = uid.trim(),
                        name = name.trim(),
                        email = email.trim(),
                        role = role.trim().lowercase(),
                        generatedReport = generatedReport.trim(),
                        apiKey = apiKey.trim(),
                        apiModel = apiModel.trim(),
                        apiTokenUsageIn = inVal,
                        apiTokenUsageOut = outVal,
                        avgApiTokenUsage = avgVal,
                    )
                    onSave(finalUser)
                },
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryNavy),
            ) {
                Icon(Icons.Default.Save, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(6.dp))
                Text("Save to Firestore")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        },
    )
}
