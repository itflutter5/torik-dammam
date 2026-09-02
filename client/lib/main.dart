import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'google_auth_service.dart';
import 'google_button.dart';

final appLanguage = ValueNotifier<String>('en');

const languageNames = {
  'en': 'English',
  'bn': 'বাংলা',
  'ur': 'اردو',
  'hi': 'हिन्दी',
};

const translations = <String, Map<String, String>>{
  'bn': {
    'Home': 'হোম',
    'Saved': 'সংরক্ষিত',
    'My posts': 'আমার পোস্ট',
    'Profile': 'প্রোফাইল',
    'Post': 'পোস্ট',
    'Login': 'লগইন',
    'Login / Sign up': 'লগইন / নিবন্ধন',
    'Create account': 'অ্যাকাউন্ট তৈরি করুন',
    'All fields marked * are required': '* চিহ্নিত সব ঘর পূরণ করা আবশ্যক',
    'All registration fields are required': 'নিবন্ধনের সব ঘর পূরণ করা আবশ্যক',
    'Create a post': 'পোস্ট তৈরি করুন',
    'Post details': 'পোস্টের বিস্তারিত',
    'Saved posts': 'সংরক্ষিত পোস্ট',
    'Your profile': 'আপনার প্রোফাইল',
    'Publish post': 'পোস্ট প্রকাশ করুন',
    'Sign out': 'সাইন আউট',
    'Language': 'ভাষা',
    'Title': 'শিরোনাম',
    'Description': 'বিবরণ',
    'Store number': 'দোকান নম্বর',
    'Salary (optional)': 'বেতন (ঐচ্ছিক)',
    'Price (optional)': 'মূল্য (ঐচ্ছিক)',
    'Unit (optional)': 'একক (ঐচ্ছিক)',
    'Photos (maximum 3)': 'ছবি (সর্বোচ্চ ৩টি)',
    'Post category': 'পোস্টের বিভাগ',
    'No saved posts': 'কোনো সংরক্ষিত পোস্ট নেই',
    'No posts yet': 'এখনও কোনো পোস্ট নেই',
    'Save profile': 'প্রোফাইল সংরক্ষণ করুন',
    'Phone': 'ফোন',
    'Email': 'ইমেইল',
    'Cancel': 'বাতিল',
    'Verify': 'যাচাই করুন',
  },
  'ur': {
    'Home': 'ہوم',
    'Saved': 'محفوظ',
    'My posts': 'میری پوسٹس',
    'Profile': 'پروفائل',
    'Post': 'پوسٹ',
    'Login': 'لاگ اِن',
    'Login / Sign up': 'لاگ اِن / رجسٹر',
    'Create account': 'اکاؤنٹ بنائیں',
    'All fields marked * are required': '* کے نشان والے تمام خانے لازمی ہیں',
    'All registration fields are required': 'رجسٹریشن کے تمام خانے پُر کرنا ضروری ہیں',
    'Create a post': 'پوسٹ بنائیں',
    'Post details': 'پوسٹ کی تفصیل',
    'Saved posts': 'محفوظ پوسٹس',
    'Your profile': 'آپ کی پروفائل',
    'Publish post': 'پوسٹ شائع کریں',
    'Sign out': 'سائن آؤٹ',
    'Language': 'زبان',
    'Title': 'عنوان',
    'Description': 'تفصیل',
    'Store number': 'دکان نمبر',
    'Salary (optional)': 'تنخواہ (اختیاری)',
    'Price (optional)': 'قیمت (اختیاری)',
    'Unit (optional)': 'اکائی (اختیاری)',
    'Photos (maximum 3)': 'تصاویر (زیادہ سے زیادہ 3)',
    'Post category': 'پوسٹ کی قسم',
    'No saved posts': 'کوئی محفوظ پوسٹ نہیں',
    'No posts yet': 'ابھی کوئی پوسٹ نہیں',
    'Save profile': 'پروفائل محفوظ کریں',
    'Phone': 'فون',
    'Email': 'ای میل',
    'Cancel': 'منسوخ',
    'Verify': 'تصدیق کریں',
  },
  'hi': {
    'Home': 'होम',
    'Saved': 'सहेजे गए',
    'My posts': 'मेरी पोस्ट',
    'Profile': 'प्रोफ़ाइल',
    'Post': 'पोस्ट',
    'Login': 'लॉग इन',
    'Login / Sign up': 'लॉग इन / पंजीकरण',
    'Create account': 'खाता बनाएँ',
    'All fields marked * are required': '* चिह्न वाले सभी फ़ील्ड आवश्यक हैं',
    'All registration fields are required': 'पंजीकरण के सभी फ़ील्ड भरना आवश्यक है',
    'Create a post': 'पोस्ट बनाएँ',
    'Post details': 'पोस्ट विवरण',
    'Saved posts': 'सहेजी गई पोस्ट',
    'Your profile': 'आपकी प्रोफ़ाइल',
    'Publish post': 'पोस्ट प्रकाशित करें',
    'Sign out': 'साइन आउट',
    'Language': 'भाषा',
    'Title': 'शीर्षक',
    'Description': 'विवरण',
    'Store number': 'स्टोर नंबर',
    'Salary (optional)': 'वेतन (वैकल्पिक)',
    'Price (optional)': 'मूल्य (वैकल्पिक)',
    'Unit (optional)': 'इकाई (वैकल्पिक)',
    'Photos (maximum 3)': 'फ़ोटो (अधिकतम 3)',
    'Post category': 'पोस्ट श्रेणी',
    'No saved posts': 'कोई सहेजी गई पोस्ट नहीं',
    'No posts yet': 'अभी कोई पोस्ट नहीं',
    'Save profile': 'प्रोफ़ाइल सहेजें',
    'Phone': 'फ़ोन',
    'Email': 'ईमेल',
    'Cancel': 'रद्द करें',
    'Verify': 'सत्यापित करें',
  },
};

const extendedTranslations = <String, Map<String, String>>{
  'bn': {
    'Add a photo': 'ছবি যোগ করুন',
    'Take photo with camera': 'ক্যামেরা দিয়ে ছবি তুলুন',
    'Upload from gallery': 'গ্যালারি থেকে আপলোড করুন',
    'Name': 'নাম',
    'Saudi phone number': 'সৌদি ফোন নম্বর',
    'Email address': 'ইমেইল ঠিকানা',
    'Password': 'পাসওয়ার্ড',
    'Enter any password': 'পাসওয়ার্ড লিখুন',
    'or': 'অথবা',
    'New user? Register': 'নতুন ব্যবহারকারী? নিবন্ধন করুন',
    'Already registered? Back to login': 'আগেই নিবন্ধিত? লগইনে ফিরুন',
    'Forgot password?': 'পাসওয়ার্ড ভুলে গেছেন?',
    'Reset password': 'পাসওয়ার্ড পুনরায় সেট করুন',
    'Verified phone or email': 'যাচাইকৃত ফোন বা ইমেইল',
    'New password': 'নতুন পাসওয়ার্ড',
    'Send code': 'কোড পাঠান',
    'Password must be at least 8 characters': 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে',
    'Password changed. You can now log in.': 'পাসওয়ার্ড পরিবর্তন হয়েছে। এখন লগইন করুন।',
    'Create your marketplace account.':
        'আপনার মার্কেটপ্লেস অ্যাকাউন্ট তৈরি করুন।',
    'Log in with your Saudi phone number.':
        'আপনার সৌদি ফোন নম্বর দিয়ে লগইন করুন।',
    'Verify your account': 'আপনার অ্যাকাউন্ট যাচাই করুন',
    'Where should we send your 6-digit verification code?':
        '৬ সংখ্যার যাচাইকরণ কোড কোথায় পাঠাব?',
    'Enter verification code': 'যাচাইকরণ কোড লিখুন',
    'Verification code': 'যাচাইকরণ কোড',
    'Cannot connect to the server': 'সার্ভারের সাথে সংযোগ করা যাচ্ছে না',
    'Search work, metal, batteries…': 'কাজ, ধাতু, ব্যাটারি খুঁজুন…',
    'Choose month': 'মাস নির্বাচন করুন',
    'All days': 'সব দিন',
    'Retry': 'আবার চেষ্টা করুন',
    'Phone dialer is not available': 'ফোন ডায়ালার পাওয়া যাচ্ছে না',
    'Camera or photo access is not available':
        'ক্যামেরা বা ছবির অনুমতি পাওয়া যায়নি',
    'Each image must be smaller than 8 MB': 'প্রতিটি ছবি ৮ এমবির কম হতে হবে',
    'Image must be smaller than 8 MB': 'ছবিটি ৮ এমবির কম হতে হবে',
    'Select a category and complete all required fields':
        'একটি বিভাগ বেছে নিয়ে সব প্রয়োজনীয় ঘর পূরণ করুন',
    'Post published': 'পোস্ট প্রকাশিত হয়েছে',
    'Categories could not be loaded': 'বিভাগগুলো লোড করা যায়নি',
    'Example: 0101': 'উদাহরণ: 0101',
    'Tap a bookmark icon to save a post here.':
        'এখানে পোস্ট রাখতে বুকমার্ক আইকনে চাপুন।',
    'Remove from saved': 'সংরক্ষিত থেকে সরান',
    'Your published advertisements will appear here.':
        'আপনার প্রকাশিত বিজ্ঞাপন এখানে দেখা যাবে।',
    'Your published advertisements appear here.':
        'আপনার প্রকাশিত বিজ্ঞাপন এখানে দেখা যায়।',
    'Profile picture updated': 'প্রোফাইল ছবি আপডেট হয়েছে',
    'Add profile picture': 'প্রোফাইল ছবি যোগ করুন',
    'Name cannot be changed': 'নাম পরিবর্তন করা যাবে না',
    'These details will appear below your posts.':
        'এই তথ্য আপনার পোস্টের নিচে দেখা যাবে।',
    'Google sign-in was not completed': 'গুগল সাইন-ইন সম্পন্ন হয়নি',
    'We sent a 6-digit code to': 'আমরা ৬ সংখ্যার কোড পাঠিয়েছি',
    'Call': 'কল করুন',
    'Find everything to buy and sell in one place.':
        'এক জায়গায় কেনাবেচার সবকিছু খুঁজুন।',
    'Signed in': 'লগইন করা হয়েছে',
    'Post number': 'পোস্ট নম্বর',
    'Salary': 'বেতন',
    'Negotiable': 'আলোচনা সাপেক্ষ',
    'Required to create a post': 'পোস্ট তৈরির জন্য প্রয়োজনীয়',
    'Store number must contain 1 to 4 digits':
        'দোকান নম্বরে ১ থেকে ৪টি সংখ্যা থাকতে হবে',
    'Posts show for 30 days. Older posts are automatically deleted.':
        'পোস্ট ৩০ দিন দেখা যায়। পুরোনো পোস্ট স্বয়ংক্রিয়ভাবে মুছে যায়।',
    'All dates in this 30-day window are shown. Dates without posts remain empty.':
        'এই ৩০ দিনের সব তারিখ দেখানো হয়। পোস্ট না থাকলে তারিখ খালি থাকে।',
    'posts': 'পোস্ট',
    'January': 'জানুয়ারি',
    'February': 'ফেব্রুয়ারি',
    'March': 'মার্চ',
    'April': 'এপ্রিল',
    'May': 'মে',
    'June': 'জুন',
    'July': 'জুলাই',
    'August': 'আগস্ট',
    'September': 'সেপ্টেম্বর',
    'October': 'অক্টোবর',
    'November': 'নভেম্বর',
    'December': 'ডিসেম্বর',
    'Change profile picture': 'প্রোফাইল ছবি পরিবর্তন করুন',
    'Saudi numbers only (+966); cannot be changed':
        'শুধু সৌদি নম্বর (+966); পরিবর্তন করা যাবে না',
    'Store number can be changed now': 'দোকান নম্বর এখন পরিবর্তন করা যাবে',
    'Can be changed again in': 'আবার পরিবর্তন করা যাবে',
    'days': 'দিন পরে',
    'Profile saved. Store number is locked for 30 days.':
        'প্রোফাইল সংরক্ষিত। দোকান নম্বর ৩০ দিনের জন্য লক করা হয়েছে।',
    'Profile is up to date': 'প্রোফাইল হালনাগাদ আছে',
    'Photo': 'ছবি',
    'Need Job': 'কাজ চাই',
    'Need Worker': 'কর্মী চাই',
    'Buy Scrap': 'স্ক্র্যাপ কিনুন',
    'Sell Scrap': 'স্ক্র্যাপ বিক্রি করুন',
    'Driver': 'ড্রাইভার',
    'Serviceman': 'সেবাকর্মী',
    'House Items': 'গৃহস্থালি সামগ্রী',
  },
  'ur': {
    'Add a photo': 'تصویر شامل کریں',
    'Take photo with camera': 'کیمرے سے تصویر لیں',
    'Upload from gallery': 'گیلری سے اپ لوڈ کریں',
    'Name': 'نام',
    'Saudi phone number': 'سعودی فون نمبر',
    'Email address': 'ای میل پتہ',
    'Password': 'پاس ورڈ',
    'Enter any password': 'پاس ورڈ درج کریں',
    'or': 'یا',
    'New user? Register': 'نئے صارف؟ رجسٹر کریں',
    'Already registered? Back to login':
        'پہلے سے رجسٹرڈ؟ لاگ اِن پر واپس جائیں',
    'Forgot password?': 'پاس ورڈ بھول گئے؟',
    'Reset password': 'پاس ورڈ ری سیٹ کریں',
    'Verified phone or email': 'تصدیق شدہ فون یا ای میل',
    'New password': 'نیا پاس ورڈ',
    'Send code': 'کوڈ بھیجیں',
    'Password must be at least 8 characters': 'پاس ورڈ کم از کم 8 حروف کا ہونا چاہیے',
    'Password changed. You can now log in.': 'پاس ورڈ تبدیل ہوگیا۔ اب لاگ اِن کریں۔',
    'Create your marketplace account.': 'اپنا مارکیٹ پلیس اکاؤنٹ بنائیں۔',
    'Log in with your Saudi phone number.':
        'اپنے سعودی فون نمبر سے لاگ اِن کریں۔',
    'Verify your account': 'اپنے اکاؤنٹ کی تصدیق کریں',
    'Where should we send your 6-digit verification code?':
        '6 ہندسوں کا تصدیقی کوڈ کہاں بھیجیں؟',
    'Enter verification code': 'تصدیقی کوڈ درج کریں',
    'Verification code': 'تصدیقی کوڈ',
    'Cannot connect to the server': 'سرور سے رابطہ نہیں ہو سکا',
    'Search work, metal, batteries…': 'کام، دھات، بیٹریاں تلاش کریں…',
    'Choose month': 'مہینہ منتخب کریں',
    'All days': 'تمام دن',
    'Retry': 'دوبارہ کوشش کریں',
    'Phone dialer is not available': 'فون ڈائلر دستیاب نہیں',
    'Camera or photo access is not available':
        'کیمرے یا تصویر تک رسائی دستیاب نہیں',
    'Each image must be smaller than 8 MB':
        'ہر تصویر 8 ایم بی سے کم ہونی چاہیے',
    'Image must be smaller than 8 MB': 'تصویر 8 ایم بی سے کم ہونی چاہیے',
    'Select a category and complete all required fields':
        'قسم منتخب کریں اور تمام ضروری خانے مکمل کریں',
    'Post published': 'پوسٹ شائع ہو گئی',
    'Categories could not be loaded': 'اقسام لوڈ نہیں ہو سکیں',
    'Example: 0101': 'مثال: 0101',
    'Tap a bookmark icon to save a post here.':
        'پوسٹ یہاں محفوظ کرنے کے لیے بک مارک دبائیں۔',
    'Remove from saved': 'محفوظ سے ہٹائیں',
    'Your published advertisements will appear here.':
        'آپ کے شائع شدہ اشتہارات یہاں نظر آئیں گے۔',
    'Your published advertisements appear here.':
        'آپ کے شائع شدہ اشتہارات یہاں دکھائی دیتے ہیں۔',
    'Profile picture updated': 'پروفائل تصویر اپ ڈیٹ ہو گئی',
    'Add profile picture': 'پروفائل تصویر شامل کریں',
    'Name cannot be changed': 'نام تبدیل نہیں کیا جا سکتا',
    'These details will appear below your posts.':
        'یہ تفصیلات آپ کی پوسٹس کے نیچے نظر آئیں گی۔',
    'Google sign-in was not completed': 'گوگل سائن اِن مکمل نہیں ہوا',
    'We sent a 6-digit code to': 'ہم نے 6 ہندسوں کا کوڈ بھیجا ہے',
    'Call': 'کال کریں',
    'Find everything to buy and sell in one place.':
        'خرید و فروخت کی ہر چیز ایک جگہ تلاش کریں۔',
    'Signed in': 'لاگ اِن ہو چکا ہے',
    'Post number': 'پوسٹ نمبر',
    'Salary': 'تنخواہ',
    'Negotiable': 'قابلِ گفت و شنید',
    'Required to create a post': 'پوسٹ بنانے کے لیے ضروری',
    'Store number must contain 1 to 4 digits':
        'دکان نمبر میں 1 سے 4 ہندسے ہونے چاہئیں',
    'Posts show for 30 days. Older posts are automatically deleted.': 'پوسٹس 30 دن تک دکھائی جاتی ہیں۔ پرانی پوسٹس خودکار طور پر حذف ہو جاتی ہیں۔',
    'All dates in this 30-day window are shown. Dates without posts remain empty.': 'اس 30 دن کی تمام تاریخیں دکھائی جاتی ہیں۔ بغیر پوسٹ والی تاریخیں خالی رہتی ہیں۔',
    'posts': 'پوسٹس',
    'January': 'جنوری',
    'February': 'فروری',
    'March': 'مارچ',
    'April': 'اپریل',
    'May': 'مئی',
    'June': 'جون',
    'July': 'جولائی',
    'August': 'اگست',
    'September': 'ستمبر',
    'October': 'اکتوبر',
    'November': 'نومبر',
    'December': 'دسمبر',
    'Change profile picture': 'پروفائل تصویر تبدیل کریں',
    'Saudi numbers only (+966); cannot be changed':
        'صرف سعودی نمبر (+966)؛ تبدیل نہیں کیا جا سکتا',
    'Store number can be changed now': 'دکان نمبر اب تبدیل کیا جا سکتا ہے',
    'Can be changed again in': 'دوبارہ تبدیل کیا جا سکتا ہے',
    'days': 'دن بعد',
    'Profile saved. Store number is locked for 30 days.':
        'پروفائل محفوظ ہو گئی۔ دکان نمبر 30 دن کے لیے مقفل ہے۔',
    'Profile is up to date': 'پروفائل تازہ ہے',
    'Photo': 'تصویر',
    'Need Job': 'کام چاہیے',
    'Need Worker': 'کارکن چاہیے',
    'Buy Scrap': 'اسکریپ خریدیں',
    'Sell Scrap': 'اسکریپ بیچیں',
    'Driver': 'ڈرائیور',
    'Serviceman': 'سروس مین',
    'House Items': 'گھریلو اشیاء',
  },
  'hi': {
    'Add a photo': 'फ़ोटो जोड़ें',
    'Take photo with camera': 'कैमरे से फ़ोटो लें',
    'Upload from gallery': 'गैलरी से अपलोड करें',
    'Name': 'नाम',
    'Saudi phone number': 'सऊदी फ़ोन नंबर',
    'Email address': 'ईमेल पता',
    'Password': 'पासवर्ड',
    'Enter any password': 'पासवर्ड दर्ज करें',
    'or': 'या',
    'New user? Register': 'नए उपयोगकर्ता? पंजीकरण करें',
    'Already registered? Back to login': 'पहले से पंजीकृत? लॉग इन पर लौटें',
    'Forgot password?': 'पासवर्ड भूल गए?',
    'Reset password': 'पासवर्ड रीसेट करें',
    'Verified phone or email': 'सत्यापित फ़ोन या ईमेल',
    'New password': 'नया पासवर्ड',
    'Send code': 'कोड भेजें',
    'Password must be at least 8 characters': 'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए',
    'Password changed. You can now log in.': 'पासवर्ड बदल गया। अब लॉग इन करें।',
    'Create your marketplace account.': 'अपना मार्केटप्लेस खाता बनाएँ।',
    'Log in with your Saudi phone number.':
        'अपने सऊदी फ़ोन नंबर से लॉग इन करें।',
    'Verify your account': 'अपने खाते को सत्यापित करें',
    'Where should we send your 6-digit verification code?':
        '6 अंकों का सत्यापन कोड कहाँ भेजें?',
    'Enter verification code': 'सत्यापन कोड दर्ज करें',
    'Verification code': 'सत्यापन कोड',
    'Cannot connect to the server': 'सर्वर से कनेक्ट नहीं हो सका',
    'Search work, metal, batteries…': 'काम, धातु, बैटरी खोजें…',
    'Choose month': 'महीना चुनें',
    'All days': 'सभी दिन',
    'Retry': 'फिर प्रयास करें',
    'Phone dialer is not available': 'फ़ोन डायलर उपलब्ध नहीं है',
    'Camera or photo access is not available':
        'कैमरा या फ़ोटो एक्सेस उपलब्ध नहीं है',
    'Each image must be smaller than 8 MB':
        'हर तस्वीर 8 एमबी से छोटी होनी चाहिए',
    'Image must be smaller than 8 MB': 'तस्वीर 8 एमबी से छोटी होनी चाहिए',
    'Select a category and complete all required fields':
        'एक श्रेणी चुनें और सभी आवश्यक फ़ील्ड भरें',
    'Post published': 'पोस्ट प्रकाशित हो गई',
    'Categories could not be loaded': 'श्रेणियाँ लोड नहीं हो सकीं',
    'Example: 0101': 'उदाहरण: 0101',
    'Tap a bookmark icon to save a post here.':
        'पोस्ट यहाँ सहेजने के लिए बुकमार्क आइकन दबाएँ।',
    'Remove from saved': 'सहेजे गए से हटाएँ',
    'Your published advertisements will appear here.':
        'आपके प्रकाशित विज्ञापन यहाँ दिखाई देंगे।',
    'Your published advertisements appear here.':
        'आपके प्रकाशित विज्ञापन यहाँ दिखाई देते हैं।',
    'Profile picture updated': 'प्रोफ़ाइल चित्र अपडेट हो गया',
    'Add profile picture': 'प्रोफ़ाइल चित्र जोड़ें',
    'Name cannot be changed': 'नाम बदला नहीं जा सकता',
    'These details will appear below your posts.':
        'ये विवरण आपकी पोस्ट के नीचे दिखाई देंगे।',
    'Google sign-in was not completed': 'Google साइन-इन पूरा नहीं हुआ',
    'We sent a 6-digit code to': 'हमने 6 अंकों का कोड भेजा है',
    'Call': 'कॉल करें',
    'Find everything to buy and sell in one place.':
        'खरीदने और बेचने की हर चीज़ एक जगह पाएँ।',
    'Signed in': 'लॉग इन है',
    'Post number': 'पोस्ट नंबर',
    'Salary': 'वेतन',
    'Negotiable': 'बातचीत योग्य',
    'Required to create a post': 'पोस्ट बनाने के लिए आवश्यक',
    'Store number must contain 1 to 4 digits':
        'स्टोर नंबर में 1 से 4 अंक होने चाहिए',
    'Posts show for 30 days. Older posts are automatically deleted.':
        'पोस्ट 30 दिनों तक दिखाई देती हैं। पुरानी पोस्ट अपने आप हट जाती हैं।',
    'All dates in this 30-day window are shown. Dates without posts remain empty.': 'इस 30-दिन की अवधि की सभी तारीखें दिखाई जाती हैं। बिना पोस्ट वाली तारीखें खाली रहती हैं।',
    'posts': 'पोस्ट',
    'January': 'जनवरी',
    'February': 'फ़रवरी',
    'March': 'मार्च',
    'April': 'अप्रैल',
    'May': 'मई',
    'June': 'जून',
    'July': 'जुलाई',
    'August': 'अगस्त',
    'September': 'सितंबर',
    'October': 'अक्टूबर',
    'November': 'नवंबर',
    'December': 'दिसंबर',
    'Change profile picture': 'प्रोफ़ाइल चित्र बदलें',
    'Saudi numbers only (+966); cannot be changed':
        'केवल सऊदी नंबर (+966); बदला नहीं जा सकता',
    'Store number can be changed now': 'स्टोर नंबर अब बदला जा सकता है',
    'Can be changed again in': 'फिर बदला जा सकता है',
    'days': 'दिन बाद',
    'Profile saved. Store number is locked for 30 days.':
        'प्रोफ़ाइल सहेजी गई। स्टोर नंबर 30 दिनों के लिए लॉक है।',
    'Profile is up to date': 'प्रोफ़ाइल अपडेट है',
    'Photo': 'फ़ोटो',
    'Need Job': 'काम चाहिए',
    'Need Worker': 'कर्मचारी चाहिए',
    'Buy Scrap': 'स्क्रैप खरीदें',
    'Sell Scrap': 'स्क्रैप बेचें',
    'Driver': 'ड्राइवर',
    'Serviceman': 'सर्विसमैन',
    'House Items': 'घरेलू सामान',
  },
};

String tr(String english) =>
    extendedTranslations[appLanguage.value]?[english] ??
    translations[appLanguage.value]?[english] ??
    english;

Future<void> setLanguage(String code) async {
  appLanguage.value = code;
  await (await SharedPreferences.getInstance()).setString('app_language', code);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final saved = (await SharedPreferences.getInstance()).getString(
    'app_language',
  );
  if (languageNames.containsKey(saved)) appLanguage.value = saved!;
  runApp(const ScrapMarketApp());
}

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: tr('Language'),
    initialValue: appLanguage.value,
    onSelected: setLanguage,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.translate, size: 21),
          const SizedBox(width: 6),
          Text(languageNames[appLanguage.value]!),
        ],
      ),
    ),
    itemBuilder: (_) => languageNames.entries
        .map(
          (entry) => PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                if (entry.key == appLanguage.value)
                  const Icon(Icons.check, size: 18),
                if (entry.key == appLanguage.value) const SizedBox(width: 8),
                Text(entry.value),
              ],
            ),
          ),
        )
        .toList(),
  );
}

class RotatingLoader extends StatefulWidget {
  const RotatingLoader({super.key, this.size = 24});

  final double size;

  @override
  State<RotatingLoader> createState() => _RotatingLoaderState();
}

class _RotatingLoaderState extends State<RotatingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox.square(
      dimension: widget.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: RotationTransition(
          turns: CurvedAnimation(parent: controller, curve: Curves.linear),
          child: Icon(
            Icons.recycling_rounded,
            color: color,
            size: widget.size * 0.7,
          ),
        ),
      ),
    );
  }
}

Future<ImageSource?> chooseImageSource(BuildContext context) =>
    showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('Add a photo'),
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(sheetContext, ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Text(tr('Take photo with camera')),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(sheetContext, ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Text(tr('Upload from gallery')),
                ),
              ),
            ],
          ),
        ),
      ),
    );

class ScrapMarketApp extends StatelessWidget {
  const ScrapMarketApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: appLanguage,
    builder: (context, language, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Torik Dammam',
      locale: Locale(language),
      supportedLocales: const [
        Locale('en'),
        Locale('bn'),
        Locale('ur'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff176b52),
          primary: const Color(0xff176b52),
          secondary: const Color(0xfff1a43c),
        ),
        scaffoldBackgroundColor: const Color(0xfff4f7f3),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const MarketplaceShell(),
    ),
  );
}

class PasswordAccessPage extends StatefulWidget {
  const PasswordAccessPage({super.key, this.registrationMode = false});

  final bool registrationMode;

  @override
  State<PasswordAccessPage> createState() => _PasswordAccessPageState();
}

class _PasswordAccessPageState extends State<PasswordAccessPage> {
  final name = TextEditingController();
  final phone = TextEditingController(text: '+9665');
  final email = TextEditingController();
  final password = TextEditingController();
  final storeNumber = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;
  bool googleReady = false;
  StreamSubscription<String>? googleSubscription;

  bool get registering => widget.registrationMode;

  @override
  void initState() {
    super.initState();
    if (!registering) _initializeGoogle();
  }

  Future<void> _initializeGoogle() async {
    try {
      final ready = await GoogleAuthService.instance.initialize();
      googleSubscription = GoogleAuthService.instance.idTokens.listen(
        _loginWithGoogle,
        onError: (_) => _showGoogleError(),
      );
      if (mounted) setState(() => googleReady = ready);
    } catch (_) {
      if (mounted) setState(() => googleReady = false);
    }
  }

  Future<void> _loginWithGoogle(String idToken) async {
    if (loading) return;
    setState(() => loading = true);
    try {
      await ApiService.instance.loginWithGoogle(idToken);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr(error.message))));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showGoogleError() {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Google sign-in was not completed'))),
      );
  }

  @override
  void dispose() {
    googleSubscription?.cancel();
    name.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    storeNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: Color(0xffe1f0e9),
                      child: Icon(Icons.recycling, size: 38),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      registering ? tr('Create account') : tr('Login'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      registering
                          ? tr('Create your marketplace account.')
                          : tr('Log in with your Saudi phone number.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 26),
                    if (registering) ...[
                      Text(
                        tr('All fields marked * are required'),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (registering) ...[
                      TextField(
                        controller: name,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: '${tr('Name')} *',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: registering
                            ? '${tr('Saudi phone number')} *'
                            : tr('Saudi phone number'),
                        hintText: '+9665XXXXXXXX',
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                    ),
                    if (registering) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: '${tr('Email address')} *',
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: obscurePassword,
                      onSubmitted: registering ? null : (_) => _enterApp(),
                      decoration: InputDecoration(
                        labelText: registering
                            ? '${tr('Password')} *'
                            : tr('Password'),
                        hintText: tr('Enter any password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (registering) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: storeNumber,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: '${tr('Store number')} *',
                          hintText: '0101',
                          counterText: '',
                          prefixIcon: const Icon(Icons.store_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: loading ? null : _enterApp,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: loading
                            ? const RotatingLoader(size: 22)
                            : Text(
                                registering
                                    ? tr('Create account')
                                    : tr('Login'),
                              ),
                      ),
                    ),
                    if (!registering)
                      TextButton(
                        onPressed: loading ? null : _forgotPassword,
                        child: Text(tr('Forgot password?')),
                      ),
                    if (!registering && googleReady) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(tr('or')),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),
                      buildGoogleSignInButton(),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: loading
                          ? null
                          : registering
                          ? () => Navigator.of(context).pop(false)
                          : _openRegistration,
                      child: Text(
                        registering
                            ? tr('Already registered? Back to login')
                            : tr('New user? Register'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _enterApp() async {
    if (registering &&
        (name.text.trim().isEmpty ||
            phone.text.trim().isEmpty ||
            email.text.trim().isEmpty ||
            password.text.isEmpty ||
            storeNumber.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('All registration fields are required'))),
      );
      return;
    }
    if (!RegExp(r'^\+9665\d{8}$').hasMatch(phone.text.trim()) ||
        password.text.length < (registering ? 8 : 1) ||
        (registering &&
            (name.text.trim().length < 2 ||
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(email.text.trim()) ||
                !RegExp(r'^\d{1,4}$').hasMatch(storeNumber.text.trim())))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Check your name, email, +9665XXXXXXXX phone, password (8+ characters), and store number (up to 4 digits)',
          ),
        ),
      );
      return;
    }
    String? verificationMethod;
    if (registering) {
      verificationMethod = await _chooseVerificationMethod();
      if (verificationMethod == null || !mounted) return;
    }
    setState(() => loading = true);
    try {
      if (registering) {
        final pending = await ApiService.instance.startRegistration(
          name: name.text.trim(),
          phone: phone.text.trim(),
          email: email.text.trim().toLowerCase(),
          password: password.text,
          storeNumber: storeNumber.text.trim(),
          verificationMethod: verificationMethod!,
        );
        if (!mounted) return;
        final code = await _askForVerificationCode(
          pending['destination'] as String? ?? '',
        );
        if (code == null) return;
        await ApiService.instance.verifyRegistration(
          verificationId: pending['verificationId'] as String,
          code: code,
        );
      } else {
        await ApiService.instance.login(
          phone: phone.text.trim(),
          password: password.text,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Cannot connect to the server'))),
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<String?> _chooseVerificationMethod() => showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(tr('Verify your account')),
      content: Text(tr('Where should we send your 6-digit verification code?')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(tr('Cancel')),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(dialogContext, 'phone'),
          icon: const Icon(Icons.sms_outlined),
          label: Text(tr('Phone')),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, 'email'),
          icon: const Icon(Icons.email_outlined),
          label: Text(tr('Email')),
        ),
      ],
    ),
  );

  Future<void> _forgotPassword() async {
    final identifier = TextEditingController(text: phone.text);
    final newPassword = TextEditingController();
    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Reset password')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: identifier,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: tr('Verified phone or email'),
                hintText: '+9665XXXXXXXX / name@example.com',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr('New password'),
                hintText: tr('Password must be at least 8 characters'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              final account = identifier.text.trim();
              if (account.length >= 3 && newPassword.text.length >= 8) {
                Navigator.pop(dialogContext, [account, newPassword.text]);
              }
            },
            child: Text(tr('Send code')),
          ),
        ],
      ),
    );
    identifier.dispose();
    if (values == null || !mounted) {
      newPassword.dispose();
      return;
    }
    setState(() => loading = true);
    try {
      final pending = await ApiService.instance.startPasswordReset(values[0]);
      if (!mounted) return;
      final code = await _askForVerificationCode(
        pending['destination'] as String? ?? '',
      );
      if (code == null) return;
      await ApiService.instance.verifyPasswordReset(
        verificationId: pending['verificationId'] as String,
        code: code,
        newPassword: values[1],
      );
      if (mounted) {
        password.text = '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Password changed. You can now log in.'))),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr(error.message))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Cannot connect to the server'))),
        );
      }
    } finally {
      newPassword.dispose();
      if (mounted) setState(() => loading = false);
    }
  }

  Future<String?> _askForVerificationCode(String destination) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Enter verification code')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${tr('We sent a 6-digit code to')} $destination.'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: tr('Verification code'),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (RegExp(r'^\d{6}$').hasMatch(controller.text)) {
                Navigator.pop(dialogContext, controller.text);
              }
            },
            child: Text(tr('Verify')),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _openRegistration() async {
    final registered = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const RegistrationPage()));
    if (registered == true && mounted) Navigator.of(context).pop(true);
  }
}

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const PasswordAccessPage(registrationMode: true);
}

class Listing {
  const Listing(
    this.title,
    this.type,
    this.price,
    this.storeNumber,
    this.description,
    this.userName,
    this.phoneNumber,
    this.postedAt,
    this.postedYear,
    this.postedMonth,
    this.postedDay,
    this.icon,
    this.color, [
    this.imageUrls = const [],
    this.postNumber = '',
    this.profileImageUrl,
    this.postId = '',
    this.isSaved = false,
  ]);

  final String title;
  final String type;
  final String price;
  final String storeNumber;
  final String description;
  final String userName;
  final String phoneNumber;
  final String postedAt;
  final int postedYear;
  final int postedMonth;
  final int postedDay;
  final IconData icon;
  final Color color;
  final List<String> imageUrls;
  final String postNumber;
  final String? profileImageUrl;
  final String postId;
  final bool isSaved;
}

const listings = [
  Listing(
    'Construction helpers needed',
    'Need Worker',
    '\$85 / day',
    '0101',
    'Need four reliable helpers for loading materials. Work starts at 8 AM.',
    'Ahmed Khan',
    '+966 50 123 4567',
    'Today, 9:30 AM',
    2026,
    9,
    1,
    Icons.engineering,
    Color(0xffe8d8c5),
  ),
  Listing(
    'Copper wire scrap',
    'Sell Scrap',
    '\$4.20 / kg',
    '0204',
    'Clean copper wire available in one large lot. Inspection is welcome.',
    'Maria Lopez',
    '+966 53 246 8105',
    'Today, 8:15 AM',
    2026,
    9,
    1,
    Icons.cable,
    Color(0xffd8e8e4),
  ),
  Listing(
    'Buying used batteries',
    'Buy Scrap',
    'Best price',
    '0318',
    'Buying used vehicle and inverter batteries in any reasonable quantity.',
    'Rahim Traders',
    '+966 54 381 7296',
    'Yesterday, 6:40 PM',
    2026,
    8,
    31,
    Icons.battery_5_bar,
    Color(0xffe5e1d5),
  ),
  Listing(
    'Experienced warehouse loader',
    'Need Job',
    '\$100 / day',
    '0407',
    'Available for warehouse loading work. Experienced and ready to start.',
    'Sam Wilson',
    '+966 55 492 6183',
    'Yesterday, 2:10 PM',
    2026,
    8,
    31,
    Icons.inventory_2,
    Color(0xffdde4ec),
  ),
  Listing(
    'Mixed aluminium sheets',
    'Sell Scrap',
    '\$2.80 / kg',
    '0512',
    'Mixed aluminium roofing sheets, dry and ready for collection today.',
    'Noor Recycling',
    '+966 56 735 2048',
    'Aug 30, 11:25 AM',
    2026,
    8,
    30,
    Icons.layers,
    Color(0xffe4ddd7),
  ),
  Listing(
    'Experienced delivery driver available',
    'Driver',
    'Negotiable',
    '0614',
    'Saudi-licensed driver available for delivery or company driving work.',
    'Fahad Ali',
    '+966 58 614 3072',
    'Aug 30, 9:10 AM',
    2026,
    8,
    30,
    Icons.local_shipping_outlined,
    Color(0xffdce7ef),
  ),
];

Listing listingFromApiRow(Map<String, dynamic> row) {
  final created = DateTime.parse(row['created_at'] as String).toLocal();
  final urls = (row['image_urls'] as List? ?? const [])
      .map((value) => value.toString())
      .toList();
  final category = row['category'] as String;
  final icon = switch (category) {
    'Need Job' => Icons.work_outline,
    'Need Worker' => Icons.engineering,
    'Buy Scrap' => Icons.shopping_cart_outlined,
    'Driver' => Icons.local_shipping_outlined,
    'Serviceman' => Icons.home_repair_service_outlined,
    'House Items' => Icons.chair_outlined,
    _ => Icons.recycling,
  };
  final priceValue = row['price'];
  final unitValue = row['unit'] as String?;
  final employmentPost = category == 'Need Worker' || category == 'Need Job';
  return Listing(
    row['title'] as String,
    category,
    priceValue == null
        ? (employmentPost
              ? '${tr('Salary')}: ${tr('Negotiable')}'
              : tr('Negotiable'))
        : employmentPost
        ? '${tr('Salary')}: $priceValue'
        : '$priceValue${unitValue == null || unitValue.isEmpty ? '' : ' / $unitValue'}',
    row['store_number'] as String,
    row['description'] as String,
    row['user_name'] as String? ?? 'User',
    row['phone'] as String? ?? '',
    '${created.day}/${created.month}/${created.year}',
    created.year,
    created.month,
    created.day,
    icon,
    const Color(0xffd8e8e4),
    urls,
    row['post_number'] as String? ?? '#${row['id']}',
    row['user_profile_image_url'] as String?,
    row['id'].toString(),
    row['is_saved'] as bool? ?? false,
  );
}

class MarketplaceShell extends StatefulWidget {
  const MarketplaceShell({super.key});

  @override
  State<MarketplaceShell> createState() => _MarketplaceShellState();
}

class _MarketplaceShellState extends State<MarketplaceShell> {
  int index = 0;
  int postsVersion = 0;
  bool signedIn = false;

  @override
  void initState() {
    super.initState();
    ApiService.instance.restoreSession().then((restored) {
      if (mounted) setState(() => signedIn = restored);
    });
  }

  Future<bool> _openLogin() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const PasswordAccessPage()));
    if (result == true && mounted) setState(() => signedIn = true);
    return result == true;
  }

  Future<void> _openPost() async {
    if (!signedIn && !await _openLogin()) return;
    if (!mounted) return;
    final published = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const CreatePostPage()));
    if (published == true && mounted) {
      setState(() {
        postsVersion++;
        index = 2;
      });
    }
  }

  Future<void> _selectDestination(int value) async {
    const protectedIndexes = {1, 2, 3};
    if (protectedIndexes.contains(value) && !signedIn) {
      final loggedIn = await _openLogin();
      if (!loggedIn || !mounted) return;
    }
    if (mounted) setState(() => index = value);
  }

  Future<void> _signOut() async {
    await ApiService.instance.signOut();
    await GoogleAuthService.instance.signOut();
    if (mounted)
      setState(() {
        signedIn = false;
        index = 0;
      });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        key: ValueKey('home-$postsVersion'),
        signedIn: signedIn,
        onLogin: _openLogin,
      ),
      SavedPage(key: ValueKey('saved-$postsVersion'), onLogin: _openLogin),
      MyPostsPage(key: ValueKey('my-posts-$postsVersion')),
      ProfilePage(onSignOut: _signOut),
    ];
    return Scaffold(
      body: pages[index],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPost,
        icon: const Icon(Icons.add),
        label: Text(tr('Post')),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _selectDestination,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: tr('Home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_outline),
            label: tr('Saved'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.article_outlined),
            label: tr('My posts'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: tr('Profile'),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.signedIn, required this.onLogin});

  final bool signedIn;
  final Future<bool> Function() onLogin;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const bannerImages = [
    'assets/banners/scrap-yard.png',
    'assets/banners/scrap-parts.png',
    'assets/banners/scrap-sunset.png',
    'assets/banners/scrap-batteries.png',
    'assets/banners/scrap-auto-parts.png',
    'assets/banners/scrap-appliances.png',
    'assets/banners/scrap-plastics.png',
    'assets/banners/scrap-cardboard.png',
    'assets/banners/scrap-construction.png',
    'assets/banners/scrap-electronics.png',
  ];

  String filter = 'All';
  String query = '';
  int selectedMonth = DateTime.now().month;
  int? selectedDay;
  int bannerIndex = 0;
  final bannerController = PageController();
  Timer? bannerTimer;
  List<Listing> remoteListings = [];
  List<String> categories = [];
  bool loadingPosts = true;
  String? postsError;

  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadCategories();
    bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !bannerController.hasClients) return;
      final next = (bannerIndex + 1) % bannerImages.length;
      bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.signedIn && widget.signedIn) _loadPosts();
  }

  Future<void> _loadCategories() async {
    try {
      final values = await ApiService.instance.fetchCategories();
      if (mounted) setState(() => categories = values);
    } catch (_) {
      // The post feed can still render while Render/Neon is waking up.
    }
  }

  Future<void> _loadPosts() async {
    try {
      final rows = await ApiService.instance.fetchPosts();
      var savedIds = <String>{};
      if (ApiService.instance.token != null) {
        try {
          final savedRows = await ApiService.instance.fetchSavedPosts();
          savedIds = savedRows.map((row) => row['id'].toString()).toSet();
        } catch (_) {
          // The public feed remains available if saved posts cannot be loaded.
        }
      }
      final mapped = rows
          .map(
            (row) => listingFromApiRow({
              ...row,
              'is_saved': savedIds.contains(row['id'].toString()),
            }),
          )
          .toList();
      if (mounted)
        setState(() {
          remoteListings = mapped;
          loadingPosts = false;
          postsError = null;
          if (mapped.isNotEmpty) selectedMonth = mapped.first.postedMonth;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          loadingPosts = false;
          postsError = 'Could not load posts';
        });
    }
  }

  @override
  void dispose() {
    bannerTimer?.cancel();
    bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postDates = remoteListings
        .map(
          (item) => DateTime(item.postedYear, item.postedMonth, item.postedDay),
        )
        .toList();
    final newestPostDate = postDates.isEmpty
        ? DateTime.now()
        : postDates.reduce(
            (current, date) => date.isAfter(current) ? date : current,
          );
    final rangeStart = newestPostDate.subtract(const Duration(days: 29));
    final windowDates = List.generate(
      30,
      (index) => rangeStart.add(Duration(days: index)),
    );
    final activeListings = remoteListings.where((item) {
      final createdAt = DateTime(
        item.postedYear,
        item.postedMonth,
        item.postedDay,
      );
      return !createdAt.isBefore(rangeStart) &&
          !createdAt.isAfter(newestPostDate);
    }).toList();
    final availableMonths =
        windowDates.map((date) => date.month).toSet().toList()..sort();
    final monthToShow = availableMonths.contains(selectedMonth)
        ? selectedMonth
        : (availableMonths.isEmpty ? selectedMonth : availableMonths.last);
    final availableDays =
        windowDates
            .where((date) => date.month == monthToShow)
            .map((date) => date.day)
            .toList()
          ..sort();
    final visible = activeListings.where((item) {
      return (filter == 'All' || item.type == filter) &&
          item.postedMonth == monthToShow &&
          (selectedDay == null || item.postedDay == selectedDay) &&
          item.title.toLowerCase().contains(query.toLowerCase());
    }).toList();
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.recycling)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Torik-Dammam Scrap Market',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  tr(
                                    'Find everything to buy and sell in one place.',
                                  ),
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          const LanguageSelector(),
                          TextButton.icon(
                            onPressed: widget.signedIn ? null : widget.onLogin,
                            icon: Icon(
                              widget.signedIn
                                  ? Icons.check_circle_outline
                                  : Icons.login,
                            ),
                            label: Text(
                              widget.signedIn
                                  ? tr('Signed in')
                                  : MediaQuery.sizeOf(context).width < 600
                                  ? tr('Login')
                                  : tr('Login / Sign up'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          height: 220,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              PageView.builder(
                                controller: bannerController,
                                itemCount: bannerImages.length,
                                onPageChanged: (value) =>
                                    setState(() => bannerIndex = value),
                                itemBuilder: (context, index) => Image.asset(
                                  bannerImages[index],
                                  fit: BoxFit.cover,
                                  semanticLabel:
                                      'Scrap market banner ${index + 1}',
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 12,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    bannerImages.length,
                                    (index) => AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      width: bannerIndex == index ? 22 : 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bannerIndex == index
                                            ? Colors.white
                                            : Colors.white70,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        onChanged: (value) => setState(() => query = value),
                        decoration: InputDecoration(
                          hintText: tr('Search work, metal, batteries…'),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: Icon(Icons.tune),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: ['All', ...categories]
                              .map(
                                (label) => ChoiceChip(
                                  label: Text(tr(label)),
                                  selected: filter == label,
                                  onSelected: (_) =>
                                      setState(() => filter = label),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xfffff3db),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xff9a6414),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tr(
                                  'Posts show for 30 days. Older posts are automatically deleted.',
                                ),
                                style: const TextStyle(
                                  color: Color(0xff68430c),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: availableMonths.isEmpty
                            ? null
                            : monthToShow,
                        decoration: InputDecoration(
                          labelText: tr('Choose month'),
                          prefixIcon: const Icon(Icons.calendar_month_outlined),
                        ),
                        items: availableMonths
                            .map(
                              (month) => DropdownMenuItem(
                                value: month,
                                child: Text(tr(monthNames[month - 1])),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            selectedMonth = value;
                            selectedDay = null;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr(
                          'All dates in this 30-day window are shown. Dates without posts remain empty.',
                        ),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(tr('All days')),
                            selected: selectedDay == null,
                            onSelected: (_) =>
                                setState(() => selectedDay = null),
                          ),
                          ...availableDays.map((day) {
                            return ChoiceChip(
                              label: Text('$day'),
                              selected: selectedDay == day,
                              onSelected: (_) =>
                                  setState(() => selectedDay = day),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (loadingPosts)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: RotatingLoader(size: 34),
                          ),
                        ),
                      if (postsError != null)
                        Row(
                          children: [
                            Expanded(child: Text(postsError!)),
                            TextButton(
                              onPressed: _loadPosts,
                              child: Text(tr('Retry')),
                            ),
                          ],
                        ),
                      Text(
                        '${tr(monthNames[monthToShow - 1])} ${tr('posts')}',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
            sliver: SliverLayoutBuilder(
              builder: (context, _) => SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisExtent: 410,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) =>
                      ListingCard(listing: visible[i], onLogin: widget.onLogin),
                  childCount: visible.length,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ListingCard extends StatefulWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.onLogin,
    this.onSavedChanged,
  });
  final Listing listing;
  final Future<bool> Function()? onLogin;
  final ValueChanged<bool>? onSavedChanged;

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard> {
  int imageIndex = 0;
  late bool saved = widget.listing.isSaved;
  bool saving = false;
  Listing get listing => widget.listing;

  @override
  void didUpdateWidget(covariant ListingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listing.imageUrls != widget.listing.imageUrls) imageIndex = 0;
    if (oldWidget.listing.postId != widget.listing.postId) {
      saved = widget.listing.isSaved;
    }
  }

  Future<bool> _toggleSaved(bool value) async {
    if (listing.postId.isEmpty || saving) return false;
    if (ApiService.instance.token == null) {
      final loggedIn = await widget.onLogin?.call() ?? false;
      if (!loggedIn || !mounted) return false;
    }
    setState(() => saving = true);
    try {
      await ApiService.instance.setPostSaved(listing.postId, value);
      if (mounted) setState(() => saved = value);
      widget.onSavedChanged?.call(value);
      return true;
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
      return false;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _callPhone() async {
    final number = listing.phoneNumber.replaceAll(RegExp(r'[^+\d]'), '');
    if (number.isEmpty || !await launchUrl(Uri(scheme: 'tel', path: number))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Phone dialer is not available'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailPage(
          listing: listing,
          initialSaved: saved,
          onToggleSaved: _toggleSaved,
        ),
      ),
    ),
    child: Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (listing.imageUrls.isEmpty)
                  ColoredBox(
                    color: listing.color,
                    child: Icon(listing.icon, size: 52, color: Colors.black54),
                  )
                else
                  PageView.builder(
                    itemCount: listing.imageUrls.length,
                    onPageChanged: (value) =>
                        setState(() => imageIndex = value),
                    itemBuilder: (context, index) => Image.network(
                      listing.imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: listing.color,
                        child: Icon(listing.icon, size: 52),
                      ),
                    ),
                  ),
                if (listing.imageUrls.length > 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 9,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        listing.imageUrls.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: index == imageIndex ? 18 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: index == imageIndex
                                ? Colors.white
                                : Colors.white70,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (listing.imageUrls.length > 1)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        child: Text(
                          '${imageIndex + 1}/${listing.imageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (listing.postNumber.isNotEmpty)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 5),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          listing.postNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 40,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Row(
                            key: const Key('post-time-left'),
                            children: [
                              const Icon(
                                Icons.schedule_outlined,
                                size: 15,
                                color: Colors.black45,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                listing.postedAt,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                tooltip: saved
                                    ? 'Remove from saved'
                                    : 'Save post',
                                visualDensity: VisualDensity.compact,
                                onPressed: saving
                                    ? null
                                    : () => _toggleSaved(!saved),
                                icon: saving
                                    ? const RotatingLoader(size: 19)
                                    : Icon(
                                        saved
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        size: 21,
                                      ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Chip(
                            key: const Key('post-category-right'),
                            label: Text(tr(listing.type)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    listing.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.price,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    '${tr('Store number')}: ${listing.storeNumber}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  if (listing.postNumber.isNotEmpty)
                    Text(
                      '${tr('Post number')}: ${listing.postNumber}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const Divider(height: 18),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: listing.profileImageUrl == null
                            ? null
                            : NetworkImage(listing.profileImageUrl!),
                        child: listing.profileImageUrl == null
                            ? const Icon(Icons.person_outline, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              listing.phoneNumber,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '${tr('Call')} ${listing.userName}',
                        onPressed: _callPhone,
                        icon: const Icon(Icons.call_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({
    super.key,
    required this.listing,
    required this.initialSaved,
    required this.onToggleSaved,
  });

  final Listing listing;
  final bool initialSaved;
  final Future<bool> Function(bool) onToggleSaved;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  int imageIndex = 0;
  late bool saved = widget.initialSaved;
  bool saving = false;

  Listing get listing => widget.listing;

  Future<void> _toggleSaved() async {
    if (saving) return;
    setState(() => saving = true);
    final changed = await widget.onToggleSaved(!saved);
    if (changed && mounted) setState(() => saved = !saved);
    if (mounted) setState(() => saving = false);
  }

  Future<void> _callPhone() async {
    final number = listing.phoneNumber.replaceAll(RegExp(r'[^+\d]'), '');
    if (number.isEmpty || !await launchUrl(Uri(scheme: 'tel', path: number))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Phone dialer is not available'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr('Post details'))),
    body: ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        SizedBox(
          height: 320,
          child: listing.imageUrls.isEmpty
              ? ColoredBox(
                  color: listing.color,
                  child: Icon(listing.icon, size: 90, color: Colors.black54),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      itemCount: listing.imageUrls.length,
                      onPageChanged: (value) =>
                          setState(() => imageIndex = value),
                      itemBuilder: (context, index) => InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Image.network(
                          listing.imageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: listing.color,
                            child: Icon(listing.icon, size: 90),
                          ),
                        ),
                      ),
                    ),
                    if (listing.imageUrls.length > 1)
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: Chip(
                          avatar: const Icon(
                            Icons.photo_library_outlined,
                            size: 17,
                          ),
                          label: Text(
                            '${imageIndex + 1}/${listing.imageUrls.length}',
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(label: Text(tr(listing.type))),
                  const Spacer(),
                  const Icon(Icons.schedule_outlined, size: 17),
                  const SizedBox(width: 5),
                  Text(
                    listing.postedAt,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  IconButton(
                    tooltip: saved ? 'Remove from saved' : 'Save post',
                    onPressed: saving ? null : _toggleSaved,
                    icon: saving
                        ? const RotatingLoader(size: 20)
                        : Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                listing.title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                listing.price,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${tr('Store number')}: ${listing.storeNumber}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (listing.postNumber.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${tr('Post number')}: ${listing.postNumber}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const Divider(height: 32),
              Text(
                tr('Description'),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(listing.description, style: const TextStyle(height: 1.5)),
              const Divider(height: 32),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: listing.profileImageUrl == null
                      ? null
                      : NetworkImage(listing.profileImageUrl!),
                  child: listing.profileImageUrl == null
                      ? const Icon(Icons.person_outline)
                      : null,
                ),
                title: Text(
                  listing.userName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(listing.phoneNumber),
                trailing: IconButton(
                  tooltip: '${tr('Call')} ${listing.userName}',
                  onPressed: _callPhone,
                  icon: const Icon(Icons.call_outlined),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final title = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final unit = TextEditingController();
  final storeNumber = TextEditingController();
  final images = <UploadImage>[];
  UploadImage? paymentProof;
  final imagePicker = ImagePicker();
  List<String> categories = [];
  bool loadingCategories = true;
  String? type;
  bool publishing = false;
  bool loadingQuota = true;
  int freeRemaining = 5;
  int bdtAmount = 165;
  String paymentCurrency = 'SAR';
  String instructionsSar = '';
  String instructionsBdt = '';

  bool get usesSalary => type == 'Need Worker' || type == 'Need Job';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    try {
      final quota = await ApiService.instance.fetchPostQuota();
      if (mounted) setState(() {
        freeRemaining = quota['freeRemaining'] as int? ?? 0;
        bdtAmount = (quota['bdtAmount'] as num?)?.round() ?? 165;
        instructionsSar = quota['instructionsSar'] as String? ?? '';
        instructionsBdt = quota['instructionsBdt'] as String? ?? '';
        loadingQuota = false;
      });
    } catch (_) {
      if (mounted) setState(() => loadingQuota = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final values = await ApiService.instance.fetchCategories();
      if (mounted)
        setState(() {
          categories = values;
          loadingCategories = false;
        });
    } catch (_) {
      if (mounted) setState(() => loadingCategories = false);
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    price.dispose();
    unit.dispose();
    storeNumber.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (images.length >= 3) return;
    final source = await chooseImageSource(context);
    if (source == null || !mounted) return;
    XFile? image;
    try {
      image = await imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1800,
      );
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Camera or photo access is not available')),
          ),
        );
      }
      return;
    }
    if (image == null) return;
    final selectedImage = image;
    final bytes = await selectedImage.readAsBytes();
    if (bytes.length > 8 * 1024 * 1024) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Each image must be smaller than 8 MB'))),
        );
      return;
    }
    setState(() => images.add(UploadImage(selectedImage.name, bytes)));
  }

  Future<void> _pickPaymentProof() async {
    final source = await chooseImageSource(context);
    if (source == null || !mounted) return;
    try {
      final image = await imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1800,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        throw const ApiException('Image must be smaller than 8 MB');
      }
      if (mounted) setState(() => paymentProof = UploadImage(image.name, bytes));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error is ApiException
            ? tr(error.message)
            : tr('Camera or photo access is not available'))),
      );
    }
  }

  Future<void> _publish() async {
    if (type == null ||
        title.text.trim().length < 3 ||
        description.text.trim().length < 10 ||
        !RegExp(r'^\d{1,4}$').hasMatch(storeNumber.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('Select a category and complete all required fields'),
          ),
        ),
      );
      return;
    }
    if (freeRemaining == 0 && paymentProof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Upload payment proof to submit this post'))),
      );
      return;
    }
    setState(() => publishing = true);
    try {
      final pendingApproval = await ApiService.instance.createPost(
        category: type!,
        title: title.text.trim(),
        description: description.text.trim(),
        price: price.text.trim(),
        unit: usesSalary ? '' : unit.text.trim(),
        storeNumber: storeNumber.text.trim(),
        images: images,
        paymentProof: freeRemaining == 0 ? paymentProof : null,
        paymentCurrency: freeRemaining == 0 ? paymentCurrency : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr(pendingApproval
              ? 'Payment submitted. Your post is waiting for admin approval.'
              : 'Post published'))));
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Cannot connect to the server'))),
        );
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr('Create a post'))),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${tr('Post category')} '),
                    const TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                tr('Required to create a post'),
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (loadingCategories)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: RotatingLoader(size: 32),
                  ),
                ),
              if (!loadingCategories && categories.isEmpty)
                Row(
                  children: [
                    Expanded(child: Text(tr('Categories could not be loaded'))),
                    TextButton(
                      onPressed: () {
                        setState(() => loadingCategories = true);
                        _loadCategories();
                      },
                      child: Text(tr('Retry')),
                    ),
                  ],
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories
                    .map(
                      (category) => ChoiceChip(
                        label: Text(tr(category)),
                        selected: type == category,
                        onSelected: (selected) => setState(() {
                          type = selected ? category : null;
                          if (usesSalary) unit.clear();
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),
              Text(
                tr('Photos (maximum 3)'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index < 2 ? 10 : 0),
                      child: AspectRatio(
                        aspectRatio: 1.25,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          clipBehavior: Clip.antiAlias,
                          onPressed: publishing || index > images.length
                              ? null
                              : () {
                                  if (index < images.length) {
                                    setState(() => images.removeAt(index));
                                  } else {
                                    _pickImage();
                                  }
                                },
                          child: index < images.length
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(
                                      images[index].bytes,
                                      fit: BoxFit.cover,
                                    ),
                                    const Positioned(
                                      right: 6,
                                      top: 6,
                                      child: CircleAvatar(
                                        radius: 13,
                                        backgroundColor: Colors.black54,
                                        child: Icon(
                                          Icons.close,
                                          size: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo_outlined),
                                    const SizedBox(height: 5),
                                    Text('${tr('Photo')} ${index + 1}'),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: title,
                decoration: InputDecoration(labelText: tr('Title')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                maxLines: 4,
                decoration: InputDecoration(labelText: tr('Description')),
              ),
              const SizedBox(height: 12),
              if (usesSalary)
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: tr('Salary (optional)'),
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: price,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: tr('Price (optional)'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unit,
                        decoration: InputDecoration(
                          labelText: tr('Unit (optional)'),
                          hintText: 'kg / item',
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              TextField(
                controller: storeNumber,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: tr('Store number'),
                  hintText: tr('Example: 0101'),
                  prefixIcon: const Icon(Icons.store_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xfff5faf7),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: loadingQuota
                      ? const Center(child: RotatingLoader(size: 26))
                      : freeRemaining > 0
                          ? Text(
                              '${tr('Free posts remaining')}: $freeRemaining / 5',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  tr('Your 5 free posts are used. Pay and upload proof for admin approval.'),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 10),
                                SegmentedButton<String>(
                                  segments: [
                                    const ButtonSegment(value: 'SAR', label: Text('5 SAR')),
                                    ButtonSegment(value: 'BDT', label: Text('$bdtAmount BDT')),
                                  ],
                                  selected: {paymentCurrency},
                                  onSelectionChanged: publishing
                                      ? null
                                      : (value) => setState(() => paymentCurrency = value.first),
                                ),
                                const SizedBox(height: 10),
                                Text(paymentCurrency == 'SAR'
                                    ? (instructionsSar.isEmpty
                                        ? tr('Pay 5 SAR using the administrator payment account.')
                                        : instructionsSar)
                                    : (instructionsBdt.isEmpty
                                        ? '${tr('Pay using the administrator payment account')}: $bdtAmount BDT'
                                        : instructionsBdt)),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: publishing ? null : _pickPaymentProof,
                                  icon: const Icon(Icons.receipt_long_outlined),
                                  label: Text(paymentProof == null
                                      ? tr('Upload payment proof *')
                                      : tr('Payment proof selected — tap to replace')),
                                ),
                                if (paymentProof != null) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 130,
                                    child: Image.memory(paymentProof!.bytes, fit: BoxFit.contain),
                                  ),
                                ],
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: publishing ? null : _publish,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: publishing
                      ? const RotatingLoader(size: 22)
                      : Text(tr('Publish post')),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SavedPage extends StatefulWidget {
  const SavedPage({super.key, required this.onLogin});

  final Future<bool> Function() onLogin;

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  bool loading = true;
  String? error;
  List<Listing> posts = [];
  final removingPostIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await ApiService.instance.fetchSavedPosts();
      if (mounted) {
        setState(() {
          posts = rows.map(listingFromApiRow).toList();
          loading = false;
          error = null;
        });
      }
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          error = tr(exception.message);
          loading = false;
        });
      }
    }
  }

  Future<void> _removeSavedPost(Listing post) async {
    if (removingPostIds.contains(post.postId)) return;
    setState(() => removingPostIds.add(post.postId));
    try {
      await ApiService.instance.setPostSaved(post.postId, false);
      if (mounted) {
        setState(() {
          posts.removeWhere((item) => item.postId == post.postId);
          removingPostIds.remove(post.postId);
        });
      }
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() => removingPostIds.remove(post.postId));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr(exception.message))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('Saved posts'),
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          if (loading)
            const Expanded(child: Center(child: RotatingLoader(size: 38)))
          else if (error != null)
            Expanded(
              child: Center(
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() => loading = true);
                    _load();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(error!),
                ),
              ),
            )
          else if (posts.isEmpty)
            Expanded(
              child: EmptyPage(
                icon: Icons.bookmark_outline,
                title: tr('No saved posts'),
                message: tr('Tap a bookmark icon to save a post here.'),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return SizedBox(
                      height: 470,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ListingCard(
                              listing: post,
                              onLogin: widget.onLogin,
                              onSavedChanged: (saved) {
                                if (!saved && mounted) {
                                  setState(
                                    () => posts.removeWhere(
                                      (item) => item.postId == post.postId,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: removingPostIds.contains(post.postId)
                                ? null
                                : () => _removeSavedPost(post),
                            icon: removingPostIds.contains(post.postId)
                                ? const RotatingLoader(size: 20)
                                : const Icon(Icons.bookmark_remove_outlined),
                            label: Text(tr('Remove from saved')),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  bool loading = true;
  String? error;
  List<Listing> posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (mounted) setState(() => error = null);
    try {
      final rows = await ApiService.instance.fetchMyPosts();
      if (mounted) {
        setState(() {
          posts = rows.map(listingFromApiRow).toList();
          loading = false;
        });
      }
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          error = exception.message;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Cannot connect to the server';
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('My posts'),
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            tr('Your published advertisements appear here.'),
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          if (loading)
            const Expanded(child: Center(child: RotatingLoader(size: 38)))
          else if (error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() => loading = true);
                        _loadPosts();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(tr('Retry')),
                    ),
                  ],
                ),
              ),
            )
          else if (posts.isEmpty)
            Expanded(
              child: EmptyPage(
                icon: Icons.article_outlined,
                title: tr('No posts yet'),
                message: tr('Your published advertisements will appear here.'),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadPosts,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => SizedBox(
                    height: 410,
                    child: ListingCard(listing: posts[index]),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final storeNumber = TextEditingController();
  String savedStoreNumber = '';
  DateTime lastStoreNumberChange = DateTime.now().subtract(
    const Duration(days: 31),
  );
  bool loadingProfile = true;
  bool savingProfile = false;
  bool uploadingProfileImage = false;
  String? profileImageUrl;
  final profileImagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final cached = ApiService.instance.currentUser;
    if (cached != null) _applyUser(cached, notify: false);
    _loadProfile();
  }

  void _applyUser(Map<String, dynamic> user, {bool notify = true}) {
    name.text = user['name'] as String? ?? '';
    phone.text = user['phone'] as String? ?? '';
    savedStoreNumber = user['storeNumber'] as String? ?? '';
    profileImageUrl = user['profileImageUrl'] as String?;
    storeNumber.text = savedStoreNumber;
    final changedAt = user['storeNumberChangedAt'] as String?;
    lastStoreNumberChange = changedAt == null
        ? DateTime.now().subtract(const Duration(days: 31))
        : DateTime.parse(changedAt).toLocal();
    loadingProfile = false;
    if (notify && mounted) setState(() {});
  }

  Future<void> _loadProfile() async {
    if (ApiService.instance.token == null) {
      if (mounted) setState(() => loadingProfile = false);
      return;
    }
    try {
      _applyUser(await ApiService.instance.fetchProfile());
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => loadingProfile = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!RegExp(r'^\d{1,4}$').hasMatch(storeNumber.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Store number must contain 1 to 4 digits'))),
      );
      return;
    }
    final changed = storeNumber.text.trim() != savedStoreNumber;
    if (changed && !canChangeStoreNumber) {
      storeNumber.text = savedStoreNumber;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${tr('Can be changed again in')} $daysUntilStoreChange ${tr('days')}',
          ),
        ),
      );
      return;
    }
    setState(() => savingProfile = true);
    try {
      final user = await ApiService.instance.updateStoreNumber(
        storeNumber.text.trim(),
      );
      _applyUser(user);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              changed
                  ? tr('Profile saved. Store number is locked for 30 days.')
                  : tr('Profile is up to date'),
            ),
          ),
        );
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr(error.message))));
    } finally {
      if (mounted) setState(() => savingProfile = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final source = await chooseImageSource(context);
    if (source == null || !mounted) return;
    XFile? image;
    try {
      image = await profileImagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1800,
      );
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Camera or photo access is not available')),
          ),
        );
      }
      return;
    }
    if (image == null) return;
    final selectedImage = image;
    final bytes = await selectedImage.readAsBytes();
    if (bytes.length > 8 * 1024 * 1024) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Image must be smaller than 8 MB'))),
        );
      return;
    }
    setState(() => uploadingProfileImage = true);
    try {
      _applyUser(
        await ApiService.instance.uploadProfileImage(
          UploadImage(selectedImage.name, bytes),
        ),
      );
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr('Profile picture updated'))));
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr(error.message))));
    } finally {
      if (mounted) setState(() => uploadingProfileImage = false);
    }
  }

  bool get canChangeStoreNumber => daysUntilStoreChange == 0;

  int get daysUntilStoreChange {
    final remaining = lastStoreNumberChange
        .add(const Duration(days: 30))
        .difference(DateTime.now());
    if (remaining.isNegative || remaining == Duration.zero) return 0;
    return (remaining.inHours / 24).ceil();
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    storeNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (loadingProfile)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: RotatingLoader(size: 34),
                      ),
                    ),
                  Text(
                    tr('Your profile'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('These details will appear below your posts.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: const Color(0xffe1f0e9),
                          backgroundImage: profileImageUrl == null
                              ? null
                              : NetworkImage(profileImageUrl!),
                          child: profileImageUrl == null
                              ? const Icon(Icons.person_outline, size: 52)
                              : null,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: IconButton.filled(
                            tooltip: tr('Add profile picture'),
                            onPressed: uploadingProfileImage
                                ? null
                                : _pickProfileImage,
                            icon: uploadingProfileImage
                                ? const RotatingLoader(size: 20)
                                : const Icon(Icons.add_a_photo_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: uploadingProfileImage ? null : _pickProfileImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      profileImageUrl == null
                          ? tr('Add profile picture')
                          : tr('Change profile picture'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: name,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: tr('Name'),
                      prefixIcon: const Icon(Icons.person_outline),
                      suffixIcon: const Icon(Icons.lock_outline),
                      helperText: tr('Name cannot be changed'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phone,
                    readOnly: true,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: tr('Saudi phone number'),
                      prefixIcon: const Icon(Icons.phone_outlined),
                      suffixIcon: const Icon(Icons.lock_outline),
                      helperText: tr(
                        'Saudi numbers only (+966); cannot be changed',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: storeNumber,
                    readOnly: !canChangeStoreNumber,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: tr('Store number'),
                      hintText: tr('Example: 0101'),
                      prefixIcon: const Icon(Icons.store_outlined),
                      suffixIcon: Icon(
                        canChangeStoreNumber
                            ? Icons.edit_outlined
                            : Icons.lock_clock_outlined,
                      ),
                      helperText: canChangeStoreNumber
                          ? tr('Store number can be changed now')
                          : '${tr('Can be changed again in')} $daysUntilStoreChange ${tr('days')}',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: loadingProfile || savingProfile
                        ? null
                        : _saveProfile,
                    icon: const Icon(Icons.check),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: savingProfile
                          ? const RotatingLoader(size: 22)
                          : Text(tr('Save profile')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (ApiService.instance.currentUser?['isAdmin'] == true) ...[
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminReviewPage()),
                      ),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(tr('Review paid posts')),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: savingProfile ? null : widget.onSignOut,
                    icon: const Icon(Icons.logout),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(tr('Sign out')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AdminReviewPage extends StatefulWidget {
  const AdminReviewPage({super.key});

  @override
  State<AdminReviewPage> createState() => _AdminReviewPageState();
}

class _AdminReviewPageState extends State<AdminReviewPage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> posts = [];
  final reviewing = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await ApiService.instance.fetchPendingPosts();
      if (mounted) setState(() { posts = values; loading = false; error = null; });
    } on ApiException catch (exception) {
      if (mounted) setState(() { error = exception.message; loading = false; });
    }
  }

  Future<void> _review(Map<String, dynamic> post, bool approved) async {
    final id = post['id'].toString();
    if (reviewing.contains(id)) return;
    setState(() => reviewing.add(id));
    try {
      await ApiService.instance.reviewPost(id, approved);
      if (mounted) setState(() => posts.removeWhere((item) => item['id'].toString() == id));
    } on ApiException catch (exception) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => reviewing.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr('Review paid posts'))),
    body: loading
        ? const Center(child: RotatingLoader(size: 38))
        : error != null
            ? Center(child: Text(error!))
            : posts.isEmpty
                ? Center(child: Text(tr('No paid posts waiting for review')))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final id = post['id'].toString();
                      final proofUrl = post['payment_proof_url'] as String?;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(post['title'] as String? ?? '',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text('${post['user_name']} - ${post['phone']}'),
                              Text('${post['payment_amount']} ${post['payment_currency']}'),
                              if (proofUrl != null) ...[
                                const SizedBox(height: 12),
                                Image.network(proofUrl, height: 260, fit: BoxFit.contain),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: OutlinedButton.icon(
                                    onPressed: reviewing.contains(id) ? null : () => _review(post, false),
                                    icon: const Icon(Icons.close),
                                    label: Text(tr('Reject')),
                                  )),
                                  const SizedBox(width: 10),
                                  Expanded(child: FilledButton.icon(
                                    onPressed: reviewing.contains(id) ? null : () => _review(post, true),
                                    icon: reviewing.contains(id)
                                        ? const RotatingLoader(size: 20)
                                        : const Icon(Icons.check),
                                    label: Text(tr('Approve')),
                                  )),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
  );
}

class EmptyPage extends StatelessWidget {
  const EmptyPage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    ),
  );
}
