import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  LanguageService._();

  static const String _prefKey = 'finsight_selected_language';

  static final ValueNotifier<String> selectedLanguage =
      ValueNotifier<String>('English (EN)');

  static String get current => selectedLanguage.value;

  static String get languageCode {
    final lang = selectedLanguage.value;
    if (lang.contains('HI')) return 'hi';
    if (lang.contains('ID')) return 'id';
    if (lang.contains('ES')) return 'es';
    if (lang.contains('FR')) return 'fr';
    if (lang.contains('DE')) return 'de';
    if (lang.contains('AR')) return 'ar';
    if (lang.contains('ZH')) return 'zh';
    return 'en';
  }

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && _translations.containsKey(_codeFor(saved))) {
      selectedLanguage.value = saved;
    }
  }

  static Future<void> setLanguage(String language) async {
    selectedLanguage.value = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, language);
  }

  static String _codeFor(String lang) {
    if (lang.contains('HI')) return 'hi';
    if (lang.contains('ID')) return 'id';
    if (lang.contains('ES')) return 'es';
    if (lang.contains('FR')) return 'fr';
    if (lang.contains('DE')) return 'de';
    if (lang.contains('AR')) return 'ar';
    if (lang.contains('ZH')) return 'zh';
    return 'en';
  }

  static String translate(String key) {
    final code = languageCode;
    if (code == 'en') return key;

    final langMap = _translations[code];
    if (langMap != null && langMap.containsKey(key)) {
      return langMap[key]!;
    }
    return key;
  }

  static final Map<String, Map<String, String>> _translations = {
    // Hindi (HI)
    'hi': {
      'Home': 'होम',
      'Activity': 'गतिविधि',
      'Budget': 'बजट',
      'Profile': 'प्रोफ़ाइल',
      'Username': 'उपयोगकर्ता नाम',
      'Account': 'खाता',
      'Settings': 'सेटिंग्स',
      'Export Data': 'डेटा निर्यात',
      'Logout': 'लॉग आउट',
      'Edit profile': 'प्रोफ़ाइल संपादित करें',
      'Full name': 'पूरा नाम',
      'Cancel': 'रद्द करें',
      'Save': 'सहेजें',
      'Logout?': 'लॉग आउट करें?',
      'Are you sure you want to log out?': 'क्या आप वाकई लॉग आउट करना चाहते हैं?',
      'No': 'नहीं',
      'Yes': 'हाँ',
      'Account Balance': 'खाता शेष',
      'No accounts yet': 'अभी तक कोई खाता नहीं',
      'Add a bank, wallet, or credit card to start tracking your finances.':
          'अपने वित्त को ट्रैक करने के लिए बैंक, वॉलेट या क्रेडिट कार्ड जोड़ें।',
      'Add new account': 'नया खाता जोड़ें',
      'Edit account': 'खाता संपादित करें',
      'Detail account': 'खाते का विवरण',
      'Balance': 'बैलेंस',
      'Account name': 'खाते का नाम',
      'Account type': 'खाते का प्रकार',
      'Currency': 'मुद्रा',
      'Language': 'भाषा',
      'Theme': 'थीम',
      'Security': 'सुरक्षा',
      'Change PIN': 'पिन बदलें',
      'Notification': 'सूचनाएं',
      'About': 'के बारे में',
      'About FinSight': 'फिनसाइट के बारे में',
      'Help': 'सहायता',
      'Frequently asked questions': 'अक्सर पूछे जाने वाले प्रश्न',
      'Recent transactions': 'हाल के लेन-देन',
      'Accounts': 'खाते',
      'Credit card due': 'क्रेडिट कार्ड बकाया',
      'Continue': 'जारी रखें',
      'Last 4 digits (optional)': 'अंतिम 4 अंक (वैकल्पिक)',
      'Choose bank or wallet provider': 'बैंक या वॉलेट प्रदाता चुनें',
      'Select a provider': 'एक प्रदाता चुनें',
      'Expense Alert': 'व्यय चेतावनी',
      'Tips & Articles': 'सुझाव और लेख',
      'What data do you want to export?': 'आप कौन सा डेटा निर्यात करना चाहते हैं?',
      'When date range?': 'किस समयावधि का?',
      'What format do you want to export?': 'किस प्रारूप में निर्यात करना चाहते हैं?',
      'Export': 'निर्यात करें',
      'Your export is ready': 'आपका निर्यात तैयार है',
      'Back to Profile': 'प्रोफ़ाइल पर वापस जाएं',
      'Usable Balance': 'उपयोग योग्य शेष राशि',
      'Total Balance': 'कुल शेष राशि',
      'Income': 'आय',
      'Expense': 'खर्च',
      'See all': 'सभी देखें',
      'Your transactions will appear here': 'आपके लेन-देन यहाँ दिखाई देंगे',
      'Your budget insights will appear here': 'आपकी बजट अंतर्दृष्टि यहाँ दिखाई देगी',
      'Your finances': 'आपका वित्त',
      'Hi,': 'नमस्ते,',
      'App lock': 'ऐप लॉक',
    },

    // Indonesian (ID)
    'id': {
      'Home': 'Beranda',
      'Activity': 'Aktivitas',
      'Budget': 'Anggaran',
      'Profile': 'Profil',
      'Username': 'Nama Pengguna',
      'Account': 'Akun',
      'Settings': 'Pengaturan',
      'Export Data': 'Ekspor Data',
      'Logout': 'Keluar',
      'Edit profile': 'Edit profil',
      'Full name': 'Nama lengkap',
      'Cancel': 'Batal',
      'Save': 'Simpan',
      'Logout?': 'Keluar?',
      'Are you sure you want to log out?': 'Apakah Anda yakin ingin keluar?',
      'No': 'Tidak',
      'Yes': 'Ya',
      'Account Balance': 'Saldo Akun',
      'No accounts yet': 'Belum ada akun',
      'Add a bank, wallet, or credit card to start tracking your finances.':
          'Tambahkan bank, dompet, atau kartu kredit untuk mulai memantau keuangan Anda.',
      'Add new account': 'Tambah akun baru',
      'Edit account': 'Edit akun',
      'Detail account': 'Detail akun',
      'Balance': 'Saldo',
      'Account name': 'Nama akun',
      'Account type': 'Tipe akun',
      'Currency': 'Mata Uang',
      'Language': 'Bahasa',
      'Theme': 'Tema',
      'Security': 'Keamanan',
      'Change PIN': 'Ubah PIN',
      'Notification': 'Notifikasi',
      'About': 'Tentang',
      'About FinSight': 'Tentang FinSight',
      'Help': 'Bantuan',
      'Frequently asked questions': 'Pertanyaan yang Sering Diajukan',
      'Recent transactions': 'Transaksi terkini',
      'Accounts': 'Akun',
      'Credit card due': 'Tagihan kartu kredit',
      'Continue': 'Lanjutkan',
      'Last 4 digits (optional)': '4 digit terakhir (opsional)',
      'Choose bank or wallet provider': 'Pilih penyedia bank atau dompet',
      'Select a provider': 'Pilih penyedia',
      'Expense Alert': 'Peringatan Pengeluaran',
      'Tips & Articles': 'Tips & Artikel',
      'Export': 'Ekspor',
      'Back to Profile': 'Kembali ke Profil',
    },

    // Spanish (ES)
    'es': {
      'Home': 'Inicio',
      'Activity': 'Actividad',
      'Budget': 'Presupuesto',
      'Profile': 'Perfil',
      'Username': 'Nombre de usuario',
      'Account': 'Cuenta',
      'Settings': 'Ajustes',
      'Export Data': 'Exportar datos',
      'Logout': 'Cerrar sesión',
      'Edit profile': 'Editar perfil',
      'Full name': 'Nombre completo',
      'Cancel': 'Cancelar',
      'Save': 'Guardar',
      'Logout?': '¿Cerrar sesión?',
      'Are you sure you want to log out?': '¿Estás seguro de que quieres cerrar sesión?',
      'No': 'No',
      'Yes': 'Sí',
      'Account Balance': 'Saldo de cuenta',
      'No accounts yet': 'Aún no hay cuentas',
      'Add new account': 'Añadir nueva cuenta',
      'Edit account': 'Editar cuenta',
      'Detail account': 'Detalle de la cuenta',
      'Balance': 'Saldo',
      'Account name': 'Nombre de cuenta',
      'Account type': 'Tipo de cuenta',
      'Currency': 'Moneda',
      'Language': 'Idioma',
      'Theme': 'Tema',
      'Security': 'Seguridad',
      'Change PIN': 'Cambiar PIN',
      'Notification': 'Notificaciones',
      'About': 'Acerca de',
      'Help': 'Ayuda',
      'Recent transactions': 'Transacciones recientes',
      'Accounts': 'Cuentas',
      'Continue': 'Continuar',
      'Back to Profile': 'Volver al perfil',
    },

    // French (FR)
    'fr': {
      'Home': 'Accueil',
      'Activity': 'Activité',
      'Budget': 'Budget',
      'Profile': 'Profil',
      'Username': 'Nom d\'utilisateur',
      'Account': 'Compte',
      'Settings': 'Paramètres',
      'Export Data': 'Exporter les données',
      'Logout': 'Déconnexion',
      'Edit profile': 'Modifier le profil',
      'Full name': 'Nom complet',
      'Cancel': 'Annuler',
      'Save': 'Enregistrer',
      'Logout?': 'Déconnexion ?',
      'No': 'Non',
      'Yes': 'Oui',
      'Account Balance': 'Solde du compte',
      'No accounts yet': 'Pas encore de compte',
      'Add new account': 'Ajouter un compte',
      'Balance': 'Solde',
      'Currency': 'Devise',
      'Language': 'Langue',
      'Theme': 'Thème',
      'Security': 'Sécurité',
      'Change PIN': 'Changer le code PIN',
      'Continue': 'Continuer',
      'Back to Profile': 'Retour au profil',
    },

    // German (DE)
    'de': {
      'Home': 'Startseite',
      'Activity': 'Aktivität',
      'Budget': 'Budget',
      'Profile': 'Profil',
      'Username': 'Benutzername',
      'Account': 'Konto',
      'Settings': 'Einstellungen',
      'Export Data': 'Daten exportieren',
      'Logout': 'Abmelden',
      'Cancel': 'Abbrechen',
      'Save': 'Speichern',
      'No': 'Nein',
      'Yes': 'Ja',
      'Account Balance': 'Kontostand',
      'No accounts yet': 'Noch keine Konten',
      'Add new account': 'Neues Konto hinzufügen',
      'Balance': 'Guthaben',
      'Currency': 'Währung',
      'Language': 'Sprache',
      'Theme': 'Design',
      'Security': 'Sicherheit',
      'Continue': 'Weiter',
      'Back to Profile': 'Zurück zum Profil',
    },

    // Arabic (AR)
    'ar': {
      'Home': 'الرئيسية',
      'Activity': 'النشاط',
      'Budget': 'الميزانية',
      'Profile': 'الملف الشخصي',
      'Account': 'الحساب',
      'Settings': 'الإعدادات',
      'Export Data': 'تصدير البيانات',
      'Logout': 'تسجيل خروج',
      'Cancel': 'إلغاء',
      'Save': 'حفظ',
      'No': 'لا',
      'Yes': 'نعم',
      'Account Balance': 'رصيد الحساب',
      'Add new account': 'إضافة حساب جديد',
      'Balance': 'الرصيد',
      'Currency': 'العملة',
      'Language': 'اللغة',
      'Security': 'الأمان',
      'Continue': 'متابعة',
      'Back to Profile': 'الرجوع إلى الملف الشخصي',
    },

    // Chinese (ZH)
    'zh': {
      'Home': '首页',
      'Activity': '明细',
      'Budget': '预算',
      'Profile': '我的',
      'Username': '用户名',
      'Account': '账户',
      'Settings': '设置',
      'Export Data': '导出数据',
      'Logout': '退出登录',
      'Cancel': '取消',
      'Save': '保存',
      'No': '否',
      'Yes': '是',
      'Account Balance': '账户余额',
      'No accounts yet': '暂无账户',
      'Add new account': '添加新账户',
      'Balance': '余额',
      'Currency': '货币',
      'Language': '语言',
      'Theme': '主题',
      'Security': '安全',
      'Continue': '继续',
      'Back to Profile': '返回个人中心',
    },
  };
}

extension StringTranslationX on String {
  String tr() => LanguageService.translate(this);
}
