# scaffold_chatmd.ps1
# สร้างโครงสร้างโปรเจกต์ ChatMD (โฟลเดอร์ + ไฟล์เปล่า + i18n เบื้องต้น)

$ErrorActionPreference = "Stop"

function New-Dirs {
  param([string[]]$paths)
  foreach ($p in $paths) {
    New-Item -ItemType Directory -Path $p -Force | Out-Null
  }
}

function Touch-Files {
  param([string[]]$files)
  foreach ($f in $files) {
    if (-Not (Test-Path $f)) {
      New-Item -ItemType File -Path $f -Force | Out-Null
    } else {
      # คงไฟล์เดิมไว้ (ไม่เขียนทับ)
    }
  }
}

Write-Host "==> Creating folders..."

$dirs = @(
  "lib\l10n",
  "lib\theme",
  "lib\core\api", "lib\core\auth", "lib\core\router", "lib\core\user",
  "lib\core\data", "lib\core\models", "lib\core\rules\packs",
  "lib\core\alerts", "lib\core\perf", "lib\core\services",
  "lib\features\auth\widgets",
  "lib\features\home",
  "lib\features\wearables",
  "lib\features\personalized\models", "lib\features\personalized\widgets",
  "lib\features\ai_chat\screens",
  "lib\features\ai_disease\screens",
  "lib\features\food\screens",
  "lib\features\fit\screens",
  "lib\features\more\screens",
  "lib\ui\widgets", "lib\ui\feed", "lib\ui\settings",
  "lib\ui\consult", "lib\ui\onboarding", "lib\ui\notifications",
  "lib\utils",
  "assets\icons", "assets\images",
  "test"
)

New-Dirs $dirs

Write-Host "==> Creating files..."

$files = @(
  "lib\main.dart",
  "lib\theme\app_theme.dart",
  "lib\core\api\http_client.dart",
  "lib\core\auth\auth_service.dart",
  "lib\core\router\app_router.dart",
  "lib\core\user\session.dart",
  "lib\core\data\user_repo.dart",
  "lib\core\data\health_repo.dart",
  "lib\core\data\feed_repo.dart",
  "lib\core\models\user_profile.dart",
  "lib\core\models\wearable_metrics.dart",
  "lib\core\models\home_plan.dart",
  "lib\core\models\rule.dart",
  "lib\core\models\condition.dart",
  "lib\core\models\action.dart",
  "lib\core\models\notification_item.dart",
  "lib\core\rules\builtin_conditions.dart",
  "lib\core\rules\builtin_actions.dart",
  "lib\core\rules\rule_engine.dart",
  "lib\core\alerts\notifier.dart",
  "lib\core\alerts\inbox_store.dart",
  "lib\core\perf\frame_guard.dart",
  "lib\core\services\background_poll.dart",
  "lib\features\auth\login_screen.dart",
  "lib\features\auth\register_screen.dart",
  "lib\features\auth\widgets\glass_card.dart",
  "lib\features\auth\widgets\social_row.dart",
  "lib\features\home\home_screen.dart",
  "lib\features\home\home_layout.dart",
  "lib\features\home\home_items.dart",
  "lib\features\wearables\health_service.dart",
  "lib\features\wearables\wearable_card.dart",
  "lib\features\personalized\personalized_card.dart",
  "lib\features\personalized\personalized_engine.dart",
  "lib\features\personalized\models\daily_tip.dart",
  "lib\features\personalized\models\personalized_event.dart",
  "lib\features\personalized\widgets\recommendation_tile.dart",
  "lib\features\ai_chat\ai_chat_card.dart",
  "lib\features\ai_chat\screens\ai_chat_screen.dart",
  "lib\features\ai_disease\disease_card.dart",
  "lib\features\ai_disease\screens\disease_check_screen.dart",
  "lib\features\food\food_card.dart",
  "lib\features\food\screens\food_screen.dart",
  "lib\features\fit\fit_card.dart",
  "lib\features\fit\screens\fit_screen.dart",
  "lib\features\more\more_card.dart",
  "lib\features\more\screens\more_screen.dart",
  "lib\ui\widgets\feature_card.dart",
  "lib\ui\widgets\net_state_banner.dart",
  "lib\ui\widgets\section_header.dart",
  "lib\ui\widgets\primary_button.dart",
  "lib\ui\widgets\glass_backdrop.dart",
  "lib\ui\feed\feed_screen.dart",
  "lib\ui\settings\settings_screen.dart",
  "lib\ui\settings\language_picker.dart",
  "lib\ui\settings\module_manager_screen.dart",
  "lib\ui\settings\thresholds_screen.dart",
  "lib\ui\settings\permissions_screen.dart",
  "lib\ui\consult\consult_screen.dart",
  "lib\ui\onboarding\consent_screen.dart",
  "lib\ui\onboarding\profile_form_screen.dart",
  "lib\ui\onboarding\conditions_picker_screen.dart",
  "lib\ui\onboarding\done_screen.dart",
  "lib\ui\notifications\inbox_screen.dart",
  "lib\utils\format.dart",
  "lib\utils\connectivity.dart",
  "lib\utils\platform.dart",
  "assets\.keep",
  "test\smoke_test.dart"
)

Touch-Files $files

Write-Host "==> Writing i18n (ARB) ..."

$appEn = @'
{
  "@@locale": "en",
  "app_name": "ChatMD",
  "login_title": "Welcome back",
  "register_title": "Create account",
  "home_title": "Home",
  "feed_title": "Feed",
  "consult_title": "Consult",
  "settings_title": "Settings"
}
'@

$appTh = @'
{
  "@@locale": "th",
  "app_name": "ChatMD",
  "login_title": "ยินดีต้อนรับกลับ",
  "register_title": "สร้างบัญชี",
  "home_title": "หน้าหลัก",
  "feed_title": "ฟีด",
  "consult_title": "ปรึกษาแพทย์",
  "settings_title": "ตั้งค่า"
}
'@

$appEn | Out-File -FilePath "lib\l10n\app_en.arb" -Encoding utf8 -Force
$appTh | Out-File -FilePath "lib\l10n\app_th.arb" -Encoding utf8 -Force

Write-Host "==> Done. Scaffold created ✅"
