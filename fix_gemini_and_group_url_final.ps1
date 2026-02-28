# fix_gemini_and_group_url_final.ps1
Write-Host "🔧 Fixing Gemini AI integration and group info URL..." -ForegroundColor Cyan

# Backup important files
$backupDir = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Copy-Item "chat_project/settings.py" "$backupDir/settings.py.bak"
Copy-Item "apps/ai_assistant/adapters.py" "$backupDir/adapters.py.bak" -ErrorAction SilentlyContinue
Copy-Item "apps/ai_assistant/services.py" "$backupDir/services.py.bak" -ErrorAction SilentlyContinue
Copy-Item "chat_project/urls.py" "$backupDir/urls.py.bak"
Write-Host "✅ Backups created in $backupDir"

# 1. Add Gemini API key to settings.py
$settingsPath = "chat_project/settings.py"
$settings = Get-Content $settingsPath -Raw
if ($settings -notmatch "gemini") {
    $settings = $settings -replace '(AI_PROVIDERS\s*=\s*\{\s*deepseek:\s*\{[^}]+\}\s*)', "$1`n    'gemini': {`n        'api_key': os.getenv('GEMINI_API_KEY', ''),`n    },"
    Set-Content -Path $settingsPath -Value $settings -Encoding UTF8
    Write-Host "✅ Updated settings.py with Gemini API key."
} else {
    Write-Host "Gemini already in AI_PROVIDERS" -ForegroundColor Yellow
}

# 2. Replace adapters.py with both adapters (using single-quoted here-string)
$adaptersPath = "apps/ai_assistant/adapters.py"
$adapterContent = @'
import aiohttp
import json
import asyncio
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

class DeepSeekSmartReplyAdapter:
    def __init__(self):
        self.api_key = settings.AI_PROVIDERS['deepseek'].get('api_key', '')
        self.api_url = "https://api.deepseek.com/v1/chat/completions"
        
    async def generate_suggestions(self, conversation_history, max_suggestions=3):
        if not self.api_key:
            logger.warning("No DeepSeek API key, using fallback")
            return self._get_fallback_suggestions()
        
        prompt = self._build_prompt(conversation_history, max_suggestions)
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    self.api_url,
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": "deepseek-chat",
                        "messages": [
                            {
                                "role": "system", 
                                "content": "You are a smart reply generator. Generate short, natural reply options."
                            },
                            {
                                "role": "user",
                                "content": prompt
                            }
                        ],
                        "temperature": 0.3,
                        "max_tokens": 150
                    },
                    timeout=5
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        return self._parse_suggestions(result)
                    else:
                        return self._get_fallback_suggestions()
                        
        except Exception as e:
            logger.error(f"Error calling DeepSeek API: {e}")
            return self._get_fallback_suggestions()
    
    def _build_prompt(self, history, max_suggestions):
        recent = history[-6:] if len(history) > 6 else history
        history_text = "\n".join(recent)
        return f"""Based on this conversation:
{history_text}

Generate {max_suggestions} short, natural reply options.
Each reply should be under 60 characters.
Return ONLY a JSON array of strings.
Example: ["Thanks!", "Sounds good", "I'll check"]"""
    
    def _parse_suggestions(self, response):
        try:
            content = response['choices'][0]['message']['content']
            import re
            json_match = re.search(r'\[.*\]', content, re.DOTALL)
            if json_match:
                suggestions = json.loads(json_match.group())
                if isinstance(suggestions, list):
                    return [s.strip()[:60] for s in suggestions if s][:3]
        except:
            pass
        return self._get_fallback_suggestions()
    
    def _get_fallback_suggestions(self):
        from django.conf import settings
        return settings.SMART_REPLY['FALLBACK_SUGGESTIONS']


class GeminiSmartReplyAdapter:
    def __init__(self):
        self.api_key = settings.AI_PROVIDERS['gemini'].get('api_key', '')
        self.api_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
        
    async def generate_suggestions(self, conversation_history, max_suggestions=3):
        if not self.api_key:
            logger.warning("No Gemini API key, using fallback")
            return self._get_fallback_suggestions()
        
        prompt = self._build_prompt(conversation_history, max_suggestions)
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.api_url}?key={self.api_key}",
                    headers={"Content-Type": "application/json"},
                    json={
                        "contents": [{
                            "parts": [{"text": prompt}]
                        }],
                        "generationConfig": {
                            "temperature": 0.3,
                            "maxOutputTokens": 150,
                            "topP": 0.9
                        }
                    },
                    timeout=5
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        return self._parse_suggestions(result)
                    else:
                        error_text = await response.text()
                        logger.error(f"Gemini API error {response.status}: {error_text}")
                        return self._get_fallback_suggestions()
        except asyncio.TimeoutError:
            logger.warning("Gemini API timeout")
            return self._get_fallback_suggestions()
        except Exception as e:
            logger.error(f"Error calling Gemini API: {e}")
            return self._get_fallback_suggestions()
    
    def _build_prompt(self, history, max_suggestions):
        recent = history[-6:] if len(history) > 6 else history
        history_text = "\n".join(recent)
        return f"""Based on this conversation:
{history_text}

Generate {max_suggestions} short, natural reply options.
Each reply should be under 60 characters.
Return ONLY a JSON array of strings.
Example: ["Thanks!", "Sounds good", "I'll check"]"""
    
    def _parse_suggestions(self, response):
        try:
            content = response['candidates'][0]['content']['parts'][0]['text']
            import re
            json_match = re.search(r'\[.*\]', content, re.DOTALL)
            if json_match:
                suggestions = json.loads(json_match.group())
                if isinstance(suggestions, list):
                    return [s.strip()[:60] for s in suggestions if s][:3]
        except Exception as e:
            logger.error(f"Error parsing Gemini response: {e}")
        return self._get_fallback_suggestions()
    
    def _get_fallback_suggestions(self):
        from django.conf import settings
        return settings.SMART_REPLY['FALLBACK_SUGGESTIONS']
'@
Set-Content -Path $adaptersPath -Value $adapterContent -Encoding UTF8
Write-Host "✅ Updated adapters.py with both DeepSeek and Gemini adapters."

# 3. Update services.py to use Gemini adapter
$servicesPath = "apps/ai_assistant/services.py"
$servicesContent = Get-Content $servicesPath -Raw
$servicesContent = $servicesContent -replace 'self\.adapter = DeepSeekSmartReplyAdapter\(\)', 'self.adapter = GeminiSmartReplyAdapter()'
Set-Content -Path $servicesPath -Value $servicesContent -Encoding UTF8
Write-Host "✅ Updated services.py to use Gemini adapter."

# 4. Add group-info URL to chat_project/urls.py
$urlsPath = "chat_project/urls.py"
$urlsContent = Get-Content $urlsPath -Raw
if ($urlsContent -notmatch "group-info") {
    $newLine = "    path('group-info/<uuid:room_id>/', TemplateView.as_view(template_name='group_info.html'), name='group-info'),"
    $urlsContent = $urlsContent -replace '(\n\]$)', "`n$newLine`n]"
    Set-Content -Path $urlsPath -Value $urlsContent -Encoding UTF8
    Write-Host "✅ Added group-info URL pattern."
} else {
    Write-Host "Group-info URL already present." -ForegroundColor Yellow
}

# 5. Ensure group_info.html exists
$groupInfoPath = "templates/group_info.html"
if (-not (Test-Path $groupInfoPath)) {
    $groupInfoTemplate = @'
<!DOCTYPE html>
<html>
<head>
    <title>Group Info</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { display: flex; align-items: center; gap: 10px; border-bottom: 1px solid #ccc; padding-bottom: 10px; }
        .back-btn { text-decoration: none; font-size: 24px; color: #000; }
        .member-list { list-style: none; padding: 0; }
        .member-item { display: flex; justify-content: space-between; padding: 10px; border-bottom: 1px solid #eee; }
        .member-name { font-weight: bold; }
        .admin-badge { background: #ff9800; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <a href="javascript:history.back()" class="back-btn">←</a>
        <h2 id="room-name">Group Info</h2>
    </div>
    <ul id="member-list" class="member-list"></ul>

    <script>
        const roomId = window.location.pathname.split('/')[2];
        const token = localStorage.getItem('token');

        async function loadMembers() {
            const res = await fetch(`/api/chat/rooms/${roomId}/members/`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const members = await res.json();
                const list = document.getElementById('member-list');
                members.forEach(m => {
                    const li = document.createElement('li');
                    li.className = 'member-item';
                    li.innerHTML = `<span class="member-name">${m.username}</span>`;
                    if (m.role === 'admin') {
                        li.innerHTML += '<span class="admin-badge">Admin</span>';
                    }
                    list.appendChild(li);
                });
            } else {
                console.error('Failed to load members');
            }
        }

        loadMembers();
    </script>
</body>
</html>
'@
    Set-Content -Path $groupInfoPath -Value $groupInfoTemplate -Encoding UTF8
    Write-Host "✅ Created missing group_info.html template."
} else {
    Write-Host "group_info.html already exists." -ForegroundColor Yellow
}

# 6. Add GEMINI_API_KEY to .env
$envPath = ".env"
$envContent = Get-Content $envPath -Raw
if ($envContent -notmatch "GEMINI_API_KEY") {
    $envContent += "`nGEMINI_API_KEY=AIzaSyAhIU6gBF0uA0xmOgdV7NKh1Pb2VsoVVwc"
    Set-Content -Path $envPath -Value $envContent -Encoding UTF8
    Write-Host "✅ Added GEMINI_API_KEY to .env file."
} else {
    Write-Host "GEMINI_API_KEY already in .env." -ForegroundColor Yellow
}

# 7. Restart containers
Write-Host "Restarting web and celery containers..." -ForegroundColor Yellow
docker-compose restart web celery
Write-Host "✅ Containers restarted."

Write-Host "`n✅ Fixes applied successfully. Test group info page and smart replies." -ForegroundColor Green